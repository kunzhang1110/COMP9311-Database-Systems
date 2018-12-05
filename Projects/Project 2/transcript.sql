CREATE OR REPLACE FUNCTION public.transcript(_sid integer)
 RETURNS SETOF transcriptrecord
 LANGUAGE plpgsql
AS $function$
declare
	rec TranscriptRecord;
	UOCtotal integer := 0;
	UOCpassed integer := 0;
	wsum integer := 0;
	wam integer := 0;
	x integer;
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
$function$