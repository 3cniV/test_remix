// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Ballot {
    struct voter {
        uint weight;
        bool voted;
        address delegate;
        uint vote;
    }

    struct proposal {
        bytes32 name;
        uint voteCount;
    }

    address public chairperson;
    mapping(address => voter) public voters;
    proposal[] public proposals;

    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    function giveRightToVote(address voterAddress) external {
        require(
            msg.sender == chairperson,
            "Only chairperson can give the right to vote."
        );
        require(
            !voters[voterAddress].voted,
            "The voter already voted."
        );
        require(voters[voterAddress].weight == 0);
        voters[voterAddress].weight = 1;
    }

    function delegate(address to) external {
        voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "You have no right to vote.");
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != msg.sender, "Found loop in delegation.");
        }

        voter storage delegate_ = voters[to];
        require(delegate_.weight >= 1);

        sender.voted = true;
        sender.delegate = to;

        if (delegate_.voted) {
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            delegate_.weight += sender.weight;
        }
    }

    function vote(uint proposalIndex) external {
        voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote.");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposalIndex;
        proposals[proposalIndex].voteCount += sender.weight;
    }

    function winningProposal() public view returns (uint winningProposal_) {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function winnerName() external view returns (bytes32 winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
}
