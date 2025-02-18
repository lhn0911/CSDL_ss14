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

DELIMITER //
CREATE PROCEDURE IncreaseSalary(
    IN emp_id INT,
    IN new_salary DECIMAL(10,2),
    IN reason TEXT
)
BEGIN
    DECLARE old_salary DECIMAL(10,2);
    
    -- Bắt đầu transaction
    START TRANSACTION;
    
    -- Kiểm tra nhân viên có tồn tại hay không
    SELECT base_salary INTO old_salary FROM salaries WHERE employee_id = emp_id;
    
    IF old_salary IS NULL THEN
        -- Nếu nhân viên không tồn tại, rollback và thông báo lỗi
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nhân viên không tồn tại!';
        ROLLBACK;
    ELSE
        -- Lưu lịch sử lương
        INSERT INTO salary_history (employee_id, old_salary, new_salary, reason)
        VALUES (emp_id, old_salary, new_salary, reason);
        
        -- Cập nhật lương mới
        UPDATE salaries SET base_salary = new_salary WHERE employee_id = emp_id;
        
        -- Commit transaction nếu không có lỗi
        COMMIT;
    END IF;
END //
DELIMITER ;

CALL IncreaseSalary(1, 5000.00, 'Tăng lương định kỳ');

DELIMITER //
CREATE PROCEDURE DeleteEmployee(IN emp_id INT)
BEGIN
    DECLARE emp_exists INT;
    
    -- Bắt đầu transaction
    START TRANSACTION;
    
    -- Kiểm tra nhân viên có tồn tại hay không
    SELECT COUNT(*) INTO emp_exists FROM employees WHERE employee_id = emp_id;
    
    IF emp_exists = 0 THEN
        -- Nếu nhân viên không tồn tại, rollback và thông báo lỗi
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nhân viên không tồn tại!';
        ROLLBACK;
    ELSE
        -- Xóa thông tin lương của nhân viên (nếu có)
        DELETE FROM salaries WHERE employee_id = emp_id;
        
        -- Xóa nhân viên
        DELETE FROM employees WHERE employee_id = emp_id;
        
        -- Commit transaction nếu không có lỗi
        COMMIT;
    END IF;
END //
DELIMITER ;

CALL DeleteEmployee(2);