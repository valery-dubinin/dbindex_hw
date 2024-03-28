USE sakila;

select (IndexLength / DataLenght * 100) as Percent_of_Indexes
FROM 
(
select sum(DATA_LENGTH) as DataLenght, sum(INDEX_LENGTH) as IndexLength from INFORMATION_SCHEMA.tables
where TABLE_SCHEMA = 'sakila'
) as summa;

	
	
-- Как было	

EXPLAIN ANALYZE 

select distinct concat(c.last_name, ' ', c.first_name), sum(p.amount) over (partition by c.customer_id, f.title)
from payment p, rental r, customer c, inventory i, film f
where date(p.payment_date) = '2005-07-30' and p.payment_date = r.rental_date and r.customer_id = c.customer_id and i.inventory_id = r.inventory_id;



-> Table scan on <temporary>  (cost=2.5..2.5 rows=0) (actual time=6287..6287 rows=391 loops=1)
    -> Temporary table with deduplication  (cost=0..0 rows=0) (actual time=6287..6287 rows=391 loops=1)
        -> Window aggregate with buffering: sum(payment.amount) OVER (PARTITION BY c.customer_id,f.title )   (actual time=2577..6035 rows=642000 loops=1)
            -> Sort: c.customer_id, f.title  (actual time=2577..2664 rows=642000 loops=1)
                -> Stream results  (cost=21.3e+6 rows=16e+6) (actual time=0.342..1898 rows=642000 loops=1)
                    -> Nested loop inner join  (cost=21.3e+6 rows=16e+6) (actual time=0.339..1649 rows=642000 loops=1)
                        -> Nested loop inner join  (cost=19.7e+6 rows=16e+6) (actual time=0.335..1455 rows=642000 loops=1)
                            -> Nested loop inner join  (cost=18.1e+6 rows=16e+6) (actual time=0.331..1236 rows=642000 loops=1)
                                -> Inner hash join (no condition)  (cost=1.54e+6 rows=15.4e+6) (actual time=0.32..56.5 rows=634000 loops=1)
                                    -> Filter: (cast(p.payment_date as date) = '2005-07-30')  (cost=1.61 rows=15400) (actual time=0.0276..8.85 rows=634 loops=1)
                                        -> Table scan on p  (cost=1.61 rows=15400) (actual time=0.0189..5.29 rows=16044 loops=1)
                                    -> Hash
                                        -> Covering index scan on f using idx_title  (cost=112 rows=1000) (actual time=0.0377..0.217 rows=1000 loops=1)
                                -> Covering index lookup on r using rental_date (rental_date=p.payment_date)  (cost=0.969 rows=1.04) (actual time=0.00122..0.00172 rows=1.01 loops=634000)
                            -> Single-row index lookup on c using PRIMARY (customer_id=r.customer_id)  (cost=250e-6 rows=1) (actual time=180e-6..204e-6 rows=1 loops=642000)
                        -> Single-row covering index lookup on i using PRIMARY (inventory_id=r.inventory_id)  (cost=250e-6 rows=1) (actual time=138e-6..163e-6 rows=1 loops=642000)


-- Поехали

EXPLAIN ANALYZE 
select distinct concat(c.last_name, ' ', c.first_name) as fi , sum(p.amount)
from customer c
join rental r on r.customer_id = c.customer_id
join inventory i on i.inventory_id = r.inventory_id
join film f on f.film_id = i.film_id
join payment p on p.customer_id = c.customer_id 
where date(p.payment_date) = '2005-07-30' and p.payment_date = r.rental_date
group by fi;

-> Table scan on <temporary>  (actual time=12.1..12.2 rows=391 loops=1)
    -> Aggregate using temporary table  (actual time=12.1..12.1 rows=391 loops=1)
        -> Nested loop inner join  (cost=18891 rows=770) (actual time=0.0839..11.1 rows=634 loops=1)
            -> Nested loop inner join  (cost=18622 rows=770) (actual time=0.08..10.3 rows=634 loops=1)
                -> Nested loop inner join  (cost=18352 rows=770) (actual time=0.0761..9.37 rows=634 loops=1)
                    -> Nested loop inner join  (cost=18083 rows=770) (actual time=0.071..8.66 rows=634 loops=1)
                        -> Filter: (cast(p.payment_date as date) = '2005-07-30')  (cost=1564 rows=15400) (actual time=0.0558..6.82 rows=634 loops=1)
                            -> Table scan on p  (cost=1564 rows=15400) (actual time=0.0459..5.55 rows=16044 loops=1)
                        -> Filter: (r.customer_id = p.customer_id)  (cost=0.969 rows=0.05) (actual time=0.00181..0.00275 rows=1 loops=634)
                            -> Covering index lookup on r using rental_date (rental_date=p.payment_date)  (cost=0.969 rows=1.04) (actual time=0.00166..0.00253 rows=1.01 loops=634)
                    -> Single-row index lookup on c using PRIMARY (customer_id=p.customer_id)  (cost=0.25 rows=1) (actual time=954e-6..978e-6 rows=1 loops=634)
                -> Single-row index lookup on i using PRIMARY (inventory_id=r.inventory_id)  (cost=0.25 rows=1) (actual time=0.00124..0.00126 rows=1 loops=634)
            -> Single-row covering index lookup on f using PRIMARY (film_id=i.film_id)  (cost=0.25 rows=1) (actual time=0.0012..0.00123 rows=1 loops=634)

-- Вторая итерация
create index pay_date on payment(payment_date);

create index pay_date on rental(rental_date);


EXPLAIN ANALYZE 
select distinct concat(c.last_name, ' ', c.first_name) as fi , sum(p.amount)
from customer c
join rental r on r.customer_id = c.customer_id
join inventory i on i.inventory_id = r.inventory_id
join film f on f.film_id = i.film_id
join payment p on p.customer_id = c.customer_id 
where date(p.payment_date) = '2005-07-30' and p.payment_date = r.rental_date
group by fi;


-> Table scan on <temporary>  (actual time=11.7..11.7 rows=391 loops=1)
    -> Aggregate using temporary table  (actual time=11.7..11.7 rows=391 loops=1)
        -> Nested loop inner join  (cost=7969 rows=770) (actual time=0.0807..10.7 rows=634 loops=1)
            -> Nested loop inner join  (cost=7699 rows=770) (actual time=0.0774..9.76 rows=634 loops=1)
                -> Nested loop inner join  (cost=7430 rows=770) (actual time=0.0739..8.86 rows=634 loops=1)
                    -> Nested loop inner join  (cost=7160 rows=770) (actual time=0.0692..8.25 rows=634 loops=1)
                        -> Filter: (cast(p.payment_date as date) = '2005-07-30')  (cost=1564 rows=15400) (actual time=0.0513..5.76 rows=634 loops=1)
                            -> Table scan on p  (cost=1564 rows=15400) (actual time=0.0423..4.57 rows=16044 loops=1)
                        -> Filter: (r.customer_id = p.customer_id)  (cost=0.26 rows=0.05) (actual time=0.00306..0.00376 rows=1 loops=634)
                            -> Index lookup on r using pay_date (rental_date=p.payment_date)  (cost=0.26 rows=1.04) (actual time=0.00291..0.00355 rows=1.01 loops=634)
                    -> Single-row index lookup on c using PRIMARY (customer_id=p.customer_id)  (cost=0.25 rows=1) (actual time=800e-6..823e-6 rows=1 loops=634)
                -> Single-row index lookup on i using PRIMARY (inventory_id=r.inventory_id)  (cost=0.25 rows=1) (actual time=0.00127..0.00129 rows=1 loops=634)
            -> Single-row covering index lookup on f using PRIMARY (film_id=i.film_id)  (cost=0.25 rows=1) (actual time=0.00138..0.00141 rows=1 loops=634)

---- 3 итерация (наконец то вспомнил о лишних таблицах))

EXPLAIN ANALYZE 
select distinct concat(c.last_name, ' ', c.first_name) as fi , sum(p.amount)
from customer c
join rental r on r.customer_id = c.customer_id
join payment p on p.customer_id = c.customer_id 
where date(p.payment_date) = '2005-07-30' and p.payment_date = r.rental_date
group by fi


-> Table scan on <temporary>  (actual time=8.95..8.98 rows=391 loops=1)
    -> Aggregate using temporary table  (actual time=8.94..8.94 rows=391 loops=1)
        -> Nested loop inner join  (cost=7283 rows=770) (actual time=0.0687..8.17 rows=634 loops=1)
            -> Nested loop inner join  (cost=7013 rows=770) (actual time=0.0638..7.51 rows=634 loops=1)
                -> Filter: (cast(p.payment_date as date) = '2005-07-30')  (cost=1564 rows=15400) (actual time=0.0504..5.89 rows=634 loops=1)
                    -> Table scan on p  (cost=1564 rows=15400) (actual time=0.0418..4.58 rows=16044 loops=1)
                -> Filter: (r.customer_id = p.customer_id)  (cost=0.25 rows=0.05) (actual time=0.00182..0.00241 rows=1 loops=634)
                    -> Covering index lookup on r using rental_date (rental_date=p.payment_date)  (cost=0.25 rows=1.04) (actual time=0.00167..0.00221 rows=1.01 loops=634)
            -> Single-row index lookup on c using PRIMARY (customer_id=p.customer_id)  (cost=0.25 rows=1) (actual time=874e-6..898e-6 rows=1 loops=634)
            
            
            
            
EXPLAIN ANALYZE             
select distinct concat(c.last_name, ' ', c.first_name) as fi , sum(p.amount)
from customer c
join rental r on r.customer_id = c.customer_id
join payment p on p.payment_date = r.rental_date
where date(p.payment_date) = '2005-07-30'
group by fi            

-> Table scan on <temporary>  (actual time=58.4..58.5 rows=391 loops=1)
    -> Aggregate using temporary table  (actual time=58.4..58.4 rows=391 loops=1)
        -> Nested loop inner join  (cost=11554 rows=16419) (actual time=0.413..57.3 rows=642 loops=1)
            -> Nested loop inner join  (cost=5808 rows=16419) (actual time=0.177..22.2 rows=16044 loops=1)
                -> Table scan on c  (cost=61.2 rows=599) (actual time=0.0454..0.343 rows=599 loops=1)
                -> Index lookup on r using idx_fk_customer_id (customer_id=c.customer_id)  (cost=6.86 rows=27.4) (actual time=0.0303..0.0349 rows=26.8 loops=599)
            -> Index lookup on p using pay_date (payment_date=r.rental_date), with index condition: (cast(p.payment_date as date) = '2005-07-30')  (cost=0.25 rows=1) (actual time=0.00205..0.00207 rows=0.04 loops=16044)


----- 4 попытка )) убрал связку rental и customer по id, что вначале привело к увеличению времени выборки. Потом поменял условие без конвертации даты. Тогда заработал нормально индекс.

EXPLAIN ANALYZE
select distinct concat(c.last_name, ' ', c.first_name) as fi , sum(p.amount)
from customer c
join rental r on r.customer_id = c.customer_id
join payment p on p.payment_date = r.rental_date
where p.payment_date >= '2005-07-30' and  p.payment_date < DATE_ADD('2005-07-30', INTERVAL 1 day) 
group by fi

-> Table scan on <temporary>  (actual time=5.73..5.78 rows=391 loops=1)
    -> Aggregate using temporary table  (actual time=5.73..5.73 rows=391 loops=1)
        -> Nested loop inner join  (cost=571 rows=634) (actual time=0.058..4.51 rows=642 loops=1)
            -> Nested loop inner join  (cost=349 rows=634) (actual time=0.0403..1.82 rows=634 loops=1)
                -> Filter: ((r.rental_date >= TIMESTAMP'2005-07-30 00:00:00') and (r.rental_date < <cache>(('2005-07-30' + interval 1 day))))  (cost=127 rows=634) (actual time=0.0261..0.645 rows=634 loops=1)
                    -> Covering index range scan on r using rental_date over ('2005-07-30 00:00:00' <= rental_date < '2005-07-31 00:00:00')  (cost=127 rows=634) (actual time=0.0234..0.385 rows=634 loops=1)
                -> Single-row index lookup on c using PRIMARY (customer_id=r.customer_id)  (cost=0.25 rows=1) (actual time=0.00162..0.00165 rows=1 loops=634)
            -> Index lookup on p using pay_date (payment_date=r.rental_date)  (cost=0.25 rows=1) (actual time=0.00327..0.004 rows=1.01 loops=634)


