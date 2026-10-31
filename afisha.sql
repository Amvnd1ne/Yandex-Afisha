-- Получение общих данных
SELECT
    currency_code,
    SUM(revenue) AS total_revenue,
    COUNT(order_id) AS total_orders,
    AVG(revenue) AS avg_revenue_per_order,
    COUNT(DISTINCT user_id) AS total_users
FROM afisha.purchases
GROUP BY currency_code
ORDER BY total_revenue DESC;

-- Изучение распределения выручки в разрезе устройств
WITH set_config_precode AS (
  SELECT set_config('synchronize_seqscans', 'off', true)
)
SELECT
    device_type_canonical,
    SUM(revenue) AS total_revenue,
    COUNT(order_id) AS total_orders,
    AVG(revenue) AS avg_revenue_per_order,
    ROUND(
        SUM(revenue)::numeric / (
            SELECT SUM(revenue)::numeric
            FROM afisha.purchases
            WHERE currency_code = 'rub'
        ),
        3
    ) AS revenue_share
FROM afisha.purchases
WHERE currency_code = 'rub'
GROUP BY device_type_canonical
ORDER BY revenue_share DESC;

-- Изучение распределения выручки в разрезе типа мероприятий
WITH set_config_precode AS (
  SELECT set_config('synchronize_seqscans', 'off', true)
)
SELECT
    e.event_type_main,
    SUM(p.revenue) AS total_revenue,
    COUNT(p.order_id) AS total_orders,
    AVG(p.revenue) AS avg_revenue_per_order,
    COUNT(DISTINCT e.event_name_code) AS total_event_name,
    AVG(p.tickets_count) AS avg_tickets,
    SUM(p.revenue) / SUM(p.tickets_count) AS avg_ticket_revenue,
    ROUND(
        (SUM(p.revenue) / (
            SELECT SUM(revenue)
            FROM afisha.purchases
            WHERE currency_code = 'rub'
        ))::numeric,
        3
    ) AS revenue_share
FROM afisha.purchases AS p
JOIN afisha.events AS e
    ON p.event_id = e.event_id
WHERE p.currency_code = 'rub'
GROUP BY e.event_type_main
ORDER BY total_orders DESC, e.event_type_main ASC;

-- Динамика изменения значений
WITH set_config_precode AS (
  SELECT set_config('synchronize_seqscans', 'off', true)
)
SELECT
    DATE_TRUNC('week', created_dt_msk)::date AS week,
    SUM(revenue) AS total_revenue,
    COUNT(order_id) AS total_orders,
    COUNT(DISTINCT user_id) AS total_users,
    SUM(revenue) / COUNT(order_id) AS revenue_per_order
FROM afisha.purchases
WHERE currency_code = 'rub'
GROUP BY week
ORDER BY week ASC;

-- Выделение топ-сегментов
WITH set_config_precode AS (
  SELECT set_config('synchronize_seqscans', 'off', true)
)
SELECT
    r.region_name,
    SUM(p.revenue) AS total_revenue,
    COUNT(p.order_id) AS total_orders,
    COUNT(DISTINCT p.user_id) AS total_users,
    SUM(p.tickets_count) AS total_tickets,
    SUM(p.revenue) / SUM(p.tickets_count) AS one_ticket_cost
FROM afisha.purchases AS p
JOIN afisha.events AS e
    ON p.event_id = e.event_id
JOIN afisha.city AS c
    ON e.city_id = c.city_id
JOIN afisha.regions AS r
    ON c.region_id = r.region_id
WHERE p.currency_code = 'rub'
GROUP BY r.region_name
ORDER BY total_revenue DESC
LIMIT 7;

-- Период данных
SELECT MIN(created_dt_msk), MAX(created_dt_msk) FROM afisha.purchases;

-- Уникальность заказов и пропуски
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT order_id) AS unique_orders,
       COUNT(*) FILTER (WHERE user_id IS NULL) AS null_users,
       COUNT(*) FILTER (WHERE revenue IS NULL) AS null_revenue
FROM afisha.purchases;

-- Валюты и типы устройств
SELECT currency_code, COUNT(*) FROM afisha.purchases GROUP BY 1 ORDER BY 2 DESC;
SELECT device_type_canonical, COUNT(*) FROM afisha.purchases GROUP BY 1 ORDER BY 2 DESC;

-- Аномалии в выручке 
SELECT MIN(revenue), MAX(revenue), AVG(revenue), PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY revenue) 
FROM afisha.purchases WHERE currency_code = 'rub';

-- Проверка связи таблиц
SELECT COUNT(*) FROM afisha.purchases p LEFT JOIN afisha.events e ON p.event_id = e.event_id WHERE e.event_id IS NULL;
-- заказов без мероприятия нет


-- Недельная выручка и заказы
SELECT
    DATE_TRUNC('week', created_dt_msk)::date AS week,
    SUM(revenue) AS total_revenue,
    COUNT(order_id) AS total_orders,
    AVG(revenue) AS avg_revenue_per_order
FROM afisha.purchases
WHERE currency_code = 'rub'
GROUP BY week
ORDER BY week ASC;

-- Общие цифры за период
SELECT
    SUM(revenue) AS total_revenue,
    COUNT(order_id) AS total_orders,
    AVG(revenue) AS avg_revenue_per_order,
    COUNT(DISTINCT user_id) AS total_users,
    SUM(tickets_count) AS total_tickets
FROM afisha.purchases
WHERE currency_code = 'rub';

-- структура выручки
SELECT
    e.event_type_main,
    SUM(p.revenue) AS total_revenue,
    ROUND(
        (SUM(p.revenue) / (SELECT SUM(revenue) FROM afisha.purchases WHERE currency_code = 'rub'))::numeric,
        3
    ) AS revenue_share
FROM afisha.purchases AS p
JOIN afisha.events AS e ON p.event_id = e.event_id
WHERE p.currency_code = 'rub'
GROUP BY e.event_type_main
ORDER BY total_revenue DESC;

-- топ 3 региона 
SELECT
    r.region_name,
    SUM(p.revenue) AS total_revenue,
    COUNT(p.order_id) AS total_orders
FROM afisha.purchases AS p
JOIN afisha.events AS e ON p.event_id = e.event_id
JOIN afisha.city AS c ON e.city_id = c.city_id
JOIN afisha.regions AS r ON c.region_id = r.region_id
WHERE p.currency_code = 'rub'
GROUP BY r.region_name
ORDER BY total_revenue DESC
LIMIT 3;

-- топ 3 события 
SELECT
    e.event_name_code,
    e.event_type_main,
    SUM(p.revenue) AS total_revenue,
    COUNT(p.order_id) AS total_orders
FROM afisha.purchases AS p
JOIN afisha.events AS e ON p.event_id = e.event_id
WHERE p.currency_code = 'rub'
GROUP BY e.event_name_code, e.event_type_main
ORDER BY total_revenue DESC
LIMIT 3;

-- топ 3 площадки 
SELECT
    v.venue_name,
    SUM(p.revenue) AS total_revenue,
    COUNT(p.order_id) AS total_orders
FROM afisha.purchases AS p
JOIN afisha.events AS e ON p.event_id = e.event_id
JOIN afisha.venues AS v ON e.venue_id = v.venue_id
WHERE p.currency_code = 'rub'
GROUP BY v.venue_name
ORDER BY total_revenue DESC
LIMIT 3;