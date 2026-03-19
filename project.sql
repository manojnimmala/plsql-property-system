--Customers
CREATE TABLE customers (
    customer_id NUMBER PRIMARY KEY,
    name VARCHAR2(100)
);

--Properties
CREATE TABLE properties (
    property_id NUMBER PRIMARY KEY,
    unit_name VARCHAR2(50),
    price NUMBER
);


--Sales
CREATE TABLE sales (
    sale_id NUMBER PRIMARY KEY,
    customer_id NUMBER,
    property_id NUMBER,
    sale_date DATE,
    CONSTRAINT fk_customer FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id),
    CONSTRAINT fk_property FOREIGN KEY (property_id)
    REFERENCES properties(property_id)
);

-- Payments
CREATE TABLE payments (
    payment_id NUMBER PRIMARY KEY,
    sale_id NUMBER,
    amount NUMBER,
    payment_date DATE,
    CONSTRAINT fk_sale FOREIGN KEY (sale_id)
    REFERENCES sales(sale_id)
);


--Procedure (Add Payment)
CREATE OR REPLACE PROCEDURE add_payment (
    p_payment_id NUMBER,
    p_sale_id NUMBER,
    p_amount NUMBER
)
IS
BEGIN
    INSERT INTO payments (payment_id, sale_id, amount, payment_date)
    VALUES (p_payment_id, p_sale_id, p_amount, SYSDATE);

    COMMIT;
END;
/

--Function (Total Paid for a Sale)
CREATE OR REPLACE FUNCTION get_total_paid (
    p_sale_id NUMBER
)
RETURN NUMBER
IS
    v_total NUMBER;
BEGIN
    SELECT NVL(SUM(amount), 0)
    INTO v_total
    FROM payments
    WHERE sale_id = p_sale_id;

    RETURN v_total;
END;

--Trigger (Prevent Overpayment)
CREATE OR REPLACE TRIGGER prevent_overpayment
BEFORE INSERT ON payments
FOR EACH ROW
DECLARE
    v_total_paid NUMBER;
    v_price NUMBER;
BEGIN
    -- Get total already paid
    SELECT NVL(SUM(amount), 0)
    INTO v_total_paid
    FROM payments
    WHERE sale_id = :NEW.sale_id;

    -- Get property price
    SELECT p.price
    INTO v_price
    FROM properties p
    JOIN sales s ON p.property_id = s.property_id
    WHERE s.sale_id = :NEW.sale_id;

    -- Check condition
    IF v_total_paid + :NEW.amount > v_price THEN
        RAISE_APPLICATION_ERROR(-20001, 'Payment exceeds property price');
    END IF;
END;

--Pending Payments Report
SELECT c.name, p.unit_name, p.price,
       NVL(SUM(pay.amount), 0) AS total_paid
FROM customers c
JOIN sales s ON c.customer_id = s.customer_id
JOIN properties p ON s.property_id = p.property_id
LEFT JOIN payments pay ON s.sale_id = pay.sale_id
GROUP BY c.name, p.unit_name, p.price
HAVING NVL(SUM(pay.amount), 0) < p.price;


--Checking with duplicate data
insert into customers(customer_id, name) values( 1, 'Manoj Nimmala');
insert into properties values(101, 'A101', 500000);
insert into sales values (1, 1, 101, SYSDATE);

--Checking add_payment 
begin
    add_payment(1, 1, 100000);
end;
/

--shows the all payments
select * from payments;


-- Gives sale ID, Name and Unit Name
select s.sale_id, c.name, p.unit_name from sales s
join customers c on s.customer_id = c.customer_id
join properties p on s.property_id = p.property_id
where s.sale_id = 1;



