// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/VotingApp.sol";
import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";

// Task: Develop a Decentralized Voting System
// Description:
// Your task is to design and implement a simple decentralized voting system for a small community using Solidity. The system should allow eligible voters to vote for candidates in an election and should be resistant to double voting. The voting contract should be deployed on the Ethereum blockchain.
// Requirements:
// 1. Voter Registration: Implement a function that allows the owner of the contract to register voters. Only registered voters should be able to vote.
// 2. Candidate Registration: Implement a function that allows candidates to be added. Assume that only the owner of the contract can add candidates.
// 3. Voting: Implement a function that allows registered voters to vote for a candidate_. Each voter should only be able to vote once. Attempting to vote again should result in an error.
// 4. Winner Declaration: Implement a function to determine the winner of the election based on the candidate_ with the most votes. Suppose there may be hundreds or thousands of candidates.
// 5. Security: Ensure that the contract is not vulnerable to common attacks (like re-entrancy, integer overflow and underflow etc.)
// 6. Testing: Write tests for your smart contract to ensure it behaves as expected.

contract VotingAppTest is Test {
    using Strings for uint256;
    using Strings for address;

    VotingApp public votingApp;

    address public immutable owner = makeAddr("owner");
    // address public voter = makeAddr("voter");
    // address public candidate_ = makeAddr("candidate_");
    address public immutable attacker = makeAddr("attacker");

    uint64 constant ELECTION_START = 1684827971;
    uint64 constant ELECTION_END =
        ELECTION_START + MINIMUM_ELECTION_DURATION + 1;

    function deploy() public {
        votingApp = new VotingApp();
    }

    function setUp() public {
        // Set block number
        vm.roll(17320544);
        // Set block timestamp
        vm.warp(ELECTION_START);

        vm.label(owner, "owner");
        vm.label(attacker, "attacker");

        vm.prank(owner);
        deploy();
    }

    /// @dev Registrer voter
    function testRegisterVoter() public {
        address voter_ = makeAddr("voter");

        vm.prank(owner);
        votingApp.registerVoter(voter_);
        assertTrue(votingApp.isVoterRegistered(voter_));
    }

    /// @dev Revert on not owner
    function testRegisterVoterNotOwner() public {
        address voter_ = makeAddr("voter");

        vm.prank(attacker);
        vm.expectRevert("UNAUTHORIZED");
        votingApp.registerVoter(voter_);
    }

    /// @dev Revert on zero address input
    function testRegisterVoterZeroAddressInput() public {
        vm.expectRevert(VotingApp.ZeroAddressInput.selector);
        vm.prank(owner);
        votingApp.registerVoter(address(0));
    }

    /// @dev Revert on voter already registered
    function testRegisterVoterAlreadyRegistered() public {
        address voter_ = makeAddr("voter");

        vm.startPrank(owner);
        votingApp.registerVoter(voter_);
        vm.expectRevert(
            abi.encodeWithSelector(
                VotingApp.VoterAlreadyRegistered.selector, voter_
            )
        );
        votingApp.registerVoter(voter_);
    }

    /// @dev Revert on registration not open
    function testRegisterVoterDuringRegistrationNotOpen() public {
        address voter_ = makeAddr("voter");

        vm.startPrank(owner);
        votingApp.openVoting(ELECTION_END);

        vm.expectRevert(VotingApp.RegistrationNotOpen.selector);
        votingApp.registerVoter(voter_);
    }

    /// @dev Register candidate
    function testRegisterCandidate() public {
        address candidate_ = makeAddr("candidate_");

        vm.prank(owner);
        votingApp.registerCandidate(candidate_);
        assertTrue(votingApp.isCandidateRegistered(candidate_));
    }

    /// @dev Revert on not owner
    function testRegisterCandidateNotOwner() public {
        address candidate_ = makeAddr("candidate_");

        vm.prank(attacker);
        vm.expectRevert("UNAUTHORIZED");
        votingApp.registerCandidate(candidate_);
    }

    /// @dev Revert on zero address input
    function testRegisterCandidateZeroAddressInput() public {
        vm.prank(owner);
        vm.expectRevert(VotingApp.ZeroAddressInput.selector);
        votingApp.registerCandidate(address(0));
    }

    /// @dev Revert on candidate already registered
    function testRegisterCandidateAlreadyRegistered() public {
        address candidate_ = makeAddr("candidate_");

        vm.startPrank(owner);
        votingApp.registerCandidate(candidate_);
        vm.expectRevert(
            abi.encodeWithSelector(
                VotingApp.CandidateAlreadyRegistered.selector, candidate_
            )
        );
        votingApp.registerCandidate(candidate_);
    }

    /// @dev Revert on registration not open
    function testRegisterCandidateDuringRegistrationNotOpen() public {
        address candidate_ = makeAddr("candidate_");

        vm.prank(owner);
        votingApp.openVoting(ELECTION_END);

        vm.prank(owner);
        vm.expectRevert(VotingApp.RegistrationNotOpen.selector);
        votingApp.registerCandidate(candidate_);
    }

    /// @dev Open voting
    function testOpenVoting(uint64 end) public {
        end = uint64(
            bound(
                end,
                ELECTION_START + MINIMUM_ELECTION_DURATION,
                ELECTION_START + MAXIMUM_ELECTION_DURATION
            )
        );
        vm.prank(owner);
        votingApp.openVoting(end);
        assertEq(
            uint8(votingApp.electionPhase()),
            uint8(VotingApp.ElectionPhase.Voting)
        );
    }

    /// @dev Revert on election duration too short
    function testOpenVotingElectionDurationTooShort(uint64 end) public {
        end = uint64(bound(end, 0, ELECTION_START + MINIMUM_ELECTION_DURATION));
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                VotingApp.ElectionDurationTooShort.selector, end
            )
        );
        votingApp.openVoting(end);
    }

    /// @dev Revert on election duration too long
    function testOpenVotingElectionDurationTooLong(uint64 end) public {
        end = uint64(
            bound(
                end,
                ELECTION_START + MAXIMUM_ELECTION_DURATION + 1,
                type(uint64).max
            )
        );
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                VotingApp.ElectionDurationTooLong.selector, end
            )
        );
        votingApp.openVoting(end);
    }

    /// @dev Revert on not owner
    function testOpenVotingNotOwner(uint64 end) public {
        vm.prank(attacker);
        vm.expectRevert("UNAUTHORIZED");
        votingApp.openVoting(end);
    }

    /// @dev Revert on registration not open
    function testOpenVotingDuringRegistrationNotOpen(uint64 end) public {
        vm.prank(owner);
        votingApp.openVoting(ELECTION_END);

        vm.prank(owner);
        vm.expectRevert(VotingApp.RegistrationNotOpen.selector);
        votingApp.openVoting(end);
    }

    /// @dev Cast vote
    function testCastVote() public {
        address voter_ = makeAddr("voter");
        address candidate_ = makeAddr("candidate_");

        vm.startPrank(owner);
        votingApp.registerVoter(voter_);
        votingApp.registerCandidate(candidate_);
        votingApp.openVoting(ELECTION_END);

        vm.startPrank(voter_);
        votingApp.castVote(candidate_);
        assertTrue(votingApp.hasVoted(voter_));
    }

    /// @dev Revert on double vote
    function testCastVoteDoubleVote() public {
        address voter_ = makeAddr("voter");
        address candidate_ = makeAddr("candidate_");

        vm.startPrank(owner);
        votingApp.registerVoter(voter_);
        votingApp.registerCandidate(candidate_);
        votingApp.openVoting(ELECTION_END);

        vm.startPrank(voter_);
        votingApp.castVote(candidate_);

        vm.expectRevert(
            abi.encodeWithSelector(VotingApp.AlreadyVoted.selector, voter_)
        );
        votingApp.castVote(candidate_);
    }

    /// @dev Revert on not voter not registered
    function testCastVoteVoterNotRegistered() public {
        address voter_ = makeAddr("voter");
        address candidate_ = makeAddr("candidate_");

        vm.startPrank(owner);
        votingApp.registerCandidate(candidate_);
        votingApp.openVoting(ELECTION_END);

        vm.startPrank(voter_);
        vm.expectRevert(
            abi.encodeWithSelector(
                VotingApp.VoterNotRegistered.selector, voter_
            )
        );
        votingApp.castVote(candidate_);
    }

    /// @dev Revert on candidate not registered
    function testCastVoteCandidateNotRegistered() public {
        address voter_ = makeAddr("voter");
        address candidate_ = makeAddr("candidate_");

        vm.startPrank(owner);
        votingApp.registerVoter(voter_);
        votingApp.openVoting(ELECTION_END);

        vm.startPrank(voter_);
        vm.expectRevert(
            abi.encodeWithSelector(
                VotingApp.CandidateNotRegistered.selector, candidate_
            )
        );
        votingApp.castVote(candidate_);
    }

    /// @dev Revert on voting not open
    function testCastVoteVotingNotOpen() public {
        address voter_ = makeAddr("voter");
        address candidate_ = makeAddr("candidate_");

        vm.startPrank(owner);
        votingApp.registerVoter(voter_);
        votingApp.registerCandidate(candidate_);

        vm.startPrank(voter_);
        vm.expectRevert(VotingApp.VotingNotOpen.selector);
        votingApp.castVote(candidate_);
    }

    /// @dev Revert on voting closed
    function testCastVoteElectionEnded() public {
        address voter_ = makeAddr("voter");
        address candidate_ = makeAddr("candidate_");

        vm.startPrank(owner);
        votingApp.registerVoter(voter_);
        votingApp.registerCandidate(candidate_);
        votingApp.openVoting(ELECTION_END);

        vm.roll(17320544);
        vm.warp(ELECTION_END + 1);

        vm.startPrank(voter_);
        vm.expectRevert(VotingApp.ElectionEnded.selector);
        votingApp.castVote(candidate_);
    }

    /// @dev Declare winner
    function testDeclareWinner() public {
        address voter_ = makeAddr("voter");
        address candidate_ = makeAddr("candidate_");

        vm.startPrank(owner);
        votingApp.registerVoter(voter_);
        votingApp.registerCandidate(candidate_);
        votingApp.openVoting(ELECTION_END);

        vm.startPrank(voter_);
        votingApp.castVote(candidate_);

        vm.startPrank(owner);
        vm.roll(block.number + 1);
        vm.warp(ELECTION_END + 1);
        votingApp.declareWinner();
        assertEq(votingApp.getWinner(), candidate_);
    }

    /// @dev Test multiple voters, multiple candidates and declare winner
    function testMultipleVotersMultipleCandidatesDeclareWinner(
        uint256[10] memory votes
    ) public {
        // Bound votes
        for (uint256 i = 0; i < votes.length; i++) {
            votes[i] = bound(votes[i], 1, 20);
        }

        // Setup candidates
        address[] memory candidates = new address[](votes.length);
        for (uint256 i = 0; i < candidates.length; i++) {
            candidates[i] = makeAddr(string.concat("candidate", i.toString()));
        }
        require(
            candidates.length == votes.length,
            "Candidates and votes length mismatch"
        );

        // Setup voters
        address[][] memory voters = new address[][](votes.length);
        for (uint256 i = 0; i < votes.length; i++) {
            voters[i] = new address[](votes[i]);
            for (uint256 j = 0; j < votes[i]; j++) {
                voters[i][j] =
                    makeAddr(string.concat("voter", i.toString(), j.toString()));
            }
        }

        // Register voters and candidates
        vm.startPrank(owner);
        for (uint256 i = 0; i < candidates.length; i++) {
            votingApp.registerCandidate(candidates[i]);
        }
        for (uint256 i = 0; i < voters.length; i++) {
            for (uint256 j = 0; j < voters[i].length; j++) {
                votingApp.registerVoter(voters[i][j]);
            }
        }

        // Open voting
        votingApp.openVoting(ELECTION_END);

        // Cast votes
        for (uint256 i = 0; i < candidates.length; i++) {
            for (uint256 j = 0; j < voters[i].length; j++) {
                vm.startPrank(voters[i][j]);
                votingApp.castVote(candidates[i]);
            }
        }

        // Declare winner
        vm.startPrank(owner);
        vm.roll(block.number + 1);
        vm.warp(ELECTION_END + 1);
        address declaredWinner = votingApp.declareWinner();

        address calculatedWinner;
        uint256 maxVotes = 0;
        for (uint256 i = 0; i < candidates.length; i++) {
            if (votes[i] > maxVotes) {
                maxVotes = votes[i];
                calculatedWinner = candidates[i];
            }
        }
        console.log("Declared winner: ", declaredWinner);

        assertEq(declaredWinner, calculatedWinner);
    }
}
