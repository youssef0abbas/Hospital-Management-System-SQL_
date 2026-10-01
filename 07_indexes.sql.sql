USE HospitalManagementSystem;
GO

-- 1. Index on Appointments (DoctorID)
CREATE NONCLUSTERED INDEX IX_Appointments_DoctorID ON Appointments(DoctorID);
GO

-- 2. Index on Appointments (PatientID)
CREATE NONCLUSTERED INDEX IX_Appointments_PatientID ON Appointments(PatientID);
GO

-- 3. Index on Admissions (PatientID)
CREATE NONCLUSTERED INDEX IX_Admissions_PatientID ON Admissions(PatientID);
GO

-- 4. Index on Appointments (Date, Time)
CREATE NONCLUSTERED INDEX IX_Appointments_Date_Time ON Appointments([Date], [Time]);
GO

-- 5. Covering Index on PatientBills with INCLUDE
CREATE NONCLUSTERED INDEX IX_PatientBills_PatientStatus_Covering 
ON PatientBills (PatientID, PaidStatus) 
INCLUDE (TotalAmount);
GO

-- Extra Custom Feature Index (Triage)
CREATE NONCLUSTERED INDEX IX_EmergencyRoomTriage_LevelStatus 
ON EmergencyRoomTriage (TriageLevel, [Status]);
GO