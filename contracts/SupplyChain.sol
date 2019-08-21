// Implement the smart contract SupplyChain following the provided instructions.
// Look at the tests in SupplyChain.test.js and run 'truffle test' to be sure that your contract is working properly.
// Only this file (SupplyChain.sol) should be modified, otherwise your assignment submission may be disqualified.

pragma solidity ^0.5.0;

contract SupplyChain {
    address payable owner = msg.sender;
    
    // Create a variable named 'itemIdCount' to store the number of items and also be used as reference for the next itemId.
    uint itemIdCount;

    // Create an enumerated type variable named 'State' to list the possible states of an item (in this order): 'ForSale', 'Sold', 'Shipped' and 'Received'.
    enum State { ForSale, Sold, Shipped, Received }

    // Create a struct named 'Item' containing the following members (in this order): 'name', 'price', 'state', 'seller' and 'buyer'. 
    struct Item {
        string name;
        uint price;
        State state;
        address payable seller;
        address payable buyer;
    }
    
    // Create a variable named 'items' to map itemIds to Items.
    mapping(uint => Item) items;
    
    // Create an event to log all state changes for each item.
    event StateChangeItem( 
        uint indexed itemId,
        string name,
        State state
    );

    // Create a modifier named 'onlyOwner' where only the contract owner can proceed with the execution.
    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner of this contract can proceed this execution!");
        _;
    }

    // Create a modifier named 'checkState' where the execution can only proceed if the respective Item of a given itemId is in a specific state.
    modifier checkState(uint _itemID, State _state){
        require(items[_itemID].state == _state, "State of this item did not met the specific state!");
        _;
    }
    
    // Create a modifier named 'checkCaller' where only the buyer or the seller (depends on the function) of an Item can proceed with the execution.
    modifier checkCaller(address _buyerOrSeller){
        require(msg.sender == _buyerOrSeller, "Only buyer or seller can proceed this execution!");
        _;
    }
    
    // Create a modifier named 'checkValue' where the execution can only proceed if the caller sent enough Ether to pay for a specific Item or fee.
    modifier checkValue(uint _value){
        require(msg.value >= _value, "You need to pay more!");
        _;
    }


    // Create a function named 'addItem' that allows anyone to add a new Item by paying a fee of 1 finney. Any overpayment amount should be returned to the caller. All struct members should be mandatory except the buyer.
    function addItem(string memory _name, uint _price) public payable checkValue(1 finney) returns(uint){
        uint itemId = itemIdCount ++;
        
        items[itemId].name = _name;
        items[itemId].price = _price;
        items[itemId].state = State.ForSale;
        items[itemId].seller = msg.sender;
        
        if(msg.value > 1 finney){
            uint changes = msg.value - 1 finney;
            msg.sender.transfer(changes);
        }
        
        emit StateChangeItem(itemId, _name, State.ForSale);
        
        return itemId;
    }
    
    // Create a function named 'buyItem' that allows anyone to buy a specific Item by paying its price. The price amount should be transferred to the seller and any overpayment amount should be returned to the buyer.
    function buyItem(uint _itemID) public payable checkState(_itemID ,State.ForSale) checkValue(items[_itemID].price){
        items[_itemID].buyer = msg.sender;
        items[_itemID].state = State.Sold;
        
        items[_itemID].seller.transfer(items[_itemID].price);
        
        if(msg.value > items[_itemID].price){
            uint changes = msg.value - items[_itemID].price;
            msg.sender.transfer(changes);
        }
        
        emit StateChangeItem(_itemID, items[_itemID].name, State.Sold);
    }
    
    // Create a function named 'shipItem' that allows the seller of a specific Item to record that it has been shipped.
    function shipItem(uint _itemID) public checkCaller(items[_itemID].seller) checkState(_itemID, State.Sold) {
        items[_itemID].state = State.Shipped;
        emit StateChangeItem(_itemID, items[_itemID].name, State.Shipped);
    }
    
    // Create a function named 'receiveItem' that allows the buyer of a specific Item to record that it has been received.
    function receiveItem(uint _itemID) public checkCaller(items[_itemID].buyer) checkState(_itemID, State.Shipped) {
        items[_itemID].state = State.Received;
        emit StateChangeItem(_itemID, items[_itemID].name, State.Received);
    }
    
    // Create a function named 'getItem' that allows anyone to get all the information of a specific Item in the same order of the struct Item. 
    function getItem(uint _itemID) public view returns(string memory, uint, State, address, address) {
        require(_itemID < itemIdCount, "There is no item in this itemID!");
        return (
            items[_itemID].name,
            items[_itemID].price,
            items[_itemID].state,
            items[_itemID].seller,
            items[_itemID].buyer
            );
    }

    // Create a function named 'withdrawFunds' that allows the contract owner to withdraw all the available funds.
    function withdrawFunds() public payable onlyOwner() {
        owner.transfer(address(this).balance);
    }
}

