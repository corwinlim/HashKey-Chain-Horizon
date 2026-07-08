# CAIOS Trust Engine - Architecture Overview

## System Architecture

### 1. Core Components

#### A. Trust Registry (TrustRegistry.sol)
**Purpose**: Manage Digital Twin identities and trust scoring

- **Digital Twin Creation**: Each companion animal gets a unique, persistent digital identity
- **Trust Scoring**: 0-1000 scale trust score with verification tracking
- **Provider Authorization**: Granular control over which providers can access data
- **Features**:
  - Immutable identity creation timestamp
  - Verification history tracking
  - Multi-provider support with authorization management

#### B. Evidence Ledger (EvidenceLedger.sol)
**Purpose**: Immutable recording of clinical evidence and outcomes

- **Evidence Recording**: Clinical results, diagnoses, treatments
- **Temporal Tracking**: Complete timestamp history
- **Verification Status**: Track which evidence has been verified
- **Audit Trail**: Full access history for compliance
- **Features**:
  - Merkle tree compatible hashing
  - Evidence categorization (diagnosis, treatment, outcome)
  - Multi-party verification support

#### C. AI Recommendation Verifier (AIRecommendationVerifier.sol)
**Purpose**: Verifiable AI outputs with proof-of-computation

- **Recommendation Submission**: AI agents submit recommendations with evidence hashes
- **Input/Output/Reasoning Hashing**: Full traceability of AI decision path
- **Proof Verification**: Third parties can verify AI reasoning
- **Agent Reputation**: Dynamic scoring based on verification outcomes
- **Features**:
  - Confidence score tracking (0-1000)
  - Multi-layer verification support
  - Agent reputation system (-50 to +1000 range)

#### D. Consent Manager (ConsentManager.sol)
**Purpose**: Granular consent and authorization management

- **Scope Definition**: Create consent scopes (medical_data, ai_recommendations, etc.)
- **Consent Granting**: Time-limited or permanent consent with expiration
- **Access Tracking**: Record each access with full audit trail
- **Revocation**: Immediate revocation capability
- **Features**:
  - Expiration-based consent auto-revocation
  - Access counting for analytics
  - Comprehensive audit logging

#### E. Agent Coordinator (AgentCoordinator.sol)
**Purpose**: Multi-agent coordination and identity management

- **Agent Registration**: Register AI agents with identity and type
- **Trust Scoring**: Individual trust scores for each agent
- **Task Coordination**: Create collaborative tasks across multiple agents
- **Communication Logging**: Record all inter-agent communication
- **Features**:
  - Agent type categorization (diagnostic, treatment, monitoring)
  - Task completion statistics
  - Success rate tracking
  - Communication message hashing

---

## Data Flow

### Scenario 1: AI-based Automatic Payment

```
1. Digital Twin Created
   └─> TrustRegistry.createDigitalTwin()
   └─> Generates unique identity for pet

2. Veterinary Service Provided
   └─> EvidenceLedger.recordEvidence()
   └─> Records clinical outcome immutably

3. AI Recommendation for Payment
   └─> AIRecommendationVerifier.submitRecommendation()
   └─> Input: service type, cost, pet health status
   └─> Output: payment recommendation with confidence score
   └─> Reasoning: insurance eligibility, historical data

4. Verification and Consent Check
   └─> ConsentManager.recordConsentAccess()
   └─> Verify owner consent for automatic payment
   └─> TrustRegistry.verifyDigitalTwin()
   └─> Update trust score

5. Payment Execution
   └─> AIRecommendationVerifier.submitVerificationProof()
   └─> Confirmation recorded on chain
   └─> Evidence linked to payment
```

### Scenario 2: AI-powered Intelligent Trading

```
1. Multi-Agent Analysis
   └─> AgentCoordinator.createCoordinationTask()
   └─> Assign: diagnostic_agent, market_agent, risk_agent

2. Agent Communication
   └─> AgentCoordinator.logAgentCommunication()
   └─> Share analysis and insights
   └─> Each message hashed for verification

3. Collaborative Recommendation
   └─> AIRecommendationVerifier.submitRecommendation()
   └─> Multi-agent consensus-based recommendation
   └─> Input: market data, pet health trends, risk factors
   └─> Output: investment/trading strategy

4. Verification Proofs
   └─> Multiple agents submit verification proofs
   └─> Each proves their reasoning independently
   └─> Trust scores updated accordingly

5. Execution with Audit Trail
   └─> AgentCoordinator.completeCoordinationTask()
   └─> Task completion recorded
   └─> Full communication history preserved
   └─> EvidenceLedger.recordEvidence()
   └─> Outcome recorded for future reference
```

---

## Security Considerations

### 1. Identity Verification
- Digital Twin identities are cryptographically bound to owner
- Identity changes require explicit owner action
- Historical verification chains prevent impersonation

### 2. Data Integrity
- All evidence hashed with Merkle tree compatibility
- Immutable timestamp records
- Cryptographic proof of temporal order

### 3. Access Control
- Granular consent scopes
- Time-based consent expiration
- Complete audit trail of all accesses
- Role-based authorization

### 4. AI Trustworthiness
- Proof-of-computation verification
- Multi-layer verification support
- Agent reputation system
- Reasoning transparency (via hashes)

### 5. Privacy
- Selective disclosure of evidence
- Privacy-preserving consent management
- Hash-based evidence references (not full data)
- Zero-knowledge proof compatibility

---

## Integration with HashKey Chain

### Network Configuration
- **Mainnet**: https://hashkey-mainnet.example.com
- **Testnet**: https://hashkey-testnet.example.com
- **RPC**: Use chain endpoints from HashKey documentation

### HSP Integration Points
- **AI Model Verification**: Submit model outputs for verification
- **Proof Generation**: Use HSP for ZK proof generation
- **Service Coordination**: Coordinate multiple HSP services

### Cross-chain Capabilities (via CCIP)
- Bridge evidence to Ethereum for insurance verification
- Federated trust scoring across chains
- Cross-chain AI agent coordination

---

## Deployment Strategy

### Phase 1: Smart Contract Deployment
1. Deploy TrustRegistry on HashKey Chain Mainnet
2. Deploy EvidenceLedger linked to TrustRegistry
3. Deploy AIRecommendationVerifier
4. Deploy ConsentManager
5. Deploy AgentCoordinator

### Phase 2: Backend Services
1. Identity Service initialization
2. Evidence Service setup
3. Agent Coordinator service startup
4. HSP SDK integration

### Phase 3: Frontend Integration
1. Connect React frontend to contracts
2. Digital Twin dashboard
3. Evidence explorer
4. Consent management UI
5. Agent status dashboard

---

## Future Enhancements

1. **Zero-Knowledge Proofs**: Full privacy-preserving verification
2. **Multi-chain Consensus**: Aggregated trust across multiple blockchains
3. **Insurance Integration**: Automated claims processing
4. **Decentralized Oracles**: For real-world veterinary data feeds
5. **DAO Governance**: Community-driven trust parameter updates

---

For implementation details, see the contract-specific documentation.
