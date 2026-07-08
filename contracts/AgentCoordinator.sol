// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AgentCoordinator
 * @dev Manages AI Agent identity, coordination, and trust scoring
 * Enables secure collaboration between multiple AI agents
 */

contract AgentCoordinator {
    // AI Agent identity structure
    struct AIAgentIdentity {
        bytes32 agentId;             // Unique agent identifier
        address agentAddress;        // Wallet address of agent
        string agentName;            // Human-readable name
        string agentType;            // Type of agent (e.g., "diagnostic", "treatment", "monitoring")
        uint256 registeredAt;        // Registration timestamp
        uint256 trustScore;          // Trust score (0-1000)
        bool isActive;               // Active status
        uint256 tasksCompleted;      // Number of completed tasks
        uint256 successfulTasks;     // Number of successful tasks
    }

    // Task coordination structure
    struct CoordinationTask {
        bytes32 taskId;              // Unique task identifier
        bytes32[] assignedAgents;    // Array of assigned agent IDs
        bytes32 digitalTwinId;       // Reference to Digital Twin
        string taskType;             // Type of task
        uint256 createdAt;           // Creation timestamp
        uint256 completedAt;         // Completion timestamp (0 if pending)
        bool isCompleted;            // Completion status
        bytes32 resultHash;          // Hash of coordination result
    }

    // Agent communication log
    struct CommunicationLog {
        bytes32 taskId;
        bytes32 fromAgentId;
        bytes32 toAgentId;
        uint256 timestamp;
        bytes32 messageHash;         // Hash of message content
        string messageType;          // Type of communication
    }

    // Events
    event AgentRegistered(bytes32 indexed agentId, address indexed agentAddress, string agentName);
    event AgentDeactivated(bytes32 indexed agentId);
    event TrustScoreUpdated(bytes32 indexed agentId, uint256 newScore);
    event CoordinationTaskCreated(bytes32 indexed taskId, bytes32[] assignedAgents);
    event CoordinationTaskCompleted(bytes32 indexed taskId, bytes32 resultHash);
    event AgentCommunication(bytes32 indexed taskId, bytes32 indexed fromAgent, bytes32 indexed toAgent);

    // Storage
    mapping(bytes32 => AIAgentIdentity) public agents;
    mapping(address => bytes32) public addressToAgentId;  // Address -> Agent ID
    mapping(bytes32 => CoordinationTask) public coordinationTasks;
    mapping(bytes32 => CommunicationLog[]) public communicationLogs;  // Task -> Communication logs
    mapping(bytes32 => bytes32[]) public agentTasks;  // Agent -> Tasks assigned

    bytes32[] public allAgents;

    /**
     * @dev Register a new AI agent
     * @param _agentName Human-readable name
     * @param _agentType Type of agent (diagnostic, treatment, monitoring, etc.)
     * @return agentId The unique agent identifier
     */
    function registerAgent(string memory _agentName, string memory _agentType) external returns (bytes32) {
        require(addressToAgentId[msg.sender] == bytes32(0), "Agent already registered");

        bytes32 agentId = keccak256(abi.encodePacked(msg.sender, _agentName, block.timestamp));

        AIAgentIdentity storage agent = agents[agentId];
        agent.agentId = agentId;
        agent.agentAddress = msg.sender;
        agent.agentName = _agentName;
        agent.agentType = _agentType;
        agent.registeredAt = block.timestamp;
        agent.trustScore = 500; // Start with neutral score
        agent.isActive = true;
        agent.tasksCompleted = 0;
        agent.successfulTasks = 0;

        addressToAgentId[msg.sender] = agentId;
        allAgents.push(agentId);

        emit AgentRegistered(agentId, msg.sender, _agentName);
        return agentId;
    }

    /**
     * @dev Update agent trust score
     * @param _agentId The agent identifier
     * @param _newScore New trust score (0-1000)
     */
    function updateTrustScore(bytes32 _agentId, uint256 _newScore) external {
        require(agents[_agentId].agentAddress != address(0), "Agent does not exist");
        require(_newScore <= 1000, "Score must be <= 1000");

        agents[_agentId].trustScore = _newScore;
        emit TrustScoreUpdated(_agentId, _newScore);
    }

    /**
     * @dev Create a coordination task involving multiple agents
     * @param _agentIds Array of agent IDs to coordinate
     * @param _digitalTwinId Reference to Digital Twin
     * @param _taskType Type of coordination task
     * @return taskId The unique task identifier
     */
    function createCoordinationTask(
        bytes32[] memory _agentIds,
        bytes32 _digitalTwinId,
        string memory _taskType
    ) external returns (bytes32) {
        require(_agentIds.length > 0, "At least one agent required");

        bytes32 taskId = keccak256(abi.encodePacked(
            _digitalTwinId,
            _agentIds,
            block.timestamp
        ));

        CoordinationTask storage task = coordinationTasks[taskId];
        task.taskId = taskId;
        task.assignedAgents = _agentIds;
        task.digitalTwinId = _digitalTwinId;
        task.taskType = _taskType;
        task.createdAt = block.timestamp;
        task.isCompleted = false;

        // Register task with each agent
        for (uint i = 0; i < _agentIds.length; i++) {
            agentTasks[_agentIds[i]].push(taskId);
        }

        emit CoordinationTaskCreated(taskId, _agentIds);
        return taskId;
    }

    /**
     * @dev Complete a coordination task
     * @param _taskId The task identifier
     * @param _resultHash Hash of the coordination result
     */
    function completeCoordinationTask(bytes32 _taskId, bytes32 _resultHash) external {
        CoordinationTask storage task = coordinationTasks[_taskId];
        require(!task.isCompleted, "Task already completed");

        task.isCompleted = true;
        task.completedAt = block.timestamp;
        task.resultHash = _resultHash;

        // Update task completion statistics for all agents
        for (uint i = 0; i < task.assignedAgents.length; i++) {
            bytes32 agentId = task.assignedAgents[i];
            agents[agentId].tasksCompleted += 1;
            agents[agentId].successfulTasks += 1;
        }

        emit CoordinationTaskCompleted(_taskId, _resultHash);
    }

    /**
     * @dev Log communication between agents
     * @param _taskId The coordination task ID
     * @param _fromAgentId Sending agent ID
     * @param _toAgentId Receiving agent ID
     * @param _messageHash Hash of message content
     * @param _messageType Type of message
     */
    function logAgentCommunication(
        bytes32 _taskId,
        bytes32 _fromAgentId,
        bytes32 _toAgentId,
        bytes32 _messageHash,
        string memory _messageType
    ) external {
        require(coordinationTasks[_taskId].createdAt != 0, "Task does not exist");

        CommunicationLog memory log = CommunicationLog({
            taskId: _taskId,
            fromAgentId: _fromAgentId,
            toAgentId: _toAgentId,
            timestamp: block.timestamp,
            messageHash: _messageHash,
            messageType: _messageType
        });
        communicationLogs[_taskId].push(log);

        emit AgentCommunication(_taskId, _fromAgentId, _toAgentId);
    }

    /**
     * @dev Get agent identity details
     * @param _agentId The agent identifier
     */
    function getAgentIdentity(bytes32 _agentId) external view returns (
        bytes32 agentId,
        address agentAddress,
        string memory agentName,
        string memory agentType,
        uint256 registeredAt,
        uint256 trustScore,
        bool isActive,
        uint256 tasksCompleted,
        uint256 successfulTasks
    ) {
        AIAgentIdentity storage agent = agents[_agentId];
        return (
            agent.agentId,
            agent.agentAddress,
            agent.agentName,
            agent.agentType,
            agent.registeredAt,
            agent.trustScore,
            agent.isActive,
            agent.tasksCompleted,
            agent.successfulTasks
        );
    }

    /**
     * @dev Get coordination task details
     * @param _taskId The task identifier
     */
    function getCoordinationTask(bytes32 _taskId) external view returns (
        bytes32 taskId,
        bytes32[] memory assignedAgents,
        bytes32 digitalTwinId,
        string memory taskType,
        uint256 createdAt,
        uint256 completedAt,
        bool isCompleted,
        bytes32 resultHash
    ) {
        CoordinationTask storage task = coordinationTasks[_taskId];
        return (
            task.taskId,
            task.assignedAgents,
            task.digitalTwinId,
            task.taskType,
            task.createdAt,
            task.completedAt,
            task.isCompleted,
            task.resultHash
        );
    }

    /**
     * @dev Get communication logs for a task
     * @param _taskId The task identifier
     */
    function getCommunicationLogs(bytes32 _taskId) external view returns (CommunicationLog[] memory) {
        return communicationLogs[_taskId];
    }

    /**
     * @dev Get all tasks for an agent
     * @param _agentId The agent identifier
     */
    function getAgentTasks(bytes32 _agentId) external view returns (bytes32[] memory) {
        return agentTasks[_agentId];
    }

    /**
     * @dev Deactivate an agent
     * @param _agentId The agent identifier
     */
    function deactivateAgent(bytes32 _agentId) external {
        require(agents[_agentId].agentAddress == msg.sender, "Only agent can deactivate itself");
        agents[_agentId].isActive = false;
        emit AgentDeactivated(_agentId);
    }
}
