//SPDX-License-Identifier : MIT

pragma solidity 0.8.15;

contract DecentralizedVoting {
    address public central;
    uint256 public start_time;
    uint256 public end_time;
    mapping(bytes32 => bool) public voters;

    struct Candidate {
        string name;
        uint vote_count;
    }
    Candidate[] public candidates;

    modifier onlyCentral() {
        require(msg.sender == central, "Only Central Body can perform this action");
        _;
    }

    modifier validTime() {
        require(block.timestamp >= start_time && block.timestamp <= end_time, "Voting is not active");
        _;
    }

    constructor() {
        central = msg.sender;
        start_time = 1734628074;
        end_time = 1734756840;
    }

    function addCandidate(string memory _name) public onlyCentral {
        candidates.push(Candidate({name: _name, vote_count: 0}));
    }

    function registerVoter(address _voter) public onlyCentral {
        bytes32 voter_hash = keccak256(abi.encodePacked(_voter));
        voters[voter_hash] = true;
    }

    function vote(uint _candidateIndex) public validTime {
        bytes32 voter_hash = keccak256(abi.encodePacked(msg.sender));
        require(voters[voter_hash], "You are not registered to vote");
        voters[voter_hash] = false;
        candidates[_candidateIndex].vote_count++;
    }

    function getResults() public view returns (Candidate[] memory) {
        return candidates;
    }

}