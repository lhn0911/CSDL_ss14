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

-- Trigger BEFORE UPDATE để kiểm tra số điện thoại hợp lệ
DELIMITER //
CREATE TRIGGER before_update_employee_phone
BEFORE UPDATE ON employees
FOR EACH ROW
BEGIN
    IF LENGTH(NEW.phone) <> 10 OR NEW.phone NOT REGEXP '^[0-9]+$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Số điện thoại phải có đúng 10 chữ số.';
    END IF;
END;
//
DELIMITER ;

-- Tạo bảng notifications
CREATE TABLE notifications (
    notification_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
);

--  Trigger tự động tạo thông báo khi nhân viên mới được thêm vào
DELIMITER //
CREATE TRIGGER after_insert_employee
AFTER INSERT ON employees
FOR EACH ROW
BEGIN
    INSERT INTO notifications (employee_id, message)
    VALUES (NEW.employee_id, 'Chào mừng');
END;
//
DELIMITER ;

-- Tạo Stored Procedure AddNewEmployeeWithPhone
DELIMITER //
CREATE PROCEDURE AddNewEmployeeWithPhone(
    IN emp_name VARCHAR(255),
    IN emp_email VARCHAR(255),
    IN emp_phone VARCHAR(20),
    IN emp_hire_date DATE,
    IN emp_department_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Lỗi khi thêm nhân viên. Hủy bỏ thao tác.';
    END;

    START TRANSACTION;

    -- Kiểm tra số điện thoại hợp lệ (áp dụng trigger trước đó)
    IF LENGTH(emp_phone) <> 10 OR emp_phone NOT REGEXP '^[0-9]+$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Số điện thoại phải có đúng 10 chữ số.';
    END IF;

    -- Thêm nhân viên mới
    INSERT INTO employees (name, email, phone, hire_date, department_id)
    VALUES (emp_name, emp_email, emp_phone, emp_hire_date, emp_department_id);

    -- Commit giao dịch nếu không có lỗi
    COMMIT;
END;
//
DELIMITER ;

CALL AddNewEmployeeWithPhone('Nguyễn Văn A', 'nguyenvana@example.com', '0123456789', '2024-02-18', 1);