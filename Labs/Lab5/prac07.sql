-- Q1
create or replace view AllRatings(taster,beer,brewer,rating)
as
	select t.given, b. name, br.name, r.score
	from ratings r join taster t on (r.taster = t.id) join beer b on (b.id = r.beer)
	join Brewer br on (b.brewer = br.id)
	order by t.given, r.score DESC;
;


-- Q2 John's favourite beer
create or replace view JohnsFavouriteBeer(brewer,beer)
as
	select brewer, beer from AllRatings 
	where taster = 'John' and rating = (
	select max(rating) from Allratings where taster = 'John')
;


-- Q3 X's favourite beer
create type BeerInfo as (brewer text, beer text);

create or replace function FavouriteBeer(taster text) returns setof BeerInfo
as $$
	select brewer, beer
	from AllRatings a1
	where a1.taster = $1 and rating = (select max(rating) from AllRatings a2 
	where a2.taster = $1)

$$ language sql
;
--select * from FavouriteBeer('Adam');


-- Q4 Beer style
create or replace function BeerStyle(brewer text, beer text) returns text
as $$
		select b.name as beerstyle 
		from Beer b, BeerStyle bs, Brewer br
		where b.style = bs.id and b.brewer = br.id and 
		lower(b.name) = lower($2) and lower(br.name) = lower($1)
		
$$ language sql
;
--select BeerStyle('Sierra Nevada','Pale Ale');


-- Q5 Taster address
create or replace function TasterAddress(text) returns text
as $$
      select case
             when loc.state is null then loc.country
             when loc.country is null then loc.state
             else loc.state||', '||loc.country
             end
      from   Taster t, Location loc
      where  t.given = $1 and t.livesIn = loc.id
$$ language sql
;

-- !!Q6 BeerSummary function 

creat or replace function BeerSummary() returns text
as $$
declare
	... replace this by your definitions ...
begin
	... replace this by your code ...
end;
$$ language plpgsql;



-- Concat aggregate

create aggregate concat (... replace by base type ...)
(
	stype     = ... replace by state type ... ,
	initcond  = ... replace by initial state ... ,
	sfunc     = ... replace by name of state transition function ...,
	finalfunc = ... replace by name of finalisation function ...
);


-- BeerSummary view

create or replace view BeerSummary(beer,rating,tasters)
as
	... replace by SQL your query using concat() and AllRatings ...
;


-- TastersByCountry view

create or replace view TastersByCountry(country,tasters)
as
	... replace by SQL your query using concat() and Taster ...
;
