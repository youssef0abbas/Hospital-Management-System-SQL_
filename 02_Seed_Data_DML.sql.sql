USE HospitalManagementSystem;
GO

INSERT INTO Patients (Name, Gender, BirthDate, Phone, Address) VALUES
('Ahmed Mahmoud Ali', 'Male', '1985-04-12', '01012345678', 'Cairo - Nasr City'),
('Mariam Mohamed Ibrahim', 'Female', '1992-08-25', '01123456789', 'Sharqia - Zagazig'),
('Omar Khaled Hassanain', 'Male', '1978-11-03', '01234567890', 'Giza - Dokki'),
('Sara Youssef Ahmed', 'Female', '2001-02-15', '01545678901', 'Cairo - Maadi'),
('Mahmoud Moustafa Kamal', 'Male', '1965-06-30', '01098765432', 'Alexandria - Smouha');
GO

INSERT INTO Doctors (Name, Specialty, Phone) VALUES 
('Dr. Hazem Abdel Aziz', 'Cardiology', '01001112233'),
('Dr. Rania Nabil', 'Pediatrics', '01112223344'),
('Dr. Tarek El Sherif', 'Orthopedics', '01223334455'),
('Dr. Shaimaa Farouk', 'Neurology', '01554443322');
GO

INSERT INTO Rooms (RoomType, PricePerDay, Is_Available) VALUES
('Single ICU', 1000.00, 0),      
('Double General', 400.00, 1),  
('VIP Suite', 1500.00, 0),       
('Single General', 600.00, 1),  
('Double General', 400.00, 1);  
GO

INSERT INTO Medications (Name, UnitPrice) VALUES
('Panadol Extra 500mg', 35.00),
('Augmentin 1g', 110.00),
('Concor 5mg', 85.50),
('Cataflam 50mg', 45.00),
('Omeprazole 20mg', 60.00);
GO

INSERT INTO Appointments (PatientID, DoctorID, [Date], [Time], [Status]) VALUES
(1, 1, CAST(GETDATE() AS DATE), '09:30:00', 'Scheduled'),
(2, 2, CAST(GETDATE() AS DATE), '11:00:00', 'Completed'),
(3, 3, '2026-08-25', '14:00:00', 'Completed'),
(4, 1, '2026-08-28', '10:00:00', 'Scheduled'),
(5, 4, '2026-08-30', '13:30:00', 'Cancelled');
GO

-- Admissions matching occupied rooms (Room 1 and Room 3)
INSERT INTO Admissions (PatientID, RoomID, AdmissionDate, DischargeDate) VALUES
(1, 1, DATEADD(DAY, -2, GETDATE()), NULL),                 
(3, 3, DATEADD(DAY, -5, GETDATE()), DATEADD(DAY, -1, GETDATE())), 
(5, 3, DATEADD(DAY, -1, GETDATE()), NULL);                  
GO

INSERT INTO Prescriptions (AppointmentID, [Date]) VALUES
(1, GETDATE()),
(2, GETDATE());
GO

INSERT INTO PrescriptionDetails (PrescriptionID, MedicationID, Quantity, Dose, Frequency) VALUES
(1, 1, 2, '1 Tablet', 'Every 8 Hours'),
(1, 3, 1, '1/2 Tablet', 'Once Daily'),
(2, 2, 1, '1 Tablet', 'Every 12 Hours');
GO

INSERT INTO PatientBills (PatientID, AdmissionID, AppointmentID, [Date], TotalAmount, PaidStatus) VALUES
(3, 2, NULL, GETDATE(), 4500.00, 'Paid'),
(1, 1, 1, GETDATE(), 1200.00, 'Unpaid'),
(2, NULL, 2, GETDATE(), 350.00, 'Paid');
GO

INSERT INTO EmergencyRoomTriage (PatientID, TriageLevel, ArrivalTime, [Status], AdmissionID) VALUES
(1, 1, GETDATE(), 'Waiting', NULL),
(2, 3, GETDATE(), 'In-Treatment', NULL);
GO