-- seed movie(475)を高評価(>=4)したユーザーが高評価した共起映画のジャンル分布を集計
-- 仮説: Crime / Thriller/ War など暗めのトーンのジャンルがベースラインより相対的に高い（lift > 1.2）

with seed_users as (
  select
    distinct userId
  from
    data-analysis-481901.portfolio_1.ratings
  where
    movieId = 475
    and rating >= 4
)

, cooccur_movies as (
  select
    distinct movieId
    ,genres
  from
    data-analysis-481901.portfolio_1.movies m
  join
    data-analysis-481901.portfolio_1.ratings r
  using
    (movieId)
  join
    seed_users s
  using
    (userId)
  where
    r.rating >= 4
    and movieId != 475
    and safe_cast(regexp_extract(m.title, r'\((\d{4})\)$') as int64) >= 1980
)

, cooccur_genre as (
  select
    genre
    ,count(distinct movieId) as co_movie_cnt
  from
    cooccur_movies
    ,unnest(split(genres, '|')) as genre
  group by
    genre
)

, baseline_movies as (
  select
    distinct m.movieId
    ,m.genres
  from
    data-analysis-481901.portfolio_1.movies m
  join
    data-analysis-481901.portfolio_1.ratings r
  using
    (movieId)
  where
    r.rating >= 4
    and safe_cast(regexp_extract(m.title, r'\((\d{4})\)$') as int64) >= 1980
)

, baseline_genre as (
  select
    genre
    ,count(distinct movieId) as base_movie_cnt
  from
    baseline_movies
    ,unnest(split(genres, '|')) as genre
  group by
    genre
)

, n as (
  select
    (select count(distinct movieId) from cooccur_movies) as co_n_movies
    ,(select count(distinct movieID) from baseline_movies) as base_n_movies
)

select
  g.genre
  ,g.co_movie_cnt
  ,round(safe_divide(g.co_movie_cnt, n.co_n_movies), 3) as co_share
  ,b.base_movie_cnt
  ,round(safe_divide(b.base_movie_cnt, n.base_n_movies), 3) as base_share
  ,round(safe_divide(safe_divide(g.co_movie_cnt, n.co_n_movies), safe_divide(b.base_movie_cnt, n.base_n_movies)), 3) as lift
from
  cooccur_genre g
left join
  baseline_genre b
using
  (genre)
cross join
  n
order by
  lift desc
  ,co_movie_cnt desc