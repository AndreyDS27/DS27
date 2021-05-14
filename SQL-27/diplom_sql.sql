Итоговая работа sql

1. В каких городах больше одного аэропорта?

-- выборка по столбцу city из airports, группировка по city, подсчет количества значений city, вывод city с количеством > 1

select city, count(city)
from airports
group by city 
having count(city) > 1




2. В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета? (Подзапрос)

-- выборка уникальных значений departure_airport из flights, по условию f.aircraft_code равен a.aircraft_code с максимальным значением range.

select distinct f.departure_airport
from flights f
where f.aircraft_code = (select a.aircraft_code
		from aircrafts a
		order by "range" desc limit 1)
		

		

3. Вывести 10 рейсов с максимальным временем задержки вылета. (Оператор LIMIT)

-- выборка значений из flights, расчет времени задержки вылета (actual_departure - scheduled_departure) as delay,
-- вывод первых 10 результатов в порядке убывания.

select flight_id, flight_no, scheduled_departure, actual_departure, (actual_departure - scheduled_departure) as delay
from flights f
where actual_departure is not null 
order by delay desc 
limit 10




4. Были ли брони, по которым не были получены посадочные талоны? (Верный тип JOIN)

-- подсчет количества book_ref в таблице boarding_passes с присоединением full join таблицы tickets по ticket_no,
-- где посадочные талоны не получены boarding_no is null

select count(t.book_ref)
from boarding_passes bp 
full join tickets t on bp.ticket_no = t.ticket_no 
where bp.boarding_no is null




5. Найдите свободные места для каждого рейса, 
их % отношение к общему количеству мест в самолете.
Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров
из каждого аэропорта на каждый день. 
Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело
из данного аэропорта на этом или более ранних рейсах за день.
(Оконная функция, Подзапросы)

-- выборка значений f.flight_id, f.aircraft_code, f.departure_airport, f.actual_departure из таблицы flights f
-- с присоединением результатов подзапросов: (общее количество мест в самолете из seats);
-- 											(количество полученных посадочных талонов из boarding_passes)
-- подсчет процентного соотношения свободных мест к ощему количеству мест в самолете,
-- с помощью оконной функции считаем накопительный итог пассажиров по каждому аэропорту за день.

select f.flight_id, f.aircraft_code, f.departure_airport, f.actual_departure, 
		cas.aircraft_seats, cbp.pass, (cas.aircraft_seats - cbp.pass) as no_pass ,  
		cast((cas.aircraft_seats - cbp.pass )*100/(cas.aircraft_seats) as float )|| '%' as percentage, 
		sum(cbp.pass) over (partition by f.departure_airport, date_trunc('day', f.actual_departure) order by f.actual_departure)
from flights f 
join (select bp.flight_id, count(bp.seat_no) as pass 
		from boarding_passes bp 
		group by bp.flight_id) as cbp on cbp.flight_id = f.flight_id
join (select distinct s.aircraft_code, count(s.seat_no) as aircraft_seats
		from seats s
		group by s.aircraft_code) as cas on cas.aircraft_code = f.aircraft_code 


	
		
6. Найдите процентное соотношение перелетов по типам самолетов от общего количества. (Подзапрос, Оператор ROUND)

-- выборка уникальных значений aircraft_code, расчет процентного соотношения перелетов по типам самолетов из flights
-- с присоединением через right join aircrafts, чтобы не потерять данные по самолетам осуществляющим рейсы и неосуществляющим. 

select distinct aircraft_code, model, 
		Round((count(aircraft_code) over (partition by aircraft_code)*100::numeric /count(flight_id) over()::numeric), 3) as percentage
from flights f 
right join aircrafts a using (aircraft_code)




7. Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета? (CTE)

-- создание CTE (выборка значений f.flight_id, a.city , tf.fare_conditions, tf.amount из ticket_flights
-- с присоединением таблиц flights и airports)
-- поиск max_economy и min_business по представлению, удовлетворяющих условию стоимости Economy > Business в рамках flight_id

explain analyze

with cte_1 as(
			select f.flight_id, a.city , tf.fare_conditions, tf.amount
			from flights f
			left join ticket_flights tf using (flight_id)
			left join airports a on f.arrival_airport = a.airport_code
			order by f.flight_id, fare_conditions asc
			)
select  flight_id, city,
        max(case when fare_conditions = 'Economy' then amount else null end) as max_economy,
        min(case when fare_conditions = 'Business' then amount else null end) as min_business 
    from cte_1    
    group by flight_id, city
    having max(amount) filter (where fare_conditions = 'Economy') > min(amount) filter(where fare_conditions = 'Business')
    
    
    

8. Между какими городами нет прямых рейсов? (Декартово произведение в предложении from,
												Самостоятельно созданные представления,
												Оператор EXCEPT)

-- создание представления (Декартово произведение для определения возможных пар городов для перелетов ),
-- исключение существующих рейсов между городами


create view no_direct_flights as
	select distinct a.city city_1, a2.city city_2
	from airports a, airports a2
	where a.city != a2.city
	except select distinct a.city city_1, a2.city city_2
	from flights f
	join airports a on f.departure_airport = a.airport_code
	join airports a2 on f.arrival_airport = a2.airport_code

select *
from no_direct_flights




9. Вычислите расстояние между аэропортами, связанными прямыми рейсами, 
сравните с допустимой максимальной дальностью перелетов  в самолетах,
обслуживающих эти рейсы. (Оператор RADIANS или использование sind/cosd)

(Кратчайшее расстояние между двумя точками A и B на земной поверхности (если принять ее за сферу) определяется зависимостью:
d = arccos {sin(latitude_a)·sin(latitude_b) + cos(latitude_a)·cos(latitude_b)·cos(longitude_a - longitude_b)}, где latitude_a и latitude_b — широты, 
longitude_a, longitude_b — долготы данных пунктов, d — расстояние между пунктами измеряется в радианах длиной дуги большого круга земного шара.
Расстояние между пунктами, измеряемое в километрах, определяется по формуле:
L = d·R, где R = 6371 км — средний радиус земного шара.)

-- выборка уникальных значений аэропортов, связанных прямыми рейсами
-- с присоединением таблиц airports a по f.departure_airport = a.airport_code,
-- airports a2  по f.arrival_airport = a2.airport_code,
-- aircrafts a3 по f.aircraft_code = a3.aircraft_code 
-- расчет расстояния между аэропортами по формуле,
-- вывод максимальной дольности полета для сравнения с расстоянием между аэропортами. 

select distinct f.departure_airport, a.airport_name, a.latitude, a.longitude, 
				f.arrival_airport, a2.airport_name, a2.latitude, a2.longitude, 
				f.aircraft_code, a3.model, a3."range",
				round((acos(sin(radians(a.latitude))*sin(radians(a2.latitude))
				+cos(radians(a.latitude))*cos(radians(a2.latitude))
				*cos(radians(a.longitude)-radians(a2.longitude))))*6371) as distance_between_airport
from flights f 
join airports a  on f.departure_airport = a.airport_code
join airports a2  on f.arrival_airport = a2.airport_code
join aircrafts a3 on f.aircraft_code = a3.aircraft_code 
order by f.departure_airport 

