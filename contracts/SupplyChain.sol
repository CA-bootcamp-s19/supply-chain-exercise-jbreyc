pragma solidity ^0.5.0;

contract SupplyChain {
    /* set owner */
    address public owner;

    /* Add a variable called skuCount to track the most recent sku # */
    uint256 private skuCount;

    /* Add a line that creates a public mapping that maps the SKU (a number) to an Item.
     Call this mappings items
  */
    mapping(uint256 => Item) public items;
    /* Add a line that creates an enum called State. This should have 4 states
    ForSale
    Sold
    Shipped
    Received
    (declaring them in this order is important for testing)
  */
    enum State {ForSale, Sold, Shipped, Received}

    /* Create a struct named Item.
    Here, add a name, sku, price, state, seller, and buyer
    We've left you to figure out what the appropriate types are,
    if you need help you can ask around :)
    Be sure to add "payable" to addresses that will be handling value transfer
  */
    struct Item {
        string name;
        uint256 sku;
        uint256 price;
        State state;
        address payable seller;
        address payable buyer;
    }

    /* Create 4 events with the same name as each possible State (see above)
    Prefix each event with "Log" for clarity, so the forSale event will be called "LogForSale"
    Each event should accept one argument, the sku */
    event LogForSale(uint256 indexed sku);
    event LogSold(uint256 indexed sku);
    event LogShipped(uint256 indexed sku);
    event LogReceived(uint256 indexed sku);

    /* Create a modifer that checks if the msg.sender is the owner of the contract */
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "\u274C Only the owner can call this function"
        );
        _;
    }

    modifier verifyCaller(address _address) {
        require(msg.sender == _address);
        _;
    }

    modifier buyerPaidEnough(uint256 _sku) {
        require(msg.value >= items[_sku].price);
        _;
    }

    modifier returnExcess(uint256 _sku) {
        //refund them after pay for item (why it is before, _ checks for logic before func)
        _;
        uint256 _price = items[_sku].price;
        uint256 amountToRefund = msg.value - _price;
        items[_sku].buyer.transfer(amountToRefund);
    }

    /* For each of the following modifiers, use what you learned about modifiers
   to give them functionality. For example, the forSale modifier should require
   that the item with the given sku has the state ForSale. 
   Note that the uninitialized Item.State is 0, which is also the index of the ForSale value,
   so checking that Item.State == ForSale is not sufficient to check that an Item is for sale.
   Hint: What item properties will be non-zero when an Item has been added?
   */
    modifier itemExists(uint256 _sku) {
        require(
            _sku <= skuCount,
            "\u26D4 The given ID does not exist as an item in inventory"
        );
        _;
    }

    modifier isForSale(uint256 _sku) {
        require(
            items[_sku].state == State.ForSale,
            "\u26D4 The sku selected is not in ForSale status"
        );
        _;
    }

    modifier isSold(uint256 _sku) {
        require(
            items[_sku].state == State.Sold,
            "\u26D4 The sku selected is not in Sold status"
        );
        _;
    }

    modifier hasShipped(uint256 _sku) {
        require(
            items[_sku].state == State.Shipped,
            "\u26D4 The sku selected is not in Shipped status"
        );
        _;
    }

    modifier isReceived(uint256 _sku) {
        require(
            items[_sku].state == State.Received,
            "\u26D4 The sku selected is not in Received status"
        );
        _;
    }

    constructor() public {
        /* Here, set the owner as the person who instantiated the contract
       and set your skuCount to 0. */
        owner = msg.sender;
        skuCount = 0;
    }

    function addItem(string memory _name, uint256 _price)
        public
        returns (bool)
    {
        items[skuCount] = Item({
            name: _name,
            sku: skuCount,
            price: _price,
            state: State.ForSale,
            seller: msg.sender,
            buyer: address(0)
        });
        skuCount++;
        emit LogForSale(skuCount);

        return true;
    }

    /* Add a keyword so the function can be paid. This function should transfer money
    to the seller, set the buyer as the person who called this transaction, and set the state
    to Sold. Be careful, this function should use 3 modifiers to check if the item is for sale,
    if the buyer paid enough, and check the value after the function is called to make sure the buyer is
    refunded any excess ether sent. Remember to call the event associated with this function!*/

    function buyItem(uint256 sku)
        public
        payable
        itemExists(sku)
        isForSale(sku)
        buyerPaidEnough(sku)
        returnExcess(sku)
        returns (bool)
    {
        items[sku].seller.transfer(items[sku].price);
        items[sku].buyer = msg.sender;
        items[sku].state = State.Sold;

        emit LogSold(sku);

        return true;
    }

    /* Add 2 modifiers to check if the item is sold already, and that the person calling this function
  is the seller. Change the state of the item to shipped. Remember to call the event associated with this function!*/
    function shipItem(uint256 sku)
        public
        verifyCaller(items[sku].seller)
        isSold(sku)
        returns (bool)
    {
        items[sku].state = State.Shipped;

        emit LogShipped(sku);
        return true;
    }

    /* Add 2 modifiers to check if the item is shipped already, and that the person calling this function
  is the buyer. Change the state of the item to received. Remember to call the event associated with this function!*/
    function receiveItem(uint256 sku)
        public
        verifyCaller(items[sku].buyer)
        hasShipped(sku)
        returns (bool)
    {
        items[sku].state = State.Received;

        emit LogReceived(sku);
        return true;
    }

    /* We have these functions completed so we can run tests, just ignore it :) */
    function fetchItem(uint256 _sku)
        public
        view
        returns (
            string memory name,
            uint256 sku,
            uint256 price,
            uint256 state,
            address seller,
            address buyer
        )
    {
        name = items[_sku].name;
        sku = items[_sku].sku;
        price = items[_sku].price;
        state = uint256(items[_sku].state);
        seller = items[_sku].seller;
        buyer = items[_sku].buyer;
        return (name, sku, price, state, seller, buyer);
    }

}
