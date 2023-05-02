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

    function pause() external;

    function unpause() external;

    /// @notice Let users withdraw their token
    /// @param _index key for users struct.
    function withdrawTokens(uint256 _index) external;

    function setDepositDeadline(uint _depositDeadline) external;

    function setTokenAddress(address _newTokenAddress) external;

    function setNftContractnAddress(address _nftAddress) external;

    /// @notice Let users deposit their token and recieve NFT(s)
    /// @param _amount amount to deposit.
    /// @param _lockDuration lock up time.
    function deposit(uint256 _amount, uint _lockDuration) external;

    function getUserLockedBatchTokenCount() external view returns (uint);
}
