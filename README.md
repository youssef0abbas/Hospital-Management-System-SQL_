Hospital Management System (SQL Server) A comprehensive database implementation for managing clinical and hospital operations using Microsoft SQL Server (SSMS).

Project Overview This database system models complete healthcare operations, managing core hospital entities including:

Patients & Doctors: Profiles, specialties, and contact details.

Appointments & Prescriptions: Scheduling, consultations, and prescribed medications.

Rooms & Admissions: Inpatient admissions, stay durations, and room availability tracking.

Emergency Room (ER) Triage: Patient prioritization by urgency levels.

Billing & Revenue: Automated room/medication cost aggregations and payment status logs.

Key Technical Features Database Schema (DDL): Structured tables enforced with Primary Keys, Foreign Keys (ON DELETE CASCADE), UNIQUE constraints, and CHECK validations.

Transactional Stored Procedures: Complete workflow execution (Booking, Admission, Discharge, Billing, Payments) wrapped in TRY...CATCH blocks and explicit transactions (BEGIN TRANSACTION, COMMIT, ROLLBACK).

Automated Triggers: Enforces business logic such as double-booking prevention (INSTEAD OF INSERT), automatic room status updates (AFTER UPDATE), and protecting paid invoices from deletion.

User-Defined Functions (UDFs): Custom Scalar and Table-Valued Functions to compute inpatient stay lengths, prescription costs, and triage lists.

Analytical Views: Reusable views for daily clinic schedules, doctor workloads, room occupancy, and revenue streams.

Repository Structure Plaintext ├── Hospital_Management_System.sql # Complete unified database script └── README.md # Project documentation (If using separated scripts, follow this execution sequence: DDL Schema ➔ Seed Data ➔ Functions ➔ Views ➔ Stored Procedures ➔ Triggers)

How to Run Launch SQL Server Management Studio (SSMS).

Open the script and run the database creation header:

SQL CREATE DATABASE HospitalManagementSystem; GO USE HospitalManagementSystem; GO Execute the SQL script to generate all schema objects, sample data, procedures, and triggers.

💻 Tech Stack DBMS: Microsoft SQL Server

Tooling: SQL Server Management Studio (SSMS)

Language: T-SQL (Transact-SQL)
