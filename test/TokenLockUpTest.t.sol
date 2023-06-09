// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TestToken.sol";
import "forge-std/console.sol";
import "../src/TokenLockUp.sol";
import "../src/interfaces/ITokenLockUp.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

contract TokenLockUpTest is Test {
    // Declare the necessary variables

    IERC20 token;
    TokenLockUp tokenLockUp;

    uint256 amount = 1000;
    uint256 lockDuration = 2 days;

    function setUp() public {
        // Deploy the TokenLockUp contract
        token =  new TestToken();
        tokenLockUp = new TokenLockUp(address(token));

        // Approve the token to be used for deposit
        token.approve(address(tokenLockUp), 1000000000000000000000);
    }

    function testDeposit() public {
        uint256 contractBalanceBeforeDepositTx = token.balanceOf(address(tokenLockUp));

        // Assert that contract balance is zero
        assertEq(contractBalanceBeforeDepositTx, 0);

        // Deposit 1000 tokens with a lockup period of 1000 seconds
        tokenLockUp.deposit(amount, lockDuration);

        uint256 contractBalanceAfterDepositTx = token.balanceOf(address(tokenLockUp));

        // Assert that contract balance is 1000
        assertEq(contractBalanceAfterDepositTx, amount);

        TokenLockUp.LockDetails memory lock = tokenLockUp.getUserDetails();

        // Assert that the user token amount is correct
        assertEq(lock.user[0].amount, amount);

        // Assert that the user total token amount locked is correct
        assertEq(lock.totalAmountLocked, amount);

        // Assert that the user token amount is correct
        assertEq(lock.user[0].lockDuration, (block.timestamp - 1) + lockDuration);

        // Assert that the user has received the right points
        assertEq(tokenLockUp.earnedPoints(address(this)), amount * 2);

        // Assert that the user has 1 locked batch of tokens
        assertEq(tokenLockUp.getUserLockedBatchTokenCount(), 1);
    }

    function testWithdrawTokens() public {
        uint userBalanceBeforeDepositTx = token.balanceOf(address(this));

        // Deposit 1000 tokens with a lockup period of 1000 seconds
        tokenLockUp.deposit(amount, lockDuration);

        uint userBalanceAfterDepositTx = token.balanceOf(address(this));

        // Advance the block timestamp to the end of the lockup period
        vm.warp(block.timestamp + lockDuration);

        // Assert that the user has 1 locked batches of tokens
        assertEq(tokenLockUp.getUserLockedBatchTokenCount(), 1);

        // Withdraw the tokens
        tokenLockUp.withdrawTokens(0);

        uint256 contractBalanceAfterWithdrawTx = token.balanceOf(address(tokenLockUp));

        // Assert that contract balance is 0
        assertEq(contractBalanceAfterWithdrawTx, 0);

        uint256 userBalanceAfterWithdrawTx = token.balanceOf(address(this));

        // Assert that the user has no locked batches of tokens
        assertEq(tokenLockUp.getUserLockedBatchTokenCount(), 0);

        assertEq(userBalanceBeforeDepositTx - amount, userBalanceAfterDepositTx);

        // Assert that the user has received 1000 tokens
        assertEq(userBalanceAfterDepositTx + amount, userBalanceAfterWithdrawTx);
    }

    function testWithdrawOnlyOneBatchTokens() public {
        // 1st user deposit
        tokenLockUp.deposit(amount, lockDuration);

        // 2nd user deposit
        tokenLockUp.deposit(amount, lockDuration);

        // User details before withdraw()
        TokenLockUp.LockDetails memory lock = tokenLockUp.getUserDetails();

        // Assert that the user 1st token amount is correct
        assertEq(lock.user[0].amount, amount);

        // Assert that the user 2nd token amount is correct
        assertEq(lock.user[1].amount, amount);

        // Assert that the user total token amount locked is correct
        assertEq(lock.totalAmountLocked, amount * 2);

        // Advance the block timestamp to the end of the lockup period
        vm.warp(block.timestamp + 3 days);

        // Withdraw the tokens
        tokenLockUp.withdrawTokens(0);

        // User details after withdraw()
        TokenLockUp.LockDetails memory lock0 = tokenLockUp.getUserDetails();

        // Assert that the user 1st token amount is 0
        assertEq(lock0.user[0].amount, 0);

        // Assert that the user 2nd token amount is still 1000
        assertEq(lock0.user[1].amount, amount);

        // Assert that the user total token amount is 1000 short
        assertEq(lock0.totalAmountLocked, amount);
    }

    function testWithdrawAllLockedTokens() public {
        // Deposit 1000 tokens with a lockup period of 1000 seconds
        tokenLockUp.deposit(amount, lockDuration);

        // Advance the block timestamp to the end of the lockup period
        vm.warp(block.timestamp + 3 days);

        tokenLockUp.deposit(amount, lockDuration);

        uint userBalanceAfterBothDepositTx = token.balanceOf(address(this));

        // Advance the block timestamp to the end of the lockup period
        vm.warp(block.timestamp + 3 days);

        // Assert that the user has 2 locked batches of tokens
        assertEq(tokenLockUp.getUserLockedBatchTokenCount(), 2);

        // Withdraw the tokens
        tokenLockUp.withdrawAllAvailableTokens();

        uint userBalanceAfterWithdrawTx = token.balanceOf(address(this));

        // Assert that the user has no locked batches of tokens
        assertEq(tokenLockUp.getUserLockedBatchTokenCount(), 0);

        // Assert that the user has received 2000 tokens extra
        assertEq(userBalanceAfterBothDepositTx + 2000, userBalanceAfterWithdrawTx);
    }

    function testWithdrawAllAvailableTokens() public {
        // Deposit 1000 tokens with a lockup period of 2 days 7 times
        for (uint256 i; i < 7; i++) {
            tokenLockUp.deposit(amount, lockDuration);
        }

        // Deposit 1000 tokens with a lockup period of 12 days
        tokenLockUp.deposit(amount, lockDuration * 6);

        uint256 contractBalanceAfterDepositTx = token.balanceOf(address(tokenLockUp));

        // Assert that contract balance is 8000
        assertEq(contractBalanceAfterDepositTx, 8000);

        // User details in contract
        TokenLockUp.LockDetails memory lock = tokenLockUp.getUserDetails();

        // Assert that the user token data for each batch is correct
        for (uint256 i; i < 7; i++) {
            assertEq(lock.user[i].amount, amount);
            assertEq(lock.user[i].lockDuration, (block.timestamp - 1) + lockDuration);
        }

        // Assert that the user total token amount locked is correct
        assertEq(lock.totalAmountLocked, 8000);

        uint userBalanceAfterBothDepositTx = token.balanceOf(address(this));

        // Advance the block timestamp to the end of the lockup period
        vm.warp(block.timestamp + 3 days);

        // Assert that the user has 2 locked batches of tokens
        assertEq(tokenLockUp.getUserLockedBatchTokenCount(), 8);

        // Withdraw the tokens
        tokenLockUp.withdrawAllAvailableTokens();

        TokenLockUp.LockDetails memory lock0 = tokenLockUp.getUserDetails();

        for (uint256 i; i < 6; i++) {
            // Assert that the user token amount for batch withdrawn is zero
            assertEq(lock0.user[i].amount, 0);
        }

        // Assert that the user token amount for batch not yet withdrawn is 1000
        assertEq(lock0.user[7].amount, amount);

        // Assert that the user total token amount locked is correct
        assertEq(lock0.totalAmountLocked, 1000);

        uint userBalanceAfterWithdrawTx = token.balanceOf(address(this));

        // Assert that the user still has 8 locked batches of tokens given he has unlocked tokens
        assertEq(tokenLockUp.getUserLockedBatchTokenCount(), 8);

        // Assert that the user has received 7000 tokens extra
        assertEq(userBalanceAfterBothDepositTx + 7000, userBalanceAfterWithdrawTx);
    }

    function testPointReduction() public {
        tokenLockUp.deposit(amount, lockDuration);

        // Assert that the user has received the right points
        assertEq(tokenLockUp.earnedPoints(address(this)), 2000);

        tokenLockUp.setNftContractnAddress(address(this));

        tokenLockUp.updateUserPoints(address(this), 500);

        // Assert that the user has received the right points
        assertEq(tokenLockUp.earnedPoints(address(this)), 1500);

    }

    function testPause() public {
        tokenLockUp.pause();
        assert(tokenLockUp.paused());
    }

    function testUnpause() public {
        tokenLockUp.pause();
        tokenLockUp.unpause();
        assert(!tokenLockUp.paused());
    }

    function testFailToDepositWhenContractIsPaused() external {
        tokenLockUp.pause();
        tokenLockUp.deposit(amount, lockDuration);
    }

    // Test case for depositing with invalid lock duration
    function testFailWhenDepositingWithInvalidLockDuration() public {
        tokenLockUp.deposit(1000, 0);
    }

    // Test case for depositing with 0 amount
    function testFailToDepositWithZeroAmount() public {
        tokenLockUp.deposit(0, lockDuration);
    }

    function testFailToWithdrawBeforeTokensAreUnlock() public {
        tokenLockUp.deposit(amount, lockDuration);
        tokenLockUp.withdrawTokens(0);
    }

    function testFailToWithdrawWhenTokensAmountIsZero() public {
        tokenLockUp.deposit(amount, lockDuration);
        tokenLockUp.deposit(amount, lockDuration);

        // Advance the block timestamp to the end of the lockup period
        vm.warp(block.timestamp + 3 days);

        // Withdraw the first batch tokens
        tokenLockUp.withdrawTokens(0);

        // Tries to withdraw the already withdrawn first batch tokens
        tokenLockUp.withdrawTokens(0);
    }

    // Test case for withdrawing with invalid index
    function testFailWhenWithdrawingWithInvalidIndex() public {
        tokenLockUp.deposit(amount, lockDuration);

        // Attempt to withdraw with invalid index
        tokenLockUp.withdrawTokens(1);
    }

    function testFailWhenCallIsNotNftContractAddress() public {
        tokenLockUp.updateUserPoints(address(this), 500);
    }

     function testFailWhenNonOwnerCallsRestrictedFunctions() public {
        vm.prank(address(1));
        tokenLockUp.setTokenAddress(address(2));
        tokenLockUp.setNftContractnAddress(address(2));
    }
}