import {ethers} from "hardhat";
import { ContractFactory } from "ethers";
import * as fs from "fs";

async function main() {
    const network: any = process.env.HARDHAT_NETWORK;
    // Come from the hardhat.config.ts, the first account is the default account to deploy contracts.
    const [admin, patient, doctor] = await ethers.getSigners();
    console.log('Deploy contracts in ' + network)
    console.log('Deploy Main Contract...')
    const MainContract: ContractFactory = await ethers.getContractFactory("MainContract");
    const maincontract = await MainContract.deploy();
    // save the addresses
    const addresses = {
        mainContract : maincontract.getAddress
    }
    // console.log(addresses)
    fs.writeFile(`address-${network}.json`, JSON.stringify(addresses, undefined, 4), err => {
        if (err) console.log('Write file error: ' + err.message)
        else console.log(`Addresses is saved into address-${network}.json...`)
    })
    console.log("Deploy finish.");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
