USE HospitalManagementSystem;
GO

-- 1. Today's Scheduled Appointments only
CREATE OR ALTER VIEW dbo.vw_TodayAppointments
AS
SELECT 
    a.AppointmentID,
    a.[Date] AS AppointmentDate,
    a.[Time] AS AppointmentTime,
    a.[Status],
    p.PatientID,
    p.Name AS PatientName,
    p.Phone AS PatientPhone,
    d.DoctorID,
    d.Name AS DoctorName,
    d.Specialty AS DoctorSpecialty
FROM Appointments a
INNER JOIN Patients p ON a.PatientID = p.PatientID
INNER JOIN Doctors d ON a.DoctorID = d.DoctorID
WHERE a.[Date] = CAST(GETDATE() AS DATE) AND a.[Status] = 'Scheduled';
GO

-- 2. Active Room Admissions
CREATE OR ALTER VIEW dbo.vw_ActiveRoomAdmissions
AS
SELECT 
    r.RoomID,
    r.RoomType,
    adm.AdmissionID,
    p.PatientID,
    p.Name AS PatientName,
    p.Phone AS PatientPhone,
    adm.AdmissionDate,
    DATEDIFF(DAY, adm.AdmissionDate, GETDATE()) AS DaysAdmitted
FROM Rooms r
INNER JOIN Admissions adm ON r.RoomID = adm.RoomID
INNER JOIN Patients p ON adm.PatientID = p.PatientID
WHERE adm.DischargeDate IS NULL AND r.Is_Available = 0;
GO

-- 3. Patient Billing Summary & Details
CREATE OR ALTER VIEW dbo.vw_PatientBillingSummary
AS
SELECT 
    p.PatientID,
    p.Name AS PatientName,
    p.Phone,
    COUNT(pb.BillID) AS TotalBills,
    ISNULL(SUM(pb.TotalAmount), 0) AS GrandTotal,
    ISNULL(SUM(CASE WHEN pb.PaidStatus = 'Paid' THEN pb.TotalAmount ELSE 0 END), 0) AS PaidAmount,
    ISNULL(SUM(CASE WHEN pb.PaidStatus IN ('Unpaid', 'Pending') THEN pb.TotalAmount ELSE 0 END), 0) AS UnpaidAmount
FROM Patients p
LEFT JOIN PatientBills pb ON p.PatientID = pb.PatientID
GROUP BY p.PatientID, p.Name, p.Phone;
GO

-- 4. Revenue By Specialty (Linked accurately via Appointments)
CREATE OR ALTER VIEW dbo.vw_RevenueBySpecialty
AS
SELECT 
    d.Specialty,
    COUNT(DISTINCT a.AppointmentID) AS TotalAppointmentsCount,
    ISNULL(SUM(pb.TotalAmount), 0) AS TotalRevenueGenerated
FROM Doctors d
LEFT JOIN Appointments a ON d.DoctorID = a.DoctorID
LEFT JOIN PatientBills pb ON a.AppointmentID = pb.AppointmentID
WHERE pb.PaidStatus = 'Paid' OR pb.PaidStatus IS NULL
GROUP BY d.Specialty;
GO

-- 5. Doctor Workload View
CREATE OR ALTER VIEW dbo.vw_DoctorWorkload
AS
SELECT 
    d.DoctorID,
    d.Name AS DoctorName,
    d.Specialty,
    YEAR(a.[Date]) AS WorkYear,
    MONTH(a.[Date]) AS WorkMonth,
    COUNT(a.AppointmentID) AS TotalMonthlyAppointments,
    COUNT(DISTINCT a.PatientID) AS UniquePatientsServiced
FROM Doctors d
LEFT JOIN Appointments a ON d.DoctorID = a.DoctorID
GROUP BY d.DoctorID, d.Name, d.Specialty, YEAR(a.[Date]), MONTH(a.[Date]);
GO