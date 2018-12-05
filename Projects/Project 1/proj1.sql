-- COMP9311 15s2 Project 1
--
-- MyMyUNSW Solution Template

-- Q1: Find longest unique student family name
-- Create view uniqueFamName for names occurring once
-- drop view uniqueFamName;
create or replace view uniqueFamName(FName) as
	select family, length(family)
	from people p1
	where not exists(
		select *
		from people p2
		where (p1.family = p2.family and p1.unswid != p2.unswid)
	) and  p1.family !~ '[\w]+[\s|-]+[\w]+';


create or replace view Q1(familyName) as
	select fname 
	from uniqueFamName 
	where length = (
	select max(length)
	from uniqueFamName u
	);

	

-- Q2: Find course with ABC grading system
create or replace view Q2(subject,semester) as
	select s.code, substring(cast(m.year as varchar(4)) from 3 for 2) || m.term 
	from 
		courses c join subjects s on (c.subject = s.id) join semesters m on (c.semester = m.id)
	where c.id in
		(
			select distinct course
			from course_enrolments
			where grade in ('A', 'B', 'C')
		)
	order by s.code;
	


-- Q3: Find count of subjects with same uoc/etfload ratio
create or replace view Q3(ratio,nsubjects) as
	select  cast(uoc/eftsload as numeric(4,1)) as  ratio, count(id)
	from  subjects
	where eftsload !=0 or eftsload  = NULL
	group by ratio
	order by ratio;
	
	
-- Q4: Find orphaned units
create or replace view Q4(orgunit) as
	select distinct longname 
	from  orgunits o
	where not exists(
		select member
		from orgunit_groups g 
		where g.member = o.id
		)
	order by longname;


-- Q5: Find subjects no longer offered in 2009 or 2010
create or replace view Q5(code, title) as
	select distinct s.code, s.longname
	from courses c join subjects s on (c.subject = s.id) join semesters m on (c.semester = m.id)
	where s.code ~ '^COMP' and (year = 2008 or year = 2009 or year =2010)
	except
	select distinct s.code, s.longname
	from courses c join subjects s on (c.subject = s.id) join semesters m on (c.semester = m.id)
	where s.code ~ '^COMP' and (year = 2009 or year = 2010);


	
-- Q6: Find top rating subject in a given semester
create type EvalRecord as (code text, title text, rating numeric(4,2));

-- Find out all evaluation
create or replace view all_eval(course_id, ratings) as
	select ce.course, cast(avg(ce.stueval) as numeric(4,2))
	from course_enrolments ce
	group by ce.course
	having count(ce.student) > 10 and 3* count(ce.stueval) > count(ce.student);

-- Find out max evaluation in a semester
create or replace view max_rating(ryear, rterm, max_rate) as
select m.year, m.term, max(a.ratings)
from courses c join subjects s on (c.subject = s.id) join semesters m on (c.semester = m.id)
	join all_eval a on (a.course_id = c.id)
group by m.year, m.term;

create or replace function Q6(integer,text) 
	returns setof EvalRecord 
as $$
declare
	r	EvalRecord;
begin
	select cast(s.code as  text), cast(s.name as text), a.ratings into r
	from courses c join subjects s on (c.subject = s.id) join semesters m on (c.semester = m.id)
	join all_eval a on (a.course_id = c.id)
	where m.year = $1 and m.term = $2 and a.ratings = (
		select max_rate
		from max_rating
		where ryear = $1 and rterm = $2
	);
	return r;
end;
$$ LANGUAGE PLPGSQL;



create or replace function Q6(integer,text) 
	returns setof EvalRecord 
as $$
	select cast(s.code as  text), cast(s.name as text), a.ratings
	from courses c join subjects s on (c.subject = s.id) join semesters m on (c.semester = m.id)
	join all_eval a on (a.course_id = c.id)
	where m.year = $1 and m.term = $2 and a.ratings = (
		select max_rate
		from max_rating
		where ryear = $1 and rterm = $2
	);
$$ LANGUAGE SQL;






