// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

/**
 * @title FundRouter
 * @dev A non-custodial smart contract for orchestrating and distributing
 * native currency (like BNB or ETH) to a global pool of recipients.
 * The contract itself never holds funds; it only routes them from the
 * sender (msg.sender) to the destinations in a single transaction.
 */
contract FundRouter {
    // --- State Variables ---

    // A dynamic array to store all registered recipient addresses.
    // Public so anyone can view the list.
    address[] public globalRecipients;

    // A mapping for efficient, O(1) lookup to check if an address
    // is already registered. This prevents duplicates in the globalRecipients array.
    mapping(address => bool) public isRecipientRegistered;

    // --- Events ---

    // Emitted when a new recipient is successfully added to the global pool.
    event RecipientRegistered(address indexed recipient);
    
    // Emitted when a distribution is successfully executed.
    event FundsDistributed(address indexed from, uint256 totalAmount, uint256 recipientCount);

    // --- Core Functions ---

    /**
     * @dev Adds the caller's address (msg.sender) to the global pool of recipients.
     * Ensures that the address is not the zero address and is not already registered.
     */
    function registerAsRecipient() external {
        address candidate = msg.sender;

        // Security Check 1: Prevent the zero address from being added.
        require(candidate != address(0), "FundRouter: Cannot register the zero address");

        // Security Check 2: Prevent duplicate addresses.
        require(!isRecipientRegistered[candidate], "FundRouter: Address is already registered");

        // Add the address and update the mapping.
        isRecipientRegistered[candidate] = true;
        globalRecipients.push(candidate);

        emit RecipientRegistered(candidate);
    }

/**
     * @dev Distributes msg.value evenly among a specified number of randomly selected recipients.
     * This function is PAYABLE, allowing the user to send BNB along with the call.
     * The contract immediately forwards the funds, maintaining a zero balance post-transaction.
     * @param numRecipients The number of unique random recipients to select from the global pool.
     */
    function distributeToRandomRecipients(uint256 numRecipients) external payable {
        // --- Input Validation ---
        uint256 totalRecipients = globalRecipients.length;
        require(msg.value > 0, "FundRouter: Must send a total amount greater than zero");
        require(numRecipients > 0, "FundRouter: Number of recipients must be greater than zero");
        require(totalRecipients >= numRecipients, "FundRouter: Not enough registered recipients to choose from");
        
        uint256 amountPerRecipient = msg.value / numRecipients;
        require(amountPerRecipient > 0, "FundRouter: Distribution amount per recipient is zero");
        
        // --- Random Selection Logic (Pseudo-random on-chain) ---
        // Create a temporary copy of the recipients array in memory.
        address[] memory recipientsPool = globalRecipients;
        
        // --- CORRECTION START ---
        // We track the "active" size of our memory pool.
        uint256 poolSize = totalRecipients; 
        
        for (uint i = 0; i < numRecipients; i++) {
            // 1. Generate a pseudo-random index within the bounds of the *current active pool size*.
            uint256 randomIndex = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, i))) % poolSize;
            
            // 2. Get the recipient at the random index.
            address recipient = recipientsPool[randomIndex];
            
            // 3. Send the funds.
            (bool success, ) = recipient.call{value: amountPerRecipient}("");
            require(success, "FundRouter: Transfer to a recipient failed");

            // 4. "Remove" the selected recipient from the pool to prevent picking them twice.
            // We do this by replacing the chosen element with the *last active element* in the pool.
            recipientsPool[randomIndex] = recipientsPool[poolSize - 1];
            
            // 5. We then shrink the active pool size by one. We are NOT changing the length of the
            // memory array itself, just the part of it we consider for the next random selection.
            poolSize--; 
        }
        // --- CORRECTION END ---
        
        emit FundsDistributed(msg.sender, msg.value, numRecipients);
    }

    // --- View Functions ---

    /**
     * @dev Returns the total number of registered recipients.
     */
    function getRecipientCount() external view returns (uint256) {
        return globalRecipients.length;
    }
}