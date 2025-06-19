
-- README SECTION (Do not remove)
-- DevifyX Assignment: Data Backup Scheduler using MySQL only
-- Author: Vamsi Vemula
-- Description: This SQL script creates a backup scheduling system using MySQL only. It includes all required tables,
-- procedures, and an event scheduler to simulate automated backups.
-- Instructions:
-- 1. Create a database in phpMyAdmin (e.g., backup_scheduler)
-- 2. Import this SQL file in the SQL tab or Import section
-- 3. Tables will be created and sample data will be inserted

-- ---------------------------------------------
-- TABLES
-- ---------------------------------------------

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    role ENUM('admin', 'operator', 'viewer') DEFAULT 'viewer'
);

CREATE TABLE backup_targets (
    target_id INT AUTO_INCREMENT PRIMARY KEY,
    target_type ENUM('file', 'database') NOT NULL,
    target_value VARCHAR(255) NOT NULL
);

CREATE TABLE backup_jobs (
    job_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    target_id INT,
    schedule_type ENUM('daily', 'weekly', 'monthly', 'custom'),
    interval_minutes INT,
    is_active BOOLEAN DEFAULT TRUE,
    last_run DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (target_id) REFERENCES backup_targets(target_id)
);

CREATE TABLE backup_history (
    history_id INT AUTO_INCREMENT PRIMARY KEY,
    job_id INT,
    run_time DATETIME,
    status ENUM('success', 'failure'),
    details TEXT,
    FOREIGN KEY (job_id) REFERENCES backup_jobs(job_id)
);

CREATE TABLE error_logs (
    error_id INT AUTO_INCREMENT PRIMARY KEY,
    job_id INT,
    error_time DATETIME,
    error_message TEXT,
    FOREIGN KEY (job_id) REFERENCES backup_jobs(job_id)
);

CREATE TABLE retention_policies (
    policy_id INT AUTO_INCREMENT PRIMARY KEY,
    job_id INT,
    keep_last_n INT DEFAULT NULL,
    delete_older_than_days INT DEFAULT NULL,
    FOREIGN KEY (job_id) REFERENCES backup_jobs(job_id)
);

-- ---------------------------------------------
-- SAMPLE DATA
-- ---------------------------------------------

INSERT INTO users (username, email, role) VALUES ('vamsi', 'vamsi@example.com', 'admin');
INSERT INTO backup_targets (target_type, target_value) VALUES ('database', 'student_db');
INSERT INTO backup_jobs (user_id, target_id, schedule_type, interval_minutes)
VALUES (1, 1, 'daily', NULL);

-- ---------------------------------------------
-- PROCEDURE TO SIMULATE BACKUP
-- ---------------------------------------------

DELIMITER //
CREATE PROCEDURE RunBackup(IN job INT)
BEGIN
    DECLARE now_time DATETIME;
    SET now_time = NOW();

    INSERT INTO backup_history (job_id, run_time, status, details)
    VALUES (job, now_time, 'success', CONCAT('Backup completed at ', now_time));

    UPDATE backup_jobs SET last_run = now_time WHERE job_id = job;
END;
//
DELIMITER ;

-- ---------------------------------------------
-- EVENT TO AUTOMATE BACKUPS
-- ---------------------------------------------

SET GLOBAL event_scheduler = ON;

CREATE EVENT IF NOT EXISTS run_all_backups
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE current_job INT;
    DECLARE job_cursor CURSOR FOR 
        SELECT job_id FROM backup_jobs WHERE is_active = TRUE;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN job_cursor;
    read_loop: LOOP
        FETCH job_cursor INTO current_job;
        IF done THEN
            LEAVE read_loop;
        END IF;
        CALL RunBackup(current_job);
    END LOOP;
    CLOSE job_cursor;
END;
