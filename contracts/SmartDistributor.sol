// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";

/**
 * @title SmartDistributor
 * @dev A non-custodial, rules-based distribution contract.
 * Users must register to become eligible recipients. Senders can then
 * distribute funds to the registered pool using various filtering and
 * distribution logic. The contract never holds funds.
 */
contract SmartDistributor {
    // --- State Variables ---
    address[] public recipients;
    mapping(address => bool) public isRegistered;
    mapping(address => uint256) private recipientIndex; // Private for internal management

    // --- Events ---
    event Registered(address indexed recipient, uint256 newTotal);
    event Unregistered(address indexed recipient, uint256 newTotal);
    event Distributed(address indexed from, uint256 totalAmount, string method);

    // --- Registration Management ---

    /**
     * @dev Registers msg.sender as an eligible recipient.
     * The address cannot be the zero address or already registered.
     */
    function register() external {
        address candidate = msg.sender;
        require(candidate != address(0), "Cannot register zero address");
        require(!isRegistered[candidate], "Address already registered");

        recipients.push(candidate);
        recipientIndex[candidate] = recipients.length - 1;
        isRegistered[candidate] = true;

        emit Registered(candidate, recipients.length);
    }

    /**
     * @dev Unregisters msg.sender, removing them from the recipient pool.
     * This uses the swap-and-pop pattern for gas-efficient removal.
     */
    function unregister() external {
        address candidate = msg.sender;
        require(isRegistered[candidate], "Address not registered");

        uint256 indexToRemove = recipientIndex[candidate];
        address lastAddress = recipients[recipients.length - 1];

        // Swap the element to remove with the last element
        recipients[indexToRemove] = lastAddress;
        recipientIndex[lastAddress] = indexToRemove;

        // Pop the last element (which is now a duplicate)
        recipients.pop();
        delete isRegistered[candidate];
        delete recipientIndex[candidate];

        emit Unregistered(candidate, recipients.length);
    }

    // --- Distribution Functions ---

    /**
     * @dev Distributes the entire sent amount to a single, registered target.
     */
    function distributeToSingle(address target) external payable {
        require(msg.value > 0, "Must send value");
        require(isRegistered[target], "Target address is not registered");

        (bool success, ) = target.call{value: msg.value}("");
        require(success, "Transfer failed");
        
        emit Distributed(msg.sender, msg.value, "single");
    }

    /**
     * @dev Distributes the sent amount equally to ALL registered recipients.
     */
    function distributeToAllEqual() external payable {
        uint256 totalRecipients = recipients.length;
        require(msg.value > 0, "Must send value");
        require(totalRecipients > 0, "No recipients registered");

        uint256 amountPerRecipient = msg.value / totalRecipients;
        require(amountPerRecipient > 0, "Amount per recipient is zero");

        for (uint i = 0; i < totalRecipients; i++) {
            (bool success, ) = recipients[i].call{value: amountPerRecipient}("");
            require(success, "Transfer failed");
        }

        emit Distributed(msg.sender, msg.value, "allEqual");
    }

    /**
     * @dev Distributes the sent amount equally among a random number of recipients.
     */
    function distributeEqualRandom(uint256 numRecipients) external payable {
        uint256 totalRecipients = recipients.length;
        require(msg.value > 0, "Must send value");
        require(numRecipients > 0, "Number of recipients must be > 0");
        require(totalRecipients >= numRecipients, "Not enough registered recipients");
        
        uint256 amountPerRecipient = msg.value / numRecipients;
        require(amountPerRecipient > 0, "Amount per recipient is zero");
        
        address[] memory pool = recipients;
        uint256 poolSize = totalRecipients;
        
        for (uint i = 0; i < numRecipients; i++) {
            uint256 randomIndex = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, i))) % poolSize;
            address recipient = pool[randomIndex];
            
            (bool success, ) = recipient.call{value: amountPerRecipient}("");
            require(success, "Transfer failed");

            pool[randomIndex] = pool[poolSize - 1];
            poolSize--;
        }
        
        emit Distributed(msg.sender, msg.value, "equalRandom");
    }

    /**
     * @dev Distributes funds based on specified percentages to specific targets.
     * The sum of percentages must be exactly 100.
     */
    function distributeWeighted(address[] calldata targets, uint256[] calldata percentages) external payable {
        require(msg.value > 0, "Must send value");
        require(targets.length == percentages.length, "Mismatched targets and percentages");
        require(targets.length > 0, "No targets specified");

        uint256 totalPercentage = 0;
        for (uint i = 0; i < percentages.length; i++) {
            require(isRegistered[targets[i]], "A target is not registered");
            totalPercentage += percentages[i];
        }
        require(totalPercentage == 100, "Percentages must sum to 100");

        for (uint i = 0; i < targets.length; i++) {
            uint256 amount = (msg.value * percentages[i]) / 100;
            (bool success, ) = targets[i].call{value: amount}("");
            require(success, "Transfer failed");
        }

        emit Distributed(msg.sender, msg.value, "weighted");
    }

    // --- View Functions ---

    function getRecipientCount() external view returns (uint256) {
        return recipients.length;
    }
}