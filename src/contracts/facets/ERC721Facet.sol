// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../libraries/LibDiamond.sol";

contract ERC721Facet is ERC721 {
    using Strings for uint256;
    
    struct NFTStorage {
        uint256 totalSupply;
        uint256 maxSupply;
        mapping(uint256 => bool) exists;
        mapping(address => uint256) balances;
        mapping(uint256 => address) owners;
        mapping(address => mapping(address => bool)) operatorApprovals;
        mapping(uint256 => address) tokenApprovals;
    }
    
    bytes32 constant STORAGE_POSITION = keccak256("diamond.nft.storage");
    
    function getStorage() internal pure returns (NFTStorage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    
    constructor() ERC721("DiamondNFT", "DNFT") {
        NFTStorage storage s = getStorage();
        s.maxSupply = 10000; // Set your desired max supply
    }
    
    function mint(address to, uint256 tokenId) public {
        NFTStorage storage s = getStorage();
        require(!s.exists[tokenId], "Token already exists");
        require(s.totalSupply < s.maxSupply, "Max supply reached");
        
        s.exists[tokenId] = true;
        s.owners[tokenId] = to;
        s.balances[to]++;
        s.totalSupply++;
        
        emit Transfer(address(0), to, tokenId);
    }

    function totalSupply() public view returns (uint256) {
        NFTStorage storage s = getStorage();
        return s.totalSupply;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        NFTStorage storage s = getStorage();
        return s.balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        NFTStorage storage s = getStorage();
        address owner = s.owners[tokenId];
        require(owner != address(0), "Token doesn't exist");
        return owner;
    }

    function tokenURI(uint256 tokenId) public pure override returns (string memory) {
        return string(abi.encodePacked("ipfs://yourBaseURI/", tokenId.toString()));
    }
}