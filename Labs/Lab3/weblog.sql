-- Q4: min,avg,max bytes transferred in page accesses

... replace this line by auxiliary views (or delete it) ...

create or replace view Q4(min,avg,max) as
	select min(nbytes), cast(avg(nbytes) as integer), max(nbytes) from accesses;
--select * from Q4;
	


-- Q5: number of sessions from CSE hosts

create or replace view Q5(nhosts) as
	select count(h.id)
	from Hosts h join Sessions s on (h.id = s.host)
	where hostname ~ 'cse.unsw.edu.au';
	
select * from Q5


-- Q6: number of sessions from non-CSE hosts

create or replace view Q6(nhosts) as
	select count(h.id)
	from Hosts h, Sessions s
	where hostname !~ 'cse.unsw.edu.au' AND h.id = s.host;
	
select * from Q6


-- Q7: session id and number of accesses for the longest session?

create or replace view p_count(id, length) as
	select s.id, count(a.page)
	from Sessions s, Accesses a
	where s.id = a.session
	group by s.id;

create or replace view Q7(session,length) as 
	select id, length
	from p_count
	where length = (select max(length) from p_count);

select * from Q7;


-- Q8: frequency of page accesses

... replace this line by auxiliary views (or delete it) ...

create or replace view Q8(page,freq) as
	select page, count(page)
	from accesses
	group by page;

select * from Q8 order by freq desc limit 10;

-- Q9: frequency of module accesses

create or replace view Q9(module,freq) as
	select trim(both '\/' from substring(page from '.*?\/')), count(page)
	from accesses
	group by trim(both '\/' from substring(page from '.*?\/'));

select * from Q9 order by freq desc limit 10;


-- Q10: "sessions" which have no page accesses

... replace this line by auxiliary views (or delete it) ...

create or replace view Q10(session) as
	select s1.id
	from sessions s1
	except
	select a1.session
	from accesses a1;

select * from Q10;

-- Q11: hosts which are not the source of any sessions

create or replace view Q11(unused) as

--drop view Q11;


select distinct hostname
from accesses a join sessions s on (a.session = s.id) join hosts h on (h.id = s.host)
where a.page !~ '^webcms' and h.hostname ~ 'cse.unsw.edu.au'

--select * from Q11;

