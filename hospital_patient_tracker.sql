-- ============================================================
-- Project: Hospital Patient Tracker
-- Database: MySQL 8.0+
-- Purpose: Track patients, doctors, departments, appointments,
--          admissions, prescriptions, and billing/payment records.
-- ============================================================

CREATE DATABASE IF NOT EXISTS hospital_patient_tracker;
USE hospital_patient_tracker;

-- WARNING: This setup section drops and recreates project tables.
-- Back up existing data before rerunning this script.
SET FOREIGN_KEY_CHECKS = 0;

DROP VIEW IF EXISTS patient_visit_history;
DROP VIEW IF EXISTS outstanding_bills;
DROP VIEW IF EXISTS doctor_appointment_summary;
DROP VIEW IF EXISTS active_admissions;

DROP PROCEDURE IF EXISTS schedule_appointment;
DROP PROCEDURE IF EXISTS record_payment;
DROP PROCEDURE IF EXISTS search_patients;

DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS bills;
DROP TABLE IF EXISTS prescriptions;
DROP TABLE IF EXISTS admissions;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS patients;
DROP TABLE IF EXISTS doctors;
DROP TABLE IF EXISTS departments;

SET FOREIGN_KEY_CHECKS = 1;

-- ------------------------------------------------------------
-- 1. Departments
-- ------------------------------------------------------------
CREATE TABLE departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    location VARCHAR(100),
    phone VARCHAR(20)
);

-- ------------------------------------------------------------
-- 2. Doctors
-- ------------------------------------------------------------
CREATE TABLE doctors (
    doctor_id INT AUTO_INCREMENT PRIMARY KEY,
    department_id INT NOT NULL,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    specialization VARCHAR(120) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(150) UNIQUE,
    consultation_fee DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT chk_doctor_fee CHECK (consultation_fee >= 0),
    CONSTRAINT fk_doctors_department
        FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- ------------------------------------------------------------
-- 3. Patients
-- Store only the information needed for this demonstration project.
-- ------------------------------------------------------------
CREATE TABLE patients (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    date_of_birth DATE,
    gender ENUM('Female', 'Male', 'Other', 'Prefer not to say')
        NOT NULL DEFAULT 'Prefer not to say',
    phone VARCHAR(20),
    email VARCHAR(150) UNIQUE,
    address VARCHAR(255),
    emergency_contact VARCHAR(100),
    emergency_phone VARCHAR(20),
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ------------------------------------------------------------
-- 4. Appointments
-- ------------------------------------------------------------
CREATE TABLE appointments (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_datetime DATETIME NOT NULL,
    reason VARCHAR(255),
    appointment_status ENUM(
        'Scheduled', 'Completed', 'Cancelled', 'No-Show'
    ) NOT NULL DEFAULT 'Scheduled',
    notes VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_appointments_patient
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    CONSTRAINT fk_appointments_doctor
        FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id),
    INDEX idx_appointment_datetime (appointment_datetime),
    INDEX idx_appointment_status (appointment_status)
);

-- ------------------------------------------------------------
-- 5. Admissions
-- discharge_date is NULL while the patient is still admitted.
-- ------------------------------------------------------------
CREATE TABLE admissions (
    admission_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    attending_doctor_id INT NOT NULL,
    admission_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    discharge_date DATETIME NULL,
    room_number VARCHAR(20),
    bed_number VARCHAR(20),
    admission_reason VARCHAR(255) NOT NULL,
    admission_status ENUM('Admitted', 'Discharged', 'Transferred')
        NOT NULL DEFAULT 'Admitted',
    discharge_notes VARCHAR(500),
    CONSTRAINT chk_admission_dates CHECK (
        discharge_date IS NULL OR discharge_date >= admission_date
    ),
    CONSTRAINT fk_admissions_patient
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    CONSTRAINT fk_admissions_doctor
        FOREIGN KEY (attending_doctor_id) REFERENCES doctors(doctor_id),
    INDEX idx_admission_status (admission_status)
);

-- ------------------------------------------------------------
-- 6. Prescriptions
-- This is a demonstration record, not a clinical decision system.
-- ------------------------------------------------------------
CREATE TABLE prescriptions (
    prescription_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    medicine_name VARCHAR(150) NOT NULL,
    dosage VARCHAR(100) NOT NULL,
    frequency VARCHAR(100),
    duration_days INT,
    instructions VARCHAR(500),
    prescribed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_prescription_duration CHECK (
        duration_days IS NULL OR duration_days > 0
    ),
    CONSTRAINT fk_prescriptions_appointment
        FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id),
    CONSTRAINT fk_prescriptions_patient
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    CONSTRAINT fk_prescriptions_doctor
        FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id)
);

-- ------------------------------------------------------------
-- 7. Bills
-- A bill can optionally be associated with an admission.
-- ------------------------------------------------------------
CREATE TABLE bills (
    bill_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    appointment_id INT NULL,
    admission_id INT NULL,
    bill_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description VARCHAR(255) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    bill_status ENUM('Unpaid', 'Partially Paid', 'Paid', 'Cancelled')
        NOT NULL DEFAULT 'Unpaid',
    CONSTRAINT chk_bill_amount CHECK (amount >= 0),
    CONSTRAINT fk_bills_patient
        FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    CONSTRAINT fk_bills_appointment
        FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
        ON DELETE SET NULL,
    CONSTRAINT fk_bills_admission
        FOREIGN KEY (admission_id) REFERENCES admissions(admission_id)
        ON DELETE SET NULL,
    INDEX idx_bills_status (bill_status)
);

-- ------------------------------------------------------------
-- 8. Payments
-- Payment entries record individual payments against a bill.
-- ------------------------------------------------------------
CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    bill_id INT NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    amount_paid DECIMAL(12,2) NOT NULL,
    payment_method ENUM('Cash', 'Card', 'UPI', 'Bank Transfer', 'Other')
        NOT NULL DEFAULT 'Other',
    transaction_reference VARCHAR(100) UNIQUE,
    payment_notes VARCHAR(255),
    CONSTRAINT chk_payment_amount CHECK (amount_paid > 0),
    CONSTRAINT fk_payments_bill
        FOREIGN KEY (bill_id) REFERENCES bills(bill_id)
        ON DELETE CASCADE,
    INDEX idx_payment_date (payment_date)
);

-- ------------------------------------------------------------
-- 9. Sample departments
-- ------------------------------------------------------------
INSERT INTO departments (department_name, location, phone) VALUES
('General Medicine', 'Block A, Floor 1', '040-40001001'),
('Cardiology', 'Block B, Floor 2', '040-40001002'),
('Orthopedics', 'Block C, Floor 1', '040-40001003'),
('Pediatrics', 'Block A, Floor 2', '040-40001004');

-- ------------------------------------------------------------
-- 10. Sample doctors
-- ------------------------------------------------------------
INSERT INTO doctors
(department_id, first_name, last_name, specialization, phone, email,
 consultation_fee) VALUES
(1, 'Anil', 'Sharma', 'General Physician', '9000001001',
 'anil.sharma@example.com', 500.00),
(2, 'Meera', 'Rao', 'Cardiologist', '9000001002',
 'meera.rao@example.com', 900.00),
(3, 'Kiran', 'Reddy', 'Orthopedic Specialist', '9000001003',
 'kiran.reddy@example.com', 700.00),
(4, 'Divya', 'Nair', 'Pediatrician', '9000001004',
 'divya.nair@example.com', 600.00);

-- ------------------------------------------------------------
-- 11. Sample patients (fictional demonstration records)
-- ------------------------------------------------------------
INSERT INTO patients
(first_name, last_name, date_of_birth, gender, phone, email, address,
 emergency_contact, emergency_phone) VALUES
('Aarav', 'Kumar', '2002-04-15', 'Male', '9100000001',
 'aarav.kumar@example.com', '12 Lake Road, Hyderabad',
 'Ravi Kumar', '9100000101'),
('Sana', 'Begum', '1998-11-02', 'Female', '9100000002',
 'sana.begum@example.com', '24 Park Street, Hyderabad',
 'Nazia Begum', '9100000102'),
('Rahul', 'Patel', '1985-07-20', 'Male', '9100000003',
 'rahul.patel@example.com', '8 Market Road, Secunderabad',
 'Amit Patel', '9100000103'),
('Ananya', 'Das', '2015-02-10', 'Female', '9100000004',
 'ananya.das@example.com', '6 Garden Lane, Hyderabad',
 'Priya Das', '9100000104');

-- ------------------------------------------------------------
-- 12. Sample appointments
-- ------------------------------------------------------------
INSERT INTO appointments
(patient_id, doctor_id, appointment_datetime, reason,
 appointment_status, notes) VALUES
(1, 1, '2026-09-10 09:30:00', 'Routine health check-up',
 'Completed', 'Routine visit completed'),
(2, 2, '2026-09-15 11:00:00', 'Cardiology consultation',
 'Completed', 'Follow-up advised'),
(3, 3, '2026-10-15 14:00:00', 'Knee pain assessment',
 'Scheduled', 'Bring previous reports'),
(4, 4, '2026-10-18 10:30:00', 'Child wellness visit',
 'Scheduled', NULL);

-- ------------------------------------------------------------
-- 13. Sample admissions
-- ------------------------------------------------------------
INSERT INTO admissions
(patient_id, attending_doctor_id, admission_date, discharge_date,
 room_number, bed_number, admission_reason, admission_status,
 discharge_notes) VALUES
(1, 1, '2026-09-10 12:00:00', '2026-09-11 10:00:00',
 'A101', 'A101-1', 'Observation after check-up', 'Discharged',
 'Discharged after observation'),
(3, 3, '2026-10-09 08:00:00', NULL,
 'C204', 'C204-2', 'Orthopedic evaluation', 'Admitted', NULL);

-- ------------------------------------------------------------
-- 14. Sample prescriptions
-- Example entries only; not medical advice.
-- ------------------------------------------------------------
INSERT INTO prescriptions
(appointment_id, patient_id, doctor_id, medicine_name, dosage,
 frequency, duration_days, instructions) VALUES
(1, 1, 1, 'Example Medicine A', 'As recorded by clinician',
 'As directed by clinician', 3, 'Demonstration data only'),
(2, 2, 2, 'Example Medicine B', 'As recorded by clinician',
 'As directed by clinician', 5, 'Demonstration data only');

-- ------------------------------------------------------------
-- 15. Sample bills
-- ------------------------------------------------------------
INSERT INTO bills
(patient_id, appointment_id, admission_id, description, amount, bill_status)
VALUES
(1, 1, 1, 'Consultation and observation', 1200.00, 'Unpaid'),
(2, 2, NULL, 'Cardiology consultation', 900.00, 'Unpaid'),
(3, 3, 2, 'Orthopedic evaluation', 2500.00, 'Unpaid'),
(4, 4, NULL, 'Pediatric consultation', 600.00, 'Unpaid');

-- ------------------------------------------------------------
-- 16. Sample payments
-- ------------------------------------------------------------
INSERT INTO payments
(bill_id, amount_paid, payment_method, transaction_reference, payment_notes)
VALUES
(1, 500.00, 'UPI', 'DEMO-PAY-0001', 'Partial demonstration payment'),
(2, 900.00, 'Card', 'DEMO-PAY-0002', 'Demonstration payment');

-- ------------------------------------------------------------
-- 17. Views
-- ------------------------------------------------------------

-- Patient appointments with doctor and department details.
CREATE VIEW patient_visit_history AS
SELECT
    a.appointment_id,
    a.appointment_datetime,
    a.appointment_status,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    d.specialization,
    dep.department_name,
    a.reason
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
JOIN doctors d ON a.doctor_id = d.doctor_id
JOIN departments dep ON d.department_id = dep.department_id;

-- Admissions where discharge has not yet been recorded.
CREATE VIEW active_admissions AS
SELECT
    ad.admission_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    CONCAT(d.first_name, ' ', d.last_name) AS attending_doctor,
    ad.admission_date,
    ad.room_number,
    ad.bed_number,
    ad.admission_reason,
    ad.admission_status
FROM admissions ad
JOIN patients p ON ad.patient_id = p.patient_id
JOIN doctors d ON ad.attending_doctor_id = d.doctor_id
WHERE ad.admission_status = 'Admitted'
  AND ad.discharge_date IS NULL;

-- Bill balance is amount due minus all recorded payments.
CREATE VIEW outstanding_bills AS
SELECT
    b.bill_id,
    b.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    b.description,
    b.amount AS bill_amount,
    COALESCE(SUM(pay.amount_paid), 0.00) AS amount_paid,
    GREATEST(b.amount - COALESCE(SUM(pay.amount_paid), 0.00), 0.00)
        AS balance_due,
    b.bill_status
FROM bills b
JOIN patients p ON b.patient_id = p.patient_id
LEFT JOIN payments pay ON b.bill_id = pay.bill_id
WHERE b.bill_status <> 'Cancelled'
GROUP BY b.bill_id, b.patient_id, p.first_name, p.last_name,
         b.description, b.amount, b.bill_status
HAVING balance_due > 0;

-- Appointment counts by doctor.
CREATE VIEW doctor_appointment_summary AS
SELECT
    d.doctor_id,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    d.specialization,
    dep.department_name,
    COUNT(a.appointment_id) AS total_appointments,
    SUM(CASE WHEN a.appointment_status = 'Completed' THEN 1 ELSE 0 END)
        AS completed_appointments,
    SUM(CASE WHEN a.appointment_status = 'Scheduled' THEN 1 ELSE 0 END)
        AS scheduled_appointments
FROM doctors d
JOIN departments dep ON d.department_id = dep.department_id
LEFT JOIN appointments a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.first_name, d.last_name,
         d.specialization, dep.department_name;

-- ------------------------------------------------------------
-- 18. Stored procedures
-- ------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE search_patients(IN p_keyword VARCHAR(100))
BEGIN
    SELECT
        patient_id,
        first_name,
        last_name,
        phone,
        email
    FROM patients
    WHERE first_name LIKE CONCAT('%', p_keyword, '%')
       OR last_name LIKE CONCAT('%', p_keyword, '%')
       OR phone LIKE CONCAT('%', p_keyword, '%')
    ORDER BY last_name, first_name;
END$$

CREATE PROCEDURE schedule_appointment(
    IN p_patient_id INT,
    IN p_doctor_id INT,
    IN p_datetime DATETIME,
    IN p_reason VARCHAR(255)
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM patients WHERE patient_id = p_patient_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Patient does not exist';
    ELSEIF NOT EXISTS (
        SELECT 1 FROM doctors
        WHERE doctor_id = p_doctor_id AND is_active = TRUE
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Doctor does not exist or is inactive';
    ELSEIF p_datetime IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Appointment date and time are required';
    ELSE
        INSERT INTO appointments
            (patient_id, doctor_id, appointment_datetime, reason)
        VALUES
            (p_patient_id, p_doctor_id, p_datetime, p_reason);

        SELECT LAST_INSERT_ID() AS new_appointment_id;
    END IF;
END$$

CREATE PROCEDURE record_payment(
    IN p_bill_id INT,
    IN p_amount DECIMAL(12,2),
    IN p_method VARCHAR(30),
    IN p_reference VARCHAR(100)
)
BEGIN
    DECLARE v_bill_amount DECIMAL(12,2);
    DECLARE v_paid_amount DECIMAL(12,2);
    DECLARE v_bill_status VARCHAR(20);

    IF p_amount IS NULL OR p_amount <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Payment amount must be greater than zero';
    END IF;

    SELECT amount, bill_status
    INTO v_bill_amount, v_bill_status
    FROM bills
    WHERE bill_id = p_bill_id;

    IF v_bill_amount IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Bill does not exist';
    ELSEIF v_bill_status = 'Cancelled' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot pay a cancelled bill';
    END IF;

    SELECT COALESCE(SUM(amount_paid), 0.00)
    INTO v_paid_amount
    FROM payments
    WHERE bill_id = p_bill_id;

    IF v_paid_amount + p_amount > v_bill_amount THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Payment exceeds the remaining bill balance';
    END IF;

    INSERT INTO payments
        (bill_id, amount_paid, payment_method, transaction_reference)
    VALUES
        (p_bill_id, p_amount, p_method, p_reference);

    SET v_paid_amount = v_paid_amount + p_amount;

    UPDATE bills
    SET bill_status = CASE
        WHEN v_paid_amount >= v_bill_amount THEN 'Paid'
        WHEN v_paid_amount > 0 THEN 'Partially Paid'
        ELSE 'Unpaid'
    END
    WHERE bill_id = p_bill_id;

    SELECT p_bill_id AS bill_id,
           v_bill_amount AS bill_amount,
           v_paid_amount AS total_paid,
           GREATEST(v_bill_amount - v_paid_amount, 0.00) AS balance_due;
END$$

DELIMITER ;

-- ============================================================
-- 19. Example queries
-- Run these individually after executing the setup script.
-- ============================================================

-- View all patients:
-- SELECT * FROM patients ORDER BY patient_id;

-- View all doctors and their departments:
-- SELECT d.doctor_id, CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
--        d.specialization, dep.department_name, d.consultation_fee
-- FROM doctors d
-- JOIN departments dep ON d.department_id = dep.department_id;

-- View appointment history:
-- SELECT * FROM patient_visit_history ORDER BY appointment_datetime DESC;

-- Find upcoming scheduled appointments:
-- SELECT * FROM patient_visit_history
-- WHERE appointment_status = 'Scheduled'
-- ORDER BY appointment_datetime;

-- View currently admitted patients:
-- SELECT * FROM active_admissions;

-- View unpaid or partially paid balances:
-- SELECT * FROM outstanding_bills ORDER BY balance_due DESC;

-- View appointment counts by doctor:
-- SELECT * FROM doctor_appointment_summary ORDER BY total_appointments DESC;

-- Count patients by gender:
-- SELECT gender, COUNT(*) AS patient_count
-- FROM patients GROUP BY gender;

-- Total billed, paid, and outstanding amounts:
-- SELECT
--     (SELECT COALESCE(SUM(amount), 0) FROM bills
--      WHERE bill_status <> 'Cancelled') AS total_billed,
--     (SELECT COALESCE(SUM(amount_paid), 0) FROM payments) AS total_paid,
--     (SELECT COALESCE(SUM(balance_due), 0) FROM outstanding_bills)
--         AS total_outstanding;

-- Search for patients with the name or phone number:
-- CALL search_patients('Aarav');

-- Schedule an appointment:
-- CALL schedule_appointment(1, 1, '2026-11-10 10:00:00',
--                           'Routine follow-up');

-- Record a payment (use a unique transaction reference):
-- CALL record_payment(1, 700.00, 'UPI', 'DEMO-PAY-0003');

-- View all payments for a bill:
-- SELECT b.bill_id, b.description, pay.payment_date, pay.amount_paid,
--        pay.payment_method, pay.transaction_reference
-- FROM bills b
-- JOIN payments pay ON b.bill_id = pay.bill_id
-- ORDER BY b.bill_id, pay.payment_date;

-- End of Hospital Patient Tracker SQL script.
