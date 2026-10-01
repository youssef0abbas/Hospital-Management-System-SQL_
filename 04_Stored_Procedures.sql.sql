USE HospitalManagementSystem;
GO

CREATE OR ALTER PROCEDURE dbo.sp_BookAppointment
    @PatientID INT,
    @DoctorID INT,
    @AppointmentDate DATE,
    @AppointmentTime TIME,
    @Status NVARCHAR(50) = 'Scheduled'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Patients WHERE PatientID = @PatientID)
            THROW 50001, 'Patient ID does not exist.', 1;

        IF NOT EXISTS (SELECT 1 FROM Doctors WHERE DoctorID = @DoctorID)
            THROW 50002, 'Doctor ID does not exist.', 1;

        INSERT INTO Appointments (PatientID, DoctorID, [Date], [Time], [Status])
        VALUES (@PatientID, @DoctorID, @AppointmentDate, @AppointmentTime, @Status);

        COMMIT TRANSACTION;
        PRINT 'Appointment booked successfully.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_AdmitPatient
    @PatientID INT,
    @RoomID INT,
    @AdmissionDate DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @IsAvailable BIT;
        SELECT @IsAvailable = Is_Available FROM Rooms WHERE RoomID = @RoomID;

        If @IsAvailable = 0 OR @IsAvailable IS NULL
            THROW 50004, 'Room is currently not available.', 1;

        INSERT INTO Admissions (PatientID, RoomID, AdmissionDate)
        VALUES (@PatientID, @RoomID, @AdmissionDate);
        -- Room Is_Available is handled automatically by trigger trg_AfterAdmission_OccupyRoom

        COMMIT TRANSACTION;
        PRINT 'Patient admitted successfully.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Corrected billing scope (uses admission cost function and current admission prescriptions)
CREATE OR ALTER PROCEDURE dbo.sp_GenerateBill
    @PatientID INT,
    @AdmissionID INT = NULL,
    @AppointmentID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @RoomCharge DECIMAL(10,2) = 0.00;
    DECLARE @MedicationCharge DECIMAL(10,2) = 0.00;
    DECLARE @TotalAmount DECIMAL(10,2) = 0.00;

    IF @AdmissionID IS NOT NULL
    BEGIN
        SET @RoomCharge = dbo.fn_CalculateAdmissionCost(@AdmissionID);
        
        SELECT @MedicationCharge = ISNULL(SUM(m.UnitPrice * pd.Quantity), 0.00)
        FROM Admissions adm
        INNER JOIN Appointments app ON adm.PatientID = app.PatientID AND app.[Date] >= CAST(adm.AdmissionDate AS DATE)
        INNER JOIN Prescriptions pr ON app.AppointmentID = pr.AppointmentID
        INNER JOIN PrescriptionDetails pd ON pr.PrescriptionID = pd.PrescriptionID
        INNER JOIN Medications m ON pd.MedicationID = m.MedicationID
        WHERE adm.AdmissionID = @AdmissionID;
    END
    ELSE IF @AppointmentID IS NOT NULL
    BEGIN
        SELECT @MedicationCharge = ISNULL(SUM(m.UnitPrice * pd.Quantity), 0.00)
        FROM Prescriptions pr
        INNER JOIN PrescriptionDetails pd ON pr.PrescriptionID = pd.PrescriptionID
        INNER JOIN Medications m ON pd.MedicationID = m.MedicationID
        WHERE pr.AppointmentID = @AppointmentID;
    END

    SET @TotalAmount = @RoomCharge + @MedicationCharge;

    INSERT INTO PatientBills (PatientID, AdmissionID, AppointmentID, [Date], TotalAmount, PaidStatus)
    VALUES (@PatientID, @AdmissionID, @AppointmentID, GETDATE(), @TotalAmount, 'Unpaid');
END;
GO

-- Single transaction ownership (Removed nested transaction call)
CREATE OR ALTER PROCEDURE dbo.sp_DischargePatient
    @AdmissionID INT,
    @DischargeDate DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @RoomID INT, @PatientID INT;
        SELECT @RoomID = RoomID, @PatientID = PatientID 
        FROM Admissions 
        WHERE AdmissionID = @AdmissionID;

        IF @RoomID IS NULL
            THROW 50005, 'Admission record not found.', 1;

        UPDATE Admissions
        SET DischargeDate = @DischargeDate
        WHERE AdmissionID = @AdmissionID;
        -- Room freeing is handled by trigger trg_AfterDischarge_FreeRoom

        -- Generate bill directly without nested transaction
        EXEC dbo.sp_GenerateBill @PatientID = @PatientID, @AdmissionID = @AdmissionID;

        COMMIT TRANSACTION;
        PRINT 'Patient discharged and bill generated successfully.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Fixed to check unpaid status and exact/valid payment handling without double auditing
CREATE OR ALTER PROCEDURE dbo.sp_ProcessBillPayment
    @BillID INT,
    @PaymentAmount DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @TotalAmount DECIMAL(10,2), @PaidStatus NVARCHAR(50);
        SELECT @TotalAmount = TotalAmount, @PaidStatus = PaidStatus FROM PatientBills WHERE BillID = @BillID;

        IF @TotalAmount IS NULL
            THROW 50006, 'Bill record not found.', 1;

        IF @PaidStatus = 'Paid'
            THROW 50008, 'Bill is already paid.', 1;

        IF @PaymentAmount < @TotalAmount
            THROW 50007, 'Payment amount is insufficient for full settlement.', 1;

        UPDATE PatientBills
        SET PaidStatus = 'Paid'
        WHERE BillID = @BillID;
        -- Audit log is automatically handled by trigger trg_AuditBillPayment safely

        COMMIT TRANSACTION;
        PRINT 'Payment processed successfully.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO