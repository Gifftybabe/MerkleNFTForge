// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721Facet.sol";
import "../libraries/LibDiamond.sol";

contract MerkleFacet {
    struct MerkleStorage {
        bytes32 merkleRoot;
        mapping(address => bool) hasClaimed;
    }
    
    bytes32 constant STORAGE_POSITION = keccak256("diamond.merkle.storage");
    
    function getStorage() internal pure returns (MerkleStorage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    
    event Claimed(address indexed claimer, uint256 tokenId);
    
    function setMerkleRoot(bytes32 _merkleRoot) external {
        LibDiamond.enforceIsContractOwner();
        MerkleStorage storage s = getStorage();
        s.merkleRoot = _merkleRoot;
    }
    
    function claim(bytes32[] calldata proof, uint256 tokenId) external {
        MerkleStorage storage s = getStorage();
        require(!s.hasClaimed[msg.sender], "Already claimed");
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, tokenId));
        require(
            MerkleProof.verify(proof, s.merkleRoot, leaf),
            "Invalid merkle proof"
        );
        
        s.hasClaimed[msg.sender] = true;
        
        // Cast this contract to ERC721Facet to call mint
        ERC721Facet(address(this)).mint(msg.sender, tokenId);
        
        emit Claimed(msg.sender, tokenId);
    }
    
    function hasClaimed(address account) external view returns (bool) {
        MerkleStorage storage s = getStorage();
        return s.hasClaimed[account];
    }
}