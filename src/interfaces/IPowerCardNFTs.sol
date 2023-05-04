// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/access/IAccessControlEnumerable.sol";

error PowerCardNFTs_NotMinter();
error PowerCardNFTs_NotBurner();

interface IPowerCardNFTs is IAccessControlEnumerable {
    function believersNFT() external view returns (uint);

    function mint(address _recipient, uint256 _id, uint256 _amount) external;
}
