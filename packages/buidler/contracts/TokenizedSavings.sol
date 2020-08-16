pragma solidity ^0.6.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
contract TokenizedSavings is ERC721 {
    // Current State of the auction
    address payable public beneficiary;
    address public highestBidder;
    uint public highestBid;
    using Counters for Counters.Counter;
    Counters.Counter token_ids;
 //   constructor(address payable _beneficiary) ERC721("SavingsAccount", "SA") public {
 //       beneficiary = _beneficiary;
 //   }

     constructor() ERC721("SavingsAccount", "SA") public {
        //beneficiary = _beneficiary;
    }
    struct SavingsToken {
        string name;
        string account_holder;
        uint value;
    }
    mapping(uint => SavingsToken) public SavingsAccount;
    function registerAccount(address owner, string memory name, string memory account_holder,
        uint value, string memory token_uri) public returns(uint) {
         token_ids.increment();
         uint token_id = token_ids.current();
         _mint(owner, token_id);
         _setTokenURI(token_id, token_uri);
         SavingsAccount[token_id] = SavingsToken(name, account_holder, value);
         return token_id;
    }
    event Bid(uint token_id, uint value, string report_uri);
    function newBid(uint token_id, uint new_value, string memory report_uri)
        public returns (uint) {
        SavingsAccount[token_id].value = new_value;
        emit Bid(token_id, new_value, report_uri);
        return SavingsAccount[token_id].value;
    }
    // Allowed withdrawals of unfilled bids
    mapping(address => uint) pendingReturns;
    bool public ended;
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
    function bid() public payable {
        require(msg.value>highestBid, "There is already higher bid");
        require(!ended, "Auction has ended. Have a nice day.");
        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(highestBidder, highestBid);
    }
    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            if(!msg.sender.send(amount)) {
                pendingReturns[msg.sender] = amount;
            }
        }
        return true;
    }
    function pendingReturn() public view returns (uint) {
        return pendingReturns[msg.sender];
    }
    function auctionEnd() public {
        require(!ended, "This acution has already ended.");
        require(msg.sender == beneficiary, "You are not able to end this auction.");
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        beneficiary.transfer(highestBid);
    }
}
