-- COMP9311 15s2 Project 2
--
-- MyMyUNSW Solution Template

-- Q1: Multiple role staff -----------------------------------------------------------------------
create type EmploymentRecord as (unswid integer, name text, roles text);
-- concatenate role, starting and ending into one line
create or replace function concat_RolesDate(role text, starting date, ending date)
returns text 
as $$
begin
	if ending is NULL then
		return role || ' (' ||starting ||'..)' ;
	else
		return role || ' (' ||starting ||'..' || ending ||')';
	end if;
end
$$ language PLPGSQL;

-- a view showing staff names, roles, staring and ending dates and sortname
create or replace view Q1_Roles (unswid, name, role, starting, ending, sortname)
as
select distinct p.unswid, p.name, sr.description, a.starting, a.ending, p.sortname
from Affiliation a, Staff s, StaffRoles sr, People p
where a.staff = s.id and a.role = sr.id and s.id = p.id
order by p.unswid , a.starting
;

-- a view showing staffs who had multiple roles
create or replace view Q1_validID(unswid, role_num)
as
select r2.unswid, count(r2.role) as role_num
from Q1_Roles r2
where r2.starting is not Null and r2.ending is not Null
group by r2.unswid
having count(r2.role)>1
;

-- aggregate state function
create or replace function concat_rows(row1 text, row2 text)
returns text
as $$
begin
	if row1 = '' then
		return row1 || row2;
	else
		return row1 || E'\n' || row2;
	end if;
end
$$ language PLPGSQL;

-- aggregate final function
create or replace function concat_rows_final(row2 text)
returns text
as $$
begin
	return row2 || E'\n';
end
$$ language PLPGSQL;

-- aggregate function: concatenate multiple roles
create aggregate aggr_rows(text)
(
	sfunc = concat_rows,
	stype = text,
	finalfunc = concat_rows_final,
	initcond = ''
);


-- Define Q1 function
create or replace function Q1() 
	returns setof EmploymentRecord 
as $$
begin	
	return query 
	select r.unswid, cast(r.name as text),aggr_rows(concat_RolesDate(r.role, r.starting, r.ending))
	from Q1_Roles r, Q1_validID v
	where r.unswid = v.unswid
	group by r.unswid, r.name, r.sortname
	order by r.sortname;
end;
$$ language PLPGSQL;



-- Q2: Trailing Space Record -----------------------------------------------------------------------
create type TrailingSpaceRecord as ("table" text, "column" text, nexamples integer);
create or replace function Q2("table" text) 
	returns setof TrailingSpaceRecord
as $$
declare
	col text;
	count integer;
	out TrailingSpaceRecord;
begin
	FOR col in EXECUTE(
		'SELECT column_name
		FROM information_schema.columns
		WHERE table_schema = ''public''
		 AND table_name   = ''' ||"table"||'''
		 AND data_type ~ ''character'''
		)
	LOOP
		EXECUTE(
		'select count(*) from '||"table"||
		' where length(rtrim('||col||'))!=length('||col||')'
		)into count;
		IF count>0
		THEN

			select "table" into out."table";
			select count into out.nexamples;
			select col into out."column";
			return next out;
		END IF;
	END LOOP;
	return;
end;
$$ language plpgsql;

-- Replace space by !
--create type replace_blank as (replaced text, len integer, len_reduced integer);
--create or replace function Q2_replace_blank(tablename text)
--returns setof replace_blank
--as $$
--begin
--	return query execute(
--	'select regexp_replace(r.longname,''[[:space:]]+$'',''!''),length(r.longname), length(rtrim(r.longname)) 
--	from '||tablename||' r
--	where length(trim(trailing from r.longname))!=length(r.longname)'
--	);
--end
--$$ language PLPGSQL;
--select * from Q2_replace_blank('subjects')


-- Q3: transcript with variations --------------------------------------------------------------------
create or replace function Q3(_sid integer) returns setof TranscriptRecord
as $$
declare
	rec TranscriptRecord;
	UOCtotal integer := 0;
	UOCpassed integer := 0;
	wsum integer := 0;
	wam integer := 0;
	x integer;
	r1 record;
	int_code text;	-- itnernal code
begin
	select s.id into x
	from   Students s join People p on (s.id = p.id)
	where  p.unswid = _sid;
	if (not found) then
		raise EXCEPTION 'Invalid student %',_sid;
	end if;
	for rec in
		select su.code, substr(t.year::text,3,2)||lower(t.sess),
			su.name, e.mark, e.grade, su.uoc
		from   CourseEnrolments e join Students s on (e.student = s.id)
			join People p on (s.id = p.id)
			join Courses c on (e.course = c.id)
			join Subjects su on (c.subject = su.id)
			join Terms t on (c.term = t.id)
		where  p.unswid = _sid
		order by t.starting,su.code
	loop
		if (rec.grade = 'SY') then
			UOCpassed := UOCpassed + rec.uoc;
		elsif (rec.mark is not null) then
			if (rec.grade in ('PT','PC','PS','CR','DN','HD')) then
				-- only counts towards creditted UOC
				-- if they passed the course
				UOCpassed := UOCpassed + rec.uoc;
			end if;
			-- we count fails towards the WAM calculation
			UOCtotal := UOCtotal + rec.uoc;
			-- weighted sum based on mark and uoc for course
			wsum := wsum + (rec.mark * rec.uoc);
		end if;
		return next rec;
	end loop;
	
	for r1 in 
		select * 
		from 	variations v join Students s on (v.student = s.id)
			join People p on (s.id = p.id)
			join Subjects su on (v.subject = su.id)
			left join ExternalSubjects es on (v.extEquiv = es.id)
		where 	p.unswid = _sid
		order by su.code
	loop
		if r1.vtype = 'advstanding' then
			UOCpassed := UOCpassed + r1.uoc;
			rec := (r1.code, NULL, 'Advanced standing, based on ...', NULL, NULL, r1.uoc);
			return next rec;
		end if;
		if r1.vtype = 'exemption' then
			rec := (r1.code, NULL, 'Exemption, based on ...', NULL, NULL, NULL);
			return next rec;
		end if;
		if r1.vtype = 'substitution' then
			UOCpassed := UOCpassed + r1.uoc;
			UOCtotal := UOCtotal + r1.uoc;		
			wsum := wsum + (r1.mark * r1.uoc);	
			rec := (r1.code, NULL, 'Substitution, based on ...', NULL, NULL, NULL);
			return next rec;
		end if;
		if r1.intEquiv is not NULL then
			select	s1.code into int_code
			from 	variations v1 join subjects s1 on (v1.intEquiv = s1.id);
			rec := (NULL, NULL, 'studying '||int_code||' at UNSW', NULL, NULL, NULL);
			return next rec;
		end if;
		if r1.extEquiv is not NULL then
			rec := (NULL, NULL, 'study at ' || r1.institution, NULL, NULL, NULL);
			return next rec;
		end if;	
	end loop;
	if (UOCtotal = 0) then
		rec := (null,null,'No WAM available',null,null,null);
	else
		wam := wsum / UOCtotal;
		rec := (null,null,'Overall WAM',wam,null,UOCpassed);
	end if;
	-- append the last record containing the WAM
	return next rec;
	return;
end;
$$ language plpgsql;
