// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GizaProtocol {
    address public developer;

    // Parameters for residential properties
    uint256 public initialSalePercentage = 15; // % of initial sale price for workers
    uint256[] public resaleRoyalties = [5, 4, 3, 2]; // Resale royalties for residential
    uint256 public resaleCount;

    // Parameters for commercial properties
    uint256 public revenueSharingPercentage = 10; // % of recurring revenue shared with workers

    // Property Types
    enum PropertyType { Residential, Commercial }

    // Worker structure
    struct Worker {
        address wallet;
        uint256 contributionShare; // Share of the total contribution
        bool isRegistered;
    }

    // Property structure
    struct Property {
        string name;
        PropertyType propertyType;
        uint256 workerPoolBalance; // Funds allocated to workers
        address owner;
    }

    mapping(address => Worker) public workers; // Worker data
    address[] public workerAddresses;

    mapping(uint256 => Property) public properties; // Properties data
    uint256 public propertyCounter;

    // Events
    event WorkerRegistered(address indexed worker, uint256 contributionShare);
    event PaymentDistributed(address indexed recipient, uint256 amount);
    event PropertySold(uint256 indexed propertyId, address indexed newOwner, uint256 salePrice);
    event RevenueShared(uint256 indexed propertyId, uint256 revenueAmount);

    modifier onlyDeveloper() {
        require(msg.sender == developer, "Only the developer can perform this action");
        _;
    }

    modifier onlyPropertyOwner(uint256 propertyId) {
        require(msg.sender == properties[propertyId].owner, "Not the property owner");
        _;
    }

    constructor() {
        developer = msg.sender;
        resaleCount = 0;
        propertyCounter = 0;
    }

    // Register a worker
    function registerWorker(address _worker, uint256 _contributionShare) external onlyDeveloper {
        require(!workers[_worker].isRegistered, "Worker already registered");
        workers[_worker] = Worker({
            wallet: _worker,
            contributionShare: _contributionShare,
            isRegistered: true
        });
        workerAddresses.push(_worker);

        emit WorkerRegistered(_worker, _contributionShare);
    }

    // Add a new property (residential or commercial)
    function addProperty(string memory name, PropertyType propertyType, address owner) external onlyDeveloper {
        properties[propertyCounter] = Property({
            name: name,
            propertyType: propertyType,
            workerPoolBalance: 0,
            owner: owner
        });
        propertyCounter++;
    }

    // Helper function to calculate percentages
    function calculatePercentage(uint256 _amount, uint256 _percentage) internal pure returns (uint256) {
        return (_amount * _percentage) / 100;
    }

    // Distribute payments to workers
    function distributeToWorkers(uint256 workerPool) internal {
        for (uint256 i = 0; i < workerAddresses.length; i++) {
            address worker = workerAddresses[i];
            uint256 payment = (workerPool * workers[worker].contributionShare) / 100;
            payable(worker).transfer(payment);
            emit PaymentDistributed(worker, payment);
        }
    }

    // Handle initial sale for residential properties
    function initialSale(uint256 propertyId, uint256 salePrice) external payable onlyPropertyOwner(propertyId) {
        Property storage property = properties[propertyId];
        require(property.propertyType == PropertyType.Residential, "Property must be residential");
        require(msg.value == salePrice, "Sent value does not match sale price");

        uint256 workerPool = calculatePercentage(salePrice, initialSalePercentage);
        distributeToWorkers(workerPool);

        resaleCount++;
        emit PropertySold(propertyId, msg.sender, salePrice);
    }

    // Handle resale royalties for residential properties
    function resale(uint256 propertyId, uint256 resalePrice) external payable {
        Property storage property = properties[propertyId];
        require(property.propertyType == PropertyType.Residential, "Property must be residential");
        require(resaleCount > 0 && resaleCount <= resaleRoyalties.length, "Resale royalties exceeded");

        uint256 royaltyPercentage = resaleRoyalties[resaleCount - 1];
        uint256 workerPool = calculatePercentage(resalePrice, royaltyPercentage);
        distributeToWorkers(workerPool);

        resaleCount++;
        emit PropertySold(propertyId, msg.sender, resalePrice);
    }

    // Share recurring revenue for commercial properties
    function shareRevenue(uint256 propertyId, uint256 revenueAmount) external payable onlyPropertyOwner(propertyId) {
        Property storage property = properties[propertyId];
        require(property.propertyType == PropertyType.Commercial, "Property must be commercial");
        require(msg.value == revenueAmount, "Sent value does not match revenue amount");

        uint256 workerPool = calculatePercentage(revenueAmount, revenueSharingPercentage);
        property.workerPoolBalance += workerPool;
        distributeToWorkers(workerPool);

        emit RevenueShared(propertyId, revenueAmount);
    }

    // Check contract balance
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
