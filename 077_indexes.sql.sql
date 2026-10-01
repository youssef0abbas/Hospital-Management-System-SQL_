USE HospitalManagementSystem;
GO

-- 1. فهارس جدول المواعيد
CREATE NONCLUSTERED INDEX IX_Appointments_DoctorID ON Appointments(DoctorID);
CREATE NONCLUSTERED INDEX IX_Appointments_PatientID ON Appointments(PatientID);
CREATE NONCLUSTERED INDEX IX_Appointments_Date_Time ON Appointments([Date], [Time]);
GO

-- 2. فهرس جدول الإقامة
CREATE NONCLUSTERED INDEX IX_Admissions_PatientID ON Admissions(PatientID);
GO

-- 3. الفهرس المغطى (Covering Index) لفواتير المرضى مع الـ INCLUDE المطلوب
CREATE NONCLUSTERED INDEX IX_PatientBills_PatientStatus_Covering 
ON PatientBills (PatientID, PaidStatus) 
INCLUDE (TotalAmount);
GO