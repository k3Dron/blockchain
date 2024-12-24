// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Counters.sol";

contract SupplyChainTracking {
    using Counters for Counters.Counter;

    struct OwnerDetails {
        address ownerAddress;
        uint256 timestamp;
    }

    struct Product {
        uint256 id;
        string name;
        OwnerDetails currentOwner;
        string status;
    }

    Counters.Counter public productCounter;
    mapping(uint256 => Product) private productById;
    mapping(uint256 => OwnerDetails[]) private ownerHistory;
    event ProductAdded(uint256 id, string name, address owner, uint256 timestamp);
    event OwnershipTransferred(uint256 id, address newOwner, uint256 timestamp);
    event StatusUpdated(uint256 id, string status, uint256 timestamp);

    function addProduct(string memory _name) public {
        productCounter.increment();
        uint256 productId = productCounter.current();
        OwnerDetails memory newOwner = OwnerDetails({
            ownerAddress: msg.sender,
            timestamp: block.timestamp
        });

        productById[productId] = Product({
            id: productId,
            name: _name,
            currentOwner: newOwner,
            status: "Manufactured"
        });

        ownerHistory[productId].push(newOwner);

        emit ProductAdded(productId, _name, msg.sender, block.timestamp);
    }

    function transferOwnership(uint256 _productId, address _newOwner, string memory _status) public {
        Product storage product = productById[_productId];
        require(msg.sender == product.currentOwner.ownerAddress, "Only the current owner can transfer ownership");
        OwnerDetails memory newOwner = OwnerDetails({
            ownerAddress: _newOwner,
            timestamp: block.timestamp
        });
        product.currentOwner = newOwner;
        product.status = _status;
        ownerHistory[_productId].push(newOwner);
        emit OwnershipTransferred(_productId, _newOwner, block.timestamp);
        emit StatusUpdated(_productId, _status, block.timestamp);
    }

    function getProductHistory(uint256 _productId) public view returns (OwnerDetails[] memory) {
        return ownerHistory[_productId];
    }

    function getProductDetails(uint256 _productId) public view returns (
        uint256 id,
        string memory name,
        address currentOwner,
        string memory status,
        uint256 timestamp
    ) {
        Product memory product = productById[_productId];
        return (
            product.id,
            product.name,
            product.currentOwner.ownerAddress,
            product.status,
            product.currentOwner.timestamp
        );
    }
}
