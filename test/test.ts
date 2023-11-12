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

    describe("Patient module test",async function () {
        it("Should add patient successfully",async function () {
            const {maincontract,accounts} = await loadFixture(deployContracts);
            await maincontract.connect(accounts.admin).addPatient(accounts.patient,"P","0","10086");
            const patientRole = await maincontract.connect(accounts.admin).PATIENT_ROLE();
            await expect(await maincontract.connect(accounts.admin).checkRole(accounts.patient,patientRole)).to.equal(true);
        })

        
    })
});
