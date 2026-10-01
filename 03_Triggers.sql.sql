USE HospitalManagementSystem;
GO

-- 1. Occupy room on admission insert
CREATE OR ALTER TRIGGER dbo.trg_AfterAdmission_OccupyRoom
ON Admissions
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Rooms
    SET Is_Available = 0
    FROM Rooms r
    INNER JOIN inserted i ON r.RoomID = i.RoomID;
END;
GO

-- 2. Free room on discharge update
CREATE OR ALTER TRIGGER dbo.trg_AfterDischarge_FreeRoom
ON Admissions
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(DischargeDate)
    BEGIN
        UPDATE Rooms
        SET Is_Available = 1
        FROM Rooms r
        INNER JOIN inserted i ON r.RoomID = i.RoomID
        WHERE i.DischargeDate IS NOT NULL;
    END
END;
GO

-- 3. Prevent double booking on appointments
CREATE OR ALTER TRIGGER dbo.trg_PreventDoubleBooking
ON Appointments
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM Appointments a
        INNER JOIN inserted i ON a.DoctorID = i.DoctorID AND a.[Date] = i.[Date] AND a.[Time] = i.[Time]
        WHERE a.[Status] != 'Cancelled'
    )
    BEGIN
        RAISERROR('The selected doctor is already booked for this date and time slot.', 16, 1);
        RETURN;
    END
    INSERT INTO Appointments (PatientID, DoctorID, [Date], [Time], [Status])
    SELECT PatientID, DoctorID, [Date], [Time], ISNULL([Status], 'Scheduled') FROM inserted;
END;
GO

-- 4. Audit bill payment automatically (Syntax fixed)
CREATE OR ALTER TRIGGER dbo.trg_AuditBillPayment
ON PatientBills
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(PaidStatus)
    BEGIN
        INSERT INTO PaymentAuditLog (BillID, PaymentDate, AmountPaid, [Status])
        SELECT i.BillID, GETDATE(), i.TotalAmount, i.PaidStatus
        FROM inserted i
        INNER JOIN deleted d ON i.BillID = d.BillID
        WHERE d.PaidStatus != 'Paid' AND i.PaidStatus = 'Paid';
    END
END;
GO

-- 5. Prevent deleting medications referenced in prescriptions
CREATE OR ALTER TRIGGER dbo.trg_PreventMedicationDelete
ON Medications
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM PrescriptionDetails pd INNER JOIN deleted d ON pd.MedicationID = d.MedicationID)
    BEGIN
        RAISERROR('Cannot delete medication because it is referenced in prescriptions history.', 16, 1);
        RETURN;
    END
    DELETE FROM Medications WHERE MedicationID IN (SELECT MedicationID FROM deleted);
END;
GO