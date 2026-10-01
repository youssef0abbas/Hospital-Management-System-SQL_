DROP DATABASE IF EXISTS HospitalManagementSystem;
CREATE DATABASE HospitalManagementSystem;
GO

USE HospitalManagementSystem;
GO

-- 1. Patients Table
CREATE TABLE Patients (
    PatientID INT IDENTITY(1,1) CONSTRAINT PK_Patients PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Gender NVARCHAR(10) NOT NULL CONSTRAINT CHK_Patients_Gender CHECK (Gender IN ('Male', 'Female', 'Other')),
    BirthDate DATE NOT NULL,
    Phone NVARCHAR(20) NULL CONSTRAINT UQ_Patients_Phone UNIQUE,
    Address NVARCHAR(200) NULL
);
GO

-- 2. Doctors Table
CREATE TABLE Doctors (
    DoctorID INT IDENTITY(1,1) CONSTRAINT PK_Doctors PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Specialty NVARCHAR(100) NOT NULL,
    Phone NVARCHAR(20) NULL CONSTRAINT UQ_Doctors_Phone UNIQUE
);
GO

-- 3. Rooms Table
CREATE TABLE Rooms (
    RoomID INT IDENTITY(1,1) CONSTRAINT PK_Rooms PRIMARY KEY,
    RoomType NVARCHAR(50) NOT NULL,
    PricePerDay DECIMAL(10,2) NOT NULL CONSTRAINT CHK_Rooms_Price CHECK (PricePerDay >= 0),
    Is_Available BIT NOT NULL CONSTRAINT DF_Rooms_IsAvailable DEFAULT 1
);
GO

-- 4. Medications Table
CREATE TABLE Medications (
    MedicationID INT IDENTITY(1,1) CONSTRAINT PK_Medications PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL CONSTRAINT CHK_Medications_UnitPrice CHECK (UnitPrice >= 0)
);
GO

-- 5. Appointments Table (Added Time CHECK constraint)
CREATE TABLE Appointments (
    AppointmentID INT IDENTITY(1,1) CONSTRAINT PK_Appointments PRIMARY KEY,
    PatientID INT NOT NULL,
    DoctorID INT NOT NULL,
    [Date] DATE NOT NULL,
    [Time] TIME NOT NULL CONSTRAINT CHK_Appointments_Time CHECK ([Time] >= '08:00' AND [Time] <= '20:00'),
    [Status] NVARCHAR(50) NOT NULL CONSTRAINT DF_Appointments_Status DEFAULT 'Scheduled'
        CONSTRAINT CHK_Appointments_Status CHECK ([Status] IN ('Scheduled', 'Completed', 'Cancelled')),
    
    CONSTRAINT FK_Appointments_Patients FOREIGN KEY (PatientID) 
        REFERENCES Patients(PatientID),
    CONSTRAINT FK_Appointments_Doctors FOREIGN KEY (DoctorID) 
        REFERENCES Doctors(DoctorID)
);
GO

-- 6. Prescriptions Table
CREATE TABLE Prescriptions (
    PrescriptionID INT IDENTITY(1,1) CONSTRAINT PK_Prescriptions PRIMARY KEY,
    AppointmentID INT NOT NULL,
    [Date] DATE NOT NULL CONSTRAINT DF_Prescriptions_Date DEFAULT GETDATE(),
    
    CONSTRAINT FK_Prescriptions_Appointments FOREIGN KEY (AppointmentID) 
        REFERENCES Appointments(AppointmentID) ON DELETE CASCADE
);
GO

-- 7. PrescriptionDetails Table (Restrict delete on Medications)
CREATE TABLE PrescriptionDetails (
    PrescriptionID INT NOT NULL,
    MedicationID INT NOT NULL,
    Quantity INT NOT NULL CONSTRAINT CHK_PrescriptionDetails_Qty CHECK (Quantity > 0),
    Dose NVARCHAR(100) NOT NULL,
    Frequency NVARCHAR(100) NOT NULL,
    
    CONSTRAINT PK_PrescriptionDetails PRIMARY KEY (PrescriptionID, MedicationID),
    CONSTRAINT FK_PrescriptionDetails_Prescriptions FOREIGN KEY (PrescriptionID) 
        REFERENCES Prescriptions(PrescriptionID) ON DELETE CASCADE,
    CONSTRAINT FK_PrescriptionDetails_Medications FOREIGN KEY (MedicationID) 
        REFERENCES Medications(MedicationID)
);
GO

-- 8. Admissions Table
CREATE TABLE Admissions (
    AdmissionID INT IDENTITY(1,1) CONSTRAINT PK_Admissions PRIMARY KEY,
    PatientID INT NOT NULL,
    RoomID INT NOT NULL,
    AdmissionDate DATETIME NOT NULL CONSTRAINT DF_Admissions_AdmissionDate DEFAULT GETDATE(),
    DischargeDate DATETIME NULL,
    
    CONSTRAINT FK_Admissions_Patients FOREIGN KEY (PatientID) 
        REFERENCES Patients(PatientID),
    CONSTRAINT FK_Admissions_Rooms FOREIGN KEY (RoomID) 
        REFERENCES Rooms(RoomID),
    CONSTRAINT CHK_Admissions_Dates CHECK (DischargeDate IS NULL OR DischargeDate >= AdmissionDate)
);
GO

-- 9. EmergencyRoomTriage Table (Added status check)
CREATE TABLE EmergencyRoomTriage (
    TriageID INT IDENTITY(1,1) CONSTRAINT PK_EmergencyRoomTriage PRIMARY KEY,
    PatientID INT NOT NULL,
    TriageLevel INT NOT NULL CONSTRAINT CHK_ERTriage_Level CHECK (TriageLevel BETWEEN 1 AND 5),
    ArrivalTime DATETIME NOT NULL CONSTRAINT DF_ERTriage_ArrivalTime DEFAULT GETDATE(),
    [Status] NVARCHAR(50) NOT NULL CONSTRAINT DF_ERTriage_Status DEFAULT 'Waiting'
        CONSTRAINT CHK_ERTriage_Status CHECK ([Status] IN ('Waiting', 'In-Treatment', 'Discharged', 'Admitted')),
    AdmissionID INT NULL,
    
    CONSTRAINT FK_ERTriage_Patients FOREIGN KEY (PatientID) 
        REFERENCES Patients(PatientID),
    CONSTRAINT FK_ERTriage_Admissions FOREIGN KEY (AdmissionID) 
        REFERENCES Admissions(AdmissionID)
);
GO

-- 10. PatientBills Table (Added AppointmentID for accurate revenue tracking)
CREATE TABLE PatientBills (
    BillID INT IDENTITY(1,1) CONSTRAINT PK_PatientBills PRIMARY KEY,
    PatientID INT NOT NULL,
    AdmissionID INT NULL,
    AppointmentID INT NULL,
    [Date] DATETIME NOT NULL CONSTRAINT DF_PatientBills_Date DEFAULT GETDATE(),
    TotalAmount DECIMAL(10,2) NOT NULL CONSTRAINT CHK_PatientBills_TotalAmount CHECK (TotalAmount >= 0),
    PaidStatus NVARCHAR(50) NOT NULL CONSTRAINT DF_PatientBills_PaidStatus DEFAULT 'Unpaid'
        CONSTRAINT CHK_PatientBills_PaidStatus CHECK (PaidStatus IN ('Paid', 'Unpaid', 'Pending')),
    
    CONSTRAINT FK_PatientBills_Patients FOREIGN KEY (PatientID) 
        REFERENCES Patients(PatientID),
    CONSTRAINT FK_PatientBills_Admissions FOREIGN KEY (AdmissionID) 
        REFERENCES Admissions(AdmissionID),
    CONSTRAINT FK_PatientBills_Appointments FOREIGN KEY (AppointmentID) 
        REFERENCES Appointments(AppointmentID)
);
GO

-- 11. PaymentAuditLog Table (Added FK to PatientBills)
CREATE TABLE PaymentAuditLog (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    BillID INT NOT NULL,
    PaymentDate DATETIME NOT NULL DEFAULT GETDATE(),
    AmountPaid DECIMAL(10,2) NOT NULL,
    [Status] NVARCHAR(50) NOT NULL,
    
    CONSTRAINT FK_PaymentAuditLog_Bills FOREIGN KEY (BillID) 
        REFERENCES PatientBills(BillID)
);
GO