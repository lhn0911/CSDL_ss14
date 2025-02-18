CREATE DATABASE ss14_second;
USE ss14_second;
-- 1. Bảng departments (Phòng ban)
CREATE TABLE departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    department_name VARCHAR(255) NOT NULL
);

-- 2. Bảng employees (Nhân viên)
CREATE TABLE employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    hire_date DATE NOT NULL,
    department_id INT NOT NULL,
    FOREIGN KEY (department_id) REFERENCES departments(department_id) ON DELETE CASCADE
);

-- 3. Bảng attendance (Chấm công)
CREATE TABLE attendance (
    attendance_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT NOT NULL,
    check_in_time DATETIME NOT NULL,
    check_out_time DATETIME,
    total_hours DECIMAL(5,2),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
);

-- 4. Bảng salaries (Bảng lương)
CREATE TABLE salaries (
    employee_id INT PRIMARY KEY,
    base_salary DECIMAL(10,2) NOT NULL,
    bonus DECIMAL(10,2) DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
);

-- 5. Bảng salary_history (Lịch sử lương)
CREATE TABLE salary_history (
    history_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT NOT NULL,
    old_salary DECIMAL(10,2),
    new_salary DECIMAL(10,2),
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reason TEXT,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
);

-- Trigger BEFORE INSERT để chỉnh sửa email nếu không có đuôi "@company.com"
DELIMITER //
CREATE TRIGGER before_insert_employee
BEFORE INSERT ON employees
FOR EACH ROW
BEGIN
    IF NEW.email NOT LIKE '%@company.com' THEN
        SET NEW.email = CONCAT(NEW.email, '@company.com');
    END IF;
END;//
DELIMITER ;


-- Trigger AFTER INSERT để thêm lương mặc định cho nhân viên mới
DELIMITER //
CREATE TRIGGER after_insert_employee
AFTER INSERT ON employees
FOR EACH ROW
BEGIN
    INSERT INTO salaries (employee_id, base_salary, bonus)
    VALUES (NEW.employee_id, 10000.00, 0.00);
END;//
DELIMITER ;

-- Trigger AFTER DELETE để lưu lịch sử lương khi nhân viên bị xóa
DELIMITER //
CREATE TRIGGER after_delete_employee
AFTER DELETE ON employees
FOR EACH ROW
BEGIN
    INSERT INTO salary_history (employee_id, old_salary, new_salary, reason)
    VALUES (OLD.employee_id, (SELECT base_salary FROM salaries WHERE employee_id = OLD.employee_id), NULL, 'Nhân viên bị xóa');
END;//
DELIMITER ;

-- Trigger BEFORE UPDATE để cập nhật total_hours khi check_out_time được cập nhật
DELIMITER //
CREATE TRIGGER before_update_attendance
BEFORE UPDATE ON attendance
FOR EACH ROW
BEGIN
    IF NEW.check_out_time IS NOT NULL THEN
        SET NEW.total_hours = TIMESTAMPDIFF(HOUR, NEW.check_in_time, NEW.check_out_time);
    END IF;
END;//
DELIMITER ;

-- Chạy câu lệnh kiểm tra
INSERT INTO departments (department_name) VALUES 
('Phòng Nhân Sự'),
('Phòng Kỹ Thuật');

INSERT INTO employees (name, email, phone, hire_date, department_id)
VALUES ('Nguyễn Văn A', 'nguyenvana', '0987654321', '2024-02-17', 1);

SELECT * FROM employees;

INSERT INTO employees (name, email, phone, hire_date, department_id)
VALUES ('Trần Thị B', 'tranthib@company.com', '0912345678', '2024-02-17', 2);

SELECT * FROM salaries;

INSERT INTO attendance (employee_id, check_in_time)
VALUES (1, '2024-02-17 08:00:00');

UPDATE attendance
SET check_out_time = '2024-02-17 17:00:00'
WHERE employee_id = 1;

SELECT * FROM attendance;