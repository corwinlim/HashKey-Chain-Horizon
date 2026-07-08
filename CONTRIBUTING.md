# Contributing to CAIOS Trust Engine

## Development Branches

- `main` - Production-ready code
- `caios-trust-engine` - Active development branch
- `feature/*` - Feature branches

## Getting Started

### Prerequisites
- Node.js v18+
- Hardhat or Truffle (for smart contract development)
- HashKey Chain testnet setup
- HSP SDK configured

### Setup

```bash
git clone https://github.com/corwinlim/HashKey-Chain-Horizon.git
cd HashKey-Chain-Horizon
npm install
```

## Project Components

### Smart Contracts

1. **TrustRegistry.sol** - Core identity and digital twin management
2. **EvidenceLedger.sol** - Immutable clinical evidence storage
3. **AIRecommendationVerifier.sol** - Proof verification for AI outputs
4. **ConsentManager.sol** - Consent and authorization management
5. **AgentCoordinator.sol** - AI agent identity and coordination

### Backend Services

- Identity Service: Manage Digital Twin identities
- Evidence Service: Handle clinical evidence ledger operations
- Agent Coordinator: Orchestrate multiple AI agents

### Integration Points

- HSP SDK for AI model verification
- Chainlink CCIP for cross-chain operations
- HashKey Chain for main smart contract deployment

## Development Workflow

1. Create feature branch: `git checkout -b feature/your-feature-name`
2. Implement changes
3. Test thoroughly
4. Create Pull Request to `caios-trust-engine` branch
5. After review and testing, merge to `main`

---

For questions, join the community: https://t.me/HashKeyChainHSK/95285
