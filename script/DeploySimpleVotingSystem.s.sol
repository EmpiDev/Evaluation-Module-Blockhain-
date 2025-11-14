// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {SimpleVotingSystem} from "../src/SimpleVotingSystem.sol";
import {VoterNFT} from "../src/VoterNFT.sol";
import {DonorNFT} from "../src/DonorNFT.sol";

contract DeploySimpleVotingSystem is Script {
    function run() external returns (SimpleVotingSystem, VoterNFT, DonorNFT) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        VoterNFT voterNFT = new VoterNFT();
        
        DonorNFT donorNFT = new DonorNFT();
        
        SimpleVotingSystem votingSystem = new SimpleVotingSystem(
            address(voterNFT),
            address(donorNFT)
        );
        
        voterNFT.transferOwnership(address(votingSystem));
        donorNFT.transferOwnership(address(votingSystem));
        
        vm.stopBroadcast();
        
        return (votingSystem, voterNFT, donorNFT);
    }
}
