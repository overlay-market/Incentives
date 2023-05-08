// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/access/IAccessControlEnumerable.sol";

error OverlayNFTs_NotMinter();
error OverlayNFTs_NotBurner();

interface IOverlayNFTs is IAccessControlEnumerable {
    function mint(address _recipient, uint256 _id, uint256 _amount) external;
}
