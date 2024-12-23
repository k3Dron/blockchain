// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DecentralizedAuction {
    struct item {
        uint256 itemId;
        string itemName;
    }
    struct Auction {
        address seller;
        item itemDetail;
        uint256 initialBid;
        address highestBidder;
        uint256 highestBid;
        bool auctionActive;
    }
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => address) public owners;
    uint256 public auctionId;
    uint256 public itemId;
    event HighestBidderUpdated(uint256 auctionId, address bidder, uint256 amount);
    event AuctionEnded(uint256 auctionId, address winner, uint256 amount);

    function launchAuction(string memory _item, uint256 _initialValue) public {
        auctions[auctionId].seller = msg.sender;
        auctions[auctionId].itemDetail.itemName = _item;
        auctions[auctionId].itemDetail.itemId = itemId;
        auctions[auctionId].initialBid = _initialValue;
        auctions[auctionId].auctionActive = true;
        owners[itemId] = msg.sender;
        auctionId++;
        itemId++;
    }

    function bid(uint256 _auctionId) public payable {
        require(auctions[_auctionId].auctionActive, "Auction has ended.");
        require(msg.value > auctions[_auctionId].initialBid, "Your bid is less than the initial bid value");
        require(msg.value > auctions[_auctionId].highestBid, "There already is a higher bidder");
        if (auctions[_auctionId].highestBid > 0) {
            (bool success, ) = payable(auctions[_auctionId].highestBidder).call{value: auctions[_auctionId].highestBid}("");
            require(success, "Refund to previous highest bidder failed");
        }
        auctions[_auctionId].highestBidder = msg.sender;
        auctions[_auctionId].highestBid = msg.value;
        owners[auctions[auctionId].itemDetail.itemId] = auctions[_auctionId].highestBidder;
        emit HighestBidderUpdated(auctionId, msg.sender, msg.value);
    }

    function endAuction(uint256 _auctionId) public {
        require(msg.sender == auctions[_auctionId].seller, "Only the seller can end the auction");
        require(auctions[_auctionId].auctionActive, "Auction has already ended");
        auctions[_auctionId].auctionActive = false;
        owners[auctions[auctionId].itemDetail.itemId] = auctions[_auctionId].highestBidder;
        payable(auctions[_auctionId].seller).transfer(auctions[_auctionId].highestBid);
        emit AuctionEnded(auctionId, auctions[_auctionId].highestBidder, auctions[_auctionId].highestBid);
    }

}
