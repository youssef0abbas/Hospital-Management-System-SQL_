USE HospitalManagementSystem;
GO

CREATE OR ALTER FUNCTION dbo.fn_GetPatientAge (@PatientID INT)
RETURNS INT
AS
BEGIN
    DECLARE @BirthDate DATE;
    SELECT @BirthDate = BirthDate FROM Patients WHERE PatientID = @PatientID;
    RETURN DATEDIFF(YEAR, @BirthDate, GETDATE()) - CASE WHEN MONTH(@BirthDate) > MONTH(GETDATE()) OR (MONTH(@BirthDate) = MONTH(GETDATE()) AND DAY(@BirthDate) > DAY(GETDATE())) THEN 1 ELSE 0 END;
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_GetPatientTotalPaid (@PatientID INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @TotalPaid DECIMAL(10,2);
    SELECT @TotalPaid = SUM(TotalAmount) FROM PatientBills WHERE PatientID = @PatientID AND PaidStatus = 'Paid';
    RETURN ISNULL(@TotalPaid, 0.00);
END;
GO

-- Standardized rule: minimum 1 billable day for admission
CREATE OR ALTER FUNCTION dbo.fn_CalculateAdmissionCost (@AdmissionID INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Cost DECIMAL(10,2);
    SELECT @Cost = CASE 
        WHEN DATEDIFF(DAY, AdmissionDate, ISNULL(DischargeDate, GETDATE())) = 0 THEN 1 
        ELSE DATEDIFF(DAY, AdmissionDate, ISNULL(DischargeDate, GETDATE())) 
    END * r.PricePerDay
    FROM Admissions adm
    INNER JOIN Rooms r ON adm.RoomID = r.RoomID
    WHERE adm.AdmissionID = @AdmissionID;
    RETURN ISNULL(@Cost, 0.00);
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_GetDoctorSchedule (@DoctorID INT, @Date DATE)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        a.AppointmentID,
        p.Name AS PatientName,
        a.[Time],
        a.[Status]
    FROM Appointments a
    INNER JOIN Patients p ON a.PatientID = p.PatientID
    WHERE a.DoctorID = @DoctorID AND a.[Date] = @Date
);
GO

CREATE OR ALTER FUNCTION dbo.fn_GetPatientMedicalHistory (@PatientID INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        a.AppointmentID,
        a.[Date],
        d.Name AS DoctorName,
        d.Specialty,
        a.[Status]
    FROM Appointments a
    INNER JOIN Doctors d ON a.DoctorID = d.DoctorID
    WHERE a.PatientID = @PatientID
);
GO