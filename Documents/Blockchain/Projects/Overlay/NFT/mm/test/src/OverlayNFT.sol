// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

error OverlayNFT_OnlyStakingContract();

contract OverlayNFT is ERC721, Ownable {

    using Strings for uint256;
    string public baseURI;
    uint256 public currentTokenId;
    address public stakingContract;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) ERC721(_name, _symbol) {
        baseURI = _baseURI;
    }

    modifier onlyStakingContract{
        if(msg.sender != stakingContract) revert OverlayNFT_OnlyStakingContract();
        _;
    }

    function setStakingContract(address _newStakingContract) external onlyStakingContract {
        stakingContract = _newStakingContract;
    }

    function mintTo(address _recipient) external onlyStakingContract returns (uint256) {
        uint256 newTokenId = ++currentTokenId;
        _safeMint(_recipient, newTokenId);
        return newTokenId;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            ownerOf(_tokenId) != address(0),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _tokenId.toString()))
                : "";
    }
}