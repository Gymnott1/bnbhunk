const hre = require("hardhat");

async function main() {
    console.log("Deploying SmartDistributor contract...");

    const distributor = await hre.ethers.deployContract("SmartDistributor");
    await distributor.waitForDeployment();

    console.log(`SmartDistributor deployed to: ${distributor.target}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});