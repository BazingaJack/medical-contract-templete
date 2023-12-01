// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// Uncomment this line to use console.log
import "hardhat/console.sol";
import {AccessControlDefaultAdminRules} from "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";

contract MainContract is AccessControlDefaultAdminRules{

    bytes32 public constant MEDICAL_INSTITUTION_ROLE = keccak256("MEDICAL_INSTITUTION");//medical institution
    bytes32 public constant PATIENT_ROLE = keccak256("PATIENT");//patient
    bytes32 public constant DOCTOR_ROLE = keccak256("DOCTOR");//doctor
    bytes32 public constant PHARMACY_DEPARTMENT_ROLE = keccak256("PHARMACY_DEPARTMENT");//pharmacy department
    uint256 public nextRoleId;
    
    struct basicHealthData{
        uint256 height;
        uint256 weight;
        uint256 bloodPressure;
        uint256 bloodSugar;
    }

    struct medicalRecord{
        uint256 recordId;
        uint256 time;
        string diseaseName;
        string detailInfo;
        string doctorAdvice;
        bool isValid;
    }

    struct reservationRecord {
        address patientAddr;
        address doctorAddr;
        uint256 time;
        bool isValid;
    }

    struct prescriptionData {
        uint256 time;
        string drugName;
        uint256 amount;
        string description;
    }

    struct prescriptionRecord {
        uint256 recordId;
        address patientAddr;
        address doctorAddr;
        prescriptionData prescription;
        bool isChecked;
        bool isDistributed;
        bool isVaild;
    }

    struct patientData {
        string name;
        string idNumber;
        string phoneNumber;
        uint256 medicalRecordNum;
        uint256 prescriptionRecordNum;
        basicHealthData patientHealthInfo;
        bool isValid;
    }

    struct doctorData {
        string name;
        uint256 doctorId;
        string department;
        uint256 age;
        bool isAvaliable;
        bool isValid;
    }

    struct pharmacyData {
        string name;
        string physicalAddress;
        string phoneNumber;
        bool isValid;
    }

    struct institutionData {
        string name;
        string institutionAddress;
        string phoneNumber;
        bool isValid;
    }

    struct paymentInfo {
        address patientAddr;
        uint256 totalCost;
        string paymentMethod;
        string billDetail;
        bool isPaid;
        bool isValid;
    }

    struct hospitalRecord {
        address patientAddr;
        uint256 wardId;
        uint256 bedNumber;
        string checkInDate;
        paymentInfo payment;
        bool isDischarge;
        bool isValid;
    }

    mapping(uint256 => bytes32) roles;
    mapping(address => patientData) patientDataSet;
    mapping(address => address) approveInfo;
    mapping(address => doctorData) doctorDataSet;
    mapping(address => pharmacyData) pharmacyDataSet;
    mapping(address => institutionData) institutionDataSet;
    mapping(address => reservationRecord) reservationRecords;
    mapping(address => mapping(uint256 => medicalRecord)) medicalRecords;
    mapping(address => mapping (uint256 => prescriptionRecord)) prescriptionRecords;
    mapping(address => paymentInfo) paymentRecords;
    mapping(address => hospitalRecord) hospitalRecords;

    constructor()AccessControlDefaultAdminRules(3 days,msg.sender){
        roles[0] = MEDICAL_INSTITUTION_ROLE;
        roles[1] = PATIENT_ROLE;
        roles[2] = DOCTOR_ROLE;
        roles[3] = PHARMACY_DEPARTMENT_ROLE;
        nextRoleId = 4;
    }

    function checkRole(address _checkAddr,bytes32 _role) public view onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
        return hasRole(_role, _checkAddr);
    }

    //Medical Institution relevant function
    function addInstitution(address _institutionAddr,string memory _name,string memory _institutionAddress,string memory _phoneNumber)
    public onlyRole(DEFAULT_ADMIN_ROLE){
        require(institutionDataSet[_institutionAddr].isValid == false,"Error : This address has already been added as a institution.");
        institutionData memory newInstitutionData = institutionData(_name,_institutionAddress,_phoneNumber,true);
        institutionDataSet[_institutionAddr] = newInstitutionData;
        grantRole(MEDICAL_INSTITUTION_ROLE, _institutionAddr);
    }

    function checkPrescription(address _patientAddr,uint256 _recordId) public onlyRole(MEDICAL_INSTITUTION_ROLE){
        require(patientDataSet[_patientAddr].isValid == true,"Error : This patient hasn't been added yet.");
        require(patientDataSet[_patientAddr].prescriptionRecordNum > _recordId,"Error : illegal record id.");
        require(prescriptionRecords[_patientAddr][_recordId].isChecked == false,"Error : this record has already been checked.");
        prescriptionRecords[_patientAddr][_recordId].isChecked = true;
    }

    function addHospitalInfo(address _patientAddr,uint256 _wardId,uint256 _bedNumber,string memory _checkInDate) 
    public onlyRole(MEDICAL_INSTITUTION_ROLE) {
        require(patientDataSet[_patientAddr].isValid == true,"Error : This patient hasn't been added yet.");
        require(hospitalRecords[_patientAddr].isValid == true,"Error : This hospital info has already been added.");
        paymentInfo memory p = paymentInfo(_patientAddr,0,"","",false,true);
        hospitalRecord memory h = hospitalRecord(_patientAddr,_wardId,_bedNumber,_checkInDate,p,false,true);
        paymentRecords[_patientAddr] = p;
        hospitalRecords[_patientAddr] = h;
    }

    function updateBillInfo(address _patientAddr,uint256 _totalCost,string memory _billDetail) 
    public onlyRole(MEDICAL_INSTITUTION_ROLE){
        require(patientDataSet[_patientAddr].isValid == true,"Error : This patient hasn't been added yet.");
        require(paymentRecords[_patientAddr].isValid == true,"Error : This payment record hasn't been added yet.");
        paymentRecords[_patientAddr].totalCost = _totalCost;
        paymentRecords[_patientAddr].billDetail = _billDetail;
    }

    function dischargeReview(address _patientAddr) public onlyRole(MEDICAL_INSTITUTION_ROLE){
        require(patientDataSet[_patientAddr].isValid == true,"Error : This patient hasn't been added yet.");
        require(hospitalRecords[_patientAddr].isValid == true,"Error : This patient's hospital records hasn't been uploaded");
        require(hospitalRecords[_patientAddr].payment.isPaid == true,"Error : This patient hasn't pay the bill.");
        require(hospitalRecords[_patientAddr].isDischarge == false,"Error : This patient has already discharged.");
        hospitalRecords[_patientAddr].isDischarge = true;
    }
    //Patient relevant function
    function addPatient(address _patientAddr,string memory _name,string memory _idNumber,string memory _phoneNumber) 
    public onlyRole(DEFAULT_ADMIN_ROLE){
        require(patientDataSet[_patientAddr].isValid == false,"Error : This address has already been added as a patient.");
        basicHealthData memory newHealthData = basicHealthData(0,0,0,0);
        patientData memory newPatientData = patientData(_name,_idNumber,_phoneNumber,0,0,newHealthData,true);
        patientDataSet[_patientAddr] = newPatientData;
        grantRole(PATIENT_ROLE, _patientAddr);
    }

    function approveToDoctor(address _doctorAddr) public onlyRole(PATIENT_ROLE) {
        require(patientDataSet[msg.sender].isValid == true,"Error : This patient hasn't been added yet.");
        require(hasRole(DOCTOR_ROLE, _doctorAddr),"Error : Health data can only be approved to doctor.");
        approveInfo[msg.sender] = _doctorAddr;
    }

    function makeReservation(address _doctorAddr,uint256 _time) public onlyRole(PATIENT_ROLE) {
        require(hasRole(DOCTOR_ROLE, _doctorAddr),"Error : Health data can only be approved to doctor.");
        require(doctorDataSet[_doctorAddr].isAvaliable == true,"Error : This doctor is not avaliable");
        doctorDataSet[_doctorAddr].isAvaliable = false;
        reservationRecord memory r = reservationRecord(msg.sender,_doctorAddr,_time,true);
        reservationRecords[msg.sender] = r;
    }

    function checkTheBill() public view onlyRole(PATIENT_ROLE) returns(uint256,string memory){
        require(patientDataSet[msg.sender].isValid == true,"Error : This patient hasn't been added yet.");
        require(paymentRecords[msg.sender].isValid == true,"Error : This patient's payment records hasn't been uploaded");
        uint256 amount = paymentRecords[msg.sender].totalCost;
        string memory m = paymentRecords[msg.sender].billDetail;
        return (amount,m);
    }

    function payTheBill(string memory _paymentMethod,uint256 _balance)
    public onlyRole(PATIENT_ROLE) returns(bool,uint256) {
        require(patientDataSet[msg.sender].isValid == true,"Error : This patient hasn't been added yet.");
        require(paymentRecords[msg.sender].isValid == true,"Error : This patient's payment records hasn't been uploaded");
        if(_balance >= paymentRecords[msg.sender].totalCost) {
            _balance -= paymentRecords[msg.sender].totalCost;
            paymentRecords[msg.sender].paymentMethod = _paymentMethod;
            paymentRecords[msg.sender].isPaid = true;
            hospitalRecords[msg.sender].payment = paymentRecords[msg.sender];
            return (true,_balance);
        }else return (false,_balance);
    }

    //Doctor relevant function
    function addDoctor(address _doctorAddr,string memory _name,uint256 _doctorId,string memory _department,uint256 _age) 
    public onlyRole(DEFAULT_ADMIN_ROLE){
        require(doctorDataSet[_doctorAddr].isValid == false,"Error : This address has already been added as a doctor.");
        doctorData memory newDoctorData = doctorData(_name,_doctorId,_department,_age,true,true);
        doctorDataSet[_doctorAddr] = newDoctorData;
        grantRole(DOCTOR_ROLE, _doctorAddr);
    }

    function getPatientMedicalRecord(address _patientAddr,uint256 _recordId)
    public view onlyRole(DOCTOR_ROLE) returns(uint256,string memory,string memory,string memory){
        require(approveInfo[_patientAddr] == msg.sender,"Error : You have no access to patient's medical record.");
        require(patientDataSet[_patientAddr].medicalRecordNum > _recordId,"Error : illegal record id.");
        medicalRecord memory r = medicalRecords[_patientAddr][_recordId];
        return(r.time,r.diseaseName,r.detailInfo,r.doctorAdvice);
    }

    function updatePatientBasicHealthInfo(address _patientAddr,uint256 _height,uint256 _weight,uint256 _bloodPressure,uint256 _bloodSugar) 
    internal onlyRole(DOCTOR_ROLE){
        require(patientDataSet[_patientAddr].isValid == true,"Error : This patient hasn't been added yet.");
        patientDataSet[_patientAddr].patientHealthInfo.height = _height;
        patientDataSet[_patientAddr].patientHealthInfo.weight = _weight;
        patientDataSet[_patientAddr].patientHealthInfo.bloodPressure = _bloodPressure;
        patientDataSet[_patientAddr].patientHealthInfo.bloodSugar = _bloodSugar;
    }

    function updatePatientMedicalRecord(address _patientAddr,uint256 _time,
    string memory _diseaseName,string memory _detailInfo,string memory _doctorAdvice)
    internal onlyRole(DOCTOR_ROLE){
        require(patientDataSet[_patientAddr].isValid == true,"Error : This patient hasn't been added yet.");
        uint256 nextRecordId = patientDataSet[_patientAddr].medicalRecordNum;
        patientDataSet[_patientAddr].medicalRecordNum++;
        medicalRecord memory r = medicalRecord(nextRecordId,_time,_diseaseName,_detailInfo,_doctorAdvice,true);
        medicalRecords[_patientAddr][nextRecordId] = r;
    }

    function updatePrescriptionRecord(address _patientAddr,uint256 _time,string memory _drugName,uint256 _amount,string memory _description)
    internal onlyRole(DOCTOR_ROLE){
        require(patientDataSet[_patientAddr].isValid == true,"Error : This patient hasn't been added yet.");
        uint256 nextRecordId = patientDataSet[_patientAddr].prescriptionRecordNum;
        patientDataSet[_patientAddr].prescriptionRecordNum++;
        prescriptionData memory p = prescriptionData(_time,_drugName,_amount,_description);
        prescriptionRecord memory record = prescriptionRecord(nextRecordId,_patientAddr,msg.sender,p,false,false,true);
        prescriptionRecords[_patientAddr][nextRecordId] = record;
    }
    
    function examineAndUpdate(address _patientAddr,basicHealthData memory _examineData,medicalRecord memory _medicalData,prescriptionData memory _prescriptionData)
    public onlyRole(DOCTOR_ROLE){
        require(patientDataSet[_patientAddr].isValid == true,"Error : This patient hasn't been added yet.");
        require(reservationRecords[_patientAddr].isValid == true,"Error : Reservation information doesn't exist.");
        updatePatientBasicHealthInfo(_patientAddr, _examineData.height, _examineData.weight, _examineData.bloodPressure, _examineData.bloodSugar);
        updatePatientMedicalRecord(_patientAddr, _medicalData.time, _medicalData.diseaseName, _medicalData.detailInfo, _medicalData.doctorAdvice);
        updatePrescriptionRecord(_patientAddr,_prescriptionData.time, _prescriptionData.drugName, _prescriptionData.amount, _prescriptionData.description);
    }
    //Pharmacy department relevant function
    function addPharmacy(address _pharmacyAddr,string memory _name,string memory _physicalAddress,string memory _phoneNumber) 
    public onlyRole(DEFAULT_ADMIN_ROLE){
        require(pharmacyDataSet[_pharmacyAddr].isValid == false,"Error : This address has already been added as a pharmacy.");
        pharmacyData memory newPharmacyData = pharmacyData(_name,_physicalAddress,_phoneNumber,true);
        pharmacyDataSet[_pharmacyAddr] = newPharmacyData;
        grantRole(PHARMACY_DEPARTMENT_ROLE, _pharmacyAddr);
    }

    function distributePrescription(address _patientAddr,uint256 _recordId) public onlyRole(PHARMACY_DEPARTMENT_ROLE) {
        require(patientDataSet[_patientAddr].isValid == true,"Error : This patient hasn't been added yet.");
        require(patientDataSet[_patientAddr].prescriptionRecordNum > _recordId,"Error : illegal record id.");
        require(prescriptionRecords[_patientAddr][_recordId].isChecked == true,"Error : this record hasn't been checked.");
        require(prescriptionRecords[_patientAddr][_recordId].isDistributed == false,"Error : this record has already been distributed.");
        prescriptionRecords[_patientAddr][_recordId].isDistributed = true;
    }
}
