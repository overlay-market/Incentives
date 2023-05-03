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
    // Define public variables for the ERC20 token and the NFT contract.
    IERC20 public token;
    IOverlayNFT public nftContract;

    // Define a public variable for the deposit deadline.
    uint256 public depositDeadline;

    // Define a struct called LockDetails that contains details of a user's locked tokens.
    struct LockDetails {
        uint256 amount;
        uint256 lockDuration;
        uint256 lockStart;
        bool withdrawn;
    }

    // Define a mapping to store the lock details for each user.
    mapping(address => LockDetails[]) public locks;

    // Define the constructor of the contract, which initializes the ERC20 token and NFT contract addresses.
    constructor(address _tokenAddress, address _nftAddress) {
        token = IERC20(_tokenAddress);
        nftContract = IOverlayNFT(_nftAddress);
    }

    /// @inheritdoc ITokenLockUp
    function deposit(
        uint256 _amount,
        uint256 _lockDuration
    ) external nonReentrant whenNotPaused {
        // If the deposit deadline has passed, revert the transaction.
        if (block.timestamp > depositDeadline)
            revert TokenLockUp_DepositDeadlineReached();

        // If the lock duration is 0, revert the transaction.
        if (_lockDuration == 0)
            revert TokenLockUp_LockDurationShouldBeGreaterThanZero();

        // If the deposit amount is 0, revert the transaction.
        if (_amount == 0) revert TokenLockUp_AmountShouldBeGreaterThanZero();

        // Transfer the tokens from the user to the contract.
        SafeERC20.safeTransferFrom(token, msg.sender, address(this), _amount);

        // Add the lock details to the mapping for the user.
        locks[msg.sender].push(
            LockDetails({
                amount: _amount,
                lockDuration: _lockDuration,
                lockStart: block.timestamp,
                withdrawn: false
            })
        );

        // Calculate the number of NFTs to send to the user based on the locked
        // token amount and duration, and mint them.
        uint256 numberOfNftToSend = calculateNftToSend(_amount, _lockDuration);
        for (uint256 i; i < numberOfNftToSend; i++) {
            nftContract.mintTo(msg.sender);
        }

        // Emit a Deposit event to signify that a deposit has been made.
        emit Deposit(msg.sender, block.timestamp + _lockDuration, _amount);
    }

    /// @inheritdoc ITokenLockUp
    function withdrawTokens(uint256 _index) public nonReentrant {
        // If the index is invalid, revert the transaction.
        if (_index > locks[msg.sender].length - 1)
            revert TokenLockUp_Invalid_Index();

        // Get the lock details
        LockDetails storage lock = locks[msg.sender][_index];

        // Check if tokens have already been withdrawn
        if (lock.withdrawn) revert TokenLockUp_TokensAlreadyWithdrawn();

        // Check if tokens are still locked
        if (block.timestamp < lock.lockStart + lock.lockDuration)
            revert TokenLockUp_TokensAreStillLocked();

        uint256 withdrawAmount = lock.amount;

        // Mark the tokens as withdrawn
        lock.withdrawn = true;

        // Transfer the tokens to the user
        SafeERC20.safeTransfer(token, msg.sender, withdrawAmount);

        // Emit an event to indicate the withdrawal
        emit Withdrawal(msg.sender, block.timestamp, withdrawAmount);
    }

    /// @inheritdoc ITokenLockUp
    function withdrawAllLockedTokens() external {
        uint count = getUserLockedBatchTokenCount();

        for (uint i; i < count; i++) {
            withdrawTokens(i);
        }
    }

    /// @inheritdoc ITokenLockUp
    function pause() external {
        _pause();
    }

    /// @inheritdoc ITokenLockUp
    function unpause() external {
        // If the deposit deadline has passed, revert the transaction.
        if (block.timestamp >= depositDeadline)
            revert TokenLockUp_DepositDeadlineNotSet();

        _unpause();
    }

    /// @inheritdoc ITokenLockUp
    function setTokenAddress(address _newTokenAddress) external onlyOwner {
        token = IERC20(_newTokenAddress);
    }

    /// @inheritdoc ITokenLockUp
    function setNftContractnAddress(address _nftAddress) external onlyOwner {
        nftContract = IOverlayNFT(_nftAddress);
    }

    /// @inheritdoc ITokenLockUp
    function setDepositDeadline(uint256 _depositDeadline) external onlyOwner {
        // Check if the previous deadline has ended
        if (depositDeadline > block.timestamp)
            revert TokenLockUp_PreviousDeadlineNotEnded();

        // Set the new deposit deadline
        depositDeadline = _depositDeadline;
    }

    /// @inheritdoc ITokenLockUp
    function getUserLockedBatchTokenCount() public view returns (uint256) {
        return locks[msg.sender].length;
    }

    /// @notice Allows the owner to set the deposit deadline.
    /// @param _amount amount deposited by user.
    /// @param _lockDuration lock up duration set by user.
    function calculateNftToSend(
        uint256 _amount,
        uint256 _lockDuration
    ) internal pure returns (uint256) {
        // logic still in the works, will return 2 for test purpose
        return 2;
    }
}
