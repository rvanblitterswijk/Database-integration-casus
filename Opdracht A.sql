/*=====    A    ===============================================================================================================================================================================================================*/

--Drop all foreign keys to implement cascading rules

--Set results to text
select ' alter table ' + TABLE_NAME + ' drop constraint ' + CONSTRAINT_NAME from INFORMATION_SCHEMA.TABLE_CONSTRAINTS where CONSTRAINT_TYPE = 'FOREIGN KEY'

alter table emp drop constraint emp_fk_grd
alter table emp drop constraint emp_fk_dep
alter table srep drop constraint srp_fk_emp
alter table memp drop constraint mmp_fk1_emp
alter table memp drop constraint mmp_fk2_emp
alter table term drop constraint trm_fk_emp
alter table dept drop constraint dep_fk_emp
alter table offr drop constraint ofr_fk_crs
alter table offr drop constraint ofr_fk_emp
alter table reg drop constraint reg_fk_emp
alter table reg drop constraint reg_fk_ofr
alter table hist drop constraint hst_fk_emp
alter table hist drop constraint hst_fk_dep
--Set results to grid

--Implement foreign keys with cascading rules like in the PDM:
alter table srep
add constraint srep_fk_emp foreign key (empno) references emp(empno)
on delete cascade
alter table memp 
add constraint mmp_fk1_emp foreign key (empno) references emp(empno)
alter table memp 
add constraint mmp_fk2_emp foreign key (mgr) references emp(empno)
alter table hist 
add constraint hist_fk_emp foreign key (empno) references emp(empno)
on delete cascade
alter table hist
add constraint hist_fk_dept foreign key (deptno) references dept(deptno)
alter table dept
add constraint dept_fk_emp foreign key (mgr) references emp(empno)
alter table emp
add constraint emp_fk1_dept foreign key (deptno) references dept(deptno)
alter table emp
add constraint emp_fk2_grd foreign key (sgrade) references grd(grade)
on update cascade
alter table offr
add constraint offr_fk1_emp foreign key (trainer) references emp(empno)
on delete set null
alter table offr
add constraint offr_fk2_crs foreign key (course) references crs(code)
on update cascade
alter table reg
add constraint reg_fk1_offr foreign key (course, starts) references offr(course, starts)
alter table reg
add constraint reg_fk2_emp foreign key (stud) references emp(empno)
on delete cascade
alter table term
add constraint term_fk_emp foreign key (empno) references emp(empno)
