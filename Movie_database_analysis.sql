-- 1. Вывести количество фильмов в каждой категории, отсортировать по убыванию.
SELECT 
c.name, 
COUNT(film_id) AS number_of_films
FROM film_category f_c
JOIN category AS c ON (f_c.category_id = c.category_id)
GROUP BY c.category_id
ORDER BY number_of_films DESC;

--2. Вывести 10 актеров, чьи фильмы большего всего арендовали, отсортировать по убыванию.
SELECT 
first_name ||' '|| last_name AS f_l_actor 
FROM film AS f
JOIN inventory AS i ON (f.film_id = i.film_id)
JOIN rental AS r ON (i.inventory_id = r.inventory_id)
JOIN film_actor AS f_a ON (i.film_id = f_a.film_id)
JOIN actor AS a ON (f_a.actor_id = a.actor_id)
GROUP BY f_l_actor
ORDER BY COUNT(f.film_id) DESC
LIMIT 10;

--3. Вывести категорию фильмов, на которую потратили больше всего денег.
WITH temp_table AS (
     SELECT 
	     c.name, 
	     f_c.film_id, 
	     r.customer_id, 
	     f.rental_rate, 
	     f.rental_duration, 
	     f.replacement_cost, 
	     (DATE(r.return_date)-DATE(r.rental_date)) AS rental_period,
	     CASE
		     WHEN (DATE(r.return_date)-DATE(r.rental_date))<f.rental_duration 
		         THEN rental_rate
		     WHEN (DATE(r.return_date)-DATE(r.rental_date))>f.rental_duration 
		         THEN rental_rate+ROUND((((DATE(r.return_date)-DATE(r.rental_date))-f.rental_duration)*f.rental_rate/f.rental_duration), 2)
		     ELSE f.replacement_cost
	     END AS calculated_cost
      FROM category AS c
      JOIN film_category AS f_c ON (c.category_id = f_c.category_id)
      JOIN film AS f ON (f_c.film_id = f.film_id)
      JOIN inventory AS i ON (f.film_id = i.film_id)
      JOIN rental AS r ON (i.inventory_id = r.inventory_id)
)
 SELECT temp_table.name, SUM(temp_table.calculated_cost) FROM temp_table
 GROUP BY temp_table.name
 ORDER BY SUM(temp_table.calculated_cost) DESC
 LIMIT 1;

--4. Вывести названия фильмов, которых нет в inventory. Написать запрос без использования оператора IN.

select title from film f
where not exists (
      select 1   
      from inventory i
      where i.film_id = f.film_id);

-- 5. Вывести топ 3 актеров, которые больше всего появлялись в фильмах в категории “Children”. Если у нескольких актеров одинаковое кол-во фильмов, вывести всех
WITH top_actors AS (
     SELECT 
	     first_name || ' ' || last_name AS f_l_actor, 
		 COUNT(f_i.film_id) AS films_number,
		 DENSE_RANK() OVER (ORDER BY COUNT(f_i.film_id) DESC) AS rank_num
	 FROM actor AS a
     JOIN film_actor AS f_i ON (a.actor_id = f_i.actor_id)
     JOIN film AS f ON (f_i.film_id = f.film_id)
     JOIN film_category AS f_c ON (f.film_id = f_c.film_id)
     JOIN category AS c ON (f_c.category_id = c.category_id)
     WHERE c.name='Children'
	 GROUP BY f_l_actor
)
SELECT top_actors.f_l_actor 
FROM top_actors
WHERE top_actors.rank_num <= 3;

--6. Вывести города с количеством активных и неактивных клиентов (активный — customer.active = 1). Отсортировать по количеству неактивных клиентов по убыванию.
SELECT 
city,
COUNT(CASE WHEN cust.active = 1 THEN 1 END) AS number_active_customer,
COUNT(CASE WHEN cust.active = 0 THEN 1 END) AS number_inactive_customer
FROM customer AS cust
JOIN address AS a on (cust.address_id = a.address_id)
JOIN city AS c on (a.city_id = c.city_id)
GROUP BY city
ORDER BY number_inactive_customer DESC;

--7.Вывести категорию фильмов, у которой самое большое кол-во часов суммарной аренды в городах (customer.address_id в этом city), и которые начинаются на букву “a”. То же самое сделать для городов в которых есть символ “-”. Написать все в одном запросе.
WITH rental_hours AS (
     SELECT 
         c.name AS category_name,
         city.city as cities,
         SUM(ROUND(EXTRACT(EPOCH FROM (r.return_date-r.rental_date)) / 3600)) AS rental_hours
     FROM category AS c
     JOIN film_category AS f_c ON (c.category_id = f_c.category_id)
     JOIN film AS f ON (f_c.film_id = f.film_id)
     JOIN inventory AS i ON (f.film_id = i.film_id)
     JOIN rental AS r ON (i.inventory_id = r.inventory_id)
     JOIN customer AS cust ON(r.customer_id = cust.customer_id)
     JOIN address as a ON (cust.address_id = a.address_id)
     JOIN city ON (a.city_id = city.city_id)
     WHERE r.return_date IS NOT NULL
     GROUP BY category_name, city.city
	 ),
cities_a AS (
     SELECT * FROM rental_hours
	 WHERE cities LIKE 'A%'
	 ORDER BY rental_hours DESC
	 LIMIT 1
), 
cities_dash AS (
     SELECT * FROM rental_hours
	 WHERE cities LIKE '%-%'
	 ORDER BY rental_hours DESC
	 LIMIT 1
)
SELECT * FROM cities_a
UNION ALL
SELECT * FROM cities_dash;



