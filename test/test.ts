import {loadFixture} from "@nomicfoundation/hardhat-network-helpers";
import {expect} from "chai";
import {ethers} from "hardhat";
import { ContractFactory } from "ethers";

describe("Medical Template Contract deployed", async function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployContracts() {
        // Contracts are deployed using the first signer/account by default
        const [deployer, patient, doctor, institution, pharmacy] = await ethers.getSigners();
        const MedicalTemplate = await ethers.getContractFactory("MedicalTemplate");
        const medicaltemplate = await MedicalTemplate.deploy();

        return {
            medicaltemplate,
            accounts : {deployer, patient, doctor, institution, pharmacy}
        }
    }

    describe("Role test",async function () {
        it("Should register institution successfully",async function () {
            const {medicaltemplate,accounts} = await loadFixture(deployContracts);
            await medicaltemplate.connect(accounts.deployer).addInstitution(accounts.institution.address,"institution1","institution address","111");
            expect (await medicaltemplate.connect(accounts.deployer).checkRole(accounts.institution.address,0)).to.equal(true);
        })
        
        it("Should register patient successfully",async function () {
            const {medicaltemplate,accounts} = await loadFixture(deployContracts);
            await medicaltemplate.connect(accounts.deployer).addPatient(accounts.patient.address,"patient1","p1","222");
            expect (await medicaltemplate.connect(accounts.deployer).checkRole(accounts.patient.address,1)).to.equal(true);
        })

        it("Should register doctor successfully",async function () {
            const {medicaltemplate,accounts} = await loadFixture(deployContracts);
            await medicaltemplate.connect(accounts.deployer).addDoctor(accounts.doctor.address,"doctor1",0,"dep",30);
            expect (await medicaltemplate.connect(accounts.deployer).checkRole(accounts.doctor.address,2)).to.equal(true);
        })

        it("Should register pharmacy successfully",async function () {
            const {medicaltemplate,accounts} = await loadFixture(deployContracts);
            await medicaltemplate.connect(accounts.deployer).addPharmacy(accounts.pharmacy.address,"pharmacy1","pharmacy address","333");
            expect (await medicaltemplate.connect(accounts.deployer).checkRole(accounts.pharmacy.address,3)).to.equal(true);
        })
    })

    describe("Patient relevant basic function test",async function () {
        it("Should approve to doctor successfully",async function () {
            const {medicaltemplate,accounts} = await loadFixture(deployContracts);
            await medicaltemplate.connect(accounts.deployer).addPatient(accounts.patient.address,"patient1","p1","222");
            await medicaltemplate.connect(accounts.deployer).addDoctor(accounts.doctor.address,"doctor1",0,"dep",30);
            await medicaltemplate.connect(accounts.patient).approveToDoctor(accounts.doctor.address);
        })

        it("Should make reservation successfully",async function () {
            const {medicaltemplate,accounts} = await loadFixture(deployContracts);
            await medicaltemplate.connect(accounts.deployer).addPatient(accounts.patient.address,"patient1","p1","222");
            await medicaltemplate.connect(accounts.deployer).addDoctor(accounts.doctor.address,"doctor1",0,"dep",30);
            await medicaltemplate.connect(accounts.patient).makeReservation(accounts.doctor.address,10000);
        })
    })

    describe("doctor relevant basic function test",async function () {
        it("Should update patient basic health info successfully",async function () {
            const {medicaltemplate,accounts} = await loadFixture(deployContracts);
            await medicaltemplate.connect(accounts.deployer).addPatient(accounts.patient.address,"patient1","p1","222");
            await medicaltemplate.connect(accounts.deployer).addDoctor(accounts.doctor.address,"doctor1",0,"dep",30);
            await medicaltemplate.connect(accounts.doctor).updatePatientBasicHealthInfo(accounts.patient.address,175,70,100,100);
        })

        it("Should update patient medical record successfully",async function () {
            const {medicaltemplate,accounts} = await loadFixture(deployContracts);
            await medicaltemplate.connect(accounts.deployer).addPatient(accounts.patient.address,"patient1","p1","222");
            await medicaltemplate.connect(accounts.deployer).addDoctor(accounts.doctor.address,"doctor1",0,"dep",30);
            await medicaltemplate.connect(accounts.doctor).updatePatientMedicalRecord(accounts.patient.address,10000,"drug","detail","advice");
        })

        it("Should update patient prescription record successfully",async function () {
            const {medicaltemplate,accounts} = await loadFixture(deployContracts);
            await medicaltemplate.connect(accounts.deployer).addPatient(accounts.patient.address,"patient1","p1","222");
            await medicaltemplate.connect(accounts.deployer).addDoctor(accounts.doctor.address,"doctor1",0,"dep",30);
            await medicaltemplate.connect(accounts.doctor).updatePrescriptionRecord(accounts.patient.address,10000,"drug",1,"description");
        })

        it("Should get patient medical record successfully",async function () {
            const {medicaltemplate,accounts} = await loadFixture(deployContracts);
            await medicaltemplate.connect(accounts.deployer).addPatient(accounts.patient.address,"patient1","p1","222");
            await medicaltemplate.connect(accounts.deployer).addDoctor(accounts.doctor.address,"doctor1",0,"dep",30);
            await medicaltemplate.connect(accounts.patient).approveToDoctor(accounts.doctor.address);
            await medicaltemplate.connect(accounts.doctor).updatePatientMedicalRecord(accounts.patient.address,10000,"drug","detail","advice");
            const [time,name,detail,advice] = await medicaltemplate.connect(accounts.doctor).getPatientMedicalRecord(accounts.patient.address,0);
            expect(time).to.equal(10000);
            expect(name).to.equal("drug");
            expect(detail).to.equal("detail");
            expect(advice).to.equal("advice");
        })
    })

    describe("institution relevant basic function test",async function() {
        it("Should check prescription successfully",async function () {
            const {medicaltemplate,accounts} = await loadFixture(deployContracts);
            await medicaltemplate.connect(accounts.deployer).addPatient(accounts.patient.address,"patient1","p1","222");
            await medicaltemplate.connect(accounts.deployer).addDoctor(accounts.doctor.address,"doctor1",0,"dep",30);
            await medicaltemplate.connect(accounts.deployer).addInstitution(accounts.institution.address,"institution1","institution address","111");
            await medicaltemplate.connect(accounts.doctor).updatePrescriptionRecord(accounts.patient.address,10000,"drug",1,"description");
            await medicaltemplate.connect(accounts.institution).checkPrescription(accounts.patient.address,0);
        })
        
        it("Should add hospital info successfully",async function () {
            const {medicaltemplate,accounts} = await loadFixture(deployContracts);
            await medicaltemplate.connect(accounts.deployer).addPatient(accounts.patient.address,"patient1","p1","222");
            await medicaltemplate.connect(accounts.deployer).addInstitution(accounts.institution.address,"institution1","institution address","111");
            await medicaltemplate.connect(accounts.institution).addHospitalInfo(accounts.patient.address,0,0,"2024-1-1");
        })

        it("Should update bill info successfully",async function () {
            const {medicaltemplate,accounts} = await loadFixture(deployContracts);
            await medicaltemplate.connect(accounts.deployer).addPatient(accounts.patient.address,"patient1","p1","222");
            await medicaltemplate.connect(accounts.deployer).addInstitution(accounts.institution.address,"institution1","institution address","111");
            await medicaltemplate.connect(accounts.institution).updateBillInfo(accounts.patient.address,100,"b_detail");
        })
    })

    describe("pharmacy relevant basic function test",async function() {
        it("Should distribute prescription successfully",async function () {
            const {medicaltemplate,accounts} = await loadFixture(deployContracts);
            await medicaltemplate.connect(accounts.deployer).addPatient(accounts.patient.address,"patient1","p1","222");
            await medicaltemplate.connect(accounts.deployer).addDoctor(accounts.doctor.address,"doctor1",0,"dep",30);
            await medicaltemplate.connect(accounts.deployer).addInstitution(accounts.institution.address,"institution1","institution address","111");
            await medicaltemplate.connect(accounts.deployer).addPharmacy(accounts.pharmacy.address,"pharmacy1","pharmacy address","333");
            await medicaltemplate.connect(accounts.doctor).updatePrescriptionRecord(accounts.patient.address,10000,"drug",1,"description");
            await medicaltemplate.connect(accounts.institution).checkPrescription(accounts.patient.address,0);
            await medicaltemplate.connect(accounts.pharmacy).distributePrescription(accounts.patient.address,0);
        })
    })

    describe("Complicated function test",async function() {
        it("Should check the bill successfully",async function () {
            const {medicaltemplate,accounts} = await loadFixture(deployContracts);
            await medicaltemplate.connect(accounts.deployer).addPatient(accounts.patient.address,"patient1","p1","222");
            await medicaltemplate.connect(accounts.deployer).addDoctor(accounts.doctor.address,"doctor1",0,"dep",30);
            await medicaltemplate.connect(accounts.deployer).addInstitution(accounts.institution.address,"institution1","institution address","111");
            await medicaltemplate.connect(accounts.institution).updateBillInfo(accounts.patient.address,100,"b_detail");
            const [amount,detail] = await medicaltemplate.connect(accounts.patient).checkTheBill();
            expect(amount).to.equal(100);
            expect(detail).to.equal("b_detail");
        })

        it("Should pay the bill successfully",async function () {
            const {medicaltemplate,accounts} = await loadFixture(deployContracts);
            await medicaltemplate.connect(accounts.deployer).addPatient(accounts.patient.address,"patient1","p1","222");
            await medicaltemplate.connect(accounts.deployer).addInstitution(accounts.institution.address,"institution1","institution address","111");
            await medicaltemplate.connect(accounts.institution).updateBillInfo(accounts.patient.address,100,"b_detail");
            await expect (medicaltemplate.connect(accounts.patient).payTheBill("alipay",50)).to.be.revertedWith("Error : Insufficient balance.");
            const payTheBillTx = await medicaltemplate.connect(accounts.patient).payTheBill("alipay",150);
            const txReceipt = await payTheBillTx.wait();
            const status = txReceipt.status;
            expect(status).to.equal(1);
        })

        it("Should discharge the review successfully",async function () {
            const {medicaltemplate,accounts} = await loadFixture(deployContracts);
            await medicaltemplate.connect(accounts.deployer).addPatient(accounts.patient.address,"patient1","p1","222");
            await medicaltemplate.connect(accounts.deployer).addInstitution(accounts.institution.address,"institution1","institution address","111");
            await expect (medicaltemplate.connect(accounts.institution).dischargeReview(accounts.patient.address)).to.be.revertedWith("Error : This patient's hospital records hasn't been uploaded");
            await medicaltemplate.connect(accounts.institution).addHospitalInfo(accounts.patient.address,0,0,"2024-1-1");
            await medicaltemplate.connect(accounts.institution).updateBillInfo(accounts.patient.address,100,"b_detail");
            await expect (medicaltemplate.connect(accounts.institution).dischargeReview(accounts.patient.address)).to.be.revertedWith("Error : This patient hasn't pay the bill.");
            await medicaltemplate.connect(accounts.patient).payTheBill("alipay",150);
            await medicaltemplate.connect(accounts.institution).dischargeReview(accounts.patient.address);
        })
    })
});
