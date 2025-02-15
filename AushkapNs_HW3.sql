-- Создаём таблицы для оригинальных таблиц и импортируем в них данные средствами импорта DBeaver
create table transaction_hw3 (transaction_id int
							, product_id int
							, customer_id int
							, transaction_date date
							, online_order boolean
							, order_status varchar(16)
							, brand varchar(128)
							, product_line varchar(16)
							, product_class	varchar(16)
							, product_size varchar(16)
							, list_price numeric(16, 2)
							, standard_cost numeric(16, 2)
)

create table customer_hw3 (customer_id int
						, first_name varchar(64)
						, last_name	varchar(64)
						, gender varchar(64)
						, DOB date
						, job_title	varchar(128)
						, job_industry_category	varchar(128)
						, wealth_segment varchar(64)
						, deceased_indicator varchar(4)
						, owns_car varchar(4)
						, address varchar(512)
						, postcode varchar(32) -- хотя по данным кажется, что это число, но, вообще говоря, почтовый индекс может быть буквами и первый ноль тоже значим
						, state	varchar(64)
						, country varchar(128)
						, property_valuation int

)

select * from customer_hw3
select * from transaction_hw3

-- 1. Вывести распределение (количество) клиентов по сферам деятельности, отсортировав результат по убыванию количества.
select 
	job_industry_category
	, count(distinct customer_id) as customer_count
from customer_hw3
group by job_industry_category
order by customer_count desc

-- 2. Найти сумму транзакций за каждый месяц по сферам деятельности, отсортировав по месяцам и по сфере деятельности.
-- Ограничение на статус транзакции не делаем, так как не требуется в задаче.
select
    to_char(date_trunc('month', t.transaction_date), 'yyyy-mm')  as transaction_month
    , c.job_industry_category
    , sum(t.list_price) as total_transaction
from transaction_hw3 t
left join customer_hw3 c on t.customer_id = c.customer_id
group by date_trunc('month', t.transaction_date), c.job_industry_category
order by date_trunc('month', t.transaction_date), c.job_industry_category

-- 3. Вывести количество онлайн-заказов для всех брендов в рамках подтвержденных заказов клиентов из сферы IT.
select 
    brand
    , count(*) as online_order_count
from transaction_hw3 t
join customer_hw3 c on t.customer_id = c.customer_id
where t.order_status = 'Approved' and c.job_industry_category = 'IT'
group by brand

-- 4. Найти по всем клиентам сумму всех транзакций (list_price), максимум, минимум и количество транзакций, отсортировав результат по убыванию суммы транзакций и количества клиентов. 
-- 	  Выполните двумя способами: используя только group by и используя только оконные функции. Сравните результат.
-- Тут вероятно опечатка в условии задачи, видимо имелось ввиду не "отсортировав результат по убыванию суммы транзакций и количества клиентов", а "отсортировав результат по убыванию суммы транзакций и количества транзакций"
-- Ограничение на статус транзакции не делаем, так как не требуется в задаче.
-- В транзакциях есть один customer_id (клиент), которого нет в customer_hw3. И в customer_hw3 есть customer_id, которых нет в transaction_hw3. В итоговой выборке они есть все.
-- Только group by:
select 
    coalesce(c.customer_id, t.customer_id) as customer_id
    , coalesce(sum(t.list_price), 0) as total
    , coalesce(max(t.list_price), 0) as maximum
    , coalesce(min(t.list_price), 0) as minimum
    , coalesce(count(t.transaction_id), 0) as quantity
from customer_hw3 c
full outer join transaction_hw3 t on c.customer_id = t.customer_id
group by c.customer_id, t.customer_id
order by total desc, quantity desc

-- Только оконные функции:
-- конструкцию with используем для лучшей читаемости запроса
with customer_transactions as (
    select 
        coalesce(c.customer_id, t.customer_id) as customer_id
        , t.transaction_id 
		, t.list_price
    from customer_hw3 c
    full outer join transaction_hw3 t on c.customer_id = t.customer_id)
select distinct
    ct.customer_id
    , coalesce(sum(ct.list_price) over (partition by ct.customer_id), 0) as total
    , coalesce(max(ct.list_price) over (partition by ct.customer_id), 0) as maximum
    , coalesce(min(ct.list_price) over (partition by ct.customer_id), 0) as minimum
    , coalesce(count(ct.transaction_id) over (partition by ct.customer_id), 0) as quantity
from customer_transactions ct
order by total desc, quantity desc

-- Сравниваем результаты запросов, чтобы убедиться, что они совпадают, как и задумывалось.
-- Используем два запроса, так как это удобнее для анализа расхождений.
-- Первая выборака минус вторая:
(
select 
    coalesce(c.customer_id, t.customer_id) as customer_id
    , coalesce(sum(t.list_price), 0) as total
    , coalesce(max(t.list_price), 0) as maximum
    , coalesce(min(t.list_price), 0) as minimum
    , coalesce(count(t.transaction_id), 0) as quantity
from customer_hw3 c
full outer join transaction_hw3 t on c.customer_id = t.customer_id
group by c.customer_id, t.customer_id
order by total desc, quantity desc
)
except
(
with customer_transactions as (
    select 
        coalesce(c.customer_id, t.customer_id) as customer_id
        , t.transaction_id 
		, t.list_price
    from customer_hw3 c
    full outer join transaction_hw3 t on c.customer_id = t.customer_id)
select distinct
    ct.customer_id
    , coalesce(sum(ct.list_price) over (partition by ct.customer_id), 0) as total
    , coalesce(max(ct.list_price) over (partition by ct.customer_id), 0) as maximum
    , coalesce(min(ct.list_price) over (partition by ct.customer_id), 0) as minimum
    , coalesce(count(ct.transaction_id) over (partition by ct.customer_id), 0) as quantity
from customer_transactions ct
order by total desc, quantity desc
)

-- Вторая выборака минус первая:
(
with customer_transactions as (
    select 
        coalesce(c.customer_id, t.customer_id) as customer_id
        , t.transaction_id 
		, t.list_price
    from customer_hw3 c
    full outer join transaction_hw3 t on c.customer_id = t.customer_id)
select distinct
    ct.customer_id
    , coalesce(sum(ct.list_price) over (partition by ct.customer_id), 0) as total
    , coalesce(max(ct.list_price) over (partition by ct.customer_id), 0) as maximum
    , coalesce(min(ct.list_price) over (partition by ct.customer_id), 0) as minimum
    , coalesce(count(ct.transaction_id) over (partition by ct.customer_id), 0) as quantity
from customer_transactions ct
order by total desc, quantity desc
)
except
(
select 
    coalesce(c.customer_id, t.customer_id) as customer_id
    , coalesce(sum(t.list_price), 0) as total
    , coalesce(max(t.list_price), 0) as maximum
    , coalesce(min(t.list_price), 0) as minimum
    , coalesce(count(t.transaction_id), 0) as quantity
from customer_hw3 c
full outer join transaction_hw3 t on c.customer_id = t.customer_id
group by c.customer_id, t.customer_id
order by total desc, quantity desc
)
-- ожидаемо получили пустые результат - расхождений нет

-- 5. Найти имена и фамилии клиентов с минимальной/максимальной суммой транзакций за весь период (сумма транзакций не может быть null). 
-- 	  Напишите отдельные запросы для минимальной и максимальной суммы.
-- Ограничение на статус транзакции не делаем, так как не требуется в задаче.
-- Учитываем, что в транзакциях есть один customer_id (клиент), которого нет в customer_hw3. 
-- Если бы он имел максимальную/минимальную сумму транзакций за весь период, то попал бы в выборку с пустыми значениями имени и фамилии.
-- конструкцию with используем для лучшей читаемости запроса

-- Ищем клиентов с минимальной суммой транзакций
-- Тут учитываем, что в customer_hw3 есть customer_id, которых нет в transaction_hw3.
-- То есть заведомо тут минимальная сумма транзакций равна 0.
with customer_totals as (
    select 
        coalesce(c.customer_id, t.customer_id) as customer_id
        , c.first_name as first_name
        , c.last_name as last_name
        , coalesce(sum(t.list_price) over (partition by c.customer_id, t.customer_id), 0) as total
    from customer_hw3 c
    full outer join transaction_hw3 t on c.customer_id = t.customer_id)
select 
	ct.first_name
	, ct.last_name
	--, ct.total
	--, ct.customer_id
from customer_totals ct
where ct.total = (select min(total) from customer_totals)

-- Тут тоже ищем клиентов с минимальной суммой транзакций, но тут не будем учитывать клиентов без транзакций.
with customer_totals as (
	select 
		t.customer_id as customer_id
		, sum(t.list_price) as total
	from transaction_hw3 t
	group by t.customer_id)
select 
	c.first_name
	, c.last_name
	--, ct.total
	--, ct.customer_id
from customer_totals ct
left join customer_hw3 c on ct.customer_id = c.customer_id
where ct.total = (select min(total) from customer_totals)

-- Ищем клиентов с максимальной суммой транзакций
with customer_totals as (
	select 
		t.customer_id as customer_id
		, sum(t.list_price) as total
	from transaction_hw3 t
	group by t.customer_id)
select 
	c.first_name
	, c.last_name
	--, ct.total
	--, ct.customer_id
from customer_totals ct
left join customer_hw3 c on ct.customer_id = c.customer_id
where ct.total = (select max(total) from customer_totals)

-- Вывести только самые первые транзакции клиентов. Решить с помощью оконных функций.
-- Ограничение на статус транзакции не делаем, так как не требуется в задаче.
-- Выводим только транзакции, то есть клиентов без транзакций в выборке не будет. И в выборке будет транзакция клиента с customer_id, которого нет в customer_hw3. 
-- transaction_date не содержит время, поэтому если у клиента в дате первой транзакции есть несколько транзакций, то самой первой транзакцией будем считать транзакцию с наименьшим id transaction_id в этой дате
select * -- кроме столбцов из transaction_hw3, есть столбец rn (row_number). 
		 -- При желании можно перечислить название необходимых столбцов. Или, чтобы не перечислять столбцы, сделать запрос из transaction_hw3 с transaction_id из подзапроса
from (select 
		t.* 
		, row_number() over (partition by t.customer_id order by t.transaction_date asc, t.transaction_id asc) as rn
      from transaction_hw3 t
    ) where rn = 1


-- Вывести имена, фамилии и профессии клиентов, между транзакциями которых был максимальный интервал (интервал вычисляется в днях).
-- Вариант 1. Тут считаем, что интервал считается между первой транзакцией клиента и последней транзакцией клиента.
-- rigth join используется, так как в таблице транзакций есть клиент, которого нет в таблице customer_hw3. Если бы он оказался с максимальным интервалом, то имя, фамилия, работа были бы пустыми.
with intervals as (
    select 
        t.customer_id
        , min(t.transaction_date) AS first_transaction
        , max(t.transaction_date) AS last_transaction
        , (max(t.transaction_date) - min(t.transaction_date)) AS interval
    from 
        transaction_hw3 t
    group by 
        t.customer_id
), 
customer_max_interval as (
	select 
    	i.customer_id
	from
    	intervals i
	where 
    	i.interval = (select max(interval) from intervals)
)  
select 
    c.first_name
   , c.last_name
   , c.job_title
from customer_hw3 c
right join customer_max_interval cmi on c.customer_id = cmi.customer_id

	
-- Вариант 2. Тут считаем, что интервал считается между любыми двумя соседними по датам транзакциями клиента.
with transaction_lag as (
    select 
        t.customer_id,
        t.transaction_date,
        lag(t.transaction_date) over (partition by t.customer_id order by t.transaction_date) as previous_transaction_date
    from 
        transaction_hw3 t
),
intervals as (
    select 
		tl.customer_id
        , (tl.transaction_date - tl.previous_transaction_date) as interval
    from 
        transaction_lag tl
    where 
        tl.previous_transaction_date is not null
),
customer_max_interval as (
	select 
    	i.customer_id
	from
    	intervals i
	where 
    	i.interval = (select max(interval) from intervals)
)  
select 
    c.first_name
   , c.last_name
   , c.job_title
from customer_hw3 c
right join customer_max_interval cmi on c.customer_id = cmi.customer_id



