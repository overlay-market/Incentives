// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/TestToken.sol";
import "../src/BelieversNFT.sol";
import "../src/TokenLockUp.sol";
import "../src/interfaces/ITokenLockUp.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

contract TokenLockUpTest is Test {
    // Declare the necessary variables
    IERC20 token;
    BelieversNFT nftContract;
    TokenLockUp tokenLockUp;
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
        tokenLockUp.deposit(1000, lockDuration);

        uint256 contractBalanceAfterDepositTx = token.balanceOf(address(tokenLockUp));

        // Assert that contract balance is 1000
        assertEq(contractBalanceAfterDepositTx, 1000);

        TokenLockUp.UserDetails[] memory user = tokenLockUp.getUserDetails();

        // Assert that the user token amount is correct
        assertEq(user[0].amount, 1000);

        // Assert that the user token amount is correct
        assertEq(user[0].lockDuration, (block.timestamp - 1) + lockDuration);

        // Assert that the user has received the right points
        assertEq(tokenLockUp.earnedPoints(address(this)), 1000 * 2);

        // Assert that the user has 1 locked batch of tokens
        assertEq(tokenLockUp.getUserLockedBatchTokenCount(), 1);
    }

    function testWithdrawTokens() public {
        uint userBalanceBeforeDepositTx = token.balanceOf(address(this));

        // Deposit 1000 tokens with a lockup period of 1000 seconds
        tokenLockUp.deposit(1000, lockDuration);

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

        assertEq(userBalanceBeforeDepositTx - 1000, userBalanceAfterDepositTx);

        // Assert that the user has received 1000 tokens
        assertEq(userBalanceAfterDepositTx + 1000, userBalanceAfterWithdrawTx);
    }

    function WithdrawAllLockedTokens() public {
        // Deposit 100 tokens with a lockup period of 1000 seconds
        tokenLockUp.deposit(100, lockDuration);

        // Advance the block timestamp to the end of the lockup period
        vm.warp(block.timestamp + 3 days);

        tokenLockUp.deposit(100, lockDuration);
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

        // Assert that the user has received 200 tokens extra
        assertEq(userBalanceAfterBothDepositTx + 200, userBalanceAfterWithdrawTx);
    }

    function testWithdrawAllAvailableTokens() public {
        // Deposit 1000 tokens with a lockup period of 2 days 6 times
        for (uint256 i; i < 7; i++) {
            tokenLockUp.deposit(1000, lockDuration);
        }

        // Deposit 1000 tokens with a lockup period of 12 days
        tokenLockUp.deposit(1000, lockDuration * 6);

        uint256 contractBalanceAfterDepositTx = token.balanceOf(address(tokenLockUp));

        // Assert that contract balance is 8000
        assertEq(contractBalanceAfterDepositTx, 8000);

        TokenLockUp.UserDetails[] memory user = tokenLockUp.getUserDetails();

        for (uint256 i; i < 7; i++) {
            // Assert that the user token data for each batch is correct
            assertEq(user[i].amount, 1000);
            assertEq(user[i].lockDuration, (block.timestamp - 1) + lockDuration);
        }

        uint userBalanceAfterBothDepositTx = token.balanceOf(address(this));

        // Advance the block timestamp to the end of the lockup period
        vm.warp(block.timestamp + 3 days);

        // Assert that the user has 2 locked batches of tokens
        assertEq(tokenLockUp.getUserLockedBatchTokenCount(), 8);

        // Withdraw the tokens
        tokenLockUp.withdrawAllAvailableTokens();

        TokenLockUp.UserDetails[] memory user1 = tokenLockUp.getUserDetails();

        for (uint256 i; i < 6; i++) {
            // Assert that the user token amount for batch withdrawn is zero
            assertEq(user1[i].amount, 0);
        }

        // Assert that the user token amount for batch not yet withdrawn is 1000
        assertEq(user1[7].amount, 1000);

        uint userBalanceAfterWithdrawTx = token.balanceOf(address(this));

        // Assert that the user still has 8 locked batches of tokens given he has unlocked tokens
        assertEq(tokenLockUp.getUserLockedBatchTokenCount(), 8);

        // Assert that the user has received 7000 tokens extra
        assertEq(userBalanceAfterBothDepositTx + 7000, userBalanceAfterWithdrawTx);
    }

    function testFailToWithdrawBeforeTokensAreUnlock() public {
        uint256 amount = 1000;
        tokenLockUp.deposit(amount, lockDuration);
        tokenLockUp.withdrawTokens(0);
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

    // Test case for depositing with invalid lock duration
    function testFailWhenDepositingWithInvalidLockDuration() public {
        tokenLockUp.deposit(1000, 0);
    }

    // Test case for depositing with 0 amount
    function testFailToDepositWithZeroAmount() public {
        tokenLockUp.deposit(0, lockDuration);
    }

    // Test case for withdrawing with invalid index
    function testFailWhenWithdrawingWithInvalidIndex() public {
        tokenLockUp.deposit(1000, lockDuration);

        // Advance the block timestamp to the end of the lockup period
        vm.warp(block.timestamp + lockDuration);

        // Attempt to withdraw with invalid index
        tokenLockUp.withdrawTokens(1);
    }

     function testFailWhenNonOwnerCallsRestrictedFunctions() public {
        vm.prank(address(1));
        tokenLockUp.setTokenAddress(address(2));
        tokenLockUp.setNftContractnAddress(address(2));
    }
}