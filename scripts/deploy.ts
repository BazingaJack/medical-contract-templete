import {ethers} from "hardhat";
import * as fs from "fs";

async function main() {
    const network: any = process.env.HARDHAT_NETWORK;
    // Come from the hardhat.config.ts, the first account is the default account to deploy contracts.
    const [owner, member1, member2] = await ethers.getSigners();
    console.log('Deploy contracts in ' + network)
    
    console.log("No error!");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
