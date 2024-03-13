// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// Uncomment this line to use console.log
import "hardhat/console.sol";
import {AccessControlDefaultAdminRules} from "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";

//本合约模板的使用场景为医疗领域，基于openzeppelin合约库中的AccessControlDefaultAdminRules标准合约模板进行开发
//使用AccessControlDefaultAdminRules标准合约模板的目的在于便捷地对使用场景中的角色进行定义、授权等一系列权限访问控制
//为了尽可能地简化开发流程和降低开发难度，本合约对部分实现细节做了一些简化，实际应用时可根据具体需求对数据结构进行一些调整
contract MedicalTemplate is AccessControlDefaultAdminRules{

    //以下是角色定义部分，每个角色以32字节作为标识，考虑做成常量，如果有新增角色定义，照着下方代码修改即可
    //管理员角色默认是合约的部署者，在构造函数中被初始化赋值，管理员角色可以给其他账户赋予角色和收回角色权限
    bytes32 public constant MEDICAL_INSTITUTION_ROLE = keccak256("MEDICAL_INSTITUTION");//medical institution
    bytes32 public constant PATIENT_ROLE = keccak256("PATIENT");//patient
    bytes32 public constant DOCTOR_ROLE = keccak256("DOCTOR");//doctor
    bytes32 public constant PHARMACY_DEPARTMENT_ROLE = keccak256("PHARMACY_DEPARTMENT");//pharmacy department
    uint256 public nextRoleId;
    
    //患者基础健康数据，可根据实际需求进行增删
    struct basicHealthData{
        uint256 height;
        uint256 weight;
        uint256 bloodPressure;
        uint256 bloodSugar;
    }

    //患者就诊数据，可有多条，每条对应一次就医记录，可根据实际需求进行增删
    //isValid字段设定的目的主要是因为solidity的mapping只能通过遍历来检查mapping中是否已经存在这条记录
    //其在合约中的作用主要是为了便于查重，如果后续选择使用其他语言编写合约可能不需要该字段，下同
    struct medicalRecord{
        uint256 recordId;
        uint256 time;
        string diseaseName;
        string detailInfo;
        string doctorAdvice;
        bool isValid;
    }

    //患者预约挂号数据，可根据实际需求进行增删
    struct reservationRecord {
        address patientAddr;
        address doctorAddr;
        uint256 time;//预约时间
        bool isValid;
    }

    //处方药物数据，这里做了简化处理，一个处方中只包含一种药物，后续可根据实际需求进行调整
    struct prescriptionData {
        uint256 time;//用药时间
        string drugName;
        uint256 amount;//药物用量
        string description;//用药描述
    }

    //患者处方记录数据，患者一次就诊可能会开多个处方，且可能会存在多次就诊，因此处方记录应该是多条的
    struct prescriptionRecord {
        uint256 recordId;
        address patientAddr;
        address doctorAddr;
        prescriptionData prescription;//处方药物数据
        bool isChecked;//该处方是否已经被医疗机构审核过了（检查是否包含违禁药）
        bool isDistributed;//该处方对应的药品是否已经被药剂科配发给患者了
        bool isVaild;
    }

    //患者数据，包含患者个人基本信息、健康信息、就诊记录条数、处方记录条数等
    struct patientData {
        string name;
        string idNumber;
        string phoneNumber;
        uint256 medicalRecordNum;
        uint256 prescriptionRecordNum;
        basicHealthData patientHealthInfo;
        bool isValid;
    }

    //医生数据，包含医生个人信息以及医生当前是否有空（如果已有患者预约该医生则显示没空）
    struct doctorData {
        string name;
        uint256 doctorId;
        string department;
        uint256 age;
        bool isAvaliable;
        bool isValid;
    }

    //药剂科基本数据
    struct pharmacyData {
        string name;
        string physicalAddress;
        string phoneNumber;
        bool isValid;
    }

    //医疗机构基本数据
    struct institutionData {
        string name;
        string institutionAddress;
        string phoneNumber;
        bool isValid;
    }

    //支付数据，包含对应的患者信息、支付总额、支付方式、账单详情、支付成功与否等数据
    struct paymentInfo {
        address patientAddr;
        uint256 totalCost;
        string paymentMethod;
        string billDetail;
        bool isPaid;
        bool isValid;
    }

    //患者住院数据，包含病房号、病床号、入住日期、患者账单信息、是否已经出院等数据
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
    mapping(address => address) approveInfo;//患者授权医生映射集合（只有经过患者授权医生才可以查看患者的就诊记录）
    mapping(address => doctorData) doctorDataSet;
    mapping(address => pharmacyData) pharmacyDataSet;
    mapping(address => institutionData) institutionDataSet;
    mapping(address => reservationRecord) reservationRecords;//患者和医生预约挂号记录映射
    mapping(address => mapping(uint256 => medicalRecord)) medicalRecords;//患者就诊数据
    mapping(address => mapping (uint256 => prescriptionRecord)) prescriptionRecords;//患者的处方数据
    mapping(address => paymentInfo) paymentRecords;
    mapping(address => hospitalRecord) hospitalRecords;

    //这里传入msg.sender就是将合约部署者设定为了默认的管理员角色，可根据实际应用需求进行更改
    constructor()AccessControlDefaultAdminRules(3 days,msg.sender){
        roles[0] = MEDICAL_INSTITUTION_ROLE;
        roles[1] = PATIENT_ROLE;
        roles[2] = DOCTOR_ROLE;
        roles[3] = PHARMACY_DEPARTMENT_ROLE;
        nextRoleId = 4;
    }

    //checkRole函数用于检查给定的地址是否拥有某个角色权限
    function checkRole(address _checkAddr,uint256 _role) public view onlyRole(DEFAULT_ADMIN_ROLE) returns(bool) {
        return hasRole(roles[_role], _checkAddr);
    }

    //以下方法基本都带有onlyRole修饰器，用于限定该函数只有拥有特定某个角色权限的账户才可以调用

    //Medical Institution relevant function
    //新增医疗机构账户
    function addInstitution(address _institutionAddr,string memory _name,string memory _institutionAddress,string memory _phoneNumber)
    public onlyRole(DEFAULT_ADMIN_ROLE){
        require(institutionDataSet[_institutionAddr].isValid == false,"Error : This address has already been added as a institution.");
        institutionData memory newInstitutionData = institutionData(_name,_institutionAddress,_phoneNumber,true);
        institutionDataSet[_institutionAddr] = newInstitutionData;
        grantRole(MEDICAL_INSTITUTION_ROLE, _institutionAddr);
    }

    //检查某个处方是否含有违禁药物
    function checkPrescription(address _patientAddr,uint256 _recordId) public onlyRole(MEDICAL_INSTITUTION_ROLE){
        require(patientDataSet[_patientAddr].isValid == true,"Error : This patient hasn't been added yet.");
        require(patientDataSet[_patientAddr].prescriptionRecordNum > _recordId,"Error : illegal record id.");
        require(prescriptionRecords[_patientAddr][_recordId].isChecked == false,"Error : this record has already been checked.");
        prescriptionRecords[_patientAddr][_recordId].isChecked = true;
    }

    //新增患者住院信息
    function addHospitalInfo(address _patientAddr,uint256 _wardId,uint256 _bedNumber,string memory _checkInDate) 
    public onlyRole(MEDICAL_INSTITUTION_ROLE) {
        require(patientDataSet[_patientAddr].isValid == true,"Error : This patient hasn't been added yet.");
        require(hospitalRecords[_patientAddr].isValid == false,"Error : This hospital info has already been added.");
        paymentInfo memory p = paymentInfo(_patientAddr,0,"","",false,false);
        hospitalRecord memory h = hospitalRecord(_patientAddr,_wardId,_bedNumber,_checkInDate,p,false,true);
        paymentRecords[_patientAddr] = p;
        hospitalRecords[_patientAddr] = h;
    }

    //更新患者住院账单
    function updateBillInfo(address _patientAddr,uint256 _totalCost,string memory _billDetail) 
    public onlyRole(MEDICAL_INSTITUTION_ROLE){
        require(patientDataSet[_patientAddr].isValid == true,"Error : This patient hasn't been added yet.");
        require(paymentRecords[_patientAddr].isValid == false,"Error : This payment record has been added.");
        paymentRecords[_patientAddr].totalCost = _totalCost;
        paymentRecords[_patientAddr].billDetail = _billDetail;
        paymentRecords[_patientAddr].isValid = true;
    }

    //对患者进行出院审核，只有完成住院账单支付才可以出院
    function dischargeReview(address _patientAddr) public onlyRole(MEDICAL_INSTITUTION_ROLE){
        require(patientDataSet[_patientAddr].isValid == true,"Error : This patient hasn't been added yet.");
        require(hospitalRecords[_patientAddr].isValid == true,"Error : This patient's hospital records hasn't been uploaded");
        require(hospitalRecords[_patientAddr].payment.isPaid == true,"Error : This patient hasn't pay the bill.");
        require(hospitalRecords[_patientAddr].isDischarge == false,"Error : This patient has already discharged.");
        hospitalRecords[_patientAddr].isDischarge = true;
    }
    //Patient relevant function
    //新增患者账户
    function addPatient(address _patientAddr,string memory _name,string memory _idNumber,string memory _phoneNumber) 
    public onlyRole(DEFAULT_ADMIN_ROLE){
        require(patientDataSet[_patientAddr].isValid == false,"Error : This address has already been added as a patient.");
        basicHealthData memory newHealthData = basicHealthData(0,0,0,0);
        patientData memory newPatientData = patientData(_name,_idNumber,_phoneNumber,0,0,newHealthData,true);
        patientDataSet[_patientAddr] = newPatientData;
        grantRole(PATIENT_ROLE, _patientAddr);
    }

    //患者授权给医生自己的就诊记录调用权限
    function approveToDoctor(address _doctorAddr) public onlyRole(PATIENT_ROLE) {
        require(patientDataSet[msg.sender].isValid == true,"Error : This patient hasn't been added yet.");
        require(hasRole(DOCTOR_ROLE, _doctorAddr),"Error : Health data can only be approved to doctor.");
        approveInfo[msg.sender] = _doctorAddr;
    }

    //患者和医生进行预约挂号
    function makeReservation(address _doctorAddr,uint256 _time) public onlyRole(PATIENT_ROLE) {
        require(hasRole(DOCTOR_ROLE, _doctorAddr),"Error : Health data can only be approved to doctor.");
        require(doctorDataSet[_doctorAddr].isAvaliable == true,"Error : This doctor is not avaliable");
        doctorDataSet[_doctorAddr].isAvaliable = false;
        reservationRecord memory r = reservationRecord(msg.sender,_doctorAddr,_time,true);
        reservationRecords[msg.sender] = r;
    }

    //患者查询自己的住院账单详情，返回值是账单总额以及详情数据
    function checkTheBill() public view onlyRole(PATIENT_ROLE) returns(uint256,string memory){
        require(patientDataSet[msg.sender].isValid == true,"Error : This patient hasn't been added yet.");
        require(paymentRecords[msg.sender].isValid == true,"Error : This patient's payment records hasn't been uploaded");
        uint256 amount = paymentRecords[msg.sender].totalCost;
        string memory m = paymentRecords[msg.sender].billDetail;
        return (amount,m);
    }

    //患者支付账单，此处只是模拟进行支付，传入的balance模拟为患者的余额，余额少于账单金额会返回支付失败信息，成功则会返回剩余金额
    function payTheBill(string memory _paymentMethod,uint256 _balance)
    public onlyRole(PATIENT_ROLE) returns(uint256) {
        require(patientDataSet[msg.sender].isValid == true,"Error : This patient hasn't been added yet.");
        require(paymentRecords[msg.sender].isValid == true,"Error : This patient's payment records hasn't been uploaded");
        require(_balance >= paymentRecords[msg.sender].totalCost,"Error : Insufficient balance.");
        _balance -= paymentRecords[msg.sender].totalCost;
        paymentRecords[msg.sender].paymentMethod = _paymentMethod;
        paymentRecords[msg.sender].isPaid = true;
        hospitalRecords[msg.sender].payment = paymentRecords[msg.sender];
        return (_balance);
    }

    //Doctor relevant function
    //新增医生账户
    function addDoctor(address _doctorAddr,string memory _name,uint256 _doctorId,string memory _department,uint256 _age) 
    public onlyRole(DEFAULT_ADMIN_ROLE){
        require(doctorDataSet[_doctorAddr].isValid == false,"Error : This address has already been added as a doctor.");
        doctorData memory newDoctorData = doctorData(_name,_doctorId,_department,_age,true,true);
        doctorDataSet[_doctorAddr] = newDoctorData;
        grantRole(DOCTOR_ROLE, _doctorAddr);
    }

    //医生读取患者的就诊记录数据，注意，只有经过患者授权的医生才能访问到其就诊记录数据
    function getPatientMedicalRecord(address _patientAddr,uint256 _recordId)
    public view onlyRole(DOCTOR_ROLE) returns(uint256,string memory,string memory,string memory){
        require(approveInfo[_patientAddr] == msg.sender,"Error : You have no access to patient's medical record.");
        require(patientDataSet[_patientAddr].medicalRecordNum > _recordId,"Error : illegal record id.");
        medicalRecord memory r = medicalRecords[_patientAddr][_recordId];
        return(r.time,r.diseaseName,r.detailInfo,r.doctorAdvice);
    }

    //医生更新患者的基础健康数据
    function updatePatientBasicHealthInfo(address _patientAddr,uint256 _height,uint256 _weight,uint256 _bloodPressure,uint256 _bloodSugar) 
    public onlyRole(DOCTOR_ROLE){
        require(patientDataSet[_patientAddr].isValid == true,"Error : This patient hasn't been added yet.");
        patientDataSet[_patientAddr].patientHealthInfo.height = _height;
        patientDataSet[_patientAddr].patientHealthInfo.weight = _weight;
        patientDataSet[_patientAddr].patientHealthInfo.bloodPressure = _bloodPressure;
        patientDataSet[_patientAddr].patientHealthInfo.bloodSugar = _bloodSugar;
    }

    //医生更新患者的就诊记录数据
    function updatePatientMedicalRecord(address _patientAddr,uint256 _time,
    string memory _diseaseName,string memory _detailInfo,string memory _doctorAdvice)
    public onlyRole(DOCTOR_ROLE){
        require(patientDataSet[_patientAddr].isValid == true,"Error : This patient hasn't been added yet.");
        uint256 nextRecordId = patientDataSet[_patientAddr].medicalRecordNum;
        patientDataSet[_patientAddr].medicalRecordNum++;
        medicalRecord memory r = medicalRecord(nextRecordId,_time,_diseaseName,_detailInfo,_doctorAdvice,true);
        medicalRecords[_patientAddr][nextRecordId] = r;
    }

    //医生更新患者的处方记录数据
    function updatePrescriptionRecord(address _patientAddr,uint256 _time,string memory _drugName,uint256 _amount,string memory _description)
    public onlyRole(DOCTOR_ROLE){
        require(patientDataSet[_patientAddr].isValid == true,"Error : This patient hasn't been added yet.");
        uint256 nextRecordId = patientDataSet[_patientAddr].prescriptionRecordNum;
        patientDataSet[_patientAddr].prescriptionRecordNum++;
        prescriptionData memory p = prescriptionData(_time,_drugName,_amount,_description);
        prescriptionRecord memory record = prescriptionRecord(nextRecordId,_patientAddr,msg.sender,p,false,false,true);
        prescriptionRecords[_patientAddr][nextRecordId] = record;
    }
    
    //该函数模拟的是医生对患者进行诊察，依次调用了updatePatientBasicHealthInfo、updatePatientMedicalRecord、updatePrescriptionRecord三个函数
    function examineAndUpdate(address _patientAddr,basicHealthData memory _examineData,medicalRecord memory _medicalData,prescriptionData memory _prescriptionData)
    public onlyRole(DOCTOR_ROLE){
        require(patientDataSet[_patientAddr].isValid == true,"Error : This patient hasn't been added yet.");
        require(reservationRecords[_patientAddr].isValid == true,"Error : Reservation information doesn't exist.");
        updatePatientBasicHealthInfo(_patientAddr, _examineData.height, _examineData.weight, _examineData.bloodPressure, _examineData.bloodSugar);
        updatePatientMedicalRecord(_patientAddr, _medicalData.time, _medicalData.diseaseName, _medicalData.detailInfo, _medicalData.doctorAdvice);
        updatePrescriptionRecord(_patientAddr,_prescriptionData.time, _prescriptionData.drugName, _prescriptionData.amount, _prescriptionData.description);
    }
    //Pharmacy department relevant function
    //新增药剂科账户
    function addPharmacy(address _pharmacyAddr,string memory _name,string memory _physicalAddress,string memory _phoneNumber) 
    public onlyRole(DEFAULT_ADMIN_ROLE){
        require(pharmacyDataSet[_pharmacyAddr].isValid == false,"Error : This address has already been added as a pharmacy.");
        pharmacyData memory newPharmacyData = pharmacyData(_name,_physicalAddress,_phoneNumber,true);
        pharmacyDataSet[_pharmacyAddr] = newPharmacyData;
        grantRole(PHARMACY_DEPARTMENT_ROLE, _pharmacyAddr);
    }

    //药剂科分发处方中的药品，注意，只有经过医疗机构审核的处方才能够分发对应的药品
    function distributePrescription(address _patientAddr,uint256 _recordId) public onlyRole(PHARMACY_DEPARTMENT_ROLE) {
        require(patientDataSet[_patientAddr].isValid == true,"Error : This patient hasn't been added yet.");
        require(patientDataSet[_patientAddr].prescriptionRecordNum > _recordId,"Error : illegal record id.");
        require(prescriptionRecords[_patientAddr][_recordId].isChecked == true,"Error : this record hasn't been checked.");
        require(prescriptionRecords[_patientAddr][_recordId].isDistributed == false,"Error : this record has already been distributed.");
        prescriptionRecords[_patientAddr][_recordId].isDistributed = true;
    }
}
