�������� ������ sql

1. � ����� ������� ������ ������ ���������?

-- ������� �� ������� city �� airports, ����������� �� city, ������� ���������� �������� city, ����� city � ����������� > 1

select city, count(city)
from airports
group by city 
having count(city) > 1




2. � ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������? (���������)

-- ������� ���������� �������� departure_airport �� flights, �� ������� f.aircraft_code ����� a.aircraft_code � ������������ ��������� range.

select distinct f.departure_airport
from flights f
where f.aircraft_code = (select a.aircraft_code
		from aircrafts a
		order by "range" desc limit 1)
		

		

3. ������� 10 ������ � ������������ �������� �������� ������. (�������� LIMIT)

-- ������� �������� �� flights, ������ ������� �������� ������ (actual_departure - scheduled_departure) as delay,
-- ����� ������ 10 ����������� � ������� ��������.

select flight_id, flight_no, scheduled_departure, actual_departure, (actual_departure - scheduled_departure) as delay
from flights f
where actual_departure is not null 
order by delay desc 
limit 10




4. ���� �� �����, �� ������� �� ���� �������� ���������� ������? (������ ��� JOIN)

-- ������� ���������� book_ref � ������� boarding_passes � �������������� full join ������� tickets �� ticket_no,
-- ��� ���������� ������ �� �������� boarding_no is null

select count(t.book_ref)
from boarding_passes bp 
full join tickets t on bp.ticket_no = t.ticket_no 
where bp.boarding_no is null




5. ������� ��������� ����� ��� ������� �����, 
�� % ��������� � ������ ���������� ���� � ��������.
�������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� ����������
�� ������� ��������� �� ������ ����. 
�.�. � ���� ������� ������ ���������� ������������� ����� - ������� ������� ��� ��������
�� ������� ��������� �� ���� ��� ����� ������ ������ �� ����.
(������� �������, ����������)

-- ������� �������� f.flight_id, f.aircraft_code, f.departure_airport, f.actual_departure �� ������� flights f
-- � �������������� ����������� �����������: (����� ���������� ���� � �������� �� seats);
-- 											(���������� ���������� ���������� ������� �� boarding_passes)
-- ������� ����������� ����������� ��������� ���� � ����� ���������� ���� � ��������,
-- � ������� ������� ������� ������� ������������� ���� ���������� �� ������� ��������� �� ����.

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


	
		
6. ������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������. (���������, �������� ROUND)

-- ������� ���������� �������� aircraft_code, ������ ����������� ����������� ��������� �� ����� ��������� �� flights
-- � �������������� ����� right join aircrafts, ����� �� �������� ������ �� ��������� �������������� ����� � ����������������. 

select distinct aircraft_code, model, 
		Round((count(aircraft_code) over (partition by aircraft_code)*100::numeric /count(flight_id) over()::numeric), 3) as percentage
from flights f 
right join aircrafts a using (aircraft_code)




7. ���� �� ������, � ������� �����  ��������� ������ - ������� �������, ��� ������-������� � ������ ��������? (CTE)

-- �������� CTE (������� �������� f.flight_id, a.city , tf.fare_conditions, tf.amount �� ticket_flights
-- � �������������� ������ flights � airports)
-- ����� max_economy � min_business �� �������������, ��������������� ������� ��������� Economy > Business � ������ flight_id

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
    
    
    

8. ����� ������ �������� ��� ������ ������? (��������� ������������ � ����������� from,
												�������������� ��������� �������������,
												�������� EXCEPT)

-- �������� ������������� (��������� ������������ ��� ����������� ��������� ��� ������� ��� ��������� ),
-- ���������� ������������ ������ ����� ��������


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




9. ��������� ���������� ����� �����������, ���������� ������� �������, 
�������� � ���������� ������������ ���������� ���������  � ���������,
������������� ��� �����. (�������� RADIANS ��� ������������� sind/cosd)

(���������� ���������� ����� ����� ������� A � B �� ������ ����������� (���� ������� �� �� �����) ������������ ������������:
d = arccos {sin(latitude_a)�sin(latitude_b) + cos(latitude_a)�cos(latitude_b)�cos(longitude_a - longitude_b)}, ��� latitude_a � latitude_b � ������, 
longitude_a, longitude_b � ������� ������ �������, d � ���������� ����� �������� ���������� � �������� ������ ���� �������� ����� ������� ����.
���������� ����� ��������, ���������� � ����������, ������������ �� �������:
L = d�R, ��� R = 6371 �� � ������� ������ ������� ����.)

-- ������� ���������� �������� ����������, ��������� ������� �������
-- � �������������� ������ airports a �� f.departure_airport = a.airport_code,
-- airports a2  �� f.arrival_airport = a2.airport_code,
-- aircrafts a3 �� f.aircraft_code = a3.aircraft_code 
-- ������ ���������� ����� ����������� �� �������,
-- ����� ������������ ��������� ������ ��� ��������� � ����������� ����� �����������. 

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

