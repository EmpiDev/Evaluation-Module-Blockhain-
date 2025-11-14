// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";


contract VoterNFT is ERC721, Ownable {
    uint256 private _nextTokenId;
    
    
    mapping(uint256 => uint256) public voteTimestamp;
    
    error OnlyVotingSystem();
    
    event VoterNFTMinted(address indexed voter, uint256 tokenId, uint256 timestamp);
    
    
    constructor() ERC721("Voter Proof", "VOTE") Ownable(msg.sender) {
        _nextTokenId = 1; 
    }
    
    function mint(address _voter) external onlyOwner returns (uint256) {
        if(_voter == address(0)) revert OnlyVotingSystem();
        
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        
        voteTimestamp[tokenId] = block.timestamp;
        _safeMint(_voter, tokenId);
        
        emit VoterNFTMinted(_voter, tokenId, block.timestamp);
        
        return tokenId;
    }
    
    
    function totalSupply() external view returns (uint256) {
        return _nextTokenId - 1;
    }
    
    
    function hasVoted(address _voter) external view returns (bool) {
        return balanceOf(_voter) > 0;
    }
}
