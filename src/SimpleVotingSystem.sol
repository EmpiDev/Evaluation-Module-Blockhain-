// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;


import {VoterNFT} from "./VoterNFT.sol";
import {DonorNFT} from "./DonorNFT.sol";
import {ISimpleVotingSystem} from "./interfaces/ISimpleVotingSystem.sol";
import {VotingSystemErrors} from "./libraries/VotingSystemErrors.sol";
import {AccessControl} from "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";


contract SimpleVotingSystem is ISimpleVotingSystem, AccessControl {
    
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    Phase public currentPhase;
    uint256 public phaseEndTime;
    bool public phaseActive;
    
    
    uint256 public constant PHASE_DELAY = 1 hours;
    
    
    VoterNFT public immutable voterNFT;
    DonorNFT public immutable donorNFT;
    
    
    mapping(Phase => address) public phaseAdmins;
    address public treasuryAddress;
    
    
    mapping(uint => Candidate) public candidates;
    uint[] private candidateIds;
    
    
    mapping(address => bool) public hasVotedMapping;
    mapping(address => bool) public hasDonatedMapping;
    
    
    mapping(Gender => uint) public genderCounts;
    uint public totalVoters;
    
    
    
    event PhaseStarted(Phase phase, uint256 startTime, address startedBy);
    event PhaseEnded(Phase phase, uint256 endTime, address endedBy);
    event PhaseAdminSet(Phase phase, address admin, address setBy);
    event CandidateAdded(uint indexed candidateId, string name, address addedBy);
    event VoteCast(address indexed voter, uint indexed candidateId, Gender gender, uint256 timestamp);
    event DonationReceived(address indexed donor, uint256 amount, uint256 timestamp);
    event WinnerDeclared(uint indexed candidateId, string name, uint voteCount);
    
    
    
    modifier onlyPhaseAdmin(Phase _phase) {
        if(msg.sender != phaseAdmins[_phase] && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert VotingSystemErrors.NotPhaseAdmin();
        }
        _;
    }
    
    modifier inPhase(Phase _phase) {
        if(currentPhase != _phase) {
            revert VotingSystemErrors.InvalidPhase();
        }
        if(!phaseActive) {
            revert VotingSystemErrors.PhaseNotActive();
        }
        _;
    }
    
    modifier phaseCanStart(Phase _phase) {
        
        if(_phase != Phase.Registration) {
            Phase expectedPhase = Phase(uint(currentPhase) + 1);
            if(_phase != expectedPhase) {
                revert VotingSystemErrors.InvalidPhase();
            }
        }
        
        
        if(phaseActive) {
            revert VotingSystemErrors.PhaseAlreadyActive();
        }
        
        
        if(_phase != Phase.Registration && block.timestamp < phaseEndTime + PHASE_DELAY) {
            revert VotingSystemErrors.MinimumDelayNotReached();
        }
        _;
    }
    
    
    
    constructor(address _voterNFT, address _donorNFT) {
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        if(_voterNFT == address(0) || _donorNFT == address(0)) {
            revert VotingSystemErrors.InvalidAddress();
        }
        
        voterNFT = VoterNFT(_voterNFT);
        donorNFT = DonorNFT(_donorNFT);
        
        currentPhase = Phase.Registration;
        phaseActive = false;
        treasuryAddress = msg.sender;
    }
    
    
    
    
    function setPhaseAdmin(Phase _phase, address _admin) external onlyRole(ADMIN_ROLE) override {
        if(_admin == address(0)) {
            revert VotingSystemErrors.InvalidAddress();
        }
        
        phaseAdmins[_phase] = _admin;
        emit PhaseAdminSet(_phase, _admin, msg.sender);
    }
    
    
    function startRegistrationPhase() external onlyPhaseAdmin(Phase.Registration) phaseCanStart(Phase.Registration) {
        currentPhase = Phase.Registration;
        phaseActive = true;
        emit PhaseStarted(Phase.Registration, block.timestamp, msg.sender);
    }
    
    
    function endRegistrationPhase() external onlyPhaseAdmin(Phase.Registration) inPhase(Phase.Registration) {
        if(candidateIds.length == 0) {
            revert VotingSystemErrors.NoCandidatesRegistered();
        }
        phaseActive = false;
        phaseEndTime = block.timestamp;
        emit PhaseEnded(Phase.Registration, block.timestamp, msg.sender);
    }
    
    
    function startDonationPhase() external onlyPhaseAdmin(Phase.Donation) phaseCanStart(Phase.Donation) {
        currentPhase = Phase.Donation;
        phaseActive = true;
        emit PhaseStarted(Phase.Donation, block.timestamp, msg.sender);
    }
    
    
    function endDonationPhase() external onlyPhaseAdmin(Phase.Donation) inPhase(Phase.Donation) {
        phaseActive = false;
        phaseEndTime = block.timestamp;
        emit PhaseEnded(Phase.Donation, block.timestamp, msg.sender);
    }
    
    
    function startVotingPhase() external onlyPhaseAdmin(Phase.Voting) phaseCanStart(Phase.Voting) {
        currentPhase = Phase.Voting;
        phaseActive = true;
        emit PhaseStarted(Phase.Voting, block.timestamp, msg.sender);
    }
    
    
    function endVotingPhase() external onlyPhaseAdmin(Phase.Voting) inPhase(Phase.Voting) {
        phaseActive = false;
        phaseEndTime = block.timestamp;
        emit PhaseEnded(Phase.Voting, block.timestamp, msg.sender);
    }
    
    
    function startTallyingPhase() external onlyPhaseAdmin(Phase.Tallying) phaseCanStart(Phase.Tallying) {
        currentPhase = Phase.Tallying;
        phaseActive = true;
        emit PhaseStarted(Phase.Tallying, block.timestamp, msg.sender);
    }
    
    
    function endTallyingPhase() external onlyPhaseAdmin(Phase.Tallying) inPhase(Phase.Tallying) {
        phaseActive = false;
        phaseEndTime = block.timestamp;
        emit PhaseEnded(Phase.Tallying, block.timestamp, msg.sender);
    }
    
    
    
    
    function addCandidate(string memory _name) external onlyPhaseAdmin(Phase.Registration) inPhase(Phase.Registration) {
        if(bytes(_name).length == 0) {
            revert VotingSystemErrors.EmptyCandidateName();
        }
        
        uint candidateId = candidateIds.length + 1;
        candidates[candidateId] = Candidate(candidateId, _name, 0);
        candidateIds.push(candidateId);
        
        emit CandidateAdded(candidateId, _name, msg.sender);
    }
    
    
    
    
    function donate() external payable inPhase(Phase.Donation) {
        if(msg.value == 0) {
            revert VotingSystemErrors.InvalidDonationAmount();
        }
        
        if(hasDonatedMapping[msg.sender]) {
            revert VotingSystemErrors.AlreadyDonated();
        }
        
        
        hasDonatedMapping[msg.sender] = true;
        
        
        donorNFT.mint(msg.sender, msg.value);
        
        
        (bool success, ) = treasuryAddress.call{value: msg.value}("");
        if(!success) {
            revert VotingSystemErrors.TransferFailed();
        }
        
        emit DonationReceived(msg.sender, msg.value, block.timestamp);
    }
    
    
    receive() external payable {
        if(currentPhase != Phase.Donation || !phaseActive) {
            revert VotingSystemErrors.NotInDonationPhase();
        }
        
        if(msg.value == 0) {
            revert VotingSystemErrors.InvalidDonationAmount();
        }
        
        if(hasDonatedMapping[msg.sender]) {
            revert VotingSystemErrors.AlreadyDonated();
        }
        
        hasDonatedMapping[msg.sender] = true;
        donorNFT.mint(msg.sender, msg.value);
        
        (bool success, ) = treasuryAddress.call{value: msg.value}("");
        if(!success) {
            revert VotingSystemErrors.TransferFailed();
        }
        
        emit DonationReceived(msg.sender, msg.value, block.timestamp);
    }
    
    
    
    
    function vote(uint _candidateId, Gender _gender) external inPhase(Phase.Voting) {
        if(hasVotedMapping[msg.sender]) {
            revert VotingSystemErrors.AlreadyVoted();
        }
        
        if(_candidateId == 0 || _candidateId > candidateIds.length) {
            revert VotingSystemErrors.InvalidCandidateId();
        }
        
        
        hasVotedMapping[msg.sender] = true;
        
        
        candidates[_candidateId].voteCount += 1;
        
        
        genderCounts[_gender] += 1;
        totalVoters += 1;
        
        
        voterNFT.mint(msg.sender);
        
        emit VoteCast(msg.sender, _candidateId, _gender, block.timestamp);
    }
    
    
    
    
    function getWinner() external view inPhase(Phase.Tallying) returns (Candidate memory) {
        if(candidateIds.length == 0) {
            revert VotingSystemErrors.NoCandidatesRegistered();
        }
        
        uint winnerId = candidateIds[0];
        uint maxVotes = candidates[winnerId].voteCount;
        
        for(uint i = 1; i < candidateIds.length; i++) {
            uint candidateId = candidateIds[i];
            if(candidates[candidateId].voteCount > maxVotes) {
                maxVotes = candidates[candidateId].voteCount;
                winnerId = candidateId;
            }
        }
        
        return candidates[winnerId];
    }
    
    
    
    
    function getCurrentPhase() external view returns (Phase) {
        return currentPhase;
    }
    
    
    function getCandidate(uint _candidateId) external view returns (Candidate memory) {
        if(_candidateId == 0 || _candidateId > candidateIds.length) {
            revert VotingSystemErrors.InvalidCandidateId();
        }
        return candidates[_candidateId];
    }
    
    
    function getCandidatesCount() external view returns (uint) {
        return candidateIds.length;
    }
    
    
    function getTotalVotes(uint _candidateId) external view returns (uint) {
        if(_candidateId == 0 || _candidateId > candidateIds.length) {
            revert VotingSystemErrors.InvalidCandidateId();
        }
        return candidates[_candidateId].voteCount;
    }
    
    
    function hasVoted(address _voter) external view returns (bool) {
        return hasVotedMapping[_voter];
    }
    
    
    function hasDonated(address _donor) external view returns (bool) {
        return hasDonatedMapping[_donor];
    }
    
    
    function getVotingStatistics() external view returns (
        uint maleCount,
        uint femaleCount,
        uint otherCount,
        uint totalVotes
    ) {
        return (
            genderCounts[Gender.Male],
            genderCounts[Gender.Female],
            genderCounts[Gender.Other],
            totalVoters
        );
    }
    
    
    function getPhaseAdmin(Phase _phase) external view override returns (address) {
        return phaseAdmins[_phase];
    }
}
