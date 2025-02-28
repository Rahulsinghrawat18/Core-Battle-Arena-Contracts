// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AA_Token} from "./AA_Token.sol";

contract AA {
    struct Item {
        uint256 price;
        string name;
    }

    address private ownerOfContract;
    uint256 public numOfItems;

    mapping(uint256 => Item) private idToItems;
    mapping(address => mapping(uint256 => bool)) private itemsBought;

    mapping(string => address) private roomWinners;
    mapping(address => uint256) private winnings;

    AA_Token public aa_Token;

    error AA__NotOwner();
    error AA_ItemAlreadyBought();
    error AA_IncorrectPayment();
    error AA_IncorrectItemID();
    error AA_WrongWinner();

    constructor() {
        ownerOfContract = msg.sender;
        aa_Token = new AA_Token();
       //Transfer ownership of AA_Token to the AA contract
        aa_Token.transferOwnership(address(this));
        numOfItems = 0;
    }

    function addItem(uint256 price, string memory name) public {
        idToItems[numOfItems] = Item(price, name);
        numOfItems++;
    }

    function buyItem(uint256 id) public payable {
        require(id < numOfItems, AA_IncorrectItemID());
        require(!itemsBought[msg.sender][id], AA_ItemAlreadyBought());
        require(msg.value == idToItems[id].price, AA_IncorrectPayment());
        itemsBought[msg.sender][id] = true;
    }

    function getItemsIdBoughtByUser(address user) public view returns (uint256[] memory) {
        uint256 itemCount = 0;
        for (uint256 i = 0; i < numOfItems; i++) {
            if (itemsBought[user][i]) {
                itemCount++;
            }
        }

        uint256[] memory boughtItems = new uint256[](itemCount);
        uint256 index = 0;

        for (uint256 i = 0; i < numOfItems; i++) {
            if (itemsBought[user][i]) {
                boughtItems[index] = i;
                index++;
            }
        }

        return boughtItems;
    }

    function getItemsBoughtByUser(address user) public view returns(Item[] memory) {
        uint256[] memory itemIds = getItemsIdBoughtByUser(user);
        Item[] memory items = new Item[](itemIds.length);
        for (uint256 i = 0; i < itemIds.length; i++) {
            items[i]=(idToItems[itemIds[i]]);
        }
        return items;
    }

    function getItemsDetails() public view returns (Item[] memory) {
        Item[] memory items = new Item[](numOfItems);
        for (uint256 i = 0; i < numOfItems; i++) {
            items[i] = idToItems[i];
        }
        return items;
    }

function registerWinner(string memory code, address winner) public {
    if (roomWinners[code] == address(0)) {
        roomWinners[code] = winner;
        winnings[winner]++;

        // Mint token every time the user wins
        try aa_Token.mint(winner) {
            // Minting successful
        } catch {
            revert("Token minting failed");
        }

    } else {
        if (roomWinners[code] != winner) {
            revert AA_WrongWinner();
        }
        roomWinners[code] = address(0);
        winnings[winner]++;

        // Mint token again because the user won again
        try aa_Token.mint(winner) {
            // Minting successful
        } catch {
            revert("Token minting failed");
        }
    }
}



    function getWinnings(address user) public view returns (uint256) {
        return winnings[user];
    }

    function getRoomWinner(string memory code) public view returns(address){
        return roomWinners[code];
    }

    function getWinningTokensAmount(address user) public view returns(uint256) {
        return aa_Token.getBalance(user);
    }

    function owner() public view returns(address) {
        return ownerOfContract;
    }

    function getTotalSupply() public view returns (uint256) {
    return aa_Token.totalSupply(); 
    }


}
