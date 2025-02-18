CREATE DATABASE ss14_first;
USE ss14_first;
-- 1. Bảng customers (Khách hàng)
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Bảng orders (Đơn hàng)
CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2) DEFAULT 0,
    status ENUM('Pending', 'Completed', 'Cancelled') DEFAULT 'Pending',
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);

-- 3. Bảng products (Sản phẩm)
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Bảng order_items (Chi tiết đơn hàng)
CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- 5. Bảng inventory (Kho hàng)
CREATE TABLE inventory (
    product_id INT PRIMARY KEY,
    stock_quantity INT NOT NULL CHECK (stock_quantity >= 0),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

-- 6. Bảng payments (Thanh toán)
CREATE TABLE payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('Credit Card', 'PayPal', 'Bank Transfer', 'Cash') NOT NULL,
    status ENUM('Pending', 'Completed', 'Failed') DEFAULT 'Pending',
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
);

-- Tạo Trigger before_insert_check_payment
DELIMITER //
CREATE TRIGGER before_insert_check_payment
BEFORE INSERT ON payments
FOR EACH ROW
BEGIN
    DECLARE order_total DECIMAL(10,2);
    
    -- Lấy tổng tiền của đơn hàng
    SELECT total_amount INTO order_total FROM orders WHERE order_id = NEW.order_id;
    
    -- Kiểm tra số tiền thanh toán có khớp không
    IF NEW.amount <> order_total THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Số tiền thanh toán không khớp với tổng đơn hàng!';
    END IF;
END //
DELIMITER ;

-- Tạo bảng order_logs
CREATE TABLE order_logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    old_status ENUM('Pending', 'Completed', 'Cancelled'),
    new_status ENUM('Pending', 'Completed', 'Cancelled'),
    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
);

-- Tạo Trigger after_update_order_status
DELIMITER //
CREATE TRIGGER after_update_order_status
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    -- Kiểm tra nếu trạng thái có sự thay đổi
    IF OLD.status <> NEW.status THEN
        INSERT INTO order_logs (order_id, old_status, new_status, log_date)
        VALUES (NEW.order_id, OLD.status, NEW.status, NOW());
    END IF;
END //
DELIMITER ;

-- Tạo Stored Procedure sp_update_order_status_with_payment
DELIMITER //
CREATE PROCEDURE sp_update_order_status_with_payment(
    IN p_order_id INT,
    IN p_new_status ENUM('Pending', 'Completed', 'Cancelled'),
    IN p_amount DECIMAL(10,2),
    IN p_payment_method ENUM('Credit Card', 'PayPal', 'Bank Transfer', 'Cash')
)
BEGIN
    DECLARE current_status ENUM('Pending', 'Completed', 'Cancelled');
    
    -- Bắt đầu transaction
    START TRANSACTION;
    
    -- Lấy trạng thái hiện tại của đơn hàng
    SELECT status INTO current_status FROM orders WHERE order_id = p_order_id;
    
    -- Nếu trạng thái đã giống new_status thì rollback
    IF current_status = p_new_status THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Đơn hàng đã có trạng thái này!';
    END IF;

    -- Nếu trạng thái mới là 'Completed', tiến hành thanh toán
    IF p_new_status = 'Completed' THEN
        INSERT INTO payments (order_id, payment_date, amount, payment_method, status)
        VALUES (p_order_id, NOW(), p_amount, p_payment_method, 'Completed');
    END IF;

    -- Cập nhật trạng thái đơn hàng
    UPDATE orders SET status = p_new_status WHERE order_id = p_order_id;

    -- Nếu không có lỗi, commit transaction
    COMMIT;
END //
DELIMITER ;

-- Thêm khách hàng
INSERT INTO customers (name, email, phone, address) VALUES
('Nguyen Van A', 'a@example.com', '0123456789', 'Hanoi'),
('Tran Thi B', 'b@example.com', '0987654321', 'Ho Chi Minh');

-- Thêm sản phẩm
INSERT INTO products (name, price, description) VALUES
('Laptop', 1500.00, 'High-end laptop'),
('Smartphone', 800.00, 'Latest smartphone');

-- Thêm đơn hàng
INSERT INTO orders (customer_id, total_amount) VALUES
(1, 1500.00),  -- Đơn hàng của Nguyen Van A
(2, 800.00);   -- Đơn hàng của Tran Thi B

-- Gọi Stored Procedure
CALL sp_update_order_status_with_payment(1, 'Completed', 1500.00, 'Credit Card');
CALL sp_update_order_status_with_payment(2, 'Completed', 800.00, 'PayPal');

-- Hiển thị bảng order_logs
SELECT * FROM order_logs;

-- Xóa Trigger trước khi chèn vào payments
DROP TRIGGER IF EXISTS before_insert_check_payment;

-- Xóa Trigger sau khi cập nhật trạng thái đơn hàng
DROP TRIGGER IF EXISTS after_update_order_status;

-- Xóa Stored Procedure
DROP PROCEDURE IF EXISTS sp_update_order_status_with_payment;