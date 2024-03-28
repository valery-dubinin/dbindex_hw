# dbindex_hw

Код тут:

https://github.com/valery-dubinin/dbindex_hw/blob/main/img/Script.sql

### Задание 1

Напишите запрос к учебной базе данных, который вернёт процентное отношение общего размера всех индексов к общему размеру всех таблиц.

### Решение  1

![img](https://github.com/valery-dubinin/dbindex_hw/blob/main/img/1.png)

### Задание 2

Выполните explain analyze следующего запроса:
```sql
select distinct concat(c.last_name, ' ', c.first_name), sum(p.amount) over (partition by c.customer_id, f.title)
from payment p, rental r, customer c, inventory i, film f
where date(p.payment_date) = '2005-07-30' and p.payment_date = r.rental_date and r.customer_id = c.customer_id and i.inventory_id = r.inventory_id
```
- перечислите узкие места;
- оптимизируйте запрос: внесите корректировки по использованию операторов, при необходимости добавьте индексы.

### Решение  1

Вначале было так:

![img](https://github.com/valery-dubinin/dbindex_hw/blob/main/img/2.png)

Потом добавили джойны:

![img](https://github.com/valery-dubinin/dbindex_hw/blob/main/img/3.png)

Потом проиндексировали:

![img](https://github.com/valery-dubinin/dbindex_hw/blob/main/img/4.png)

Потом вспомнили о лишних данных

![img](https://github.com/valery-dubinin/dbindex_hw/blob/main/img/5.png)

После доработки вышло так:

Убрал связку rental и customer по id, что вначале привело к увеличению времени выборки. Потом поменял условие без конвертации даты. Тогда заработал нормально индекс.

![img](https://github.com/valery-dubinin/dbindex_hw/blob/main/img/6.png)

