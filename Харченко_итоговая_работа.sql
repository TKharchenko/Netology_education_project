 --1 В каких городах больше одного аэропорта?

-- в запросе используем  оператор where для выбора списка городов. Чтобы определить сколько в городе аэропортов, используем подзапрос. 
-- В подзапросе данные группируем по городам и выводим те, в которых колличество значений больше 1.

select *
from airports a 
where a.city in (
	select a.city 
	from airports a  
	group by a.city
	having count(*) > 1)
order by a.city ;
--выводим через distinct уникальный список городов
select distinct city
from airports a 
where a.city in (
	select a.city 
	from airports a  
	group by a.city
	having count(*) > 1)
order by a.city ;

--2 В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета? 

-- используя подзапрос можно определить модель самолета с максимальная дальность полета через функцию max,
-- выбрать аэропорты через условие where из flights, в которых рейсы осуществляются этой моделью самолета

select f.departure_airport as airport, a1.airport_name  as airport_name
from flights f
join airports a1 on a1.airport_code  = f.departure_airport
where aircraft_code in
	(select a.aircraft_code  
	from aircrafts a
	where a."range" in (select max("range") from aircrafts a ))
group by 1, 2 ;

--можно использавать данные из мат.представления, то это делает запрос более оптимальным

select departure_airport as airport, departure_airport_name as airport_name 
from bookings.routes
where aircraft_code in (
	select a.aircraft_code  
	from aircrafts a
	where a."range" in (select max("range") from aircrafts a ))
group by 1, 2 ;


--3 Вывести 10 рейсов с максимальным временем задержки вылета 

--используем функцию age для вычисления интервала между двумя датами, 
--получаем секунды в интервале через epoch,  extract делим результат на 60 , чтобы получить время задержки в мин
select flight_id, flight_no, f.departure_airport , f.arrival_airport ,f.actual_departure, f.scheduled_departure, 
extract ('epoch' from age (f.actual_departure, f.scheduled_departure ))/60 as late_for_min
from flights f  ;

--в результатчерез функцию limit выводим 10 результатов по сортировке по временем задержки вылета в минутах от наибольшего 
-- в результате видим код аэропорта
select z.flight_id, z.flight_no, z.departure_airport, z.arrival_airport, z.late_for_min, Z.late_for
from ( 
	select flight_id, flight_no, departure_airport, arrival_airport,
	extract ('epoch' from age (f.actual_departure, f.scheduled_departure ))/60 as late_for_min,
	age (f.actual_departure, f.scheduled_departure ) as late_for
	from flights f) z
where late_for_min is not null 
order by late_for_min desc
limit 10 ;

--4 Были ли брони, по которым не были получены посадочные талоны?
--выбирая left объединяем данные таблиц только учитывая имеющиеся данные по броням
--оператором where выводим те билеты, которые не имеют номера посадочного

select b.book_ref, t.ticket_no, bp.boarding_no  
from bookings b 
left join tickets t on b.book_ref =t.book_ref 
left join boarding_passes bp on t.ticket_no = bp.ticket_no 
where bp.boarding_no is null 
order by b.book_ref;

--так как в одной броне может быть несколько билетов, то выбираем уникальные номера бронирования,
--в которых не были получены посадочные
select count(distinct b.book_ref) as "колич броней"
from (
	select b.book_ref, t.ticket_no, bp.boarding_no  
	from bookings b 
	left join tickets t on b.book_ref =t.book_ref 
	left join boarding_passes bp on t.ticket_no = bp.ticket_no 
	where bp.boarding_no is null 
	order by b.book_ref) b;

--если нас интересуют только выполненные рейсы, добавляем условие, где заполнено поле actual_departure
select count(distinct b.book_ref) as "колич броней"
from (
	select b.book_ref, t.ticket_no, bp.boarding_no  
	from bookings b 
	left join tickets t on b.book_ref =t.book_ref 
	left join boarding_passes bp on t.ticket_no = bp.ticket_no 
	left join flights f on  bp.flight_id = f.flight_id 
	where bp.boarding_no is null and f.actual_departure is not null 
	order by b.book_ref) b;

--5 Найдите количество свободных мест для каждого рейса, их % отношение к общему количеству мест в самолете.
--Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый денью
--во вложенных запросах, можно получить количество мест в каждой моделе самолета всего
--посчитав функцией count кол flight_id в таблице boarding_passes, определить количество заполненных мест в определеннном рейсе
select 
f.flight_id,
f.flight_no, 
f.aircraft_code as model,
(select count(*)
	from seats s
	where s.aircraft_code = f.aircraft_code) as col_seats,
(select count(*)
	from boarding_passes bp 
	where bp.flight_id = f.flight_id  ) as board_seats
from flights f 
where f.actual_departure is not null

--создать cte из подзапросыов, чтобы потом к ним обращаться
--данные о вылете следует привести к формату timestamp, чтобы не учитывать час пояс.
--присоеденив таблицу flights, получим только вылетевших пассажиров.
--применив функцию round округлим результат вычислений, данные приведем к типу numeric.
--в результат выведем процетное отношение к общему количеству мест в самолете.
--вывести через оконную функцию суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день
--для группировки добавила функцию date_trunc, чтобы данные по дню получить

with  cte1 as (
	select a1.model as model , s.aircraft_code,  count(s.seat_no)
	from seats s
	join aircrafts a1 on s.aircraft_code = a1.aircraft_code
	group by 1, 2) ,
cte2 as (
	select bp.flight_id,
	f.departure_airport,
	f.actual_departure::timestamp as actual_depart,
	count(bp.boarding_no)
	from boarding_passes bp
	join flights f on f.flight_id = bp.flight_id and f.actual_departure is not null
	group by 1, 2, 3 
	order by 2, 3) 
select 
f.flight_id,
f.flight_no, 
a.airport_name,
cte1.model,
cte2.actual_depart,
(cte1.count - cte2.count) as free_seats,
round((cte1.count - cte2.count) * 100/cte1.count::numeric, 2) as perсent,
cte2.count as board_pas,
sum(cte2.count) over (partition by a.airport_name, date_trunc('day', cte2.actual_depart::date) order by cte2.actual_depart)
from flights f 
join airports a on a.airport_code = f.departure_airport
join cte1 on cte1.aircraft_code = f.aircraft_code 
join cte2 on cte2.flight_id = f.flight_id ;

--6 Найдите процентное соотношение перелетов по типам самолетов от общего количества.
--count flight_id по типу самолета всего рейсов
select aircraft_code,
count(flight_id) as col
from flights f  
group by 1

--или оконной функцией
select distinct f.aircraft_code,
count (flight_id) over (partition by f.aircraft_code) as col
from flights f

--функцией sum получим общее количество рейсов по всем типам  самолетов
select sum(z.col) 
from (
	select aircraft_code,
	count(flight_id) as col
	from flights f  
	group by 1) z ;

-- через вложенный запрос без группировки получаем всего рейсов 
select f.aircraft_code, count(flight_id) as col,
(select 
	count(flight_id)
from flights f   
	)  as sum_col
from flights f   
group by 1 ;

--применив функцию round округлим результат вычислений. При округлении вычисления приведем к типу numeric 
--в результат выведем процетн перелетов по типу самолета в общ кол

select f.aircraft_code,
a.model, 
count(f.flight_id) as col_flight,
round(count(f.flight_id)* 100/(select count(flight_id) from flights f)::numeric, 2) as perсent
from flights f  
join aircrafts a on a.aircraft_code =f.aircraft_code 
group by 1,2
 

--7 Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?
--используем сte для разграничения  стоимости билета эконом и бизнес класса по каждому рейсу
--функцией case сравниваем стоимости билетов по классу в расках одного рейса
--данные взяты из представления flights_v, чтобы вывести названия городов
with cte1 as (
	select flight_id, fare_conditions , amount as e_price 
	from ticket_flights tf
	where fare_conditions = 'Economy'
	group by flight_id, amount , fare_conditions  
	order by flight_id),
cte2 as (
	select flight_id, fare_conditions , amount  as b_price 
	from ticket_flights tf
	where fare_conditions = 'Business'
	group by flight_id, amount , fare_conditions  
	order by flight_id)	
select fv.flight_id, fv.departure_city, fv.arrival_city, e_price, b_price, 
	case 
	when  b_price < e_price then 'да'
	else 'нет'
	end as "Бизнес класс дешевле"
from flights_v fv
join cte1 c1  on c1.flight_id = fv.flight_id 
join cte2 c2  on c2.flight_id = fv.flight_id
order by fv.flight_id  

--в рамках перелета ест несколько вариантов стоимости в эконом классе
--выберем max стоимость перелета в эконом, min в бизнес
with cte1 as (
	select flight_id, fare_conditions , max(amount) as e_price 
	from ticket_flights tf
	where fare_conditions = 'Economy'
	group by flight_id, fare_conditions  
	order by flight_id),
cte2 as (
	select flight_id, fare_conditions , min(amount)  as b_price 
	from ticket_flights tf
	where fare_conditions = 'Business'
	group by flight_id, amount , fare_conditions  
	order by flight_id)	
select fv.flight_id, fv.departure_city, fv.arrival_city, e_price, b_price, 
	case 
	when  b_price < e_price then 'да'
	else 'нет'
	end as "Бизнес класс дешевле"
from flights_v fv
join cte1 c1  on c1.flight_id = fv.flight_id 
join cte2 c2  on c2.flight_id = fv.flight_id
order by fv.flight_id  

--проверка, изменили исходную стоимость билета эконом класса 
select flight_id, fare_conditions , amount as e_price 
	from ticket_flights tf
	where fare_conditions = 'Economy' and flight_id = 1
	group by flight_id, amount , fare_conditions  
	order by flight_id
	
select flight_id, fare_conditions , amount  as b_price 
	from ticket_flights tf
	where fare_conditions = 'Business' and flight_id = 1
	group by flight_id, amount , fare_conditions  
	order by flight_id
	
-- вывести список городов
select z.flight_id, z.departure_city, z.arrival_city, "Бизнес класс дешевле"
from (with cte1 as (
	select flight_id, fare_conditions , max(amount) as e_price 
	from ticket_flights tf
	where fare_conditions = 'Economy'
	group by flight_id, fare_conditions  
	order by flight_id),
cte2 as (
	select flight_id, fare_conditions , min(amount)  as b_price 
	from ticket_flights tf
	where fare_conditions = 'Business'
	group by flight_id, amount , fare_conditions  
	order by flight_id)	
select fv.flight_id, fv.departure_city, fv.arrival_city, e_price, b_price, 
	case 
	when  b_price < e_price then 'да'
	else 'нет'
	end as "Бизнес класс дешевле"
from flights_v fv
join cte1 c1  on c1.flight_id = fv.flight_id 
join cte2 c2  on c2.flight_id = fv.flight_id
order by fv.flight_id  ) z
where  "Бизнес класс дешевле" = 'да' ;

--8 Между какими городами нет прямых рейсов?
-- airports содержит множество аэропортов. Декартово произведение само себя создаст отношение всех возможных пар прямых перелетов.
--нужно исключить одинаковый пункт вылета и прилета, получим все варианты аэропортов вылетов и прилетов

select a1.airport_code as departure_airport, a1.city as city_departure , a2.airport_code  as arrival_airport , a2.city as city_arrival 
from airports a1 ,  airports a2 
where a1.city!= a2.city
order by a1.airport_code ;

--убираем зеркальные варианты

select a1.airport_code as departure_airport, a1.city as city_departure , a2.airport_code  as arrival_airport , a2.city as city_arrival 
from airports a1 ,  airports a2 
where a1.city != a2.city and a1.city > a2.city
order by a1.airport_code ;

--представлении routes есть отношение прямых перелетов из городов
-- выводим список городов междукоторыми есть сообщение
select r.departure_airport, r.departure_city, r.arrival_airport,  r.arrival_city  
from  routes r 
group by  1, 2, 3, 4
order by r.departure_city ;

--представлении flights_v есть отношение прямых перелетов из городов
select fv.departure_airport, fv.departure_city, fv.arrival_airport,  fv.arrival_city  
from  flights_v fv  
group by  1, 2, 3, 4
order by fv.departure_city ;

select fv.departure_city, fv.arrival_city  
from  flights_v fv  
where fv.departure_city != fv.arrival_city and fv.departure_city > fv.arrival_city
group by  1, 2
order by fv.departure_city 

--следует использовать оператор exept для объединения, чтобы из возможных вариантов вычесть те, между которыми есть сообщение
--оставляем только список городов, так как есть в некоторых несколько аэропортов
(select city_departure, city_arrival
from (
	select a1.airport_code as departure_airport, a1.city as city_departure , a2.airport_code  as arrival_airport , a2.city as city_arrival 
	from airports a1 ,  airports a2 
	where a1.city != a2.city and a1.city > a2.city) t1)
	except 
(select fv.departure_city, fv.arrival_city  
from  flights_v fv  
where fv.departure_city != fv.arrival_city and fv.departure_city > fv.arrival_city
group by  1, 2  ) 
order by city_departure ;

--можно создать материализованное представление, чтобы соеденить данные из таблицы flights и airports
create materialized view tabl_1 as 
	select f.flight_id, f.flight_no, f.aircraft_code, f.departure_airport, a.airport_name as  departure_airport_name,
	a.city as departure_city, f.arrival_airport, a1.airport_name as  arrival_airport_name,
	a1.city as arrival_city
	from flights f 
	left join airports a on a.airport_code = f.departure_airport 
   	left join airports a1 on a1.airport_code = f.arrival_airport 

(select city_departure, city_arrival
from (
	select a1.airport_code as departure_airport, a1.city as city_departure , a2.airport_code  as arrival_airport , a2.city as city_arrival 
	from airports a1 ,  airports a2 
	where a1.city != a2.city and a1.city > a2.city) t1)
	except 
(select t.departure_city, t.arrival_city  
from  tabl_1 t 
where t.departure_city != t.arrival_city and t.departure_city > t.arrival_city) 
order by city_departure ;
 
--9 Вычислите расстояние между аэропортами, связанными прямыми рейсами, сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы 
--в flights есть отношение прямых перелетов между аэропортами, выводим данные через функцию where и убираем возможные зеркала
select f.departure_airport, f.arrival_airport  
from  flights f 
where f.departure_airport != f.arrival_airport and f.departure_airport > f.arrival_airport 
group by  1, 2
order by f.departure_airport ;

--модели самолетов по дальности полета
select * 
from aircrafts 
order by range desc ;

--longitude - это долгота, latitude- это широта, данные представлены в градусах 
--d = arccos {sin(latitude_a)·sin(latitude_b) + cos(latitude_a)·cos(latitude_b)·cos(longitude_a - longitude_b)}
--считаем в градусах, через функцию radians преобразовать в радианы 
--результат вычисления следует привести к типу numeric и найти расстояние между точками в км по формуле d * 6371 as L
select f.departure_airport, a.airport_name as departure_airport_name, a.latitude as latitude_b, a.longitude as longitude_b,
f.arrival_airport, a1.airport_name as arrival_airport_name, a1.latitude as latitude_a, a1.longitude as longitude_a,
round(radians(acosd(sind(a1.latitude)*sind(a.latitude) +  cosd(a1.latitude)*cosd(a.latitude)*cosd(a1.longitude - a.longitude)))::numeric,2) * 6371 as L
from  (
	select f.departure_airport, f.arrival_airport  
	from  flights f 
	where f.departure_airport != f.arrival_airport  and f.departure_airport > f.arrival_airport 
	group by  1, 2) f 
join airports a on a.airport_code = f.departure_airport 
join airports a1 on  a1.airport_code = f.arrival_airport ;

--сравните с допустимой максимальной дальностью перелетов в самолетах, обслуживающих эти рейсы
--для удобства в cte1 убираем отношение прямых перелетов между аэропортами
--через case проведем сравнение дальности модели самолета по рейсу с расстоянием по этому рейсу
--чтобы использовать результаты вычислений в case в подзапрос убираем вычисление расстояния между двумя аэропортами
with cte1 as (
	select f.departure_airport, f.arrival_airport, f.aircraft_code    
	from  flights f 
	where f.departure_airport != f.arrival_airport  and f.departure_airport > f.arrival_airport
	group by  1, 2, 3) 
select departure_airport_name, arrival_airport_name, model, max_distance, L,
case
	when max_distance > L then 'долетит'
	else 'не долетит'
end as "сравнение"
from (
select f.departure_airport, a.airport_name as departure_airport_name, a.latitude as latitude_b, a.longitude as longitude_b,
f.arrival_airport, a1.airport_name as arrival_airport_name, a1.latitude as latitude_a, a1.longitude as longitude_a,
ar.model as model,
ar.range as max_distance,
round(radians(acosd(sind(a1.latitude)*sind(a.latitude) +  cosd(a1.latitude)*cosd(a.latitude)*cosd(a1.longitude - a.longitude)))::numeric,2) * 6371 as L
from cte1 f 
join airports a on a.airport_code = f.departure_airport 
join airports a1 on  a1.airport_code = f.arrival_airport 
join (
	select  aircraft_code, model, "range"
	from aircrafts 
	order by range desc ) ar on ar.aircraft_code = f.aircraft_code ) t ;