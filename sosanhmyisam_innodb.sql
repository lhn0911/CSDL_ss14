----------------------------------------------------------------------
| Tiêu chí               | MyISAM              | InnoDB               |
----------------------------------------------------------------------
| Hỗ trợ giao dịch       | Không hỗ trợ        | Hỗ trợ đầy đủ        |
----------------------------------------------------------------------
| Khóa                   | Khóa bảng           | Khóa dòng            |
----------------------------------------------------------------------
| Tốc độ                 | Đọc nhanh hơn       | Ghi nhanh hơn        |
----------------------------------------------------------------------
| Khóa ngoại             | Không hỗ trợ        | Hỗ trợ               |
----------------------------------------------------------------------
| Rollback               | Không có            | Có thể rollback      |


-- 1 hỗ trợ giao dịch(ko)
-- myisam
CREATE TABLE orders_myisam (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100),
    amount INT
) ENGINE=MyISAM;

START TRANSACTION;
INSERT INTO orders_myisam (product_name, amount) VALUES ('Laptop', 2);
ROLLBACK; -- Không có tác dụng, dữ liệu vẫn bị lưu vào bảng
SELECT * FROM orders_myisam;
-- innodb(co)
CREATE TABLE orders_innodb (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100),
    amount INT
) ENGINE=InnoDB;

START TRANSACTION;
INSERT INTO orders_innodb (product_name, amount) VALUES ('Laptop', 2);
ROLLBACK; -- Thành công, dữ liệu bị hủy
SELECT * FROM orders_innodb;
-- 2 khoa
-- myisam
CREATE TABLE inventory_myisam (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    stock INT
) ENGINE=MyISAM;

LOCK TABLE inventory_myisam WRITE;
INSERT INTO inventory_myisam (stock) VALUES (100);
UNLOCK TABLES; -- Toàn bộ bảng bị khóa khi INSERT
 -- innodb
 CREATE TABLE inventory_innodb (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    stock INT
) ENGINE=InnoDB;

START TRANSACTION;
UPDATE inventory_innodb SET stock = stock - 1 WHERE product_id = 1;
COMMIT; -- Chỉ khóa dòng có product_id = 1
-- 3 toc do
-- doc du lieu
SELECT * FROM big_table; -- MyISAM nhanh hơn InnoDB với truy vấn SELECT lớn
-- ghi du lieu
INSERT INTO big_table VALUES (...); -- InnoDB nhanh hơn MyISAM khi thực hiện nhiều giao dịch cùng lúc
-- 4 khoa ngoai
-- myisam
CREATE TABLE customers_myisam (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100)
) ENGINE=MyISAM;

CREATE TABLE orders_myisam (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    FOREIGN KEY (customer_id) REFERENCES customers_myisam(customer_id) -- Lỗi!
) ENGINE=MyISAM;
-- innodb
CREATE TABLE customers_innodb (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE orders_innodb (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    FOREIGN KEY (customer_id) REFERENCES customers_innodb(customer_id) ON DELETE CASCADE
) ENGINE=InnoDB;
-- 5 roll back
-- myisam(ko the roll back)
-- innodb
START TRANSACTION;
INSERT INTO orders_innodb (product_name, amount) VALUES ('Phone', 3);
ROLLBACK; -- Xóa dữ liệu vừa chèn
