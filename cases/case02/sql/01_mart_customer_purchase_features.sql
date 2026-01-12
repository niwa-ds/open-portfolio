-- 目的: 顧客単位（customer_unique_id）で購買特徴量を作成（RFM + 初回情報 + カテゴリ傾向）
-- 対象: order_status = 'delivered' のみ
-- 主な指標の定義:
-- - recency : データ内の最新 delivered_date から各顧客の最終購入日までの日数差
-- - frequency : delivered の注文数（order_id数）
-- - monetary : delivered の累計支払額（order_payments を注文単位で合算）
-- - total_item : delivered の購入点数合計（order_items の行数合計）
-- - top_category_cnt : 最頻カテゴリの購入点数（※「点数」=明細行数。注文回数ではない）
-- ============================================================

with order_base as (
  select
    order_id
    ,customer_id
    ,order_delivered_customer_date as delivered_date
  from
    data-analysis-481901.portfolio_2.orders
  where
    order_status = 'delivered'
)

, order_payment_base as (
  select
    order_id
    ,sum(payment_value) as payment_charge
  from
    data-analysis-481901.portfolio_2.order_payments
  group by
    order_id
)

, order_item_base as (
  select
    order_id
    ,count(*) as item_cnt
  from
    data-analysis-481901.portfolio_2.order_items
  group by
    order_id
)

, base as (
  select
    ob.order_id
    ,ob.customer_id
    ,ob.delivered_date
    ,oi.item_cnt
    ,op.payment_charge
  from
    order_base ob
  left join
    order_item_base oi
  using
    (order_id)
  left join
    order_payment_base op
  using
    (order_id)
)

, first_ranked as (
  select
    c.customer_unique_id
    ,b.payment_charge
    ,b.item_cnt
    ,row_number() over (partition by c.customer_unique_id order by b.delivered_date, b.order_id) as rnk
  from
    base b
  left join
    data-analysis-481901.portfolio_2.customers c
  using
    (customer_id)
)

, first_base as (
  select
    customer_unique_id
    ,payment_charge as first_monetary
    ,item_cnt as first_item_cnt
  from
    first_ranked
  where
    rnk = 1
)

, latest as(
  select
    max(delivered_date) as latest_date
  from
    base
)

, customer_base as (
  select
    c.customer_unique_id
    ,min(b.delivered_date) as first_date
    ,date_diff(l.latest_date, max(b.delivered_date), day) as recency
    ,sum(b.payment_charge) as monetary
    ,count(distinct b.order_id) as frequency
    ,avg(b.payment_charge) as avg_order_value
    ,sum(b.item_cnt) as total_item
    ,f.first_monetary
    ,f.first_item_cnt
  from
    base b
  cross join
    latest l
  left join
    data-analysis-481901.portfolio_2.customers c
  using
    (customer_id)
  left join
    first_base f
  using
    (customer_unique_id)
  group by
    c.customer_unique_id
    ,l.latest_date
    ,f.first_monetary
    ,f.first_item_cnt
)

, order_product_base as (
  select
    ob.order_id
    ,c.customer_unique_id
    ,coalesce(pc.string_field_1, pc.string_field_0) as category_name
  from
    order_base ob
  left join
    data-analysis-481901.portfolio_2.order_items oi
  using
    (order_id)
  left join 
    data-analysis-481901.portfolio_2.products p
  using
    (product_id)
  left join
    data-analysis-481901.portfolio_2.product_category_name_translation pc
  on
    p.product_category_name = pc.string_field_0
  left join
    data-analysis-481901.portfolio_2.customers c
  using
    (customer_id)
)

, category_base as (
  select
    customer_unique_id
    ,category_name
    ,count(*) as category_cnt
  from
    order_product_base
  group by
    1, 2
)
, category_rank as (
  select
    customer_unique_id
    ,category_name
    ,category_cnt
    ,row_number() over (partition by customer_unique_id order by category_cnt desc, category_name) as rnk
  from
    category_base
)

, category_top as (
  select
    customer_unique_id
    ,category_name as top_category
    ,category_cnt as top_category_cnt
  from
    category_rank
  where
    rnk = 1
)

, category_diversity as (
  select
    customer_unique_id
    ,count(distinct category_name) as diversity
  from
    order_product_base
  group by
    1
)

select
  cb.customer_unique_id
  ,cb.first_date
  ,cb.recency
  ,cb.monetary
  ,cb.frequency
  ,cb.avg_order_value
  ,cb.total_item
  ,cb.first_monetary
  ,cb.first_item_cnt
  ,if(cb.frequency>1, 1, 0) as repeat_flag
  ,ct.top_category
  ,ct.top_category_cnt
  ,cd.diversity as category_diversity
  ,safe_divide(ct.top_category_cnt, cb.total_item) as category_share_top
from
  customer_base cb
left join
  category_top ct
using
  (customer_unique_id)
left join
  category_diversity cd
using
  (customer_unique_id)