-- ===================================================================
-- SQL Server DDL script:   am4dp_create.sql
--                    Creates the COURSE schema
--Based on example database AM4DP
--described in Applied Mathematics for Database Professionals (published by Apress, 2007) 
--written by Toon Koppelaars and Lex de Haan   
-- ===================================================================
-- Drop database COURSE first ...
-- ===================================================================

IF DB_ID('COURSE') IS NOT NULL
     DROP DATABASE COURSE
GO

CREATE DATABASE COURSE
GO

USE COURSE
GO

-- ===================================================================
-- Create GRD
-- =================================================================== 
create table  grd
( grade       numeric(2,0)   not null
, llimit      numeric(7,2)   not null
, ulimit      numeric(7,2)   not null
, bonus       numeric(7,2)   not null
);

-- ===================================================================
-- Create EMP
-- ===================================================================
create table  emp
( empno       numeric(4,0)   not null
, ename       varchar(8)    not null
, job         varchar(9)    not null
, born        date          not null
, hired       date          not null
, sgrade      numeric(2,0)   not null
, msal        numeric(7,2)   not null
, username    varchar(15)  not null
, deptno      numeric(2,0)   not null
); 

-- ===================================================================
-- Create SREP
-- ===================================================================
create table  srep
( empno       numeric(4,0)   not null
, target      numeric(6,0)   not null
, comm        numeric(7,2)   not null
);
 
-- ===================================================================
-- Create MEMP
-- ===================================================================
create table  memp
( empno       numeric(4,0)   not null
, mgr         numeric(4,0)   not null
);

-- ===================================================================
-- Create TERM
-- ===================================================================

create table  term
( empno       numeric(4,0)   not null
, leftcomp    date       not null			
, comments    varchar(60)   
); 

-- ===================================================================
-- Create DEPT
-- ===================================================================
create table  dept
( deptno      numeric(2,0)   not null
, dname       varchar(12)   not null
, loc         varchar(14)    not null
, mgr         numeric(4,0)   not null
);

-- ===================================================================
-- Create CRS
-- ===================================================================
create table  crs
( code        varchar(6)    not null
, descr       varchar(40)   not null
, cat         varchar(3)    not null
, dur         numeric(2,0)   not null
);

-- ===================================================================
-- Create OFFR
-- ===================================================================
create table  offr
( course      varchar(6)    not null
, starts      date          not null
, status      varchar(4)    not null
, maxcap      numeric(2,0)   not null
, trainer     numeric(4,0)   
, loc         varchar(14)    not null
);

-- ===================================================================
-- Create REG
-- ===================================================================
create table  reg
( stud        numeric(4,0)   not null
, course      varchar(6)    not null
, starts      date          not null
, eval        numeric(1,0)   not null
);

-- ===================================================================
-- Create HIST
-- ===================================================================
create table  hist
( empno       numeric(4,0)   not null
, until       date          not null
, deptno      numeric(2,0)   not null
, msal        numeric(7,2)   not null
);


