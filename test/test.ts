import {loadFixture} from "@nomicfoundation/hardhat-network-helpers";
import {expect} from "chai";
import {ethers} from "hardhat";
import { ContractFactory } from "ethers";

describe("Main deployed", async function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployContracts() {
        // Contracts are deployed using the first signer/account by default
        const [admin, patient, doctor] = await ethers.getSigners();
        const MainContract: ContractFactory = await ethers.getContractFactory("MainContract");
        const maincontract = await MainContract.deploy();

        return {
            maincontract,
            accounts : {admin, patient, doctor}
        }
    }

});
