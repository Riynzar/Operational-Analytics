
SELECT 
    count() as total_delivered_orders,
    sum(date(order_delivered_customer_date) <= date(order_estimated_delivery_date)) as on_time_orders,
    sum(date(order_delivered_customer_date) > date(order_estimated_delivery_date)) as late_orders,
    round(on_time_orders / total_delivered_orders * 100, 2) as sla_compliance_rate_pct
FROM olist.orders
WHERE order_status = 'delivered' 
  AND order_delivered_customer_date IS NOT NULL;


-- ---------------------------------------------------------------------------------
-- STEP 1: THE HOOK (LATE DELIVERY SEVERITY DISTRIBUTION)
-- Posisi di Dashboard: Baris 2 (Donut Chart)
-- Deskripsi: Memecah pesanan terlambat berdasarkan tingkat keparahannya.
-- Argumen: "Meski SLA 93%, ada anomali mematikan: Mayoritas yang telat langsung telat >1 minggu."
-- ---------------------------------------------------------------------------------
SELECT 
    multiIf(
        delay_days <= 0, 'On Time',
        delay_days <= 3, '1-3 Days Late',
        delay_days <= 7, '4-7 Days Late',
        'More than 1 Week Late'
    ) as delay_severity,
    count() as order_count
FROM (
    SELECT 
        dateDiff('day', order_estimated_delivery_date, order_delivered_customer_date) as delay_days
    FROM olist.orders
    WHERE order_status = 'delivered' 
      AND order_delivered_customer_date IS NOT NULL
)
GROUP BY delay_severity
ORDER BY order_count DESC;


-- ---------------------------------------------------------------------------------
-- STEP 2: THE LOCATION (EXTREME LATE COUNT PER ROUTE)
-- Posisi di Dashboard: Baris 2 (Tabel dengan Conditional Formatting)
-- Deskripsi: Mencari tahu rute mana yang paling banyak menyumbang angka telat ekstrim.
-- Argumen: "Keterlambatan ini tidak acak, melainkan terpusat pada jalur logistik tertentu."
-- ---------------------------------------------------------------------------------
SELECT 
    s.seller_state AS origin,
    c.customer_state AS destination,
    count(DISTINCT o.order_id) AS extreme_late_count,
    round(avg(dateDiff('day', o.order_estimated_delivery_date, o.order_delivered_customer_date)), 1) AS avg_days_late
FROM olist.orders AS o
JOIN olist.order_items AS oi ON o.order_id = oi.order_id
JOIN olist.sellers AS s ON oi.seller_id = s.seller_id
JOIN olist.customers AS c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered' 
  AND o.order_delivered_customer_date IS NOT NULL
  AND dateDiff('day', o.order_estimated_delivery_date, o.order_delivered_customer_date) > 7
GROUP BY origin, destination
ORDER BY extreme_late_count DESC
LIMIT 10;


-- ---------------------------------------------------------------------------------
-- STEP 3: THE CULPRIT (AVERAGE DAY AT SELLER VS CARRIER)
-- Posisi di Dashboard: Baris 3 (Dua Angka Besar Bersebelahan)
-- Deskripsi: Membedah waktu khusus untuk pesanan yang telat lebih dari 1 minggu.
-- Argumen: "Ini membuktikan kurir (Carrier) adalah biang kerok utama, bukan seller."
-- ---------------------------------------------------------------------------------
SELECT 
    round(avg(dateDiff('day', order_purchase_timestamp, order_delivered_carrier_date)), 1) as avg_days_at_seller,
    round(avg(dateDiff('day', order_delivered_carrier_date, order_delivered_customer_date)), 1) as avg_days_at_carrier,
    round(avg(dateDiff('day', order_purchase_timestamp, order_delivered_customer_date)), 1) as total_lead_time_days
FROM olist.orders
WHERE order_status = 'delivered' 
  AND order_delivered_carrier_date IS NOT NULL 
  AND order_delivered_customer_date IS NOT NULL
  AND dateDiff('day', order_estimated_delivery_date, order_delivered_customer_date) > 7;


-- ---------------------------------------------------------------------------------
-- STEP 4: THE SOLUTION - INTERNAL (SELLER WITH MOST EXTREME LATE ORDERS)
-- Posisi di Dashboard: Baris 4 (Tabel Kiri dengan Data Bars)
-- Deskripsi: Mencari "Tersangka Utama" di level individu (Toko).
-- Argumen: "Meski kurir lambat, kita harus menghukum toko yang menahan barang >5 hari."
-- ---------------------------------------------------------------------------------
SELECT 
    oi.seller_id,
    s.seller_state,
    count(DISTINCT oi.order_id) as total_extreme_late_orders,
    round(avg(dateDiff('day', o.order_purchase_timestamp, o.order_delivered_carrier_date)), 1) as avg_days_holding_item
FROM olist.order_items oi
JOIN olist.orders o ON oi.order_id = o.order_id
JOIN olist.sellers s ON oi.seller_id = s.seller_id
WHERE o.order_status = 'delivered'
  AND dateDiff('day', o.order_estimated_delivery_date, o.order_delivered_customer_date) > 7
GROUP BY oi.seller_id, s.seller_state
HAVING total_extreme_late_orders > 10
ORDER BY total_extreme_late_orders DESC
LIMIT 10;


-- ---------------------------------------------------------------------------------
-- STEP 5: THE SOLUTION - EXTERNAL (LONGEST SHIPPING DURATION BY ROUTE)
-- Posisi di Dashboard: Baris 4 (Tabel Kanan dengan Conditional Formatting)
-- Deskripsi: Evaluasi rute spesifik untuk memutus kontrak kurir yang lambatnya tidak wajar.
-- Argumen: "Ini adalah daftar Rute Spesifik di mana mitra logistik kita harus dievaluasi."
-- ---------------------------------------------------------------------------------
SELECT 
    s.seller_state AS origin,
    c.customer_state AS destination,
    count(DISTINCT o.order_id) AS total_delayed_shipments,
    round(avg(dateDiff('day', o.order_delivered_carrier_date, o.order_delivered_customer_date)), 1) AS avg_days_with_carrier
FROM olist.orders AS o
JOIN olist.order_items AS oi ON o.order_id = oi.order_id
JOIN olist.sellers AS s ON oi.seller_id = s.seller_id
JOIN olist.customers AS c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered' 
  AND o.order_delivered_carrier_date IS NOT NULL
  AND o.order_delivered_customer_date IS NOT NULL
  AND dateDiff('day', o.order_estimated_delivery_date, o.order_delivered_customer_date) > 7
GROUP BY origin, destination
HAVING total_delayed_shipments > 50 
ORDER BY avg_days_with_carrier DESC
LIMIT 10;
