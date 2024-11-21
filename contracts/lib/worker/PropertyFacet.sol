// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibProperty {
    struct Property {
        string name;
        uint256 propertyType; // 0 = Residential, 1 = Commercial
        uint256 workerPoolBalance; // Funds allocated to workers
        address owner;
    }

    struct PropertyStorage {
        mapping(uint256 => Property) properties;
        uint256 propertyCounter;
    }

    bytes32 constant STORAGE_POSITION = keccak256("gizaprotocol.property.storage");

    function propertyStorage() internal pure returns (PropertyStorage storage ps) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }
}

contract PropertyFacet {
    event PropertyAdded(uint256 indexed propertyId, string name, uint256 propertyType, address owner);

    function addProperty(
        string memory _name,
        uint256 _propertyType,
        address _owner
    ) external {
        LibProperty.PropertyStorage storage ps = LibProperty.propertyStorage();
        ps.properties[ps.propertyCounter] = LibProperty.Property({
            name: _name,
            propertyType: _propertyType,
            workerPoolBalance: 0,
            owner: _owner
        });
        emit PropertyAdded(ps.propertyCounter, _name, _propertyType, _owner);
        ps.propertyCounter++;
    }

    function getProperty(uint256 propertyId) external view returns (LibProperty.Property memory) {
        LibProperty.PropertyStorage storage ps = LibProperty.propertyStorage();
        return ps.properties[propertyId];
    }
}
