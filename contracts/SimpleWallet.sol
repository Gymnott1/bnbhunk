// SPDX-License-Identifier: MIT
// Specifies the license for your code. It's a good practice.
pragma solidity ^0.8.9;

// This is a helpful tool for debugging. We'll use it to print messages.
import "hardhat/console.sol";

// This is the start of our contract definition.
contract SimpleWallet {
    
    // This is a "state variable". It will be stored permanently on the blockchain.
    // We make it 'public' so Solidity automatically creates a function for us to read its value.
    // 'payable' means this address can receive coins.
    address payable public owner;

    // This is the constructor. It runs ONLY ONCE when the contract is first deployed.
    // 'msg.sender' is a global variable that always holds the address of the account
    // that is currently calling the function.
    constructor() {
        owner = payable(msg.sender); // Set the person who deploys the contract as the owner.
        console.log("SimpleWallet deployed by:", owner);
    }

    // This special function allows the contract to receive raw BNB/ETH transfers.
    // If someone just sends BNB to the contract's address, this function is triggered.
    // 'external' means it can be called from outside the contract.
    // 'payable' means this function is allowed to receive coins.
    receive() external payable {
        console.log("Received %s wei from %s", msg.value, msg.sender);
    }
    
    // A simple function to check the current BNB balance of this contract.
    // 'view' means it only reads data from the blockchain and doesn't change anything.
    // 'returns (uint256)' means it will give back a number (the balance).
    function getBalance() public view returns (uint256) {
        // 'address(this)' refers to the contract's own address.
        return address(this).balance;
    }

    // A function to withdraw all the BNB from the contract.
    function withdraw() public {
        // This is a security check. It makes sure ONLY the owner can call this function.
        // If the person calling is not the owner, the transaction will fail.
        require(msg.sender == owner, "Only the owner can withdraw!");

        console.log("Withdrawing %s wei to %s", address(this).balance, owner);

        // This transfers the entire balance of the contract to the owner's address.
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Withdrawal failed.");
    }
}