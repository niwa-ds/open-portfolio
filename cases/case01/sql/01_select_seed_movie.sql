-- 起点動画の選定
-- 定義:
--  露出：rating件数(cnt)
--  方針：
--    露出が極端に少ない作品は平均評価が不安定になるため、cnt >= 20 を下限に設定。
--    そのうえで、露出上位10–20%（第2デシル）を「メジャーすぎないが評価が十分に集まる帯」として起点にする。

with base as (
  select
    movieID as movie_id
    ,m.title
    ,m.genres
    ,safe_cast(regexp_extract(m.title, r'\((\d{4})\)$') as int64) as release_year
    ,count(*) as cnt
    ,avg(r.rating) as avg_rate
  from
    data-analysis-481901.portfolio_1.ratings r
  join
    data-analysis-481901.portfolio_1.movies m
  using
    (movieId)
  group by
    1, 2, 3, 4
)

, decile as (
  select
    *
    ,ntile(10) over (order by cnt desc) as tile
  from
    base
)

select
  movie_id
  ,title
  ,genres
  ,release_year
  ,cnt
  ,avg_rate
from
  decile
where
  release_year >= 1980
  and avg_rate >= 4
  and tile = 2
  and cnt >= 20
order by
  avg_rate desc