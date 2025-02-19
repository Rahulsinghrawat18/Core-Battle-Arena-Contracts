// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {Deploy} from "../script/Deploy.s.sol";
import {AA} from "../src/AA.sol";

contract AATest is Test {
    Deploy deploy;
    AA aa;

    address OWNER = makeAddr("Owner");
    address USER = makeAddr("USER");
    address WINNER1 = makeAddr("Winner1");
    address WINNER2 = makeAddr("Winner2");
    address P1 = makeAddr("P1");

    function setUp() public returns (AA) {
        deploy = new Deploy();
        aa = deploy.run();
        return aa;
    }

    function testOwnerIsSet() view public {
        assertEq(aa.owner(), address(this));
    }

    function testItemsZeroOnStart() view public {
        assertEq(aa.numOfItems(), 0);
    }

    function testItemAdded() public {
        vm.prank(OWNER);
        aa.addItem(1 ether, "Sword");
        assertEq(aa.numOfItems(), 1);

        AA.Item memory item = aa.getItemsDetails()[0];
        assertEq(item.price, 1 ether);
        assertEq(keccak256(abi.encodePacked(item.name)), keccak256(abi.encodePacked("Sword")));
    }

    function testItemBought() public {
        vm.prank(OWNER);
        aa.addItem(1 ether, "Sword");

        vm.deal(USER, 1 ether);
        vm.startPrank(USER);
        aa.buyItem{value: 1 ether}(0);
        vm.stopPrank();

        uint256[] memory boughtItemIds = aa.getItemsIdBoughtByUser(USER);
        assertEq(boughtItemIds.length, 1);
        assertEq(boughtItemIds[0], 0);

        AA.Item[] memory boughtItems = aa.getItemsBoughtByUser(USER);
        assertEq(boughtItems.length, 1);
        assertEq(boughtItems[0].price, 1 ether);
        assertEq(keccak256(abi.encodePacked(boughtItems[0].name)), keccak256(abi.encodePacked("Sword")));
    }

    function testMultipleItemsAdded() public {
        vm.prank(OWNER);
        aa.addItem(1 ether, "Sword");
        aa.addItem(2 ether, "Shield");
        aa.addItem(3 ether, "Bow");

        assertEq(aa.numOfItems(), 3);

        AA.Item[] memory items = aa.getItemsDetails();
        assertEq(items[0].price, 1 ether);
        assertEq(keccak256(abi.encodePacked(items[0].name)), keccak256(abi.encodePacked("Sword")));
        assertEq(items[1].price, 2 ether);
        assertEq(keccak256(abi.encodePacked(items[1].name)), keccak256(abi.encodePacked("Shield")));
        assertEq(items[2].price, 3 ether);
        assertEq(keccak256(abi.encodePacked(items[2].name)), keccak256(abi.encodePacked("Bow")));
    }

    function testMultipleItemsBought() public {
        vm.prank(OWNER);
        aa.addItem(1 ether, "Sword");
        aa.addItem(2 ether, "Shield");

        vm.deal(USER, 3 ether);
        vm.startPrank(USER);
        aa.buyItem{value: 1 ether}(0);
        aa.buyItem{value: 2 ether}(1);
        vm.stopPrank();

        uint256[] memory boughtItemIds = aa.getItemsIdBoughtByUser(USER);
        assertEq(boughtItemIds.length, 2);
        assertEq(boughtItemIds[0], 0);
        assertEq(boughtItemIds[1], 1);

        AA.Item[] memory boughtItems = aa.getItemsBoughtByUser(USER);
        assertEq(boughtItems.length, 2);
        assertEq(boughtItems[0].price, 1 ether);
        assertEq(keccak256(abi.encodePacked(boughtItems[0].name)), keccak256(abi.encodePacked("Sword")));
        assertEq(boughtItems[1].price, 2 ether);
        assertEq(keccak256(abi.encodePacked(boughtItems[1].name)), keccak256(abi.encodePacked("Shield")));
    }

    function testRegisterWinnerOnce() public {
        string memory roomCode = "ROOM1";

        vm.prank(P1);
        aa.registerWinner(roomCode, WINNER1);

        assertEq(aa.getWinnings(WINNER1), 0);
        assertEq(aa.getRoomWinner(roomCode), WINNER1);
    }

    function testRegisterWinnerTwiceAndReset() public {
        string memory roomCode = "ROOM1";

        vm.prank(WINNER1);
        aa.registerWinner(roomCode, WINNER1);

        vm.prank(P1);
        aa.registerWinner(roomCode, WINNER1);

        assertEq(aa.getWinnings(WINNER1), 1);
        assertEq(aa.getRoomWinner(roomCode), address(0));
    }

    function testRegisterDifferentWinnerFails() public {
        string memory roomCode = "ROOM1";

        vm.prank(P1);
        aa.registerWinner(roomCode, WINNER1);

        vm.expectRevert(abi.encodeWithSignature("AA_WrongWinner()"));
        vm.prank(WINNER1);
        aa.registerWinner(roomCode, WINNER2);
    }

    function testWinningsIncrementCorrectly() public {
        string memory roomCode1 = "ROOM1";
        string memory roomCode2 = "ROOM2";

        vm.prank(P1);
        aa.registerWinner(roomCode1, WINNER1);
        vm.prank(WINNER1);
        aa.registerWinner(roomCode1, WINNER1);
        vm.prank(P1);
        aa.registerWinner(roomCode2, WINNER1);
        vm.prank(WINNER1);
        aa.registerWinner(roomCode2, WINNER1);
        
        assertEq(aa.getWinnings(WINNER1), 2);
    }

     function testInitialTokenBalance() public view {
        uint256 initialBalance = aa.getWinningTokensAmount(WINNER1);
        assertEq(initialBalance, 0, "Initial token balance should be 0");
    }

    function testMintTokenForWinner() public {
        string memory roomCode = "ROOM1";

        vm.prank(P1);
        aa.registerWinner(roomCode, WINNER1);

        vm.prank(WINNER1);
        aa.registerWinner(roomCode, WINNER1);
        
        uint256 balanceAfterWin = aa.getWinningTokensAmount(WINNER1);
        assertEq(balanceAfterWin, 1, "Winner should receive 1 token after registration");

        assertEq(aa.getRoomWinner(roomCode), address(0), "Room winner should be reset after claiming winnings");
        assertEq(aa.getWinnings(WINNER1), 1, "Winner's winnings should be incremented");
    }

    function testMintTokenForMultipleWins() public {
        string memory roomCode1 = "ROOM1";
        string memory roomCode2 = "ROOM2";

        vm.prank(P1);
        aa.registerWinner(roomCode1, WINNER1);
        vm.prank(WINNER1);
        aa.registerWinner(roomCode1, WINNER1);
        vm.prank(P1);
        aa.registerWinner(roomCode2, WINNER1);
        vm.prank(WINNER1);
        aa.registerWinner(roomCode2, WINNER1);

        uint256 balanceAfterMultipleWins = aa.getWinningTokensAmount(WINNER1);
        assertEq(balanceAfterMultipleWins, 2, "Winner should receive 2 tokens after multiple wins");

        assertEq(aa.getWinnings(WINNER1), 2, "Winner's winnings should be 2 after multiple room wins");
    }

    function testTokenBalanceAfterMultiplePlayers() public {
        string memory roomCode1 = "ROOM1";
        string memory roomCode2 = "ROOM2";

        vm.prank(P1);
        aa.registerWinner(roomCode1, WINNER1);
        vm.prank(WINNER1);
        aa.registerWinner(roomCode1, WINNER1);
        vm.prank(P1);
        aa.registerWinner(roomCode2, WINNER2);
        vm.prank(WINNER2);
        aa.registerWinner(roomCode2, WINNER2);

        uint256 balanceWinner1 = aa.getWinningTokensAmount(WINNER1);
        uint256 balanceWinner2 = aa.getWinningTokensAmount(WINNER2);
        assertEq(balanceWinner1, 1, "Winner1 should have 1 token");
        assertEq(balanceWinner2, 1, "Winner2 should have 1 token");

        assertEq(aa.getWinnings(WINNER1), 1, "Winner1's winnings should be 1");
        assertEq(aa.getWinnings(WINNER2), 1, "Winner2's winnings should be 1");
    }

    function testTokenNotMintedForWrongWinner() public {
        string memory roomCode = "ROOM1";

        vm.prank(P1);
        aa.registerWinner(roomCode, WINNER1);

        vm.expectRevert(abi.encodeWithSignature("AA_WrongWinner()"));
        vm.prank(WINNER1);
        aa.registerWinner(roomCode, WINNER2);

        uint256 balanceWinner2 = aa.getWinningTokensAmount(WINNER2);
        assertEq(balanceWinner2, 0, "Tokens should not be minted for the wrong winner");
    }
}
