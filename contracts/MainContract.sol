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
    uint256 public nextRecordId;
    
    struct healthData{
        uint256 height;
        uint256 weight;
        uint256 bloodPressure;
        uint256 bloodSugar;
    }

    struct patientData {
        string name;
        string idNumber;
        string phoneNumber;
        healthData patientHealthInfo;
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

    struct record {
        address patientAddr;
        address doctorAddr;
        uint256 time;
    }

    mapping(uint256 => bytes32) roles;
    mapping(address => patientData) patientDataSet;
    mapping(address => address) approveInfo;
    mapping(address => doctorData) doctorDataSet;
    mapping(uint256 => record) records;

    constructor()AccessControlDefaultAdminRules(3 days,msg.sender){
        roles[0] = MEDICAL_INSTITUTION_ROLE;
        roles[1] = PATIENT_ROLE;
        roles[2] = DOCTOR_ROLE;
        roles[3] = PHARMACY_DEPARTMENT_ROLE;
        nextRoleId = 4;
        nextRecordId = 0;
    }

    function checkRole(address _checkAddr,bytes32 _role) public view onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
        return hasRole(_role, _checkAddr);
    }

    //Medical Institution relevant function
    
    //Patient relevant function
    function addPatient(
        address _patientAddr,
        string memory _name,
        string memory _idNumber,
        string memory _phoneNumber) public onlyRole(DEFAULT_ADMIN_ROLE){
            require(patientDataSet[_patientAddr].isValid == false,"Error : This address has already been added as a patient.");
            healthData memory newHealthData = healthData(0,0,0,0);
            patientData memory newPatientData = patientData(_name,_idNumber,_phoneNumber,newHealthData,true);
            patientDataSet[_patientAddr] = newPatientData;
            grantRole(PATIENT_ROLE, _patientAddr);
        }

    function updatePatientHealthInfo(
        address _patientAddr,
        uint256 _height,
        uint256 _weight,
        uint256 _bloodPressure,
        uint256 _bloodSugar) public onlyRole(DEFAULT_ADMIN_ROLE){
            require(patientDataSet[_patientAddr].isValid == true,"Error : This patient hasn't been added yet.");
            patientDataSet[_patientAddr].patientHealthInfo.height = _height;
            patientDataSet[_patientAddr].patientHealthInfo.weight = _weight;
            patientDataSet[_patientAddr].patientHealthInfo.bloodPressure = _bloodPressure;
            patientDataSet[_patientAddr].patientHealthInfo.bloodSugar = _bloodSugar;
        }

    function approveToDoctor(address _doctorAddr) public onlyRole(PATIENT_ROLE) {
        require(patientDataSet[msg.sender].isValid == true,"Error : This patient hasn't been added yet.");
        require(hasRole(DOCTOR_ROLE, _doctorAddr),"Error : Health data can only be approved to doctor.");
        approveInfo[msg.sender] = _doctorAddr;
    }

    function makeAnAppointment(address _doctorAddr,uint256 _time) public onlyRole(PATIENT_ROLE) {
        require(hasRole(DOCTOR_ROLE, _doctorAddr),"Error : Health data can only be approved to doctor.");
        require(doctorDataSet[_doctorAddr].isAvaliable == true,"Error : This doctor is not avaliable");
        doctorDataSet[_doctorAddr].isAvaliable = false;
        record memory r = record(msg.sender,_doctorAddr,_time);
        records[nextRecordId++] = r;
    }

    //Doctor relevant function
    function addDoctor(address _doctorAddr,string memory _name,uint256 _doctorId,string memory _department,uint256 _age) 
    public onlyRole(DEFAULT_ADMIN_ROLE){
        require(doctorDataSet[_doctorAddr].isValid == false,"Error : This address has already been added as a doctor.");
        doctorData memory newDoctorData = doctorData(_name,_doctorId,_department,_age,true,true);
        doctorDataSet[_doctorAddr] = newDoctorData;
        grantRole(DOCTOR_ROLE, _doctorAddr);
    }
    
    //Pharmacy department relevant function
}
