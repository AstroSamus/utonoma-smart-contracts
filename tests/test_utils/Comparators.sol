// SPDX-License-Identifier: MIT
        
pragma solidity 0.8.22;

abstract contract Comparators {
    ///#dev: Compares two arrays, returns true if they are equal
    function arrayComparator(uint256[] memory array1, uint256[] memory array2) public pure returns(bool){
        if(array1.length != array2.length) return false;

        for(uint256 i = 0; i < array1.length; i++){
            if(array1[i] != array2[i]) return false;
        }

        return true;
    }
}