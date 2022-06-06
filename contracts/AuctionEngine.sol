// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AuctionEngine {
    address public owner;
    uint constant DURATION = 2 days;
    uint constant FEE = 10; // 10%

    struct Auction {
        address payable seller;
        uint startPrice;
        uint finalPrice;
        uint startAt;
        uint endsAt;
        uint discountRate;
        string item;
        bool stopped;
    }

    Auction[] public auctions;
    
    event AuctionCreated(uint index, string itemName, uint startPrice, uint duration);
    event AuctionEnded(uint index, uint finalPrice, address winner);


    constructor() {
        owner = msg.sender;
    }

    function createAuction(uint _startPrice, uint _discountRate, string calldata _item, uint _duration) external {
        uint duration = _duration == 0 ? DURATION : _duration;

        require(_startPrice >= _discountRate * duration, "incorrect price");

        Auction memory newAuction = Auction({
            seller: payable(msg.sender),
            startPrice: _startPrice,
            finalPrice: _startPrice,
            discountRate: _discountRate,
            startAt: block.timestamp,
            endsAt: block.timestamp + duration,
            item: _item,
            stopped: false
        });

        auctions.push(newAuction);

        emit AuctionCreated(auctions.length - 1, _item, _startPrice, duration);
    }

    function getPrice(uint index) public view returns(uint) {
        Auction memory currentAuction = auctions[index];
        require(!currentAuction.stopped, "stopped");
        uint elapsed = block.timestamp - currentAuction.startAt;
        uint discount = currentAuction.discountRate * elapsed;
        return currentAuction.startPrice - discount;
    }

    function buy(uint index) external payable {
        Auction memory currentAuction = auctions[index];
        require(!currentAuction.stopped, "stopped");
        require(block.timestamp < currentAuction.endsAt, "ended");
        uint currentPrice = getPrice(index);
        require(msg.value >= currentPrice, "not enought funds!");
        currentAuction.stopped = true;
        currentAuction.finalPrice = currentPrice;

        uint refund = msg.value - currentPrice;

        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }

        currentAuction.seller.transfer(
            currentPrice - ((currentPrice * FEE) / 100)
        );

        emit AuctionEnded(index, currentPrice, msg.sender);
    }
}