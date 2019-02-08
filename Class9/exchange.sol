pragma solidity ^0.5.0;

contract ERC20API{
    function allowance(address tokenOwner, address spender) public view returns (uint);
    function transfer(address to, uint tokens) public returns (bool);
    function transferFrom(address _from, address to, uint tokens) public returns (bool);
}

contract exchange{
    
    struct Offer{
        uint amount;
        address maker;
    }
    struct OrderBook{
        uint higherPrice;
        uint lowerPrice;
        
        mapping (uint => Offer) offers;
        uint offerPointer;
        uint offerLength;
    }
    struct Token{
        address tokenContract;
        mapping (uint => OrderBook) buyBook;
        uint maxBuyPrice;
        uint minBuyPrice;
        uint amountBuyPrices;
        
        mapping (uint => OrderBook) sellBook;
        uint minSellPrice;
        uint maxSellPrice;
        uint amountSellPrice;
    }
    
    mapping (address=>Token) tokenList;
    
    mapping (address => uint) ethBalance;
    
    mapping (address => mapping(address=>uint)) tokenBalance;
    

    

    function buyToken(address _token, uint _price, uint _amount) public{

        Token storage loadedToken = tokenList[_token];
        uint ethRequired = _price*_amount;
        
        require(ethRequired>=_amount);
        require(ethRequired>=_price);
        require(ethBalance[msg.sender]>=ethRequired);
        require(ethBalance[msg.sender]-ethRequired>=0);
        require(ethBalance[msg.sender]-ethRequired<=ethBalance[msg.sender]);
        ethBalance[msg.sender]-=ethRequired;
        
        if (loadedToken.amountSellPrice==0||loadedToken.minSellPrice>=_price){
            storeBuyOrder(_token, _price, _amount, msg.sender);
        }else{
            
        }
    }
    
    function sellToken(address _token, uint _price, uint _amount) public{
        Token storage loadedToken = tokenList[_token];
        uint ethRequired = _price*_amount;
        
        require(ethRequired>=_amount);
        require(ethRequired>=_price);
        require(tokenBalance[msg.sender][_token]>=_amount);
        require(tokenBalance[msg.sender][_token]-_amount>=0);
        require(ethBalance[msg.sender]+ethRequired>=ethBalance[msg.sender]);
        
        tokenBalance[msg.sender][_token]-=_amount;
        
        if(loadedToken.amountBuyPrices==0||loadedToken.maxBuyPrice<_price){
            storeSellOrder(_token, _price, _amount, msg.sender);
        }else {//execute order
            uint sellPrice = loadedToken.maxBuyPrice;
            uint remainingAmount=_amount;
            uint offerPointer;
            while (sellPrice>=_price && remainingAmount > 0){
                offerPointer = loadedToken.buyBook[sellPrice].offerPointer;
                while(offerPointer<=loadedToken.buyBook[sellPrice].offerLength && remainingAmount>0){
                    uint volumeAtPointer = loadedToken.buyBook[sellPrice].offers[offerPointer].amount;
                    if (volumeAtPointer<=remainingAmount){
                        uint ethRequiredNow = volumeAtPointer*sellPrice;
                        require(tokenBalance[msg.sender][_token]>=volumeAtPointer);
                        require(tokenBalance[msg.sender][_token]-volumeAtPointer>=0);
                        tokenBalance[msg.sender][_token]-=volumeAtPointer;
                        tokenBalance[loadedToken.buyBook[sellPrice].offers[offerPointer].maker][_token]+=volumeAtPointer;
                        loadedToken.buyBook[sellPrice].offers[offerPointer].amount=0;
                        ethBalance[msg.sender]+=ethRequiredNow;
                        loadedToken.buyBook[sellPrice].offerPointer++;
                        remainingAmount-=volumeAtPointer;
                    }else{
                        require(volumeAtPointer-remainingAmount>0);
                        ethRequired = remainingAmount*sellPrice;
                        require(tokenBalance[msg.sender][_token]>=remainingAmount);
                        tokenBalance[msg.sender][_token]-=remainingAmount;
                        loadedToken.buyBook[sellPrice].offers[offerPointer].amount-=remainingAmount;
                        ethBalance[msg.sender]+=ethRequired;
                        tokenBalance[loadedToken.buyBook[sellPrice].offers[offerPointer].maker][_token]+=remainingAmount;
                        remainingAmount=0;
                    }
                    
                    if(offerPointer==loadedToken.buyBook[sellPrice].offerLength && loadedToken.buyBook[sellPrice].offers[offerPointer].amount==0){
                        loadedToken.amountBuyPrices--;
                        if (sellPrice==loadedToken.buyBook[sellPrice].lowerPrice || loadedToken.buyBook[sellPrice].lowerPrice==0){
                        loadedToken.maxBuyPrice=0;
                        }else {
                            loadedToken.maxBuyPrice=loadedToken.buyBook[sellPrice].lowerPrice;
                            loadedToken.buyBook[loadedToken.buyBook[sellPrice].lowerPrice].higherPrice=loadedToken.maxBuyPrice;
                        }
                    }
                    offerPointer++;
                }
                sellPrice=loadedToken.maxBuyPrice;
            }
            if (remainingAmount>0){
                sellToken(_token, _price, remainingAmount);
            }
        }
    }
    
    function storeSellOrder(address _token, uint _price, uint _amount, address _maker) private{
        tokenList[_token].sellBook[_price].offerLength++;
        tokenList[_token].sellBook[_price].offers[tokenList[_token].sellBook[_price].offerLength] = Offer(_amount, _maker);
        
        if (tokenList[_token].sellBook[_price].offerLength==1){
            tokenList[_token].sellBook[_price].offerPointer=1;
            tokenList[_token].amountSellPrice++;
            
            uint currentSellPrice = tokenList[_token].minSellPrice;
            uint highestSellPrice = tokenList[_token].maxSellPrice;
            
            if (highestSellPrice==0 || highestSellPrice<_price){
                if(currentSellPrice==0){
                    tokenList[_token].minSellPrice=_price;
                    tokenList[_token].sellBook[_price].higherPrice=0;
                    tokenList[_token].sellBook[_price].lowerPrice=0;
                }else{
                    tokenList[_token].sellBook[highestSellPrice].higherPrice = _price;
                    tokenList[_token].sellBook[_price].lowerPrice = highestSellPrice;
                    tokenList[_token].sellBook[_price].higherPrice = _price;
                }
                tokenList[_token].maxSellPrice=_price;
            }else if(currentSellPrice>_price){
                tokenList[_token].sellBook[currentSellPrice].lowerPrice=_price;
                tokenList[_token].sellBook[_price].higherPrice=currentSellPrice;
                tokenList[_token].sellBook[_price].lowerPrice=0;
                tokenList[_token].minSellPrice=_price;
            }else{
                uint sellPrice = tokenList[_token].minSellPrice;
                bool finished=false;
                while(sellPrice>0 && !finished){
                    if(sellPrice<_price&&tokenList[_token].sellBook[sellPrice].higherPrice>_price){
                        tokenList[_token].sellBook[_price].lowerPrice = sellPrice;
                        tokenList[_token].sellBook[_price].higherPrice = tokenList[_token].sellBook[sellPrice].higherPrice;
                        
                        tokenList[_token].sellBook[tokenList[_token].sellBook[sellPrice].higherPrice].lowerPrice=_price;
                        
                        tokenList[_token].sellBook[sellPrice].higherPrice = _price;
                    }
                    sellPrice=tokenList[_token].sellBook[sellPrice].higherPrice;
                }
            }
        }
    }
    
    function storeBuyOrder(address _token, uint _price, uint _amount, address _maker) private{
        tokenList[_token].buyBook[_price].offerLength++;
        tokenList[_token].buyBook[_price].offers[tokenList[_token].buyBook[_price].offerLength]=Offer(_amount, _maker);
        
        if(tokenList[_token].buyBook[_price].offerLength==1){
            tokenList[_token].buyBook[_price].offerPointer=1;
            tokenList[_token].amountBuyPrices++;
            
            uint currentBuyPrice = tokenList[_token].maxBuyPrice;
            uint lowestBuyPrice = tokenList[_token].minBuyPrice;
            
            if(lowestBuyPrice==0||lowestBuyPrice>_price){
                if (currentBuyPrice==0){
                    tokenList[_token].maxBuyPrice=_price;
                    tokenList[_token].buyBook[_price].higherPrice = _price;
                    tokenList[_token].buyBook[_price].lowerPrice = 0;
                }else{
                    tokenList[_token].buyBook[lowestBuyPrice].lowerPrice=_price;
                    tokenList[_token].buyBook[_price].higherPrice=lowestBuyPrice;
                    tokenList[_token].buyBook[_price].lowerPrice=0;
                }
                tokenList[_token].minBuyPrice=_price;
            }else if(currentBuyPrice<_price){
                tokenList[_token].buyBook[currentBuyPrice].higherPrice=_price;
                tokenList[_token].buyBook[_price].higherPrice=_price;
                tokenList[_token].buyBook[_price].lowerPrice=currentBuyPrice;
                tokenList[_token].maxBuyPrice=_price;
            }else{
                uint buyPrice = tokenList[_token].maxBuyPrice;
                bool finished=false;
                while(buyPrice>0&&!finished){
                    if(buyPrice<_price && tokenList[_token].buyBook[buyPrice].higherPrice>_price){
                        tokenList[_token].buyBook[_price].lowerPrice=buyPrice;
                        tokenList[_token].buyBook[_price].higherPrice=tokenList[_token].buyBook[buyPrice].higherPrice;
                        tokenList[_token].buyBook[tokenList[_token].buyBook[buyPrice].higherPrice].lowerPrice=_price;
                        tokenList[_token].buyBook[buyPrice].higherPrice=_price;
                        finished=true;
                    }
                    buyPrice=tokenList[_token].buyBook[buyPrice].lowerPrice;
                }
            }
        }
    }
    
    function removeOrder(address _token, bool isSellOrder, uint _price) public{
        Token storage loadedToken = tokenList[_token];
        if (isSellOrder){
            uint counter = loadedToken.sellBook[_price].offerPointer;
            while (counter <= loadedToken.sellBook[_price].offerLength){
                if (loadedToken.sellBook[_price].offers[counter].maker==msg.sender){
                    uint orderVolume = loadedToken.sellBook[_price].offers[counter].amount;
                    require(tokenBalance[msg.sender][_token]+orderVolume>=tokenBalance[msg.sender][_token]);
                    loadedToken.sellBook[_price].offers[counter].amount=0;
                    tokenBalance[msg.sender][_token]+=orderVolume;
                }
                counter++;
            }
        }else {
            uint counter = loadedToken.buyBook[_price].offerPointer;
            while (counter <= loadedToken.buyBook[_price].offerLength){
                if (loadedToken.buyBook[_price].offers[counter].maker==msg.sender){
                    uint orderVolume = loadedToken.buyBook[_price].offers[counter].amount*_price;
                    require(ethBalance[msg.sender]+orderVolume>=ethBalance[msg.sender]);
                    loadedToken.buyBook[_price].offers[counter].amount=0;
                }
                counter++;
            }
        }
    }
    
    function getSellOrders(address _token) public view returns(uint[] memory, uint[] memory){
        Token storage loadedToken = tokenList[_token];
        uint[] memory ordersPrices = new uint[](loadedToken.amountSellPrice);
        uint[] memory ordersvolumes = new uint[](loadedToken.amountSellPrice);
        
        uint sellPrice = loadedToken.minSellPrice;
        uint counter = 0;
        
        if (loadedToken.minSellPrice>0){
            while(sellPrice<=loadedToken.maxSellPrice){
                
                
                 ordersPrices[counter] = sellPrice;
                 uint priceVolume = 0;
                 uint offerPointer = loadedToken.sellBook[sellPrice].offerPointer;
                
                while(offerPointer <=loadedToken.sellBook[sellPrice].offerLength){
                    priceVolume += loadedToken.sellBook[sellPrice].offers[offerPointer].amount;
                    offerPointer++;
                }
                ordersvolumes[counter]=priceVolume;
                if (sellPrice==loadedToken.sellBook[sellPrice].higherPrice){
                    break;
                }else{
                    sellPrice=loadedToken.sellBook[sellPrice].higherPrice;
                }
                counter++;
            }
        }
        return(ordersPrices, ordersvolumes);
    }
    
    function getBuyOrders(address _token) public view returns(uint[] memory, uint[] memory){
        Token storage loadedToken = tokenList[_token];
        uint[] memory ordersPrices = new uint[](loadedToken.amountBuyPrices);
        uint[] memory ordersvolumes = new uint[](loadedToken.amountBuyPrices);
        
        uint buyPrice = loadedToken.minBuyPrice;
        uint counter = 0;
        
        if (loadedToken.maxBuyPrice>0){
            while(buyPrice<=loadedToken.maxBuyPrice){
                ordersPrices[counter]=buyPrice;
                uint priceVolume=0;
                uint offerPointer=loadedToken.buyBook[buyPrice].offerPointer;
                
                while(offerPointer<=loadedToken.buyBook[buyPrice].offerLength){
                    priceVolume+=loadedToken.buyBook[buyPrice].offers[offerPointer].amount;
                    offerPointer++;
                }
                
                ordersvolumes[counter] = priceVolume;
                
                if (buyPrice==loadedToken.buyBook[buyPrice].higherPrice){
                    break;
                }else{
                    buyPrice=loadedToken.buyBook[buyPrice].higherPrice;
                }
                counter++;
            }
        }
        
        return(ordersPrices, ordersvolumes);
    }
    
    function() external payable{
        require(ethBalance[msg.sender]+msg.value>=ethBalance[msg.sender]);
        ethBalance[msg.sender]+=msg.value;
    }    
    
    function withdrawEth(uint _wei) public {
        require(ethBalance[msg.sender]-_wei>=0);
        require(ethBalance[msg.sender]-_wei<=ethBalance[msg.sender]);
        ethBalance[msg.sender]-=_wei;
        msg.sender.transfer(_wei);
    }
    
    function depositToken(address _token, uint _amount) public {
        ERC20API tokenLoaded = ERC20API(_token);
        require(tokenLoaded.allowance(msg.sender, address(this))>=_amount);
        require(tokenLoaded.transferFrom(msg.sender, address(this), _amount));
        tokenBalance[msg.sender][_token]+=_amount;
    }
    
    function withdrawToken(address _token, uint _amount) public {
        ERC20API tokenLoaded = ERC20API(_token);
        require(tokenBalance[msg.sender][_token]-_amount>=0);
        require(tokenBalance[msg.sender][_token]-_amount<=tokenBalance[msg.sender][_token]);
        tokenBalance[msg.sender][_token]-=_amount;
        require(tokenLoaded.transfer(msg.sender, _amount));
    }
 
}
