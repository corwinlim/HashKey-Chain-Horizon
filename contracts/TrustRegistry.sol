// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TrustRegistry
 * @dev Core contract for Digital Twin Identity and Trust Registry management
 * Manages unique identities for companion animals and their verification status
 */

contract TrustRegistry {
    // Digital Twin structure
    struct DigitalTwin {
        bytes32 twinId;              // Unique identifier
        address owner;               // Owner address
        bytes32 identityHash;        // Cryptographic hash of identity
        uint256 createdAt;           // Creation timestamp
        uint256 lastVerified;        // Last verification timestamp
        bool isActive;               // Active status
        mapping(address => bool) authorizedProviders;  // Authorized data providers
    }

    // Trust score structure
    struct TrustScore {
        uint256 score;               // 0-1000 scale
        uint256 lastUpdated;         // Last update timestamp
        uint256 verificationCount;   // Number of verifications
        uint256 evidenceCount;       // Number of linked evidence items
    }

    // Events
    event DigitalTwinCreated(bytes32 indexed twinId, address indexed owner);
    event DigitalTwinVerified(bytes32 indexed twinId, uint256 trustScore);
    event ProviderAuthorized(bytes32 indexed twinId, address indexed provider);
    event ProviderRevoked(bytes32 indexed twinId, address indexed provider);
    event TrustScoreUpdated(bytes32 indexed twinId, uint256 newScore);

    // Storage
    mapping(bytes32 => DigitalTwin) public digitalTwins;
    mapping(bytes32 => TrustScore) public trustScores;
    mapping(address => bytes32[]) public ownerTwins;

    /**
     * @dev Create a new Digital Twin for a companion animal
     * @param _identityHash Hash of the animal's identity data
     * @return twinId The unique identifier for the Digital Twin
     */
    function createDigitalTwin(bytes32 _identityHash) external returns (bytes32) {
        bytes32 twinId = keccak256(abi.encodePacked(msg.sender, block.timestamp, _identityHash));
        require(digitalTwins[twinId].createdAt == 0, "Twin already exists");

        DigitalTwin storage twin = digitalTwins[twinId];
        twin.twinId = twinId;
        twin.owner = msg.sender;
        twin.identityHash = _identityHash;
        twin.createdAt = block.timestamp;
        twin.isActive = true;

        ownerTwins[msg.sender].push(twinId);

        // Initialize trust score
        trustScores[twinId].score = 500; // Start with neutral score
        trustScores[twinId].lastUpdated = block.timestamp;

        emit DigitalTwinCreated(twinId, msg.sender);
        return twinId;
    }

    /**
     * @dev Verify and update trust score for a Digital Twin
     * @param _twinId The Digital Twin identifier
     * @param _newScore Updated trust score
     */
    function verifyDigitalTwin(bytes32 _twinId, uint256 _newScore) external {
        require(digitalTwins[_twinId].createdAt != 0, "Twin does not exist");
        require(_newScore <= 1000, "Score must be <= 1000");

        DigitalTwin storage twin = digitalTwins[_twinId];
        twin.lastVerified = block.timestamp;

        TrustScore storage score = trustScores[_twinId];
        score.score = _newScore;
        score.lastUpdated = block.timestamp;
        score.verificationCount += 1;

        emit DigitalTwinVerified(_twinId, _newScore);
        emit TrustScoreUpdated(_twinId, _newScore);
    }

    /**
     * @dev Authorize a data provider for a Digital Twin
     * @param _twinId The Digital Twin identifier
     * @param _provider Address of the provider
     */
    function authorizeProvider(bytes32 _twinId, address _provider) external {
        require(digitalTwins[_twinId].owner == msg.sender, "Only owner can authorize");
        digitalTwins[_twinId].authorizedProviders[_provider] = true;
        emit ProviderAuthorized(_twinId, _provider);
    }

    /**
     * @dev Revoke provider authorization
     * @param _twinId The Digital Twin identifier
     * @param _provider Address of the provider
     */
    function revokeProvider(bytes32 _twinId, address _provider) external {
        require(digitalTwins[_twinId].owner == msg.sender, "Only owner can revoke");
        digitalTwins[_twinId].authorizedProviders[_provider] = false;
        emit ProviderRevoked(_twinId, _provider);
    }

    /**
     * @dev Get Digital Twin details
     * @param _twinId The Digital Twin identifier
     */
    function getDigitalTwin(bytes32 _twinId) external view returns (
        bytes32 twinId,
        address owner,
        bytes32 identityHash,
        uint256 createdAt,
        uint256 lastVerified,
        bool isActive
    ) {
        DigitalTwin storage twin = digitalTwins[_twinId];
        return (
            twin.twinId,
            twin.owner,
            twin.identityHash,
            twin.createdAt,
            twin.lastVerified,
            twin.isActive
        );
    }

    /**
     * @dev Get trust score for a Digital Twin
     * @param _twinId The Digital Twin identifier
     */
    function getTrustScore(bytes32 _twinId) external view returns (uint256, uint256, uint256) {
        TrustScore storage score = trustScores[_twinId];
        return (score.score, score.verificationCount, score.evidenceCount);
    }
}
