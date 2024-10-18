// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


import "forge-std/Test.sol";
import "../src/contracts/Diamond.sol";
import "../src/contracts/facets/ERC721Facet.sol";
import "../src/contracts/facets/MerkleFacet.sol";
import "../src/contracts/facets/PresaleFacet.sol";

contract DiamondTest is Test {
    Diamond diamond;
    ERC721Facet erc721Facet;
    MerkleFacet merkleFacet;
    PresaleFacet presaleFacet;
    
    // Using the actual Merkle root from your terminal output
    bytes32 constant MERKLE_ROOT = 0x93f727ecf745867f0c5a4bcbc0256e39d9bb85ad76e7813dec1da9295819489c;
    
    // Test address from your terminal output
    address constant ALLOWED_MINTER = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    function setUp() public {
        // Deploy facets
        erc721Facet = new ERC721Facet();
        merkleFacet = new MerkleFacet();
        presaleFacet = new PresaleFacet();

        // Create facet cuts array
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](3);
        
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(erc721Facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getERC721Selectors()
        });

        cuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(merkleFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getMerkleSelectors()
        });

        cuts[2] = IDiamondCut.FacetCut({
            facetAddress: address(presaleFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getPresaleSelectors()
        });

        // Deploy diamond
        diamond = new Diamond(address(this), cuts);
        
        // Set the merkle root
        MerkleFacet(address(diamond)).setMerkleRoot(MERKLE_ROOT);
    }

    function testMerkleClaim() public {
        // Using the actual proof from your terminal output
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = 0xdce7c4a0d1e0d39be67438b65afa52e56f10cfd0bf43a4313153c33f6a006a08;
        
        vm.startPrank(ALLOWED_MINTER);
        MerkleFacet(address(diamond)).claim(proof, 1);  // Token ID 1 from your whitelist
        vm.stopPrank();
        
        assertEq(ERC721Facet(address(diamond)).ownerOf(1), ALLOWED_MINTER);
    }

    function testPresaleMint() public {
        PresaleFacet(address(diamond)).setPresaleActive(true);
        
        // Test minimum purchase (0.01 ETH = 1 NFT)
        address buyer = address(1);
        vm.deal(buyer, 0.01 ether);
        vm.prank(buyer);
        PresaleFacet(address(diamond)).presaleMint{value: 0.01 ether}(1);
        
        assertEq(ERC721Facet(address(diamond)).balanceOf(buyer), 1);

        // Test maximum purchase (1 ETH = 30 NFTs)
        address buyer2 = address(2);
        vm.deal(buyer2, 1 ether);
        vm.prank(buyer2);
        PresaleFacet(address(diamond)).presaleMint{value: 1 ether}(30);
        
        assertEq(ERC721Facet(address(diamond)).balanceOf(buyer2), 30);
    }

    function testFailPresaleInactive() public {
        address buyer = address(1);
        vm.deal(buyer, 0.01 ether);
        vm.prank(buyer);
        PresaleFacet(address(diamond)).presaleMint{value: 0.01 ether}(1);
    }

    // Helper functions to get function selectors for each facet
    function getERC721Selectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](9);
        selectors[0] = ERC721Facet.balanceOf.selector;
        selectors[1] = ERC721Facet.ownerOf.selector;
        selectors[2] = ERC721Facet.tokenURI.selector;
        selectors[3] = ERC721Facet.approve.selector;
        selectors[4] = ERC721Facet.getApproved.selector;
        selectors[5] = ERC721Facet.setApprovalForAll.selector;
        selectors[6] = ERC721Facet.isApprovedForAll.selector;
        selectors[7] = ERC721Facet.transferFrom.selector;
        selectors[8] = ERC721Facet.safeTransferFrom.selector;
        return selectors;
    }

    function getMerkleSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = MerkleFacet.setMerkleRoot.selector;
        selectors[1] = MerkleFacet.claim.selector;
        selectors[2] = MerkleFacet.hasClaimed.selector;
        return selectors;
    }

    function getPresaleSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = PresaleFacet.setPresaleActive.selector;
        selectors[1] = PresaleFacet.presaleMint.selector;
        selectors[2] = PresaleFacet.presaleMinted.selector;
        return selectors;
    }
}