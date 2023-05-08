// SPDX-License-Identifier: MIT

/**
 * Created on 2023-05-02 02:00
 * @Summary A smart contract that let users redeem NFTs with points earned for locking OVL
 * @title OverlayNFTs
 * @author: Overlay - c-n-o-t-e
 */

pragma solidity ^0.8.13;

import "src/interfaces/IOverlayNFTs.sol";
import "src/interfaces/ITokenLockUp.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";

contract OverlayNFTs is IOverlayNFTs, AccessControlEnumerable, ERC1155 {
    string public name;
    string public symbol;

    ITokenLockUp public tokenLockUp;

    mapping(uint => string) public tokenURI;
    mapping(uint256 => uint256) public totalSupply;

    NFTS public nfts;

    constructor() ERC1155("") {
        symbol = "NIPS";
        name = "OverlayNFTs";

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyMinter() {
        if (!hasRole(keccak256("MINTER"), msg.sender))
            revert OverlayNFTs_NotMinter();
        _;
    }

    modifier onlyBurner() {
        if (!hasRole(keccak256("BURNER"), msg.sender))
            revert OverlayNFTs_NotBurner();
        _;
    }

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender))
            revert OverlayNFTs_NotBurner();
        _;
    }

    function setTokenLockUpAddress(address _addr) external {
        tokenLockUp = ITokenLockUp(_addr);
    }

    function mint(
        address _to,
        uint _id,
        uint _amount
    ) external override onlyMinter {
        totalSupply[_id] += _amount;
        _mint(_to, _id, _amount, "");
    }

    function mintBatch(
        address _to,
        uint[] memory _ids,
        uint[] memory _amounts
    ) external onlyMinter {
        for (uint256 i = 0; i < _ids.length; i++) {
            totalSupply[_ids[i]] += _amounts[i];
        }

        _mintBatch(_to, _ids, _amounts, "");
    }

    function burn(uint _id, uint _amount) external onlyBurner {
        totalSupply[_id] -= _amount;
        _burn(msg.sender, _id, _amount);
    }

    function burnBatch(
        uint[] memory _ids,
        uint[] memory _amounts
    ) external onlyBurner {
        for (uint256 i = 0; i < _ids.length; i++) {
            totalSupply[_ids[i]] -= _amounts[i];
        }

        _burnBatch(msg.sender, _ids, _amounts);
    }

    function setURI(uint _id, string memory _uri) external onlyAdmin {
        tokenURI[_id] = _uri;
        emit URI(_uri, _id);
    }

    function uri(uint _id) public view override returns (string memory) {
        return tokenURI[_id];
    }

    function redeemOverlayNFT(
        uint256 _pointsToReduce,
        uint256 _nftToRedeem
    ) external {
        // Todo
        // check if users points earned is eligible to redeem NFT revert if not
        // if eligible calculated amount and mint NFT
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC1155, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
