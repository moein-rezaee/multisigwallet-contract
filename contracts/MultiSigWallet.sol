// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Approve(uint indexed txId, address indexed owner);
    event Revoke(uint indexed txId, address indexed owner);
    event Execute(uint indexed txId);

    struct Transaction {
        address to;
        uint amount;
        bytes data;
        bool executed;
    }

    Transaction[] public transactions;
    address[] public owners;
    mapping(address => bool) public isOwner;
    mapping(uint => mapping(address => bool)) public approved;
    uint8 public approvers;

    modifier onlyOwner {
        require(isOwner[msg.sender], "Only owner has permission to submit transaction");
        _;
    }
    modifier notExecuted(uint txId) {
        require(!transactions[txId].executed, "Transaction already executed");
        _;
    }
    modifier notApproved(uint txId) {
        require(!approved[txId][msg.sender], "Transaction already approved");
        _;
    }
    modifier isApproved(uint txId) {
        require(approved[txId][msg.sender], "Transaction not approved");
        _;
    }
    modifier txExist(uint txId) {
        require(txId < transactions.length, "Transaction not found");
        _;
    }
    modifier validApproveCount(uint txId) {
        require(getApproversCount(txId) >= approvers, "Approve count is not valid");
        _;
    }

    function create(address[] memory Owners, uint8 Approvers) external {
        require(Owners.length > 0, "Please enter the owners");
        require(Approvers > 0 && Approvers < Owners.length, "Please enter valid approvers count");

        for (uint8 i; i < Owners.length; i++) 
        {
            address owner = Owners[i];
            require(owner != address(0), "Owner address is invalid");
            require(!isOwner[owner] , "Owner is not uinq");
            isOwner[owner] = true;
            owners.push(owner);
        }

        approvers = Approvers;
    }

    //واریز به قرارداد
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(address to, uint amount, bytes calldata data) public onlyOwner {
        transactions.push(Transaction ({
            to: to,
            amount: amount,
            data: data,
            executed: false
        }));
        emit Submit(transactions.length - 1);
    }

    function approve(uint txId) public onlyOwner txExist(txId) notApproved(txId) notExecuted(txId)  {
        approved[txId][msg.sender] = true;
        emit Approve(txId, msg.sender);
    }

    function getApproversCount(uint txId) private view returns(uint count) {
        for (uint8 i; i < owners.length; i++) 
            if(approved[txId][owners[i]]) count += 1;
        return count;
    }

    function execute(uint txId) external txExist(txId) notExecuted(txId) validApproveCount(txId) {
        Transaction storage trn = transactions[txId]; 
        trn.executed = true; 
        (bool success, ) = trn.to.call{value: trn.amount}(trn.data); 
        require(success, "Execute failed");
        emit Execute(txId);
    }

    function revoke(uint txId) external onlyOwner txExist(txId) notExecuted(txId) isApproved(txId) {
        approved[txId][msg.sender] = false;
        emit Revoke(txId, msg.sender);
    }
}
