// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EvidenceLedger
 * @dev Immutable ledger for clinical evidence and outcomes
 * Maintains tamper-proof records of medical data and AI recommendations
 */

contract EvidenceLedger {
    // Evidence record structure
    struct EvidenceRecord {
        bytes32 recordId;            // Unique record identifier
        bytes32 digitalTwinId;       // Reference to Digital Twin
        bytes32 evidenceHash;        // Hash of evidence data
        address recordedBy;          // Who recorded this evidence
        uint256 timestamp;           // When recorded
        string evidenceType;         // Type: "clinical", "recommendation", "outcome"
        string dataCategory;         // E.g., "diagnosis", "treatment", "outcome"
        bool isVerified;             // Verification status
        uint256 verificationCount;   // Number of verifications
    }

    // Audit log structure
    struct AuditEntry {
        bytes32 recordId;
        address accessor;
        uint256 timestamp;
        string action;               // "created", "verified", "accessed"
        bool success;
    }

    // Events
    event EvidenceRecorded(bytes32 indexed recordId, bytes32 indexed digitalTwinId, string evidenceType);
    event EvidenceVerified(bytes32 indexed recordId, uint256 verificationCount);
    event AuditLogCreated(bytes32 indexed recordId, address indexed accessor, string action);

    // Storage
    mapping(bytes32 => EvidenceRecord) public evidenceRecords;
    mapping(bytes32 => AuditEntry[]) public auditLogs;
    mapping(bytes32 => bytes32[]) public twinEvidence;  // Twin -> Evidence records

    /**
     * @dev Record clinical evidence on the ledger
     * @param _digitalTwinId Reference to the Digital Twin
     * @param _evidenceHash Hash of the evidence data
     * @param _evidenceType Type of evidence (clinical, recommendation, outcome)
     * @param _dataCategory Category of data
     * @return recordId The unique identifier for this record
     */
    function recordEvidence(
        bytes32 _digitalTwinId,
        bytes32 _evidenceHash,
        string memory _evidenceType,
        string memory _dataCategory
    ) external returns (bytes32) {
        bytes32 recordId = keccak256(abi.encodePacked(
            _digitalTwinId,
            _evidenceHash,
            block.timestamp,
            msg.sender
        ));

        EvidenceRecord storage record = evidenceRecords[recordId];
        record.recordId = recordId;
        record.digitalTwinId = _digitalTwinId;
        record.evidenceHash = _evidenceHash;
        record.recordedBy = msg.sender;
        record.timestamp = block.timestamp;
        record.evidenceType = _evidenceType;
        record.dataCategory = _dataCategory;
        record.isVerified = false;
        record.verificationCount = 0;

        twinEvidence[_digitalTwinId].push(recordId);

        // Create audit log
        _logAuditEntry(recordId, msg.sender, "created", true);

        emit EvidenceRecorded(recordId, _digitalTwinId, _evidenceType);
        return recordId;
    }

    /**
     * @dev Verify evidence record
     * @param _recordId The evidence record identifier
     */
    function verifyEvidence(bytes32 _recordId) external {
        require(evidenceRecords[_recordId].timestamp != 0, "Record does not exist");

        EvidenceRecord storage record = evidenceRecords[_recordId];
        record.verificationCount += 1;
        if (record.verificationCount >= 1) {
            record.isVerified = true;
        }

        _logAuditEntry(_recordId, msg.sender, "verified", true);
        emit EvidenceVerified(_recordId, record.verificationCount);
    }

    /**
     * @dev Get evidence record details
     * @param _recordId The evidence record identifier
     */
    function getEvidenceRecord(bytes32 _recordId) external view returns (
        bytes32 recordId,
        bytes32 digitalTwinId,
        bytes32 evidenceHash,
        address recordedBy,
        uint256 timestamp,
        string memory evidenceType,
        string memory dataCategory,
        bool isVerified,
        uint256 verificationCount
    ) {
        EvidenceRecord storage record = evidenceRecords[_recordId];
        return (
            record.recordId,
            record.digitalTwinId,
            record.evidenceHash,
            record.recordedBy,
            record.timestamp,
            record.evidenceType,
            record.dataCategory,
            record.isVerified,
            record.verificationCount
        );
    }

    /**
     * @dev Get all evidence for a Digital Twin
     * @param _digitalTwinId The Digital Twin identifier
     */
    function getEvidenceForTwin(bytes32 _digitalTwinId) external view returns (bytes32[] memory) {
        return twinEvidence[_digitalTwinId];
    }

    /**
     * @dev Get audit trail for a record
     * @param _recordId The record identifier
     */
    function getAuditTrail(bytes32 _recordId) external view returns (AuditEntry[] memory) {
        return auditLogs[_recordId];
    }

    /**
     * @dev Internal function to log audit entries
     */
    function _logAuditEntry(bytes32 _recordId, address _accessor, string memory _action, bool _success) internal {
        auditLogs[_recordId].push(AuditEntry({
            recordId: _recordId,
            accessor: _accessor,
            timestamp: block.timestamp,
            action: _action,
            success: _success
        }));

        emit AuditLogCreated(_recordId, _accessor, _action);
    }
}
