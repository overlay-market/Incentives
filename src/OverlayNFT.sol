// SPDX-License-Identifier: UNLICENSED

/**
 * Created on 2023-05-01 11:39
 * @Summary A smart contract that mints NFTs as reward for the LockUp contract.
 * @title OverlayNFT
 * @author: Overlay - c-n-o-t-e
 */

pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Counters.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

error OverlayNFT_OnlyStakingContract();

contract OverlayNFT is ERC721, Ownable {

    using Strings for uint256;
    using Counters for Counters.Counter;

    event Mint(
        address indexed _addr,
        uint256 id
    );
    
    string public baseURI;
    uint256 public currentTokenId;

    Counters.Counter public _orderID;
    address public stakingContract;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) ERC721(_name, _symbol) {
        baseURI = _baseURI;
    }

    modifier onlyStakingContract() {
        if(msg.sender != stakingContract) revert OverlayNFT_OnlyStakingContract();
        _;
    }

    function setStakingContract(address _newStakingContract) external onlyStakingContract {
        stakingContract = _newStakingContract;
    }

    function mintTo(address _recipient) external onlyStakingContract {
        _orderID.increment();
        _safeMint(_recipient, _orderID.current());

        emit Mint(_recipient, _orderID.current());
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