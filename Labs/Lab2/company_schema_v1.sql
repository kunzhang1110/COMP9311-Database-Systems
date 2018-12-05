-- Schema for simple company database

create table Employees (
	tfn         char(11)
	            constraint ValidTFN
		    check (tfn ~ '[0 - 9]{3} - [0 - 9]{3} - [0 - 9]{3}'),
	givenName   varchar(30) not null,
	familyName  varchar(30),
	hoursPweek  float
		    constraint ValidHPW
                    check (hoursPweek >= 0 and hoursPweek <=168),
	primary key (tfn)
);

create table Departments (
	id          char(3),
                    constraint ValidDeptID
                    check (id ~ '[0-9]{3}'),
	name        varchar(100) unique,
	manager     char(11) not null
		    constraint ValidEmployee references Employees(tfn),
	primary key (id)
);

create table DeptMissions (
	department  char(3),
	keyword     varchar(20),
	primary key (department, keyword)
);

create table WorksFor (
	employee    char(11)
		    constraint ValidEmployee references Employees(tfn),
	department  char(3)
		    constraint ValidDepartment references Departments(id),
	percentage  float
		    constraint ValidPtg
                    check (percentage>0.0 and percentage<=100.0)
);
