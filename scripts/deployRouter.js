const hre = require("hardhat");

async function main() {
    console.log("Deploying FundRouter contract...");

    const fundRouter = await hre.ethers.deployContract("FundRouter");

    await fundRouter.waitForDeployment();

    console.log(
        `FundRouter deployed to: ${fundRouter.target}`
    );
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});