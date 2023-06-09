// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IBelieversNFT {
    function setStakingContract(address _newStakingContract) external;

    function mintTo(address _recipient) external;
}
