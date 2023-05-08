// SPDX-License-Identifier: UNLICENSED

/**
 * Created on 2023-05-02 02:00
 * @Summary A smart contract that let users lock their tokens and receive points.
 * @title TokenLockUp
 * @author: Overlay - c-n-o-t-e
 */

pragma solidity ^0.8.13;

import "src/interfaces/ITokenLockUp.sol";
import "src/interfaces/IOverlayNFTs.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/Pausable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenLockUp is ITokenLockUp, Ownable, Pausable, ReentrancyGuard {
    // Define public variables for the ERC20 token and the NFT contract.
    IERC20 public token;
    IOverlayNFTs public OverlayNFT;

    // Define a public variable for the deposit deadline.
    uint256 public depositDeadline;

    // Define a struct called LockDetails that contains details of a user's locked tokens.
    struct LockDetails {
        uint256 amount;
        uint256 lockDuration;
        uint256 lockStart;
    }

    // Define a mapping to store the lock details for each user.
    mapping(address => LockDetails[]) public locks;

    // Define a mapping to store points earned for each user.
    mapping(address => uint256) public earnedPoints;

    // Define the constructor of the contract, which initializes the ERC20 token and NFT contract addresses.
    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
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
                lockStart: block.timestamp
            })
        );

        // Calculate the number of NFTs to send to the user based on the locked
        // token amount and duration, and mint them.

        uint256 pointsEarned = calculateNftAmountToSend(
            _amount,
            _lockDuration
        );

        earnedPoints[msg.sender] += pointsEarned;

        // Emit a Deposit event to signify that a deposit has been made.
        emit Deposit(msg.sender, block.timestamp + _lockDuration, _amount);
    }

    /// @inheritdoc ITokenLockUp
    function withdrawTokens(uint256 _index) public nonReentrant {
        // If the index is invalid, revert the transaction.
        if (_index >= locks[msg.sender].length)
            revert TokenLockUp_Invalid_Index();

        // Get the lock details
        LockDetails storage lock = locks[msg.sender][_index];

        // Check if tokens are still locked
        if (block.timestamp < lock.lockStart + lock.lockDuration)
            revert TokenLockUp_TokensAreStillLocked();

        uint256 withdrawAmount = lock.amount;

        locks[msg.sender][_index] = locks[msg.sender][
            locks[msg.sender].length - 1
        ];
        locks[msg.sender].pop();

        // Transfer the tokens to the user
        SafeERC20.safeTransfer(token, msg.sender, withdrawAmount);

        // Emit an event to indicate the withdrawal
        emit Withdrawal(msg.sender, block.timestamp, withdrawAmount);
    }

    /// @inheritdoc ITokenLockUp
    function withdrawAllLockedTokens() external {
        uint count = getUserLockedBatchTokenCount();

        for (uint i; i < count; i++) {
            withdrawTokens(0);
        }
    }

    /// @inheritdoc ITokenLockUp
    function pause() external onlyOwner {
        _pause();
    }

    /// @inheritdoc ITokenLockUp
    function unpause() external onlyOwner {
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
        OverlayNFT = IOverlayNFTs(_nftAddress);
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
    function calculateNftAmountToSend(
        uint256 _amount,
        uint256 _lockDuration
    ) internal pure returns (uint256) {
        uint256 getDays = _lockDuration / 1 days;
        return (_amount * getDays);
    }
}
