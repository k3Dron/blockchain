// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MultiSigWallet is ReentrancyGuard {
    struct Transaction {
        address payable to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 approvalCount;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public requiredApprovals;
    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public approvals;

    event Deposit(address indexed sender, uint256 amount);
    event TransactionCreated(uint256 indexed txId, address indexed to, uint256 value, bytes data);
    event TransactionApproved(uint256 indexed txId, address indexed approver);
    event TransactionExecuted(uint256 indexed txId);

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "Transaction does not exist");
        _;
    }

    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "Transaction already executed");
        _;
    }

    modifier notApproved(uint256 _txId) {
        require(!approvals[_txId][msg.sender], "Transaction already approved");
        _;
    }

    constructor(address[] memory _owners, uint256 _requiredApprovals) {
        require(_owners.length > 0, "Owners required");
        require(
            _requiredApprovals > 0 && _requiredApprovals <= _owners.length,
            "Invalid required approvals"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        requiredApprovals = _requiredApprovals;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submitTransaction(address payable _to, uint256 _value, bytes memory _data ) public onlyOwner {
        transactions.push(Transaction({to: _to,value: _value,data: _data,executed: false,approvalCount: 0}));
        emit TransactionCreated(transactions.length - 1, _to, _value, _data);
    }

    function approveTransaction(uint256 _txId) public onlyOwner txExists(_txId) notExecuted(_txId) notApproved(_txId)    {
        approvals[_txId][msg.sender] = true;
        transactions[_txId].approvalCount++;
        emit TransactionApproved(_txId, msg.sender);
        if (transactions[_txId].approvalCount >= requiredApprovals) {
            _executeTransaction(_txId); 
        }
    }

    function getTransaction(uint256 _txId) public view txExists(_txId) returns ( address to, uint256 value, bytes memory data, bool executed, uint256 approvalCount )
    {
        Transaction memory transaction = transactions[_txId];
        return (transaction.to,transaction.value, transaction.data, transaction.executed, transaction.approvalCount
        );
    }

    function _executeTransaction(uint256 _txId) private txExists(_txId) notExecuted(_txId) nonReentrant
    {
        Transaction storage transaction = transactions[_txId];
        require( transaction.approvalCount >= requiredApprovals,  "Not enough approvals" );
        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "Transaction failed");
        emit TransactionExecuted(_txId);
    }
}


/*
For my use: 

[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB,
 0x17F6AD8Ef982297579C203069C1DbfFE4348c372], 3

0xdD870fA1b7C4700F2BD7f44238821C26f7392148,10, 0x446f6e6174696f6e20746f77617264732078797a
*/