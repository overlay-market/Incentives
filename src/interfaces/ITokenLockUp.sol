// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

error TokenLockUp_Invalid_Index();
error TokenLockUp_TokensAreStillLocked();
error TokenLockUp_DepositDeadlineNotSet();
error TokenLockUp_DepositDeadlineReached();
error TokenLockUp_TokensAlreadyWithdrawn();
error TokenLockUp_PreviousDeadlineNotEnded();
error TokenLockUp_DurationBelowExistingDuration();
error TokenLockUp_AmountShouldBeGreaterThanZero();
error TokenLockUp_LockDurationShouldBeGreaterThanZero();

interface ITokenLockUp {
    event Deposit(address indexed _addr, uint256 timestamp, uint256 amount);

    event Withdrawal(address indexed _addr, uint256 timestamp, uint256 amount);

    /// @notice Pauses the contract.
    function pause() external;

    /// @notice Unpauses the contract if the deposit deadline has not passed.
    function unpause() external;

    /// @notice Allows a user to withdraw their locked tokens if the lock duration has passed.
    /// @param _index key for users struct.
    function withdrawTokens(uint256 _index) external;

    /// @notice Allows the owner to set the deposit deadline.
    /// @param _depositDeadline new nft address.
    function setDepositDeadline(uint256 _depositDeadline) external;

    /// @notice Allows the owner to set the address of the token contract.
    /// @param _newTokenAddress new token address.
    function setTokenAddress(address _newTokenAddress) external;

    /// @notice Allows the owner to set the address of the NFT contract.
    /// @param _nftAddress new nft address.
    function setNftContractnAddress(address _nftAddress) external;

    /// @notice Allows a user to lock up their tokens for a specified duration in exchange for NFTs.
    /// @param _amount amount to deposit.
    /// @param _lockDuration lock up time.
    function deposit(uint256 _amount, uint256 _lockDuration) external;

    /// @notice Allows the user to get the count of their locked token batches.
    function getUserLockedBatchTokenCount() external view returns (uint256);
}
