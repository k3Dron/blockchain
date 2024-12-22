// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DecentralizedAuction {
    address public seller;
    address public highestBidder;
    uint256 public highestBid;
    uint256 public initialValue;
    bool public auctionActive;

    event HighestBidderUpdated(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    constructor() {
        seller = msg.sender;
    }

    function launchAuction(uint256 _initialValue) public {
        require(msg.sender == seller, "Only the seller can start an auction!");
        auctionActive = true;
        initialValue = _initialValue;
    }

    function bid() public payable {
        require(auctionActive, "Auction has ended.");
        require(msg.value > initialValue, "Your bid is less than the initial bid value");
        require(msg.value > highestBid, "There already is a higher bidder");
        if (highestBid > 0) {
            (bool success, ) = payable(highestBidder).call{value: highestBid}("");
            require(success, "Refund to previous highest bidder failed");
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidderUpdated(msg.sender, msg.value);
    }

    function endAuction() public {
        require(msg.sender == seller, "Only the seller can end the auction");
        require(auctionActive, "Auction has already ended");
        auctionActive = false;
        payable(seller).transfer(highestBid);
        emit AuctionEnded(highestBidder, highestBid);
    }
}
