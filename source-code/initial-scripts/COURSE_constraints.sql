-- ===================================================================
-- SQL Server DDL script:   am4dp_create.sql
--                    Creates the COURSE schema
--Based on example database AM4DP
--described in Applied Mathematics for Database Professionals (published by Apress, 2007) 
--written by Toon Koppelaars and Lex de Haan   

use COURSE; 

-- Een salarisschaal specificeert salarisinterval van minimaal 500 euro.
-- De ondergrens waarde van een salarisschaal (llimit) identificeert de schaal in kwestie. 
-- Oefeningen studenten eind week 1
 
 -- attribute constraints:
alter table grd add constraint  grd_chk_grad  check (grade  > 0);
alter table grd add constraint  grd_chk_llim  check (llimit > 0);
alter table grd add constraint  grd_chk_ulim  check (ulimit > 0);
alter table grd add constraint  grd_chk_bon1  check (bonus  > 0);

 -- tuple constraints:
 
alter table grd add constraint  grd_chk_bon2  check (bonus < llimit);
  --table constraints:
alter table grd add constraint  grd_pk        primary key (grade);
alter table grd add constraint  grd_unq2      unique (ulimit);
  -- attribute constraints: -- 
alter table emp add constraint  emp_chk_empno check (empno > 999);
alter table emp add constraint  emp_chk_job   check (job in ('PRESIDENT'
                                         ,'MANAGER'
                                         ,'SALESREP'
                                         ,'TRAINER'
                                         ,'ADMIN'  ));
alter table emp add constraint  emp_chk_brn    check (cast(born as date) = born);
alter table emp add constraint  emp_chk_hrd   check (cast(hired as date) = hired);
alter table emp add constraint  emp_chk_msal   check (msal > 0);
alter table emp add constraint  emp_chk_usrnm  check(upper(username) = username);
  -- tuple constraints:
  -- table constraints:
alter table emp add constraint  emp_pk        primary key (empno);
alter table emp add constraint  emp_unq1      unique (username);
  -- attribute constraints:
alter table srep add constraint  srp_chk_empno check (empno > 999);
alter table srep add constraint  srp_chk_targ  check (target > 9999);
alter table srep add constraint  srp_chk_comm  check (comm > 0);
  -- table constraints:
alter table srep add constraint  srp_pk        primary key (empno);
  -- attribute constraints:
alter table memp add constraint  mmp_chk_empno check (empno > 999);
alter table memp add constraint  mmp_chk_mgr   check (mgr > 999);
  -- tuple constraints:
alter table memp add constraint  mmp_chk_cycl  check (empno <> mgr); 
  -- table constraints:
alter table memp add constraint  mmp_pk        primary key (empno);
  -- attribute constraints:
alter table term add constraint  trm_chk_empno check (empno > 999);
alter table term add constraint  trm_chk_lft   check (cast(leftcomp as date) = leftcomp);
  -- tuple constraints:
  -- table constraints:
alter table term add constraint  trm_pk        primary key (empno);
  -- attribute constraints:
alter table dept add constraint  dep_chk_dno   check (deptno > 0);
alter table dept add constraint  dep_chk_dnm   check (upper(dname) = dname);
alter table dept add constraint  dep_chk_loc   check (upper(loc) = loc);
alter table dept add constraint  dep_chk_mgr   check (mgr > 999);
  -- tuple constraints:
  -- table constraints:
alter table dept add constraint  dep_pk        primary key (deptno);
alter table dept add constraint  dep_unq1      unique (dname,loc);
  -- attribute constraints:
alter table crs add constraint  reg_chk_code  check (code = upper(code));
alter table crs add constraint  reg_chk_cat   check (cat in ('GEN','BLD','DSG'));
alter table crs add constraint  reg_chk_dur1  check (dur between 1 and 15);
  -- tuple constraints:
alter table crs add constraint  reg_chk_dur2  check (cat <> 'BLD' OR dur <= 5);
  -- table constraints:
alter table crs add constraint  crs_pk        primary key (code);


-- Een cursus uitvoering (tabel OFFR) heeft altijd een trainer tenzij de status waarde 
-- aangeeft dat de cursus afgeblazen (status ‘CANC’) is of dat de cursus gepland is (status ‘SCHD’).  
-- Oefening studenten eind week 1

  -- attribute constraints:
alter table offr add constraint  ofr_chk_crse  check (course = upper(course));
alter table offr add constraint  ofr_chk_strs  check (cast(starts as date) = starts);
alter table offr add constraint  ofr_chk_stat  check (status in ('SCHD','CONF','CANC'));
alter table offr add constraint  ofr_chk_mxcp  check (maxcap between 6 and 99);
  -- tuple constraints:

  -- table constraints:
alter table offr add constraint  ofr_pk        primary key (course,starts);
alter table offr add constraint  ofr_unq       unique (starts,trainer);
  -- attribute constraints:
alter table reg add constraint  reg_chk_stud  check (stud > 999);
alter table reg add constraint  reg_chk_crse  check (course = upper(course));
alter table reg add constraint  reg_chk_strs  check (cast(starts as date) = starts);
alter table reg add constraint  reg_chk_eval  check (eval between -1 and 5);
  -- tuple constraints:
  -- table constraints:
alter table reg add constraint  reg_pk        primary key (stud,starts);
  -- attribute constraints:
alter table hist add constraint  hst_chk_eno   check (empno > 999);
alter table hist add constraint  hst_chk_unt   check (cast(until as date) = until);
alter table hist add constraint  hst_chk_dno   check (deptno > 0);
alter table hist add constraint  hst_chk_msal  check (msal > 0);
  -- tuple constraints:
  -- table constraints:
alter table hist add constraint  hst_pk        primary key (empno,until);
 -- database constraints:
alter table emp add constraint  emp_fk_grd    foreign key (sgrade)
                            references grd(grade);
alter table emp add constraint  emp_fk_dep foreign key (deptno)
										   references dept(deptno);
 -- database constraints:
alter table srep add constraint  srp_fk_emp    foreign key (empno)
                            references emp(empno);
 -- database constraints:
alter table memp add constraint  mmp_fk1_emp   foreign key (empno)
                            references emp(empno);
alter table memp add constraint  mmp_fk2_emp   foreign key (mgr)
                            references emp(empno);
 -- database constraints:
alter table term add constraint  trm_fk_emp    foreign key (empno)
                            references emp(empno);
alter table dept add constraint  dep_fk_emp    foreign key (mgr)
                            references emp(empno); 

 -- database constraints:
alter table offr add constraint  ofr_fk_crs    foreign key (course)
                            references crs(code);
alter table offr add  constraint  ofr_fk_emp    foreign key (trainer)
                            references emp(empno);
 -- database constraints:
alter table reg add constraint  reg_fk_emp    foreign key (stud)
                            references emp(empno);
alter table reg add constraint  reg_fk_ofr    foreign key (course,starts)
                            references offr(course,starts);
 -- database constraints:
alter table hist add constraint  hst_fk_emp    foreign key (empno)
                            references emp(empno);
alter table hist add constraint  hst_fk_dep    foreign key (deptno)
                            references dept(deptno);
