// We require the Hardhat Runtime Environment explicitly here.
const hre = require("hardhat");

async function main() {
    // We get the contract to deploy. Hardhat knows to look for "SimpleWallet"
    // in the contracts/ folder and that it's been compiled.
    const simpleWallet = await hre.ethers.deployContract("SimpleWallet");

    // This waits until the contract is officially mined and deployed on our local blockchain.
    await simpleWallet.waitForDeployment();

    // The 'target' property on the deployed contract object is the address.
    console.log(
        `SimpleWallet deployed to: ${simpleWallet.target}`
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});