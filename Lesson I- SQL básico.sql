-- ======================================
-- Ejercicios SELECT 
-- ======================================

/*
Selecciona todos los campos de la tabla customers
Selecciona el nombre, la ciudad y el país de todos los clientes
Selecciona el nombre, la línea de productos y el precio de todos los productos
Selecciona el número de pedido y el estado para todos los pedidos realizados en el 
año 2003
Selecciona el número de pedido, el código del producto y el precio unitario para 
todos los productos cuyo precio sea mayor a 50
Selecciona el nombre y el cargo de todos los empleados que trabajan en la oficina 
de París
*/

select * from customers;


select customerName, city, country from customers;

select productName, productLine, MSRP from products p;

-- Selecciona el número de pedido y el estado para todos los pedidos realizados en el año 2003
select 
orderNumber, status 
-- *
from orders o 
where orderDate between '2003-01-01' AND '2003-12-31';

/* Selecciona el número de pedido, el código del producto y el precio unitario para 
todos los productos cuyo precio sea mayor a 50 */

select 
orderNumber, productCode, priceEach
from orderdetails o
where priceEach > 50 ;

/*
Selecciona el nombre y el cargo de todos los empleados que trabajan en la oficina 
de París
*/

-- Lo hacemos en dos pasos
select officeCode from offices o where city = 'Paris';

select firstName, lastName, jobTitle from employees e 
where officeCode = '4';

-- ======================================
-- Ejercicios CASE
-- ======================================
/*	
Selecciona el nombre de los productos y crea un campo con el rango de stock 
(menos de 100, de 100 a 5000 y más de 5000). Utiliza la tabla products
*/
	
select 
productName, quantityInStock,
case
	when quantityInStock < 100 then '01 - Menor que 100'
	when quantityInStock <= 5000 then '02 - Entre 100 y 5000'
	when quantityInStock > 5000 then '03 - Mayor de 5000'
end rango_stock

from products;
	
/*	
Selecciona el número de pedido y el estado del pedido. Si el estado del pedido es "In 
Process", muestra "En proceso". Si el estado del pedido es "On Hold", muestra "En 
espera". Si el estado del pedido es "Shipped", muestra "Enviado". Si el estado del 
pedido es "Resolved", muestra "Resuelto". Utiliza la tabla orders
*/

select
orderNumber, status,
CASE 
	when status = 'In Process' then 'En proceso'
	when status = 'On Hold' then 'En espera'	
	when status = 'Shipped' then 'Enviado'
	when status = 'Resolved' then 'Resuelto'	
	else status
END estado_traducido

from orders o ;


/*
Selecciona los cheques (número de cheque) , su importe y un rango de importe 
(menos de 1000, de 1000 a 20000 y más de 20000)
*/

select 
checkNumber, amount,
case
	when amount < 1000 then '01 - Menor que 1000'
	when amount <= 20000 then '02 - Entre 1000 y 20000'
	when amount > 20000 then '03 - Mayor de 20000'
end rango_importe
from payments p;
