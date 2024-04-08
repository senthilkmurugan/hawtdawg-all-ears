/* 
Adding POC Data: 
	1. POC interaction at vendor level and vendor x campaign level both.
	2. Try out both the metrics to check which is making sense.
*/


/* Defining the path */
libname MDB "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/MDB";

Proc SQL;
Create table Cube1 as 
select * from MDB.BELSOMRA_HCP_MDB_Feb20_Feb23;
Run;

/* QC Checks */
Proc print data=cube1 (obs=20);
Run;

Proc sql;
select count(distinct PARTY_ID), count(distinct yearmo) from Cube1;
/* IDs: 632559, Months: 37 */
select count(distinct PARTY_ID), count(distinct yearmo) from Cube1 
where yearmo>=202102 and yearmo<=202301;
/* IDs: 628204, Months: 24 */
Run;


/* Defining Path */
%LET PATH="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Common/POC Data/"; 
LIBNAME LOCAL &PATH;


/* QC Check For All the vendors */
Data poc;
set  LOCAL.poc_jan21jan23_hcp_updt;
where New_Brand='BELSOMRA';
run;

proc sql;
select distinct(vendor_name) from poc;
run;


/* Phase 1: POC data Agg at vendor level (Flag at Party ID level) Agg means 0 and 1 at HCP level */
proc print data=LOCAL.final_poc_brand_data_agg (obs=100);
run;

proc means data=LOCAL.final_poc_brand_data_agg NMISS N; 
run;

Data pp1;
set  LOCAL.final_poc_brand_data_agg;
if nmiss(party_id) > 0 
then delete;
where BRAND='BELSOMRA';
run;


Data pp1;
set pp1;
year = input(yearmo, 6.);
drop yearmo;
rename year=yearmo;
run;

/* QC */
proc sql;
select distinct yearmo from pp1;
/* POC Data from Jan'21 - Dec'23 */
select sum(pp_hcp), sum(pp_hcc), sum(cw_comm), sum(webmd) 
from pp1 where yearmo <= 202301;
/* 65930,864761,149017,64834 */
run;


/* proc export data = pp1 */
/* outfile= "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/Belsomra_POC_Data.csv"  */
/* dbms= csv replace; */
/* run; */


/* Filtering for the Modelling Time Frame */
DATA PP1;
SET PP1;
WHERE YEARMO>202002 and yearmo<202302;
/* POC data from Jan'21 - Dec'23 */
RUN;

/* QC Check */
proc sql;
select distinct yearmo from PP1;
run;

proc sql;
select yearmo,
sum(pp_hcp) as pp_hcp_agg,
sum(pp_hcc) as pp_hcc_agg,
sum(pw_hcc) as pw_hcc_agg,
sum(const_med) as const_med_agg,
sum(cw_comm) as cw_comm_agg,
sum(TMH) as TMH_agg,
sum(check_up) as check_up_agg,
sum(HM) as HM_agg,
Sum(RH) as RH_agg,
sum(webmd) as webmd_agg,
sum(writemd) as writemd_agg 
from pp1 group by yearmo;
Run;

/* Patient Point HCP & HCC, WebMD and CoverWrap communications is only active for Belsomra in */
proc sql;
create table pp1 as 
select party_id, yearmo,
sum(pp_hcp) as pp_hcp_agg,
sum(pp_hcc) as pp_hcc_agg,
sum(cw_comm) as cw_comm_agg,
sum(webmd) as webmd_agg
from pp1 
group by 1,2 
order by 1,2;
run;

proc sql;
select max(pp_hcp_agg), max(pp_hcc_agg), max(cw_comm_agg), max(webmd_agg) from pp1;
run;

proc sql;
select count(*), count(distinct party_id), count(distinct yearmo) from PP1;
/* No.of Rows:991814, IDs:61431, Months:25 (Jan'21-Jan'23) */
select sum(pp_hcp_agg), sum(pp_hcc_agg), sum(cw_comm_agg), sum(webmd_agg) from PP1;
/* 65930,864761,149017,64834 */
run;

PROC SORT DATA=pp1 nodupkey out=ppp1; BY PARTY_ID yearmo ; 
RUN;



/* Phase 2: POC data vendor x campaign level (If we have diff camp running at vend x Camp level like PP HCC) - Freq of Reach of POC is used*/
proc print data=LOCAL.final_poc_brand_data (obs=100);
run;

Data pp2;
set  LOCAL.final_poc_brand_data;
if nmiss(party_id) > 0 
then delete;
where BRAND='BELSOMRA';
run;

proc sql;
select distinct yearmo from pp2;
run;


Data pp2;
set pp2;
year = input(yearmo, 6.);
drop yearmo;
rename year=yearmo;
run;


DATA PP2;
SET PP2;
WHERE YEARMO>202002 and yearmo<202302;
RUN;


/* proc export data = pp2 */
/* outfile= "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/Belsomra_POC_Data_HCC.csv"  */
/* dbms= csv replace; */
/* run; */


/* QC Check */
proc sql;
select yearmo,
sum(pp_hcp) as pp_hcp,
sum(pp_hcc) as pp_hcc,
sum(pw_hcc) as pw_hcc,
sum(const_med) as const_med,
sum(cw_comm) as cw_comm,
sum(TMH) as TMH,
sum(check_up) as check_up,
sum(HM) as HM,
Sum(RH) as RH,
sum(webmd) as webmd,
sum(writemd) as writemd 
from pp2 group by yearmo;
run;


/* Patient Point HCP & HCC, WebMD and CoverWrap communications is only active for Belsomra in */
proc sql;
create table pp2 as 
select party_id, yearmo,
sum(pp_hcp) as pp_hcp,
sum(pp_hcc) as pp_hcc,
sum(cw_comm) as cw_comm,
sum(webmd) as webmd
from pp2 group by 1,2 
order by 1,2;
run;

proc sql;
select max(pp_hcp), max(pp_hcc), max(cw_comm), max(webmd) from pp2;
select count(*), count(distinct party_id), count(distinct yearmo) from PP2;
/* No.of Rows:991814, IDs:61431, Months:25 */
run;

PROC SORT DATA=pp2 nodupkey out=ppp2; 
BY PARTY_ID yearmo ; 
RUN;



/* Selecting unique Party_ID's */
proc sql;
create table party_id_pp as 
select distinct party_id from ppp1;
run;

proc sql;
create table party_id_MDB as 
select distinct party_id from MDB.BELSOMRA_HCP_MDB_Feb20_Feb23;
run;

/*  */
proc sql;
select count(party_id) from party_id_pp;
/* Party_id: 61431 */
select count(party_id) from party_id_MDB;
/* Party_id: 632559 */
run;

proc sql;
select distinct yearmo from MDB.BELSOMRA_HCP_MDB_Feb20_Feb23;
/* Feb'20 - Feb'23  */
run;

PROC SQL;
CREATE TABLE SET AS 
SELECT PARTY_ID FROM PARTY_ID_MDB UNION 
SELECT PARTY_ID FROM PARTY_ID_PP
ORDER BY PARTY_ID ;
RUN;

proc sql;
select count(distinct party_id) from set;
run;


/* Selecting Unique Months */
proc sql; create table yearmo 
as select distinct yearmo as yearmo from cube1 order by yearmo;
run;


/* Creating Standardized Data */
proc sql;
create table dummy as select party_id, yearmo from yearmo cross join SET
order by 1, 2 ;
run;

PROC SORT DATA=cube1;
BY PARTY_ID YEARMO; 
RUN;

DATA cube1;
set cube1;
drop brand;
run;

/* QC Check */
proc means data=Cube1 NMISS N; 
run;

proc sql;
select count(distinct(party_id)) from PARTY_ID_MDB;
select count(distinct(party_id)) from PARTY_ID_PP;
select count(party_id) from set;
select count(distinct(party_id)) from set;
select count(distinct(party_id)) from dummy;


CREATE TABLE SET2 AS 
SELECT PARTY_ID FROM PARTY_ID_MDB UNION All
SELECT PARTY_ID FROM PARTY_ID_PP
ORDER BY PARTY_ID ;
select count(party_id) from set2;
select count(distinct(yearmo)) from dummy;
select count(distinct(party_id))*count(distinct(yearmo)), count(*) from dummy;
Run;


/* Left joining POC data */
PROC SQL ;
CREATE TABLE Cube2 AS
SELECT A.*, B.* 
FROM DUMMY AS A LEFT JOIN Cube1 AS B 
ON A.PARTY_ID = B.PARTY_ID AND A.YEARMO = B.YEARMO;
RUN;

PROC SQL ;
CREATE TABLE Cube3 AS
SELECT A.*, B.* FROM Cube2 AS A LEFT JOIN PPP1 AS B 
ON A.PARTY_ID = B.PARTY_ID AND A.YEARMO = B.YEARMO;
RUN;

PROC SQL ;
CREATE TABLE Cube4 AS
SELECT A.*, B.* FROM Cube3 AS A LEFT JOIN PPP2 AS B 
ON A.PARTY_ID = B.PARTY_ID AND A.YEARMO = B.YEARMO;
RUN;


proc stdize data=cube4
	out=cube5
	reponly missing=0;
run;

data cube5;
set cube5;
drop year month day;
run;


/* Check */
proc sql;
select count(distinct(party_id)), count(*) from Cube5;
/* IDs:645352,	Rows:23878024 */
Run;

proc sql;
select sum(pp_hcp), sum(pp_hcc), sum(cw_comm), sum(webmd) from pp2;
select sum(pp_hcp), sum(pp_hcc), sum(cw_comm), sum(webmd) from cube5;
run;
proc sql;
select sum(pp_hcp_agg), sum(pp_hcc_agg), sum(cw_comm_agg), sum(webmd_agg) from pp1;
select sum(pp_hcp_agg), sum(pp_hcc_agg), sum(cw_comm_agg), sum(webmd_agg) from cube5;
run;


/* Spliting Pre and Post (Oct'21)*/
proc sql;
create table email_split as 
select party_id, yearmo,
case
	when yearmo>=202110 then hcp_field_eng
	else 0
	end as hcp_field_eng_post,
case
	when yearmo<202110 then hcp_field_eng
	else 0
	end as hcp_field_eng_pre,
case
	when yearmo>=202110 then hcp_sfmc_eng
	else 0
	end as hcp_sfmc_eng_post,
case
	when yearmo<202110 then hcp_sfmc_eng
	else 0
	end as hcp_sfmc_eng_pre
from cube5;
run;

/* Check */
proc sql;
select sum(hcp_field_eng_pre), sum(hcp_sfmc_eng_pre) from email_split where yearmo >= 202201 and yearmo <=202212;
Run; 

PROC SQL ;
CREATE TABLE Cube6 AS
SELECT A.*, B.* FROM Cube5 AS A LEFT JOIN email_split AS B 
ON A.PARTY_ID = B.PARTY_ID AND A.YEARMO = B.YEARMO;
RUN;

/* Check */
proc sql;
select sum(hcp_field_eng_pre), sum(hcp_sfmc_eng_pre) from Cube6 where yearmo >= 202201 and yearmo <=202212;
Run; 


proc sql;
create table MDB.BELSOMRA_HCP_Feb20_Feb23_Final as 
select *, 
case when pp_hcc > 0 or pp_hcp >0 
then 1 else 0
end as pp_any 
from cube6;
run;


/* Qc Check  */
proc sql;
select sum(hcp_sfmc_eng_post)+sum(hcp_sfmc_eng_pre), sum(hcp_sfmc_eng), 
sum(hcp_field_eng_post)+sum(hcp_field_eng_pre), sum(hcp_field_eng) 
from MDB.BELSOMRA_HCP_Feb20_Feb23_Final;
/* 447883	447883	77995	77995*/
select count(*), count(distinct(party_id)), sum(hcp_grail_nrx) 
from MDB.BELSOMRA_HCP_Feb20_Feb23_Final where yearmo >=202102 and yearmo <=202301;
/* 15488448,645352,493963.4 */

run;

proc sql;
select count(*), count(distinct party_id), sum(hcp_grail_nrx) 
from MDB.BELSOMRA_HCP_Feb20_Feb23_Final ;
/* 23878024, 645352, 493963.4 */
run;

proc sql;
select sum(pp_hcc), sum(pp_hcp), sum(pp_any) 
from MDB.BELSOMRA_HCP_Feb20_Feb23_Final ;
/* 963370	65930	884727 - sum want match because it has freq */
run;

