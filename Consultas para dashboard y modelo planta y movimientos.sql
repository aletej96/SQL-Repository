
use classicmodels;

/*

-- Vista de pedidos con datos adicionales: importe del pedido y comercial asociado al cliente

create or replace view classicmodels.orders_amount as (
select 
pedidos.*,
importes.totalAmount,
clientes.salesRepEmployeeNumber as employeeNumber

from classicmodels.orders pedidos
left join (
	select 
	o.orderNumber,
	sum(quantityOrdered*priceEach) as totalAmount
	from classicmodels.orderdetails o 
	group by 1
	order by 2 desc) importes
on pedidos.orderNumber=importes.orderNumber	

left join classicmodels.customers clientes
on pedidos.customerNumber=clientes.customerNumber 
);
*/


-- PEDIDOS por fecha, estado, ciudad de cliente y empleado y cargo superior

create view classicmodels.pbi_pedidos as (

select 
base.orderDate as fecha_pedido,
year(base.orderDate) as anno_pedido,
month(base.orderDate) as mes_pedido,
DATE_FORMAT(base.orderDate,'%Y-%m') as anno_mes_pedido, -- 2004-01
base.status, 
clientes.city as ciudad_cliente,
clientes.country as pais_cliente,
concat(empleados.Firstname,' ',empleados.LastName)as Nombre_empleado,
base.employeeNumber,
oficinas.city as ciudad_oficina,
oficinas.country as pais_oficina,
superior.jobTitle as cargo_superior,
count(*) as pedidos,
sum(base.totalAmount) as importe

from classicmodels.orders_amount base

left join classicmodels.customers clientes 
on base.customerNumber=clientes.customerNumber 

left join classicmodels.employees empleados 
on base.employeeNumber=empleados.employeeNumber 

left join classicmodels.offices oficinas 
on empleados.officeCode=oficinas.officeCode 

left join classicmodels.employees superior 
on empleados.reportsTo=superior.employeeNumber 

group by 1,2,3,4,5,6,7,8,9,10,11,12);

-- PRODUCTOS por fecha, ciudad de cliente, empleado, superior y linea de producto

create view classicmodels.pbi_productos as (
SELECT 
base.orderDate as fx_pedido,
DATE_FORMAT(base.orderDate,'%Y-%m') as fx_anno_mes_pedido,
clientes.city as ciudad_cliente,
clientes.country as pais_cliente,
empleados.employeeNumber,
concat(empleados.Firstname,' ',empleados.LastName)as Nombre_empleado,
oficinas.city as ciudad_empleado,
oficinas.country as pais_empleado,
superior.jobTitle as cargo_superior,
productos.productcode as codigo_producto,
productos.productName as nombre_producto,
productos.productLine as linea_producto,
sum(detalle.quantityOrdered) as unidades,
sum(detalle.quantityOrdered*detalle.priceEach) as importe_venta,
sum(detalle.quantityOrdered*productos.buyprice) as importe_compra,
sum(detalle.quantityOrdered*detalle.priceEach) - sum(detalle.quantityOrdered*productos.buyprice) as margen

from classicmodels.orders base

left join classicmodels.orderdetails detalle
on base.orderNumber=detalle.orderNumber 

left join classicmodels.products productos
on detalle.productCode=productos.productCode 

left join classicmodels.customers clientes 
on base.customerNumber=clientes.customerNumber 

left join classicmodels.employees empleados 
on clientes.salesRepEmployeeNumber=empleados.employeeNumber 

left join classicmodels.offices oficinas 
on empleados.officeCode=oficinas.officeCode 


left join classicmodels.employees superior
on empleados.reportsTo=superior.employeeNumber 

group by 1,2,3,4,5,6,7,8,9,10,11,12);


-- ENVIO - Tiempo medio de preparacion (entre pedido y envio)
create view classicmodels.pbi_time_shipping as (

select 
DATE_FORMAT(base.orderDate,'%Y-%m') as anno_mes_pedido, 
sum(datediff(base.shippedDate,base.orderDate))/count(*) as dias_medio_preparacion 
from classicmodels.orders_amount base
where status ='Shipped'
group by 1

);

-- ENVIO - Pedidos por estado y mes
create view classicmodels.pbi_order_status as (

select 
DATE_FORMAT(base.orderDate,'%Y-%m') as anno_mes_pedido,
count(*) as ca_pedidos,
sum(case when base.status='Shipped' then 1 else 0 end) as ca_shipped,
sum(case when base.status='In Process' then 1 else 0 end) as ca_process,
sum(case when base.status='Cancelled' then 1 else 0 end) as ca_cancelled,
sum(case when base.status not in ('Cancelled','In Process','Shipped') then 1 else 0 end) as ca_resto_estados
from classicmodels.orders_amount base
group by 1);


-- INGRESOS vs IMPORTE PEDIDOS mensual

create view classicmodels.pbi_orders_payments as (
select 
anno_mes,
sum(importe_pedidos) as importe_pedidos,
sum(ingresos) as ingresos
from
(
	select 
	
	DATE_FORMAT(base.orderDate,'%Y-%m') as anno_mes,
	sum(base.totalAmount) as importe_pedidos,
	cast(0 as dec) as ingresos
	from classicmodels.orders_amount base
	where base.status <>'Cancelled'
	group by 1
	
	union
	
	select 
	
	DATE_FORMAT(base.paymentDate,'%Y-%m') as anno_mes,
	0 as importe_pedidos,
	sum(base.amount) as ingresos
	from classicmodels.payments base
	group by 1
) tabla
group by 1
order by 1
);

-- EMPLEADOS Y JERARQUIA
create view classicmodels.pbi_employee_hierarchy as (
with recursive jerarquia_empleados as
  ( select employeenumber,
           reportsto as managernumber,
           cast(null as char(50)) as managertitle,
           cast(null as char(50)) as managerofficecode,
           officecode, 
           jobTitle,
           1 nivel
   from classicmodels.employees
   where reportsto is null
     union all
     select e.employeenumber,
            e.reportsto,
            ep.jobTitle,
            ep.officecode,
            e.officecode,
            e.jobTitle,
            nivel+1
     from employees e
     inner join jerarquia_empleados ep on ep.employeenumber = e.reportsto  /* Para cada empleado busca si hay alguno del cual es su superior*/
/*No hace falta condicion de parada porque parará cuando un empleado no tenga colaboradores a su cargo*/
)
select empleados.employeenumber,
       empleados.nivel,
       empleados.jobTitle,
       oficinas.city,
       empleados.managernumber,
       empleados.managerTitle,
       oficinas_mng.city as managercity
from jerarquia_empleados empleados
inner join offices oficinas 
on empleados.officeCode=oficinas.officeCode 
left join offices oficinas_mng
on empleados.managerofficeCode=oficinas_mng.officeCode 
order by empleados.nivel, oficinas.city);


-- VISTAS PARA EL MODELO DE PLANTA Y MOVIMIENTOS


/*
 * 
 * 
 *
 *
 *
set @@cte_max_recursion_depth = 10000;

create table classicmodels.calendario as (

with recursive cte_calendario as (
	select date('2003-01-01') as calendar_date -- fecha de inicio
	union all
	select date_add(calendar_date, interval 1 day) as calendar_date from cte_calendario 
	where year(date_add(calendar_date, interval 1 day)) <= 2025 -- condicion de fin, fecha final
)

select
calendar_date as fecha,
year(calendar_date) as fx_anno,
month(calendar_date) as fx_mes,
day(calendar_date) as fx_day,
date_format(calendar_date, '%Y%m') as fx_anno_mes,
date_format(calendar_Date,'%x-%v') as semana -- formato 
from cte_calendario

);


 * 
 */

-- Para calcular planta cruzamos los pedidos con el calendario con las condiciones de filtrado de fecha

create or replace view planta as (
SELECT 
calendario.fecha,
pedidos.customerNumber,
count(*) as ca_pedidos,
sum(pedidos.totalAmount) as importe,
case when sum(pedidos.totalAmount)<30000 then '1.) Plata'
when sum(pedidos.totalAmount)<50000 then '2.) Oro'
when sum(pedidos.totalAmount)>=50000 then '3.) Platino'
end as tipo_cliente

from classicmodels.orders_amount pedidos

inner join classicmodels.calendario calendario 
on pedidos.orderDate between DATE_add(calendario.fecha,interval -60 day) and calendario.fecha  

where calendario.fecha between str_to_date('2003-01-01','%Y-%m-%d') and str_to_date('2005-05-31','%Y-%m-%d')

group by 1,2
);

-- Para calcular altas y bajas cruzamos por cliente con el día anterior para ver si hay cambios (si está al día anterior y el no en el actual es una baja, y al reves es un alta)

create or replace view movimientos as 
select 
'Alta' as tipo_movimiento,
actual.fecha as fecha_movimiento,
actual.customerNumber

from classicmodels.planta actual
left join classicmodels.planta ayer
on actual.customerNumber=ayer.customerNumber
and date_add(actual.fecha,interval -1 day)=ayer.fecha
where ayer.customerNumber is null

union 

select 
'Baja' as tipo_movimiento,
date_add(ayer.fecha,interval 1 day) as fecha_movimiento,
ayer.customerNumber

from classicmodels.planta ayer
left join classicmodels.planta actual
on actual.customerNumber=ayer.customerNumber
and date_add(actual.fecha,interval -1 day)=ayer.fecha
where actual.customerNumber is null;

-- VISTA PBI PLANTA (consideramos planta a clientes que han hecho un pedido en 60 días)

create or replace view classicmodels.pbi_planta as (

select
fecha,
DATE_FORMAT(fecha, '%Y-%m') as mes,
tipo_cliente,
count(*) as ca_clientes
from classicmodels.planta tabla
group by 1,2,3
order by 1,2,3);

-- VISTA PBI MOVIMIENTOS (en base a la planta se calculan movimientos - altas y bajas)

create or replace view classicmodels.pbi_movimientos as (
SELECT 
tipo_movimiento,
fecha_movimiento,
DATE_FORMAT(fecha_movimiento, '%Y-%m') as mes_movimiento,
count(*) as ca_clientes

from classicmodels.movimientos tabla
group by 1,2,3);


-- CHURN RATE

create or replace view classicmodels.pbi_churn as (
select 
planta.mes,
coalesce(bajas.bajas,0)/planta.clientes_medios as churn

from
(
	select 
	DATE_FORMAT(fecha, '%Y-%m') as mes,
	avg(ca_clientes) as clientes_medios
	from classicmodels.pbi_planta
	group by 1
) planta

left join 
(
	select mes_movimiento,
	sum(ca_clientes) as bajas
	from classicmodels.pbi_movimientos
	where tipo_movimiento='Baja'
	group by 1
) bajas
on planta.mes=bajas.mes_movimiento
);