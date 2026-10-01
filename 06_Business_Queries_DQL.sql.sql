USE HospitalManagementSystem;
GO

-- 1. Daily doctor schedule with patient contacts
SELECT 
    a.AppointmentID,
    d.Name AS DoctorName,
    d.Specialty,
    p.Name AS PatientName,
    p.Phone AS PatientPhone,
    a.[Date] AS AppointmentDate,
    a.[Time] AS AppointmentTime,
    a.[Status]
FROM Appointments a
INNER JOIN Doctors d ON a.DoctorID = d.DoctorID
INNER JOIN Patients p ON a.PatientID = p.PatientID
WHERE a.[Date] = CAST(GETDATE() AS DATE) AND a.[Status] = 'Scheduled';
GO

-- 2. Revenue by specialty (Corrected join logic to prevent duplication)
SELECT 
    d.Specialty,
    COUNT(DISTINCT a.AppointmentID) AS TotalAppointments,
    ISNULL(SUM(pb.TotalAmount), 0) AS TotalRevenue
FROM Doctors d
INNER JOIN Appointments a ON d.DoctorID = a.DoctorID
INNER JOIN PatientBills pb ON a.AppointmentID = pb.AppointmentID
WHERE pb.PaidStatus = 'Paid'
GROUP BY d.Specialty;
GO

-- 3. Unpaid bills and outstanding balances
SELECT 
    pb.BillID,
    p.PatientID,
    p.Name AS PatientName,
    p.Phone,
    pb.[Date] AS BillDate,
    pb.TotalAmount,
    pb.PaidStatus
FROM PatientBills pb
INNER JOIN Patients p ON pb.PatientID = p.PatientID
WHERE pb.PaidStatus IN ('Unpaid', 'Pending');
GO

-- 4. Running visit count using window functions
SELECT 
    p.PatientID,
    p.Name AS PatientName,
    a.AppointmentID,
    a.[Date] AS VisitDate,
    ROW_NUMBER() OVER (PARTITION BY p.PatientID ORDER BY a.[Date], a.[Time]) AS VisitSequenceNumber
FROM Appointments a
INNER JOIN Patients p ON a.PatientID = p.PatientID;
GO

-- 5. Multi-table join across main clinical entities
SELECT 
    pr.PrescriptionID,
    p.Name AS PatientName,
    d.Name AS DoctorName,
    m.Name AS MedicationName,
    pd.Quantity,
    pd.Dose,
    pd.Frequency
FROM Prescriptions pr
INNER JOIN Appointments app ON pr.AppointmentID = app.AppointmentID
INNER JOIN Patients p ON app.PatientID = p.PatientID
INNER JOIN Doctors d ON app.DoctorID = d.DoctorID
INNER JOIN PrescriptionDetails pd ON pr.PrescriptionID = pd.PrescriptionID
INNER JOIN Medications m ON pd.MedicationID = m.MedicationID;
GO