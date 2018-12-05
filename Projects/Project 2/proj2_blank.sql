-- COMP9311 15s2 Project 2
--
-- MyMyUNSW Solution Template

-- Q1: ...
create type EmploymentRecord as (unswid integer, name text, roles text);
create or replace function Q1() 
	returns setof EmploymentRecord 
as $$
... one SQL statement, possibly using other functions defined by you ...
$$ language plpgsql;




-- Q2: ...
create type TrailingSpaceRecord as ("table" text, "column" text, nexamples integer);
create or replace function Q2("table" text) 
	returns setof TrailingSpaceRecord
as $$
... one SQL statement, possibly using other functions defined by you ...
$$ language plpgsql;



-- Q3: transcript with variations
create or replace function Q3(_sid integer) returns setof TranscriptRecord
as $$
... one SQL statement, possibly using other functions defined by you ...
$$ language plpgsql;
