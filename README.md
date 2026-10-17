# Hospital Patient Tracker

## Project Description

The **Hospital Patient Tracker** is a database management project developed using MySQL to manage hospital information, including patients, doctors, departments, appointments, admissions, prescriptions, bills, and payments.

The project helps organize patient records, track appointments, monitor admitted patients, manage billing information, and calculate outstanding balances. It demonstrates practical SQL concepts such as table relationships, joins, stored procedures, views, indexes, and constraints.

**Note:** This is a database demonstration project using fictional sample records. It is not a clinical decision-making system.

## Technologies Used

- **Database:** MySQL 8.0+
- **Language:** SQL
- **Tool:** MySQL Workbench

## Features

- Manage patient records and contact information.
- Store doctor details and specializations.
- Organize hospital departments.
- Schedule and track appointments.
- Manage patient admissions and discharge information.
- Maintain prescription records.
- Generate patient billing records.
- Record payments using different payment methods.
- Calculate outstanding bill balances.
- Search patients by name or phone number.
- Generate appointment and doctor summaries.
- Identify currently admitted patients.
- Maintain data integrity using constraints and relationships.

## Database Structure

The project contains eight main tables:

| Table | Description |
|---|---|
| `departments` | Stores hospital department details. |
| `doctors` | Stores doctor information and specializations. |
| `patients` | Stores patient registration details. |
| `appointments` | Manages patient appointments. |
| `admissions` | Tracks patient admission and discharge records. |
| `prescriptions` | Stores demonstration prescription records. |
| `bills` | Maintains patient billing details. |
| `payments` | Records individual payments against bills. |

## Database Objects

### Stored Procedures

- `search_patients` – Searches patients by first name, last name, or phone number.
- `schedule_appointment` – Creates an appointment after validating the patient and doctor.
- `record_payment` – Records a payment and updates the bill status and remaining balance.

### Views

- `patient_visit_history` – Displays appointments with patient, doctor, and department details.
- `active_admissions` – Displays patients who are currently admitted.
- `outstanding_bills` – Shows unpaid balances for bills that are not cancelled.
- `doctor_appointment_summary` – Summarizes appointments by doctor.

### Indexes and Constraints

- Primary keys and foreign keys.
- Unique constraints for selected email and transaction-reference fields.
- Check constraints for fees, billing amounts, payment amounts, and date values.
- Indexes to support appointment, admission, billing, and payment queries.
- ENUM fields to restrict selected statuses and payment methods to defined values.

## Repository Structure

```text
Hospital-Patient-Tracker/
├── hospital_patient_tracker.sql
└── README.md
```

## Installation and Setup

### Step 1: Install MySQL

Install MySQL Server 8.0 or a compatible version and MySQL Workbench.

### Step 2: Download the Repository

Clone the GitHub repository:

```bash
git clone <your-github-repository-url>
```

Alternatively, download the repository as a ZIP file.

### Step 3: Open the SQL File

Open `hospital_patient_tracker.sql` in MySQL Workbench.

### Step 4: Execute the SQL Script

Run the complete SQL script to create the database tables, insert sample data, and create the views and stored procedures.

**Important:** The script drops and recreates the project's tables and related database objects. Back up existing project data before running it again.

## Example SQL Queries

### 1. Display All Patients

```sql
USE hospital_patient_tracker;

SELECT *
FROM patients
ORDER BY patient_id;
```

### 2. Display Doctors and Departments

```sql
SELECT
    d.doctor_id,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    d.specialization,
    dep.department_name,
    d.consultation_fee
FROM doctors d
JOIN departments dep
    ON d.department_id = dep.department_id;
```

### 3. View Patient Appointment History

```sql
SELECT *
FROM patient_visit_history
ORDER BY appointment_datetime DESC;
```

### 4. View Currently Admitted Patients

```sql
SELECT *
FROM active_admissions;
```

### 5. View Outstanding Bills

```sql
SELECT *
FROM outstanding_bills
ORDER BY balance_due DESC;
```

### 6. View Doctor Appointment Summary

```sql
SELECT *
FROM doctor_appointment_summary
ORDER BY total_appointments DESC;
```

### 7. Search for a Patient

```sql
CALL search_patients('Aarav');
```

### 8. Schedule an Appointment

```sql
CALL schedule_appointment(
    1,
    1,
    '2026-11-10 10:00:00',
    'Routine follow-up'
);
```

This schedules an appointment for patient ID 1 with doctor ID 1, provided the patient and active doctor exist and the appointment date and time are supplied.

### 9. Record a Payment

```sql
CALL record_payment(
    1,
    700.00,
    'UPI',
    'DEMO-PAY-0003'
);
```

This records a payment of 700 for bill ID 1, provided the payment is valid and does not exceed the remaining bill balance. The transaction reference must be unique.

## Learning Outcomes

- Understanding relational database design.
- Creating tables with primary and foreign keys.
- Using SQL joins and aggregate functions.
- Creating views for reports.
- Implementing stored procedures.
- Applying constraints and indexes.
- Managing appointments and admission records.
- Tracking billing, payments, and outstanding balances.
- Writing SQL queries for hospital administration reports.

## Future Enhancements

- Develop a web interface for hospital staff.
- Add secure login and role-based access.
- Generate downloadable patient and billing reports.
- Add appointment reminders.
- Improve billing reports and payment tracking.
- Implement audit logs and automated backups.
- Integrate with a secure hospital application using appropriate privacy and access controls.

## Conclusion

The Hospital Patient Tracker demonstrates how MySQL can organize hospital records and support appointment scheduling, admission tracking, and billing operations. It provides a foundation for developing a complete hospital management application with a frontend and backend.

## Author Details
- **Name:** KURUBA CHANDRAMOULI 
- **Domain:** SQL
- **Internship ID:** CITS9354
