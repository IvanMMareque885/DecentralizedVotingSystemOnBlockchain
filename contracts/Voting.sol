// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Voting is ReentrancyGuard {
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    struct Voter {
        bool hasVoted;
        uint vote;
        bool isRegistered;
    }

    struct Proposal {
        uint id;
        string description;
        uint voteCountYes;
        uint voteCountNo;
        bool executed;
        string status;
    }

    address public electionOfficial;
    bool private votingStartedFlag = false;
    bool private votingEndedFlag = false;

    IERC20 public voteToken;

    mapping(uint => Candidate) public candidates;
    mapping(address => Voter) public voters;
    mapping(uint => Proposal) public proposals;
    mapping(uint => mapping(address => bool)) public proposalVoters;
    mapping(uint => mapping(address => bool)) public proposalVotes;

    uint public candidatesCount;
    uint public proposalsCount;

    event CandidateRegistered(uint id, string name);
    event VoterRegistered(address voter);
    event VoteCasted(address voter, uint candidateId);
    event VotingEnded();
    event ProposalCreated(uint id, string description);
    event ProposalVoted(uint id, address voter, bool support);
    event ProposalFinalized(uint id, bool passed);

    modifier onlyOfficial() {
        require(msg.sender == electionOfficial, "Only the election official can call this");
        _;
    }

    modifier onlyDuringVoting() {
        require(votingStartedFlag && !votingEndedFlag, "Voting is not active");
        _;
    }

    constructor(address _voteTokenAddress) {
        electionOfficial = msg.sender;
        voteToken = IERC20(_voteTokenAddress);
    }

    function registerCandidate(string memory _name) public onlyOfficial {
        for (uint i = 1; i <= candidatesCount; i++) {
            require(keccak256(bytes(candidates[i].name)) != keccak256(bytes(_name)), "Candidate already registered");
        }
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
        emit CandidateRegistered(candidatesCount, _name);
    }

    function registerVoter(address _voter) public onlyOfficial {
        require(!voters[_voter].isRegistered, "Voter is already registered");
        voters[_voter] = Voter(false, 0, true);
        emit VoterRegistered(_voter);
    }

    function startVoting() public onlyOfficial {
        require(!votingStartedFlag, "Voting already started");
        votingStartedFlag = true;
        votingEndedFlag = false;
    }

    function vote(uint _candidateId) public onlyDuringVoting {
        require(msg.sender != electionOfficial, "Official cannot vote");
        require(voters[msg.sender].isRegistered, "Not registered to vote");
        require(!voters[msg.sender].hasVoted, "You have already voted");
        require(candidates[_candidateId].id != 0, "Invalid candidate");

        voters[msg.sender].hasVoted = true;
        voters[msg.sender].vote = _candidateId;
        candidates[_candidateId].voteCount++;

        emit VoteCasted(msg.sender, _candidateId);
    }

    function endVoting() public onlyOfficial onlyDuringVoting {
        votingEndedFlag = true;
        emit VotingEnded();
    }

    function getResults(uint _candidateId) public view returns (uint) {
        require(votingEndedFlag, "Voting has not ended");
        return candidates[_candidateId].voteCount;
    }

    function votingStarted() public view returns (bool) {
        return votingStartedFlag;
    }

    function votingEnded() public view returns (bool) {
        return votingEndedFlag;
    }

    function getElectionOfficial() public view returns (address) {
        return electionOfficial;
    }

    function createProposal(string memory _description) public nonReentrant {
        require(voteToken.balanceOf(msg.sender) >= 10 * 10**18, "Not enough VTK to propose");
        voteToken.transferFrom(msg.sender, address(this), 10 * 10**18);

        proposalsCount++;
        proposals[proposalsCount] = Proposal({
            id: proposalsCount,
            description: _description,
            voteCountYes: 0,
            voteCountNo: 0,
            executed: false,
            status: "Pending"
        });

        emit ProposalCreated(proposalsCount, _description);
    }

    function voteOnProposal(uint _proposalId, bool support) public {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already finalized");
        require(!proposalVoters[_proposalId][msg.sender], "You have already voted on this proposal");

        proposalVotes[_proposalId][msg.sender] = true;

        if (support) {
            proposal.voteCountYes++;
        } else {
            proposal.voteCountNo++;
        }

        proposalVoters[_proposalId][msg.sender] = true;

        emit ProposalVoted(_proposalId, msg.sender, support);
    }

    function finalizeProposal(uint _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Already finalized");

        bool passed = proposal.voteCountYes > proposal.voteCountNo;
        proposal.executed = true;
        proposal.status = passed ? "Passed" : "Rejected";

        emit ProposalFinalized(_proposalId, passed);
    }

    function getProposalStatus(uint _proposalId) public view returns (string memory) {
        return proposals[_proposalId].status;
    }

    function getProposalVotes(uint _proposalId) public view returns (uint yesVotes, uint noVotes) {
        Proposal storage p = proposals[_proposalId];
        return (p.voteCountYes, p.voteCountNo);
    }

    function hasVotedOnProposal(address voter, uint proposalId) public view returns (bool) {
        return proposalVotes[proposalId][voter];
    }
}
