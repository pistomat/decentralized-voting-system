// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/VotingApp.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

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

    address public owner = makeAddr("owner");
    // address public voter = makeAddr("voter");
    // address public candidate_ = makeAddr("candidate_");
    address public attacker = makeAddr("attacker");

    uint64 constant ELECTION_START = 1684827971;
    uint64 constant ELECTION_END = ELECTION_START + MINIMUM_ELECTION_DURATION + 1;
    


    function setUp() public {
        // Set block number
        vm.roll(17320544);
        // Set block timestamp
        vm.warp(ELECTION_START);

        vm.label(owner, "owner");
        vm.label(attacker, "attacker");

        vm.prank(owner);
        votingApp = new VotingApp();
    }

    /// @dev Registrer voter
    function testRegisterVoter(address voter_) public {
        vm.assume(voter_ != address(0));

        vm.prank(owner);
        votingApp.registerVoter(voter_);
        assertTrue(votingApp.isVoterRegistered(voter_));
    }

    /// @dev Revert on not owner
    function testRegisterVoterNotOwner(address voter_) public {
        vm.assume(voter_ != address(0));

        vm.prank(attacker);
        vm.expectRevert("Ownable: caller is not the owner");
        votingApp.registerVoter(voter_);
    }

    /// @dev Revert on zero address input
    function testRegisterVoterZeroAddressInput() public {
        vm.prank(owner);
        vm.expectRevert(VotingApp.ZeroAddressInput.selector);
        votingApp.registerVoter(address(0));
    }

    /// @dev Revert on registration not open
    function testRegisterVoterDuringRegistrationNotOpen(address voter_) public {
        vm.assume(voter_ != address(0));

        vm.prank(owner);
        votingApp.openVoting(ELECTION_END);

        vm.prank(owner);
        vm.expectRevert(VotingApp.RegistrationNotOpen.selector);
        votingApp.registerVoter(voter_);
    }

    /// @dev Register candidate
    function testRegisterCandidate(address candidate_) public {
        vm.assume(candidate_ != address(0));

        vm.prank(owner);
        votingApp.registerCandidate(candidate_);
        assertTrue(votingApp.isCandidateRegistered(candidate_));
    }

    /// @dev Revert on not owner
    function testRegisterCandidateNotOwner(address candidate_) public {
        vm.assume(candidate_ != address(0));

        vm.prank(attacker);
        vm.expectRevert("Ownable: caller is not the owner");
        votingApp.registerCandidate(candidate_);
    }

    /// @dev Revert on zero address input
    function testRegisterCandidateZeroAddressInput() public {
        vm.prank(owner);
        vm.expectRevert(VotingApp.ZeroAddressInput.selector);
        votingApp.registerCandidate(address(0));
    }

    /// @dev Revert on registration not open
    function testRegisterCandidateDuringRegistrationNotOpen(address candidate_) public {
        vm.assume(candidate_ != address(0));

        vm.prank(owner);
        votingApp.openVoting(ELECTION_END);

        vm.prank(owner);
        vm.expectRevert(VotingApp.RegistrationNotOpen.selector);
        votingApp.registerCandidate(candidate_);
    }

    /// @dev Open voting
    function testOpenVoting(uint64 end) public {
        vm.prank(owner);
        votingApp.openVoting(end);
        assertEq(uint8(votingApp.electionPhase()), uint8(VotingApp.ElectionPhase.Voting));
    }

    /// @dev Revert on not owner
    function testOpenVotingNotOwner(uint64 end) public {
        vm.prank(attacker);
        vm.expectRevert("Ownable: caller is not the owner");
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
    function testCastVote(address voter_, address candidate_) public {
        vm.assume(voter_ != address(0));
        vm.assume(candidate_ != address(0));

        vm.startPrank(owner);
        votingApp.registerVoter(voter_);
        votingApp.registerCandidate(candidate_);
        votingApp.openVoting(ELECTION_END);

        vm.startPrank(voter_);
        votingApp.castVote(candidate_);
        assertTrue(votingApp.hasVoted(voter_));
    }

    /// @dev Revert on double vote
    function testCastVoteDoubleVote(address voter_, address candidate_) public {
        vm.assume(voter_ != address(0));
        vm.assume(candidate_ != address(0));

        vm.startPrank(owner);
        votingApp.registerVoter(voter_);
        votingApp.registerCandidate(candidate_);
        votingApp.openVoting(ELECTION_END);

        vm.startPrank(voter_);
        votingApp.castVote(candidate_);

        vm.expectRevert(VotingApp.AlreadyVoted.selector);
        votingApp.castVote(candidate_);
    }

    /// @dev Revert on not voter not registered
    function testCastVoteVoterNotRegistered(address voter_, address candidate_) public {
        vm.assume(voter_ != address(0));
        vm.assume(candidate_ != address(0));
        vm.startPrank(owner);
        votingApp.registerCandidate(candidate_);
        votingApp.openVoting(ELECTION_END);

        vm.startPrank(voter_);
        vm.expectRevert(VotingApp.VoterNotRegistered.selector);
        votingApp.castVote(candidate_);
    }

    /// @dev Revert on candidate not registered
    function testCastVoteCandidateNotRegistered(address voter_, address candidate_) public {
        vm.assume(voter_ != address(0));
        vm.assume(candidate_ != address(0));

        vm.startPrank(owner);
        votingApp.registerVoter(voter_);
        votingApp.openVoting(ELECTION_END);

        vm.startPrank(voter_);
        vm.expectRevert(VotingApp.CandidateNotRegistered.selector);
        votingApp.castVote(candidate_);
    }

    /// @dev Revert on voting not open
    function testCastVoteVotingNotOpen(address voter_, address candidate_) public {
        vm.assume(voter_ != address(0));
        vm.assume(candidate_ != address(0));

        vm.startPrank(owner);
        votingApp.registerVoter(voter_);
        votingApp.registerCandidate(candidate_);

        vm.startPrank(voter_);
        vm.expectRevert(VotingApp.VotingNotOpen.selector);
        votingApp.castVote(candidate_);
    }

    /// @dev Revert on voting closed
    function testCastVoteElectionEnded(address voter_, address candidate_) public {
        vm.assume(voter_ != address(0));
        vm.assume(candidate_ != address(0));

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
    function testDeclareWinner(address voter_, address candidate_) public {
        vm.assume(voter_ != address(0));
        vm.assume(candidate_ != address(0));

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
        uint256[] memory votes
    ) public {
        // Setup candidates
        address[] memory candidates = new address[](votes.length);
        for (uint256 i = 0; i < votes.length; i++) {
            candidates[i] = makeAddr(string.concat("candidate", i.toString()));
        }

        // Setup voters
        address[][] memory voters = new address[][](votes.length);
        for (uint256 i = 0; i < votes.length; i++) {
            voters[i] = new address[](votes[i]);
            for (uint256 j = 0; j < votes[i]; j++) {
                voters[i][j] = makeAddr(string.concat("voter", i.toString(), j.toString()));
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

        assertEq(declaredWinner, calculatedWinner);
    }
}
