// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;


library VotingSystemErrors {
    
    error Unauthorized();
    error InvalidAddress();
    error InvalidPhase();
    error PhaseNotActive();
    error PhaseAlreadyActive();
    
    
    error MinimumDelayNotReached();
    error PhaseStillActive();
    
    
    error EmptyCandidateName();
    error InvalidCandidateId();
    error NoCandidatesRegistered();
    
    
    error AlreadyVoted();
    error NotInVotingPhase();
    
    
    error NotInDonationPhase();
    error InvalidDonationAmount();
    error AlreadyDonated();
    error TransferFailed();
    
    
    error NotPhaseAdmin();
    error NotSuperAdmin();
    error AdminAlreadySet();
}
