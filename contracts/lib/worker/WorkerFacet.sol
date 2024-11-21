// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibWorker {
    struct Worker {
        address wallet;
        uint256 contributionShare; // Share of the total contribution
        bool isRegistered;
    }

    struct WorkerStorage {
        mapping(address => Worker) workers;
        address[] workerAddresses;
    }

    bytes32 constant STORAGE_POSITION = keccak256("gizaprotocol.worker.storage");

    function workerStorage() internal pure returns (WorkerStorage storage ws) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ws.slot := position
        }
    }
}

contract WorkerFacet {
    event WorkerRegistered(address indexed worker, uint256 contributionShare);

    function registerWorker(address _worker, uint256 _contributionShare) external {
        LibWorker.WorkerStorage storage ws = LibWorker.workerStorage();
        require(!ws.workers[_worker].isRegistered, "Worker already registered");

        ws.workers[_worker] = LibWorker.Worker({
            wallet: _worker,
            contributionShare: _contributionShare,
            isRegistered: true
        });
        ws.workerAddresses.push(_worker);

        emit WorkerRegistered(_worker, _contributionShare);
    }

    function getWorker(address _worker) external view returns (LibWorker.Worker memory) {
        LibWorker.WorkerStorage storage ws = LibWorker.workerStorage();
        return ws.workers[_worker];
    }

    function getAllWorkers() external view returns (address[] memory) {
        LibWorker.WorkerStorage storage ws = LibWorker.workerStorage();
        return ws.workerAddresses;
    }
}
