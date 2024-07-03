-- Clase 20240702 - Consultas

-- Vistas

select * from classicmodels.pbi_pedidos
select * from classicmodels.pbi_productos
select * from classicmodels.pbi_time_shipping

select  * from classicmodels.pbi_order_status order by 1

select * from classicmodels.pbi_orders_payments


-- Explicación recursividad

-- Imaginemos que creamos la tabla jerarquia con aquellos empleados que no tienen jefe (solo 1 registro, el presidente)
create table sandbox.jerarquia as
(
  select employeenumber,
           reportsto as managernumber,
           cast(null as char(50)) as managertitle,
           cast(null as char(50)) as managerofficecode,
           officecode, 
           jobTitle,
           1 nivel
   from classicmodels.employees
   where reportsto is null
)

-- Sloo aparece un registro
select * from sandbox.jerarquia;


-- Ahora hacemos una consulta de todos los empleados cuyo jefe está en la tabla jerarquía recien creada 
     select e.employeenumber,
            e.reportsto,
            ep.jobTitle,
            ep.officecode,
            e.officecode,
            e.jobTitle,
            nivel+1
     from employees e
     inner join sandbox.jerarquia ep on e.reportsto = ep.employeenumber

-- Lo que hace la siguiente inserción es añadir, nivel a nivel, a los empleados cuyo jefe está en la tabla jerarquía (siempre y cuando el empleado no haya sido ya añadido)  
-- Añadimos los dos vicepresidentes que dependen del presidente
insert into sandbox.jerarquia
     select e.employeenumber,
            e.reportsto,
            ep.jobTitle,
            ep.officecode,
            e.officecode,
            e.jobTitle,
            nivel+1
     from employees e
     inner join sandbox.jerarquia ep on e.reportsto = ep.employeenumber
     where e.employeenumber not in (select employeenumber from sandbox.jerarquia)


select * from sandbox.jerarquia;



-- La alternativa a todo lo que hemos visto antes es hacer una consulta recursiva. Esto se hace empleando una CTE (common table espression con la palabra reservada RECURSIVE)
with recursive jerarquia_empleados as
  ( 
  
  select employeenumber,
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
select * from jerarquia_empleados;



select * from classicmodels.calendario;


-- Planta 
select * from planta where customerNumber = 363;

select fecha, count(*) clientes from planta group by 1 order by 1

select * from orders where customerNumber = 363

-- Movimientos
select * from movimientos

-- Churn rate
select * from classicmodels.pbi_churn