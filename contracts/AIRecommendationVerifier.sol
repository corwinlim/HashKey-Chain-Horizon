// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AIRecommendationVerifier
 * @dev Verifies AI recommendations with traceable evidence and reasoning
 * Implements proof-of-computation pattern for AI inference results
 */

contract AIRecommendationVerifier {
    // AI Recommendation structure
    struct AIRecommendation {
        bytes32 recommendationId;    // Unique identifier
        bytes32 digitalTwinId;       // Reference to Digital Twin
        bytes32 inputHash;           // Hash of input data
        bytes32 outputHash;          // Hash of AI output
        bytes32 reasoningHash;       // Hash of reasoning/evidence
        address aiAgent;             // Address of AI agent
        uint256 timestamp;           // When recommendation made
        uint256 confidence;          // Confidence score (0-1000)
        bool isVerified;             // Verification status
        uint256 verificationCount;   // Number of independent verifications
    }

    // Verification proof structure
    struct VerificationProof {
        bytes32 recommendationId;
        address verifier;            // Who verified
        uint256 timestamp;
        bytes32 proofHash;           // Hash of proof data
        bool result;                 // Verification result
    }

    // Events
    event RecommendationCreated(bytes32 indexed recommendationId, bytes32 indexed digitalTwinId, address indexed aiAgent);
    event RecommendationVerified(bytes32 indexed recommendationId, bool result, uint256 verificationCount);
    event ProofSubmitted(bytes32 indexed recommendationId, address indexed verifier, bool result);

    // Storage
    mapping(bytes32 => AIRecommendation) public recommendations;
    mapping(bytes32 => VerificationProof[]) public verificationProofs;
    mapping(bytes32 => bytes32[]) public twinRecommendations;  // Twin -> Recommendations
    mapping(address => uint256) public agentReputationScore;   // Agent -> Reputation

    /**
     * @dev Submit an AI recommendation with evidence
     * @param _digitalTwinId Reference to Digital Twin
     * @param _inputHash Hash of input data used by AI
     * @param _outputHash Hash of AI output
     * @param _reasoningHash Hash of reasoning/evidence path
     * @param _confidence Confidence score of recommendation
     * @return recommendationId The unique identifier
     */
    function submitRecommendation(
        bytes32 _digitalTwinId,
        bytes32 _inputHash,
        bytes32 _outputHash,
        bytes32 _reasoningHash,
        uint256 _confidence
    ) external returns (bytes32) {
        require(_confidence <= 1000, "Confidence must be <= 1000");

        bytes32 recommendationId = keccak256(abi.encodePacked(
            msg.sender,
            _digitalTwinId,
            _outputHash,
            block.timestamp
        ));

        AIRecommendation storage rec = recommendations[recommendationId];
        rec.recommendationId = recommendationId;
        rec.digitalTwinId = _digitalTwinId;
        rec.inputHash = _inputHash;
        rec.outputHash = _outputHash;
        rec.reasoningHash = _reasoningHash;
        rec.aiAgent = msg.sender;
        rec.timestamp = block.timestamp;
        rec.confidence = _confidence;
        rec.isVerified = false;
        rec.verificationCount = 0;

        twinRecommendations[_digitalTwinId].push(recommendationId);

        // Initialize agent reputation if needed
        if (agentReputationScore[msg.sender] == 0) {
            agentReputationScore[msg.sender] = 500; // Start with neutral score
        }

        emit RecommendationCreated(recommendationId, _digitalTwinId, msg.sender);
        return recommendationId;
    }

    /**
     * @dev Submit verification proof for a recommendation
     * @param _recommendationId The recommendation identifier
     * @param _proofHash Hash of the verification proof
     * @param _result Verification result (true = valid, false = invalid)
     */
    function submitVerificationProof(
        bytes32 _recommendationId,
        bytes32 _proofHash,
        bool _result
    ) external {
        require(recommendations[_recommendationId].timestamp != 0, "Recommendation does not exist");

        AIRecommendation storage rec = recommendations[_recommendationId];
        rec.verificationCount += 1;

        // Mark as verified if we have at least one valid verification
        if (_result) {
            rec.isVerified = true;
            // Increase agent reputation on successful verification
            if (agentReputationScore[rec.aiAgent] < 1000) {
                agentReputationScore[rec.aiAgent] += 10;
            }
        } else {
            // Decrease agent reputation on failed verification
            if (agentReputationScore[rec.aiAgent] > 0) {
                agentReputationScore[rec.aiAgent] -= 20;
            }
        }

        VerificationProof memory proof = VerificationProof({
            recommendationId: _recommendationId,
            verifier: msg.sender,
            timestamp: block.timestamp,
            proofHash: _proofHash,
            result: _result
        });
        verificationProofs[_recommendationId].push(proof);

        emit ProofSubmitted(_recommendationId, msg.sender, _result);
        emit RecommendationVerified(_recommendationId, _result, rec.verificationCount);
    }

    /**
     * @dev Get recommendation details with full traceability
     * @param _recommendationId The recommendation identifier
     */
    function getRecommendation(bytes32 _recommendationId) external view returns (
        bytes32 recommendationId,
        bytes32 digitalTwinId,
        bytes32 inputHash,
        bytes32 outputHash,
        bytes32 reasoningHash,
        address aiAgent,
        uint256 timestamp,
        uint256 confidence,
        bool isVerified,
        uint256 verificationCount
    ) {
        AIRecommendation storage rec = recommendations[_recommendationId];
        return (
            rec.recommendationId,
            rec.digitalTwinId,
            rec.inputHash,
            rec.outputHash,
            rec.reasoningHash,
            rec.aiAgent,
            rec.timestamp,
            rec.confidence,
            rec.isVerified,
            rec.verificationCount
        );
    }

    /**
     * @dev Get verification proofs for a recommendation
     * @param _recommendationId The recommendation identifier
     */
    function getVerificationProofs(bytes32 _recommendationId) external view returns (VerificationProof[] memory) {
        return verificationProofs[_recommendationId];
    }

    /**
     * @dev Get recommendations for a Digital Twin
     * @param _digitalTwinId The Digital Twin identifier
     */
    function getRecommendationsForTwin(bytes32 _digitalTwinId) external view returns (bytes32[] memory) {
        return twinRecommendations[_digitalTwinId];
    }

    /**
     * @dev Get AI agent reputation score
     * @param _agent Address of the AI agent
     */
    function getAgentReputation(address _agent) external view returns (uint256) {
        return agentReputationScore[_agent];
    }
}
