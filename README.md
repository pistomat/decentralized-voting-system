# VotingApp
## Description
VotingApp is a simple decentralized voting system implemented in Solidity. The smart contract allows eligible voters to vote for candidates in an election and prevents double voting. The VotingApp contract is deployed on the Ethereum blockchain and provides various functionalities for voter registration, candidate registration, casting votes, and winner declaration.

## Features
1. **Voter Registration:** Only the owner of the contract can register voters. Only registered voters are able to vote.
1. **Candidate Registration:** Only the owner of the contract can add candidates.
1. **Voting:** Registered voters can vote for a candidate. Each voter is only able to vote once. Attempting to vote again results in an error.
1. **Winner Declaration:** The contract determines the winner of the election based on the candidate who achieved the most votes the first.
1. **Election Duration:** The minimum duration of an election is 1 day and the maximum duration of an election is 1 year.

## Deployment


## Note on Winner Ties
Please note that in the case of a tie (i.e., multiple candidates receiving the same top number of votes), the winner is determined as the first candidate who reached the top number of votes. This design choice means that the system is susceptible to front-running attacks. In a front-running scenario, an entity could potentially observe a transaction that's been broadcast to the network (but not yet confirmed), and then submit their own transaction with a higher gas fee to secure priority in the transaction queue, thus changing the outcome of the election. However, this model was adopted to keep gas costs low and maintain the simplicity of this app. More sophisticated solutions to handle ties or prevent front-running attacks are beyond the scope of this simple demonstration app. It's important to consider these aspects if you're planning to use this code for more substantial applications or purposes.
