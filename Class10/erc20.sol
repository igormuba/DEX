pragma solidity ^0.5.0;

contract erc20{

    string public _tokenName;
    string public _tokenSymbol;
    address public creator; //address of contract creator to be defined
    uint256 public _totalSupply; //total coin supply
    mapping (address => mapping (address => uint256)) private _allowed; //allowance
    mapping (address => uint256) public balances; //like a dictionary, an address represents
                                                  // a positive integer
    // new variables can't be created
    //the above ones are created during contract creation

    //below is the constructor function called only when the contract is created
    constructor() public{
        _tokenName = "ERC20 Token"; //sets the name of the token
        _tokenSymbol = "ERCT"; //ticker symbol of the token
        creator = msg.sender; //the creator of the contract
        //msg.sender is automatically generated on contract deploy
        _totalSupply = 100; //sets the total supply
        balances[creator] = _totalSupply; //gives all the supply to the contract creator
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function balanceOf(address owner) public view returns(uint256){
        return balances[owner];
    }
    
    function approve(address _spender, uint _amount) public returns(bool){
        _allowed[msg.sender][_spender]=_amount;
    }

    function allowance(address owner, address spender) public view returns (uint256){
        return _allowed[owner][spender]; //adds to the allowance mapping
    }

    function transfer(address receiver, uint256 amount) 
        public returns(bool){
            address owner = msg.sender; //this is the caller of the function
            
            require(amount > 0); //the caller has to have a balance of more than zero tokens
            require(balances[owner] >= amount); //the balance must be bigger than the transaction amount
            
            balances[owner] -= amount; //deduct from the balance of the sender first
            balances[receiver] += amount; //add to the balance of the receiver after
            return true;
    }
         
    function transferFrom(address sender, address receiver, uint256 amount) public returns(bool){
            require(amount <= _allowed[sender][msg.sender]); //requires that the caller of the function has the permission to send this value from the sender of the amount
            
            require(amount > 0); //the caller has to have a balance of more than zero tokens
            require(balances[sender] >= amount); //the balance must be bigger than the transaction amount
            
            balances[sender] -= amount; //deduct from the balance of the sender first
            balances[receiver] += amount; //add to the balance of the receiver after
            return true;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

}
   


    

