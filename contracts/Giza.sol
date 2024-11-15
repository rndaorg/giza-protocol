// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Giza {
    address public developer;
    uint256 public initialSalePercentage = 15; // Initial sale percentage to pay contractors and workers
    uint256[] public resaleRoyalties = [5, 4, 3, 2]; // Royalties for each subsequent resale
    uint256 public resaleCount;

    struct Worker {
        address wallet;
        uint256 contributionShare; // Proportionate share of the total contribution
        bool isRegistered;
    }

    mapping(address => Worker) public workers;
    address[] public workerAddresses;
    
    event WorkerRegistered(address indexed worker, uint256 contributionShare);
    event PaymentDistributed(address indexed recipient, uint256 amount);
    event PropertySold(address indexed newOwner, uint256 salePrice);
    
    modifier onlyDeveloper() {
        require(msg.sender == developer, "Only the developer can perform this action");
        _;
    }

    constructor() {
        developer = msg.sender;
        resaleCount = 0;
    }

    // Register a worker with a proportionate contribution share
    function registerWorker(address _worker, uint256 _contributionShare) external onlyDeveloper {
        require(!workers[_worker].isRegistered, "Worker is already registered");
        workers[_worker] = Worker({
            wallet: _worker,
            contributionShare: _contributionShare,
            isRegistered: true
        });
        workerAddresses.push(_worker);
        
        emit WorkerRegistered(_worker, _contributionShare);
    }
    
    // Helper function to calculate percentages
    function calculatePercentage(uint256 _amount, uint256 _percentage) internal pure returns (uint256) {
        return (_amount * _percentage) / 100;
    }

    // Distribute initial sale amount to workers based on their contribution shares
    function distributeInitialSale(uint256 salePrice) internal {
        uint256 workerPool = calculatePercentage(salePrice, initialSalePercentage);
        
        for (uint256 i = 0; i < workerAddresses.length; i++) {
            address worker = workerAddresses[i];
            uint256 payment = (workerPool * workers[worker].contributionShare) / 100;
            payable(worker).transfer(payment);
            emit PaymentDistributed(worker, payment);
        }
    }

    // Distribute resale royalties, decreasing with each resale
    function distributeResaleRoyalty(uint256 resalePrice) internal {
        require(resaleCount < resaleRoyalties.length, "No more royalties due");

        uint256 royaltyPercentage = resaleRoyalties[resaleCount];
        uint256 workerPool = calculatePercentage(resalePrice, royaltyPercentage);

        for (uint256 i = 0; i < workerAddresses.length; i++) {
            address worker = workerAddresses[i];
            uint256 payment = (workerPool * workers[worker].contributionShare) / 100;
            payable(worker).transfer(payment);
            emit PaymentDistributed(worker, payment);
        }

        resaleCount++;
    }

    // Execute initial sale, and distribute payment
    function initialSale(address newOwner, uint256 salePrice) external payable onlyDeveloper {
        require(resaleCount == 0, "Initial sale has already been completed");
        require(msg.value == salePrice, "Sent value does not match sale price");

        distributeInitialSale(salePrice);

        resaleCount++;
        emit PropertySold(newOwner, salePrice);
    }

    // Execute a resale, triggering royalty payments
    function resale(address newOwner, uint256 resalePrice) external payable {
        require(resaleCount > 0 && resaleCount <= resaleRoyalties.length, "Resales exceeded royalty cap");
        require(msg.value == resalePrice, "Sent value does not match resale price");

        distributeResaleRoyalty(resalePrice);

        emit PropertySold(newOwner, resalePrice);
    }

    // Check the balance of the contract
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Fallback to receive Ether
    receive() external payable {}
}
