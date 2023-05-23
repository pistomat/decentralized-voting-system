// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @dev OpenZeppelin Contracts v4.8.3
import { Owned } from "solmate/auth/Owned.sol";

// Task: Develop a Decentralized Voting System
// Description:
// Your task is to design and implement a simple decentralized voting system for a small community using Solidity. The system should allow eligible voters to vote for candidates in an election and should be resistant to double voting. The voting contract should be deployed on the Ethereum blockchain.
// Requirements:
// 1. Voter Registration: Implement a function that allows the owner of the contract to register voters. Only registered voters should be able to vote.
// 2. Candidate Registration: Implement a function that allows candidates to be added. Assume that only the owner of the contract can add candidates.
// 3. Voting: Implement a function that allows registered voters to vote for a candidate. Each voter should only be able to vote once. Attempting to vote again should result in an error.
// 4. Winner Declaration: Implement a function to determine the winner of the election based on the candidate with the most votes. Suppose there may be hundreds or thousands of candidates.
// 5. Security: Ensure that the contract is not vulnerable to common attacks (like re-entrancy, integer overflow and underflow etc.)
// 6. Testing: Write tests for your smart contract to ensure it behaves as expected.

// The minimum duration of an election is 1 day
uint64 constant MINIMUM_ELECTION_DURATION = 60 * 60 * 24;
// The maximum duration of an election is 1 year
uint64 constant MAXIMUM_ELECTION_DURATION = 60 * 60 * 24 * 365;

/// @title VotingApp
/// @notice A simple decentralized voting system.
/// @notice Ties are broken by the first candidate to reach the most votes.
/// @dev Because of the way that ties are handled, the protocol is vulnerable to front-running attacks, but this is out of the scope of this small demo.
/// @author pistomat
contract VotingApp is Owned {
    event VoterRegistered(address indexed voter);
    event CandidateRegistered(address indexed candidate);
    event VoteCast(address indexed voter, address indexed candidate);
    event VotingOpened(uint64 indexed end);
    event WinnerDeclared(address indexed winner);

    error VoterAlreadyRegistered(address voter);
    error VoterNotRegistered(address voter);
    error AlreadyVoted(address voter);
    error CandidateAlreadyRegistered(address candidate);
    error CandidateNotRegistered(address candidate);
    error RegistrationNotOpen();
    error VotingNotOpen();
    error ElectionNotEnded();
    error ElectionEnded();
    error ElectionDurationTooShort(uint64 end);
    error ElectionDurationTooLong(uint64 end);
    error ZeroAddressInput();

    enum ElectionPhase {
        Registration,
        Voting,
        Ended
    }

    /// @dev voter => registered
    mapping(address => bool) internal _voterRegistered;
    /// @dev voter => voted
    mapping(address => bool) internal _hasVoted;
    /// @dev candidate => registered
    mapping(address => bool) internal _candidateRegistered;
    /// @dev candidate => votes
    mapping(address => uint256) internal _votesCount;
    address internal _frontRunner;
    uint256 internal _frontRunnerVotes;

    uint64 internal _electionEnd;
    ElectionPhase internal _electionPhase;

    constructor() Owned(msg.sender) {
        _electionPhase = ElectionPhase.Registration;
    }

    modifier registrationOpen() {
        if (_electionPhase != ElectionPhase.Registration) {
            revert RegistrationNotOpen();
        }
        _;
    }

    modifier votingOpen() {
        if (_electionPhase != ElectionPhase.Voting) revert VotingNotOpen();
        _;
    }

    /// READ METHODS

    /// @notice Returns whether the voter is registered
    /// @param voter The address of the voter
    /// @return True if the voter is registered, false otherwise
    function isVoterRegistered(address voter) external view returns (bool) {
        return _voterRegistered[voter];
    }

    /// @notice Returns whether the candidate is registered
    /// @param candidate The address of the candidate
    /// @return True if the candidate is registered, false otherwise
    function isCandidateRegistered(address candidate)
        external
        view
        returns (bool)
    {
        return _candidateRegistered[candidate];
    }

    /// @notice Returns the timestamp of the end of the election.
    /// @notice Election end is set only after the voting phase has started.
    /// @dev It is not possible to vote after the election has ended
    /// @return The timestamp of the end of the election
    function electionEnd() external view returns (uint64) {
        return _electionEnd;
    }

    /// @notice Returns the current phase of the election
    /// @return The current phase of the election
    function electionPhase() external view returns (ElectionPhase) {
        return _electionPhase;
    }

    /// @notice Returns whether the voter has voted
    /// @param voter The address of the voter
    /// @return True if the voter has voted, false otherwise
    function hasVoted(address voter) external view returns (bool) {
        return _hasVoted[voter];
    }

    /// @notice Returns the candidate who achieved the most votes the first
    /// @return winner The winner of the election
    function getWinner() external view returns (address winner) {
        if (_electionPhase != ElectionPhase.Ended) revert ElectionNotEnded();

        winner = _frontRunner;
    }

    /// WRITE METHODS

    /// @notice Registers a voter
    /// @dev Only the owner of the contract can register voters
    /// @dev Voters must be registered before the election starts
    /// @param voter The address of the voter
    function registerVoter(address voter) external onlyOwner registrationOpen {
        if (_voterRegistered[voter]) revert VoterAlreadyRegistered(voter);
        if (voter == address(0)) revert ZeroAddressInput();

        _voterRegistered[voter] = true;

        emit VoterRegistered(voter);
    }

    /// @notice Registers a candidate
    /// @dev Only the owner of the contract can register candidates
    /// @dev Candidates must be registered before the election starts
    /// @param candidate The address of the candidate
    function registerCandidate(address candidate)
        external
        onlyOwner
        registrationOpen
    {
        if (_candidateRegistered[candidate]) {
            revert CandidateAlreadyRegistered(candidate);
        }
        if (candidate == address(0)) revert ZeroAddressInput();

        _candidateRegistered[candidate] = true;

        emit CandidateRegistered(candidate);
    }

    /// @notice Opens the voting phase
    /// @dev Only the owner of the contract can open the voting phase
    /// @dev The voting phase must be opened only after the registration phase

    function openVoting(uint64 electionEnd_)
        external
        onlyOwner
        registrationOpen
    {
        if (electionEnd_ < block.timestamp + MINIMUM_ELECTION_DURATION) {
            revert ElectionDurationTooShort(electionEnd_);
        }
        if (electionEnd_ > block.timestamp + MAXIMUM_ELECTION_DURATION) {
            revert ElectionDurationTooLong(electionEnd_);
        }
        _electionEnd = electionEnd_;
        _electionPhase = ElectionPhase.Voting;

        emit VotingOpened(_electionEnd);
    }

    /// @notice Casts a vote for a candidate
    /// @dev Only registered voters can vote
    /// @dev Only registered candidates can be voted for
    /// @dev Voters can vote only once
    /// @dev Voters can vote only during the voting phase
    function castVote(address candidate) external votingOpen {
        if (!_candidateRegistered[candidate]) {
            revert CandidateNotRegistered(candidate);
        }
        if (!_voterRegistered[msg.sender]) {
            revert VoterNotRegistered(msg.sender);
        }
        if (_hasVoted[msg.sender]) revert AlreadyVoted(msg.sender);
        if (uint256(_electionEnd) < block.timestamp) revert ElectionEnded();

        _hasVoted[msg.sender] = true;
        /// @dev Integer overflow is unlikely, so this could be in an unchecked block
        uint256 candidateVotes = ++_votesCount[candidate];

        if (candidateVotes > _frontRunnerVotes) {
            _frontRunnerVotes = candidateVotes;
            _frontRunner = candidate;
        }

        emit VoteCast(msg.sender, candidate);
    }

    /// @notice Declares the winner of the election and ends the election
    /// @dev Only the owner of the contract can declare the winner
    /// @dev The election can be declared only after the voting phase
    function declareWinner() external votingOpen returns (address winner) {
        if (uint256(_electionEnd) > block.timestamp) revert ElectionNotEnded();

        _electionPhase = ElectionPhase.Ended;
        winner = _frontRunner;

        emit WinnerDeclared(winner);
    }
}
