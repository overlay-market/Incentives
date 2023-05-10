// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

error TokenLockUp_Invalid_Index();
error TokenLockUp_AmountCannotBeZero();
error TokenLockUp_TokensAreStillLocked();
error TokenLockUp_DepositDeadlineNotSet();
error TokenLockUp_NotOverlayNftContract();
error TokenLockUp_DepositDeadlineReached();
error TokenLockUp_TokensAlreadyWithdrawn();
error TokenLockUp_PreviousDeadlineNotEnded();
error TokenLockUp_DurationBelowExistingDuration();
error TokenLockUp_AmountShouldBeGreaterThanZero();
error TokenLockUp_LockDurationShouldBeGreaterThanZero();

interface ITokenLockUp {
    /// @notice Emits an event whenever the deposit function is called.
    event Deposit(address indexed _addr, uint256 timestamp, uint256 amount);

    /// @notice Emits an event whenever the withdraw function is called.
    event Withdrawal(address indexed _addr, uint256 timestamp, uint256 amount);

    // Contains details of a user's locked tokens and total locked amount.
    struct LockDetails {
        uint256 totalAmountLocked;
        UserDetails[] user;
    }

    // Contains details of a user's locked tokens.
    struct UserDetails {
        uint256 amount;
        uint256 lockDuration;
        uint256 lockStart;
    }

    /// @notice Pauses the contract.
    function pause() external;

    /// @notice Unpauses the contract if the deposit deadline has not passed.
    function unpause() external;

    /// @notice Withdraws all users locked token given they've surpass their locked
    function withdrawAllAvailableTokens() external;

    /// @notice Allows a user to withdraw their locked tokens if the lock duration has passed.
    /// @param _index Key for users struct.
    function withdrawTokens(uint256 _index) external;

    /// @notice Allows the owner to set the address of the token contract.
    /// @param _newTokenAddress New token address.
    function setTokenAddress(address _newTokenAddress) external;

    /// @notice Allows the owner to set the address of the NFT contract.
    /// @param _nftAddress New nft address.
    function setNftContractnAddress(address _nftAddress) external;

    /// @notice Allows a user to lock up their tokens for a specified duration in exchange for NFTs.
    /// @param _amount Amount to deposit.
    /// @param _lockDuration Lock up time.
    function deposit(uint256 _amount, uint256 _lockDuration) external;

    /// @notice Allows the user to get their total points earned
    /// @param _userAddress User's address
    /// @return uints256 Points earned from locking OVL
    function earnedPoints(address _userAddress) external view returns (uint256);

    /// @notice Allows the user to get the count of their locked token batches.
    /// @return uints256 Total locked count.
    function getUserLockedBatchTokenCount() external view returns (uint256);

    /// @notice Used to reduce users points after they redeem an NFT from the OverlayNFT contract.
    /// @param _userAddress User address whose points are to be reduced.
    /// @param _pointsToReduce amount of points to be subtracted.
    function updateUserPoints(
        address _userAddress,
        uint256 _pointsToReduce
    ) external;

    /// @notice Used to return the withdrawable amount and their index a user has.
    /// @return withdrawableAmount total amount to withdraw.
    /// @return indexToWithdraw index of withdrawable amount.
    function getAllWithdrawableBatchTokens()
        external
        view
        returns (uint256 withdrawableAmount, uint256[] memory indexToWithdraw);
}
