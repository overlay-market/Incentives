// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "src/interfaces/IPowerCardNFTs.sol";
import "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";

contract PowerCardNFTs is IPowerCardNFTs, AccessControlEnumerable, ERC1155 {
    string public name;
    string public symbol;

    uint256 public PowerCard = 2;
    uint256 public believersNFT = 1;

    mapping(uint => string) public tokenURI;
    mapping(uint256 => uint256) public totalSupply;

    constructor() ERC1155("") {
        symbol = "PCN";
        name = "PowerCardNFTs";

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyMinter() {
        if (!hasRole(keccak256("MINTER"), msg.sender))
            revert PowerCardNFTs_NotMinter();
        _;
    }

    modifier onlyBurner() {
        if (!hasRole(keccak256("BURNER"), msg.sender))
            revert PowerCardNFTs_NotBurner();
        _;
    }

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender))
            revert PowerCardNFTs_NotBurner();
        _;
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

    function redeemPowerCardNFT(
        uint256 _burnId,
        uint256 _burnAmount,
        uint256 _mintId
    ) external {
        // Todo
        // check if users believersNFT _burnAmount is eligible to redeem NFT revert if not
        // if eligible burn _burnAmount and mint powerCardNFT and calculated amount
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
