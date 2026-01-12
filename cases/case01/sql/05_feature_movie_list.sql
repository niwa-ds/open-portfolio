-- 02の共起映画、03の共起ジャンル、04の頻出タグを用いた特集用映画リスト作成
-- 対象ジャンル: Film-Noir, War, Drama, Romance
-- 対象映画: 平均評価 >= 4 かつ レビュー数 >= 20（品質担保）
-- tag_cnt は「特集テーマへの適合度（頻出タグ一致数）」を表す

with seed_users as (
  select
    distinct userId
  from
    data-analysis-481901.portfolio_1.ratings
  where
    movieId = 475
    and rating >= 4
)

, cooccur as (
  select
    movieId

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
  having
    count(distinct r.userId) >= 3
)

, movie_rate_over4 as (
  select
    movieId
  from
    data-analysis-481901.portfolio_1.ratings
  group by
    movieId
  having
    avg(rating) >= 4
    and count(*) >= 20

)

,movie_genre as (
  select
    movieId
    ,genre
  from
    data-analysis-481901.portfolio_1.movies
    ,unnest(split(genres, '|')) as genre
  where
    genre in ('Film-Noir', 'War', 'Drama', 'Romance')
    and safe_cast(regexp_extract(title, r'\((\d{4})\)$') as int64) >= 1980

)

, base as (
  select
    mg.movieId
    ,mg.genre
    ,lower(trim(t.tag)) as tag
  from
    movie_genre mg
  join
    data-analysis-481901.portfolio_1.tags t
  using
    (movieId)
  where
    exists(
      select
        1
      from
        movie_rate_over4 mr
      where
        mr.movieId = mg.movieId
    )
)

, genre_tag as (
  select
    genre
    ,tag
  from
    base
  group by
    genre
    ,tag
  having
    count(distinct movieId) >= 3
  qualify
    row_number() over (partition by genre order by count(distinct movieId) desc) <= 10
)

, movie_list as (
  select
    distinct movieId
  from
    base b
  join
    genre_tag gt
  on
    b.genre = gt.genre
    and b.tag = gt.tag
)

select
  m.movieId
  ,m.title
  ,m.genres
  ,count(*) as tag_cnt
  ,case when c.movieId is not null then 1 else 0 end as co_flag
from
  data-analysis-481901.portfolio_1.tags t
join
  movie_list ml
using
  (movieId)
join
  genre_tag gt
on
  lower(trim(t.tag)) = gt.tag
join
  data-analysis-481901.portfolio_1.movies m
using
  (movieId)
left join
  cooccur c
using
  (movieId)
group by
  1, 2, 3, 5
order by
  co_flag desc
  ,tag_cnt desc