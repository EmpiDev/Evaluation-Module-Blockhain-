// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface ISimpleVotingSystem {
    enum Phase {
        Registration,  
        Donation,      
        Voting,        
        Tallying       
    }

    enum Gender {
        Male,
        Female,
        Other
    }

    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    struct PhaseInfo {
        Phase currentPhase;
        uint phaseEndTime;
        bool phaseActive;
    }

    
    function setPhaseAdmin(Phase _phase, address _admin) external;
    
    
    function addCandidate(string memory _name) external;
    function startRegistrationPhase() external;
    function endRegistrationPhase() external;
    
    
    function startDonationPhase() external;
    function endDonationPhase() external;
    function donate() external payable;
    
    
    function startVotingPhase() external;
    function endVotingPhase() external;
    function vote(uint _candidateId, Gender _gender) external;
    
    
    function startTallyingPhase() external;
    function endTallyingPhase() external;
    function getWinner() external view returns (Candidate memory);
    
    
    function getCurrentPhase() external view returns (Phase);
    function getCandidate(uint _candidateId) external view returns (Candidate memory);
    function getCandidatesCount() external view returns (uint);
    function getTotalVotes(uint _candidateId) external view returns (uint);
    function hasVoted(address _voter) external view returns (bool);
    function hasDonated(address _donor) external view returns (bool);
    function getVotingStatistics() external view returns (uint maleCount, uint femaleCount, uint otherCount, uint totalVotes);
    function getPhaseAdmin(Phase _phase) external view returns (address);
}
