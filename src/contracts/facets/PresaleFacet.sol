// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC721Facet.sol";
import "../libraries/LibDiamond.sol";

contract PresaleFacet {
    struct PresaleStorage {
        bool presaleActive;
        uint256 presalePrice; // Price per NFT in wei
        mapping(address => uint256) presaleMinted;
    }
    
    bytes32 constant STORAGE_POSITION = keccak256("diamond.presale.storage");
    
    function getStorage() internal pure returns (PresaleStorage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    
    event PresaleMint(address indexed buyer, uint256 amount);
    
    constructor() {
        PresaleStorage storage s = getStorage();
        s.presalePrice = 0.01 ether; // 1 ETH = 30 NFTs, so 0.01 ETH per NFT
    }
    
    function setPresaleActive(bool _active) external {
        LibDiamond.enforceIsContractOwner();
        PresaleStorage storage s = getStorage();
        s.presaleActive = _active;
    }
    
    function presaleMint(uint256 amount) external payable {
        PresaleStorage storage s = getStorage();
        require(s.presaleActive, "Presale not active");
        require(amount > 0, "Must mint at least 1");
        require(amount <= 30, "Cannot mint more than 30");
        require(msg.value >= amount * s.presalePrice, "Insufficient payment");
        require(s.presaleMinted[msg.sender] + amount <= 30, "Exceeds max per address");
        
        uint256 startTokenId = ERC721Facet(address(this)).totalSupply();
        
        for(uint256 i = 0; i < amount; i++) {
            ERC721Facet(address(this)).mint(msg.sender, startTokenId + i);
        }
        
        s.presaleMinted[msg.sender] += amount;
        
        emit PresaleMint(msg.sender, amount);
    }
    
    function presaleMinted(address account) external view returns (uint256) {
        PresaleStorage storage s = getStorage();
        return s.presaleMinted[account];
    }
}