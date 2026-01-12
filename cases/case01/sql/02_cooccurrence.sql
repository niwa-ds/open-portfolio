-- 目的: seed movie(475) を高評価(>=4)したユーザーが、他に高評価している映画（共起）を抽出する
-- 定義: 共起 = seed_users が rating>=4 を付けた映画
-- 出力: 共起ユーザー数(cooccur_uu)の降順でランキング
with seed_users as (
  select
    distinct userId
  from
    data-analysis-481901.portfolio_1.ratings
  where
    movieId = 475
    and rating >= 4
)

, seed_n as (
  select
    count(*) seed_uu
  from
    seed_users
)

, movie_cnt as (
  select
    movieId
    ,count(distinct userId) as movie_cnt
  from
    data-analysis-481901.portfolio_1.ratings
  group by
    movieId
)

, cooccur as (
  select
    movieId
    ,count(*) cooccur_cnt
    ,count(distinct r.userId) as cooccur_uu
  from
    data-analysis-481901.portfolio_1.ratings r
  join
    seed_users s
  using
    (userId)
  where
    r.rating >= 4
    and movieId != 475
  group by
    movieId
)

select
  m.title
  ,m.genres
  ,mc.movie_cnt
  ,c.cooccur_cnt
  ,c.cooccur_uu
  ,round(safe_divide(c.cooccur_uu, seed_n.seed_uu), 3) as cooccur_rate
  ,round(safe_divide(c.cooccur_uu, mc.movie_cnt), 3) as affinity
from
  cooccur c
cross join
  seed_n
join
  data-analysis-481901.portfolio_1.movies m
using
  (movieId)
join
  movie_cnt mc
using
  (movieId)
order by
  c.cooccur_uu desc