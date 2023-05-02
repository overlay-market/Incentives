// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "src/interfaces/IOverlayNFT.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/Pausable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

error LockUp_Invalid_Index();
error LockUp_TokensAreStillLocked();
error LockUp_DepositDeadlineNotSet();
error LockUp_DepositDeadlineReached();
error LockUp_TokensAlreadyWithdrawn();
error LockUp_PreviousDeadlineNotEnded();
error LockUp_DurationBelowExistingDuration();
error LockUp_AmountShouldBeGreaterThanZero();
error LockUp_LockDurationShouldBeGreaterThanZero();

contract LockUp is Ownable, Pausable, ReentrancyGuard {

    event Deposit(
        address indexed _addr,
        uint256 timestamp,
        uint256 amount
    );
    event Withdrawal(
        address indexed _addr,
        uint256 timestamp,
        uint256 amount
    );

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
        pause();
        token = IERC20(_tokenAddress);
        nftContract = IOverlayNFT(_nftAddress);
    }

    function deposit(uint256 _amount, uint _lockDuration) external nonReentrant() whenNotPaused() {
        if(block.timestamp > depositDeadline) revert LockUp_DepositDeadlineReached();
        if(_amount == 0) revert LockUp_AmountShouldBeGreaterThanZero();
        if(_lockDuration == 0) revert LockUp_LockDurationShouldBeGreaterThanZero();

        locks[msg.sender].push(LockDetails({
            amount: _amount,
            lockDuration: _lockDuration,
            lockStart: block.timestamp,
            withdrawn: false
        }));

        SafeERC20.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            _amount
        );

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
        if(block.timestamp >= depositDeadline) revert LockUp_DepositDeadlineNotSet();
        _unpause();
    }

    function withdrawTokens(uint256 _index) external nonReentrant() {
        if(_index > locks[msg.sender].length) revert LockUp_Invalid_Index();
        LockDetails storage lock = locks[msg.sender][_index];

        if(lock.withdrawn) revert LockUp_TokensAlreadyWithdrawn();
        if(block.timestamp < lock.lockStart + lock.lockDuration) revert LockUp_TokensAreStillLocked();
        
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
        if(depositDeadline > block.timestamp) revert LockUp_PreviousDeadlineNotEnded();
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
