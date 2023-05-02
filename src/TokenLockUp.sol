// SPDX-License-Identifier: UNLICENSED

/**
 * Created on 2023-05-02 02:00
 * @Summary A smart contract that let users lock their tokens and get an NFT.
 * @title TokenTokenLockUp
 * @author: Overlay - c-n-o-t-e
 */

pragma solidity ^0.8.13;

import "src/interfaces/IOverlayNFT.sol";
import "src/interfaces/ITokenLockUp.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/Pausable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenLockUp is ITokenLockUp, Ownable, Pausable, ReentrancyGuard {

    IERC20 public token;
    IOverlayNFT public nftContract;
    uint256 public depositDeadline;

    struct LockDetails {
        uint256 amount;
        uint256 lockDuration;
        uint lockStart;
        bool withdrawn;
    }

    mapping(address => LockDetails[]) public locks;

    constructor(address _tokenAddress, address _nftAddress) {
        token = IERC20(_tokenAddress);
        nftContract = IOverlayNFT(_nftAddress);
    }

    /// @inheritdoc ITokenLockUp
    function deposit(uint256 _amount, uint _lockDuration) external nonReentrant() whenNotPaused() {
        if(_amount == 0) revert TokenLockUp_AmountShouldBeGreaterThanZero();
        if(_lockDuration == 0) revert TokenLockUp_LockDurationShouldBeGreaterThanZero();
        if(block.timestamp > depositDeadline) revert TokenLockUp_DepositDeadlineReached();

        SafeERC20.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            _amount
        );

        locks[msg.sender].push(LockDetails({
            amount: _amount,
            lockDuration: _lockDuration,
            lockStart: block.timestamp,
            withdrawn: false
        }));

        uint numberOfNftToSend = calculateNftToSend(_amount, _lockDuration);

        for(uint i; i < numberOfNftToSend; i++){
            nftContract.mintTo(msg.sender);
        }
        
        emit Deposit(msg.sender, block.timestamp + _lockDuration, _amount);
    }

    function pause() external {
        _pause();
    }

    function unpause() external {
        if(block.timestamp >= depositDeadline) revert TokenLockUp_DepositDeadlineNotSet();
        _unpause();
    }

    /// @inheritdoc ITokenLockUp
    function withdrawTokens(uint256 _index) external nonReentrant() {
        if(_index > locks[msg.sender].length) revert TokenLockUp_Invalid_Index();
        LockDetails storage lock = locks[msg.sender][_index];

        if(lock.withdrawn) revert TokenLockUp_TokensAlreadyWithdrawn();
        if(block.timestamp < lock.lockStart + lock.lockDuration) revert TokenLockUp_TokensAreStillLocked();
        
        uint256 withdrawAmount = lock.amount;
        lock.withdrawn = true;

        SafeERC20.safeTransfer(
            token,
            msg.sender,
            withdrawAmount
        );

        emit Withdrawal(
            msg.sender,
            block.timestamp,
            withdrawAmount
        );
    }

    function setTokenAddress(address _newTokenAddress) external onlyOwner {
        token = IERC20(_newTokenAddress);
    }

    function setNftContractnAddress(address _nftAddress) external onlyOwner {
        nftContract = IOverlayNFT(_nftAddress);
    }

    function setDepositDeadline(uint _depositDeadline) external onlyOwner {
        if(depositDeadline > block.timestamp) revert TokenLockUp_PreviousDeadlineNotEnded();
        depositDeadline = _depositDeadline;
    }

    function getUserLockedBatchTokenCount() external view returns(uint) {
        return locks[msg.sender].length;
    }

    function calculateNftToSend(uint _amount, uint _lockDuration) internal pure returns(uint) {
        // logic still in the works, will return 2 for test purpose
        return 2;
    }
}
