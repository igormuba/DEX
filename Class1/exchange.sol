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
