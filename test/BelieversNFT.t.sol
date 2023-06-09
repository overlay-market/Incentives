// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/BelieversNFT.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

contract BelieversNFTTests is Test {
    using stdStorage for StdStorage;

    BelieversNFT private nft;

    function setUp() public {
        // Deploy NFT contract
        nft = new BelieversNFT("NFT_Demo", "ND", "baseUri");
        nft.setStakingContract(address(this));
    }

    function testFailMintToZeroAddress() public {
        nft.mintTo(address(0));
    }

    function testNewMintOwnerRegistered() public {
        nft.mintTo(address(1));
        uint256 slotOfNewOwner = stdstore
            .target(address(nft))
            .sig(nft.ownerOf.selector)
            .with_key(1)
            .find();

        uint160 ownerOfTokenIdOne = uint160(uint256((vm.load(address(nft),bytes32(abi.encode(slotOfNewOwner))))));
        assertEq(address(ownerOfTokenIdOne), address(1));
    }

    function testBalanceIncremented() public { 
        nft.mintTo(address(1));
        uint256 slotBalance = stdstore
            .target(address(nft))
            .sig(nft.balanceOf.selector)
            .with_key(address(1))
            .find();
        
        uint256 balanceFirstMint = uint256(vm.load(address(nft), bytes32(slotBalance)));
        assertEq(balanceFirstMint, 1);

        nft.mintTo(address(1));
        uint256 balanceSecondMint = uint256(vm.load(address(nft), bytes32(slotBalance)));
        assertEq(balanceSecondMint, 2);
    }

    function testSafeContractReceiver() public {
        Receiver receiver = new Receiver();
        nft.mintTo(address(receiver));
         uint256 slotBalance = stdstore
            .target(address(nft))
            .sig(nft.balanceOf.selector)
            .with_key(address(receiver))
            .find();

        uint256 balance = uint256(vm.load(address(nft), bytes32(slotBalance)));
        assertEq(balance, 1);
    }
    
    function testFailUnSafeContractReceiver() public {
        vm.etch(address(1), bytes("mock code"));
        nft.mintTo(address(1));
    }
}


contract Receiver is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4){
        return this.onERC721Received.selector;
    }
}