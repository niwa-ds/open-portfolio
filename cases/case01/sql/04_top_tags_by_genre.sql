-- 03の分析より、lift1.2を超えたジャンルにおける頻出タグ分析
-- 対象ジャンル: Film-Noir, War, Drama, Romance
-- 対象映画: 1980年以降公開 かつ 平均評価 >= 4 かつ レビュー数 >= 20（品質担保）

with movie_rate_over4 as (
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
    mg.movieId as movie_id
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

select
  genre
  ,tag
  ,count(distinct movie_id) as tag_movies
from
  base
group by
  genre
  ,tag
having
  tag_movies >= 3
qualify
  row_number() over (partition by genre order by tag_movies desc) <= 10
order by
  genre
  ,tag_movies desc