// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";


contract DonorNFT is ERC721, Ownable {
    uint256 private _nextTokenId;
    
    
    mapping(uint256 => uint256) public donationAmount;
    mapping(uint256 => uint256) public donationTimestamp;
    
    error OnlyVotingSystem();
    
    event DonorNFTMinted(address indexed donor, uint256 tokenId, uint256 amount, uint256 timestamp);
    
    
    constructor() ERC721("Donor Proof", "DONOR") Ownable(msg.sender) {
        _nextTokenId = 1; 
    }
    
    
    function mint(address _donor, uint256 _amount) external onlyOwner returns (uint256) {
        if(_donor == address(0)) revert OnlyVotingSystem();
        
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        
        donationAmount[tokenId] = _amount;
        donationTimestamp[tokenId] = block.timestamp;
        _safeMint(_donor, tokenId);
        
        emit DonorNFTMinted(_donor, tokenId, _amount, block.timestamp);
        
        return tokenId;
    }
    
    
    function totalSupply() external view returns (uint256) {
        return _nextTokenId - 1;
    }
    
    
    function hasDonated(address _donor) external view returns (bool) {
        return balanceOf(_donor) > 0;
    }
}
