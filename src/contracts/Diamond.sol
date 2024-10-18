// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./libraries/LibDiamond.sol";

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    
    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }
}

contract Diamond {
    constructor(address _contractOwner, IDiamondCut.FacetCut[] memory _diamondCut) {
        LibDiamond.setContractOwner(_contractOwner);
        
        for(uint i = 0; i < _diamondCut.length; i++) {
            LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
            IDiamondCut.FacetCut memory cut = _diamondCut[i];
            
            for(uint j = 0; j < cut.functionSelectors.length; j++) {
                bytes4 selector = cut.functionSelectors[j];
                ds.facetAddressAndPositionMap[selector] = LibDiamond.FacetAddressAndPosition(
                    cut.facetAddress,
                    uint96(ds.functionSelectors.length)
                );
                ds.functionSelectors.push(selector);
            }
        }
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        address facet = ds.facetAddressAndPositionMap[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {revert(0, returndatasize())}
            default {return(0, returndatasize())}
        }
    }

    receive() external payable {}
}