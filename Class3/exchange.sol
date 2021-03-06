pragma solidity ^0.5.0;

contract ERC20API{
    function allowance(address tokenOwner, address spender) public view returns (uint);
    function transfer(address to, uint tokens) public returns (bool);
    function transferFrom(address from, address to, uint tokens) public returns (bool);
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
    
    function() external payable{
        require(ethBalance[msg.sender]+msg.value>=ethBalance[msg.sender]);
        ethBalance[msg.sender]+=msg.value;
    }
    
    //<-function to buy tokens
    function buyToken(address _token, uint _price, uint _amount) public{

    }
    //function to buy tokens->
    
    //<-function to store unfilled order/remainings
    function storeBuyOrder(address _token, uint _price, uint _amount, address _maker) public{
        //not loading the token again to avoid reaching stack limit
        //as this function can be called from another function
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
    //function to store unfilled order/remainings->
    
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
