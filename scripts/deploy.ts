import {ethers} from "hardhat";
import * as fs from "fs";

async function main() {
    const network: any = process.env.HARDHAT_NETWORK;
    // Come from the hardhat.config.ts, the first account is the default account to deploy contracts.
    const [admin, patient, doctor] = await ethers.getSigners();
    console.log('Deploy contracts in ' + network)
    console.log('Deploy MedicalTemplate Contract...')
    const MedicalTemplate = await ethers.getContractFactory('MedicalTemplate');
    const medical = await MedicalTemplate.deploy();
    await medical.deployed();
    // save the addresses
    const addresses = {
        MedicalTemplate : medical.address
    }
    console.log(addresses)
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
