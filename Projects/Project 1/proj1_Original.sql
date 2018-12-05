-- COMP9311 15s2 Project 1
--
-- MyMyUNSW Solution Template

-- Q1: ...
create or replace view Q1(familyName)
as
... one SQL statement, possibly using other views defined by you ...
;


-- Q2: ...
create or replace view Q2(subject,semester)
as
... one SQL statement, possibly using other views defined by you ...
;


-- Q3: ...
create or replace view Q3(ratio,nsubjects)
as
... one SQL statement, possibly using other views defined by you ...
;


-- Q4: ...
create or replace view Q4(orgunit)
as
... one SQL statement, possibly using other views defined by you ...
;


-- Q5: ...
create or replace view Q5(code, title)
as
... one SQL statement, possibly using other views defined by you ...
;


-- Q6: ...
create type EvalRecord as (code text, title text, rating numeric(4,2));

create or replace function Q6(integer,text) 
	returns setof EvalRecord 
as $$
... one SQL statement, possibly using other views defined by you ...
$$ language plpgsql
;


