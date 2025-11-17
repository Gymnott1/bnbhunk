//
// --- IMPORTANT SETUP ---
//

// 1. PASTE YOUR DEPLOYED CONTRACT ADDRESS HERE
const contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

// 2. PASTE YOUR CONTRACT'S ABI HERE
// Go to artifacts/contracts/SmartDistributor.sol/SmartDistributor.json
// and copy the entire array associated with the "abi" key.
const contractABI = [

    {
        "anonymous": false,
        "inputs": [{
                "indexed": true,
                "internalType": "address",
                "name": "from",
                "type": "address"
            },
            {
                "indexed": false,
                "internalType": "uint256",
                "name": "totalAmount",
                "type": "uint256"
            },
            {
                "indexed": false,
                "internalType": "string",
                "name": "method",
                "type": "string"
            }
        ],
        "name": "Distributed",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [{
                "indexed": true,
                "internalType": "address",
                "name": "recipient",
                "type": "address"
            },
            {
                "indexed": false,
                "internalType": "uint256",
                "name": "newTotal",
                "type": "uint256"
            }
        ],
        "name": "Registered",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [{
                "indexed": true,
                "internalType": "address",
                "name": "recipient",
                "type": "address"
            },
            {
                "indexed": false,
                "internalType": "uint256",
                "name": "newTotal",
                "type": "uint256"
            }
        ],
        "name": "Unregistered",
        "type": "event"
    },
    {
        "inputs": [{
            "internalType": "uint256",
            "name": "numRecipients",
            "type": "uint256"
        }],
        "name": "distributeEqualRandom",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "distributeToAllEqual",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function"
    },
    {
        "inputs": [{
            "internalType": "address",
            "name": "target",
            "type": "address"
        }],
        "name": "distributeToSingle",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function"
    },
    {
        "inputs": [{
                "internalType": "address[]",
                "name": "targets",
                "type": "address[]"
            },
            {
                "internalType": "uint256[]",
                "name": "percentages",
                "type": "uint256[]"
            }
        ],
        "name": "distributeWeighted",
        "outputs": [],
        "stateMutability": "payable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "getRecipientCount",
        "outputs": [{
            "internalType": "uint256",
            "name": "",
            "type": "uint256"
        }],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [{
            "internalType": "address",
            "name": "",
            "type": "address"
        }],
        "name": "isRegistered",
        "outputs": [{
            "internalType": "bool",
            "name": "",
            "type": "bool"
        }],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [{
            "internalType": "uint256",
            "name": "",
            "type": "uint256"
        }],
        "name": "recipients",
        "outputs": [{
            "internalType": "address",
            "name": "",
            "type": "address"
        }],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "register",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "unregister",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    }
];

// --- APPLICATION LOGIC ---

// Globals
let provider;
let signer;
let contract;

// DOM Elements
const connectButton = document.getElementById('connectButton');
const statusEl = document.getElementById('status');
const accountEl = document.getElementById('account');
const recipientCountEl = document.getElementById('recipientCount');
const registerButton = document.getElementById('registerButton');
const distributeAmountInput = document.getElementById('distributeAmount');
const distributeButton = document.getElementById('distributeButton');
const logContent = document.getElementById('logContent');

// --- Functions ---

function log(message) {
    console.log(message);
    logContent.innerHTML = `${new Date().toLocaleTimeString()}: ${message}\n${logContent.innerHTML}`;
}

async function connectWallet() {
    log("Connecting wallet...");
    if (typeof window.ethereum === 'undefined') {
        log("MetaMask is not installed!");
        return;
    }

    try {
        provider = new ethers.providers.Web3Provider(window.ethereum);
        await provider.send("eth_requestAccounts", []);
        signer = provider.getSigner();
        contract = new ethers.Contract(contractAddress, contractABI, provider);

        const userAddress = await signer.getAddress();
        accountEl.textContent = userAddress;
        statusEl.textContent = "Connected";
        connectButton.textContent = "Wallet Connected";
        connectButton.disabled = true;

        log(`Connected with account: ${userAddress}`);
        enableUI();
        updateContractInfo();
    } catch (error) {
        log(`Connection failed: ${error.message}`);
        console.error(error);
    }
}

async function updateContractInfo() {
    try {
        const count = await contract.getRecipientCount();
        recipientCountEl.textContent = count.toString();
        log(`Recipient count updated: ${count.toString()}`);
    } catch (error) {
        log(`Failed to fetch contract info: ${error.message}`);
    }
}

function enableUI() {
    registerButton.disabled = false;
    distributeButton.disabled = false;
}

async function registerAsRecipient() {
    log("Attempting to register as a recipient...");
    const contractWithSigner = contract.connect(signer);
    try {
        const tx = await contractWithSigner.register();
        log(`Transaction sent... hash: ${tx.hash}`);
        await tx.wait(); // Wait for the transaction to be mined
        log("Successfully registered!");
        updateContractInfo();
    } catch (error) {
        log(`Registration failed: ${error.message}`);
        console.error(error);
    }
}

async function distributeToAll() {
    const amount = distributeAmountInput.value;
    if (!amount || parseFloat(amount) <= 0) {
        log("Please enter a valid amount > 0.");
        return;
    }

    log(`Distributing ${amount} BNB to all recipients...`);
    const contractWithSigner = contract.connect(signer);
    try {
        const valueInWei = ethers.utils.parseEther(amount);
        const tx = await contractWithSigner.distributeToAllEqual({ value: valueInWei });
        log(`Transaction sent... hash: ${tx.hash}`);
        await tx.wait();
        log("Distribution successful!");
        updateContractInfo();
    } catch (error) {
        log(`Distribution failed: ${error.message}`);
        console.error(error);
    }
}

// --- Event Listeners ---
connectButton.addEventListener('click', connectWallet);
registerButton.addEventListener('click', registerAsRecipient);
distributeButton.addEventListener('click', distributeToAll);