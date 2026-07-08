// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ConsentManager
 * @dev Manages granular consent and authorization for data sharing
 * Maintains complete audit trail of all consents and revocations
 */

contract ConsentManager {
    // Consent scope structure
    struct ConsentScope {
        bytes32 scopeId;             // Unique consent scope identifier
        string scopeName;            // E.g., "medical_data", "ai_recommendations"
        string description;          // Detailed description
        bool isActive;               // Active status
    }

    // Consent grant structure
    struct ConsentGrant {
        bytes32 consentId;           // Unique consent identifier
        bytes32 digitalTwinId;       // Reference to Digital Twin
        address grantedTo;           // Who has permission
        bytes32 scopeId;             // What data/action
        address grantedBy;           // Who gave permission (owner)
        uint256 grantedAt;           // When granted
        uint256 expiresAt;           // Expiration time (0 = never)
        bool isActive;               // Active status
        uint256 accessCount;         // Number of times accessed
    }

    // Audit log entry
    struct AuditLog {
        bytes32 consentId;
        address actor;               // Who performed the action
        uint256 timestamp;
        string action;               // "granted", "revoked", "accessed", "expired"
        bool success;
    }

    // Events
    event ConsentScopeCreated(bytes32 indexed scopeId, string scopeName);
    event ConsentGranted(bytes32 indexed consentId, bytes32 indexed digitalTwinId, address indexed grantedTo);
    event ConsentRevoked(bytes32 indexed consentId, address indexed revokedBy);
    event ConsentAccessed(bytes32 indexed consentId, address indexed accessor);
    event AuditLogEntry(bytes32 indexed consentId, address indexed actor, string action);

    // Storage
    mapping(bytes32 => ConsentScope) public consentScopes;
    mapping(bytes32 => ConsentGrant) public consentGrants;
    mapping(bytes32 => AuditLog[]) public auditLogs;
    mapping(bytes32 => bytes32[]) public twinConsents;  // Twin -> Consents
    mapping(address => bytes32[]) public granterConsents;  // Grantee -> Consents granted

    bytes32[] public allScopes;

    /**
     * @dev Create a new consent scope
     * @param _scopeName Name of the consent scope
     * @param _description Description of what this scope covers
     * @return scopeId The unique identifier
     */
    function createConsentScope(string memory _scopeName, string memory _description) external returns (bytes32) {
        bytes32 scopeId = keccak256(abi.encodePacked(_scopeName, block.timestamp));

        ConsentScope storage scope = consentScopes[scopeId];
        scope.scopeId = scopeId;
        scope.scopeName = _scopeName;
        scope.description = _description;
        scope.isActive = true;

        allScopes.push(scopeId);

        emit ConsentScopeCreated(scopeId, _scopeName);
        return scopeId;
    }

    /**
     * @dev Grant consent to an entity
     * @param _digitalTwinId Reference to Digital Twin
     * @param _grantedTo Address to grant permission to
     * @param _scopeId Consent scope
     * @param _expiresAt Expiration timestamp (0 = never expires)
     * @return consentId The unique consent identifier
     */
    function grantConsent(
        bytes32 _digitalTwinId,
        address _grantedTo,
        bytes32 _scopeId,
        uint256 _expiresAt
    ) external returns (bytes32) {
        require(consentScopes[_scopeId].isActive, "Scope does not exist or is inactive");
        require(_grantedTo != address(0), "Invalid recipient address");

        bytes32 consentId = keccak256(abi.encodePacked(
            _digitalTwinId,
            _grantedTo,
            _scopeId,
            block.timestamp
        ));

        ConsentGrant storage consent = consentGrants[consentId];
        consent.consentId = consentId;
        consent.digitalTwinId = _digitalTwinId;
        consent.grantedTo = _grantedTo;
        consent.scopeId = _scopeId;
        consent.grantedBy = msg.sender;
        consent.grantedAt = block.timestamp;
        consent.expiresAt = _expiresAt;
        consent.isActive = true;
        consent.accessCount = 0;

        twinConsents[_digitalTwinId].push(consentId);
        granterConsents[_grantedTo].push(consentId);

        _logAuditEntry(consentId, msg.sender, "granted", true);
        emit ConsentGranted(consentId, _digitalTwinId, _grantedTo);

        return consentId;
    }

    /**
     * @dev Revoke a consent grant
     * @param _consentId The consent identifier
     */
    function revokeConsent(bytes32 _consentId) external {
        ConsentGrant storage consent = consentGrants[_consentId];
        require(consent.grantedBy == msg.sender, "Only grantor can revoke");
        require(consent.isActive, "Consent already inactive");

        consent.isActive = false;
        _logAuditEntry(_consentId, msg.sender, "revoked", true);
        emit ConsentRevoked(_consentId, msg.sender);
    }

    /**
     * @dev Record a consent access event
     * @param _consentId The consent identifier
     */
    function recordConsentAccess(bytes32 _consentId) external {
        ConsentGrant storage consent = consentGrants[_consentId];
        require(consent.isActive, "Consent is not active");
        require(
            consent.expiresAt == 0 || consent.expiresAt > block.timestamp,
            "Consent has expired"
        );
        require(consent.grantedTo == msg.sender, "Only grantee can access");

        consent.accessCount += 1;
        _logAuditEntry(_consentId, msg.sender, "accessed", true);
        emit ConsentAccessed(_consentId, msg.sender);
    }

    /**
     * @dev Get consent details
     * @param _consentId The consent identifier
     */
    function getConsentDetails(bytes32 _consentId) external view returns (
        bytes32 consentId,
        bytes32 digitalTwinId,
        address grantedTo,
        bytes32 scopeId,
        address grantedBy,
        uint256 grantedAt,
        uint256 expiresAt,
        bool isActive,
        uint256 accessCount
    ) {
        ConsentGrant storage consent = consentGrants[_consentId];
        return (
            consent.consentId,
            consent.digitalTwinId,
            consent.grantedTo,
            consent.scopeId,
            consent.grantedBy,
            consent.grantedAt,
            consent.expiresAt,
            consent.isActive,
            consent.accessCount
        );
    }

    /**
     * @dev Get audit trail for a consent
     * @param _consentId The consent identifier
     */
    function getConsentAuditTrail(bytes32 _consentId) external view returns (AuditLog[] memory) {
        return auditLogs[_consentId];
    }

    /**
     * @dev Get all consents for a Digital Twin
     * @param _digitalTwinId The Digital Twin identifier
     */
    function getConsentsForTwin(bytes32 _digitalTwinId) external view returns (bytes32[] memory) {
        return twinConsents[_digitalTwinId];
    }

    /**
     * @dev Internal function to log audit entries
     */
    function _logAuditEntry(bytes32 _consentId, address _actor, string memory _action, bool _success) internal {
        auditLogs[_consentId].push(AuditLog({
            consentId: _consentId,
            actor: _actor,
            timestamp: block.timestamp,
            action: _action,
            success: _success
        }));

        emit AuditLogEntry(_consentId, _actor, _action);
    }
}
