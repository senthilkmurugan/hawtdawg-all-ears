/* 
Adding POC Data: 
	1. POC interaction at vendor level and vendor x campaign level both.
	2. Try out both the metrics to check which is making sense.
*/

/* Defining the path */
libname MDB "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCC/MDB";
LIBNAME HCC "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCC/FINAL_DATASET";
LIBNAME ZIP_DMA "/efs-MAIO/Shared_Data/ZiptoDMA";

Proc SQL;
create table Cube1 as 
select * from MDB.BELSOMRA_HCC_MDB_May19_Mar23;
Run;

/* Checks */
proc print data=cube1 (obs=20);
run;


proc sql;
select count(distinct Dmaname), count(distinct yearmo) from Cube1;
/* DMAs: 211, Months: 47 */
run;


/* Defining Path */
%LET PATH="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Common/POC Data/"; 
LIBNAME LOCAL &PATH;

/* QC Check For All the vendors (Checking the raw table) */
Data poc;
set  LOCAL.poc_jan21jan23_hcp_updt;
where New_Brand='BELSOMRA';
run;

proc print data=poc (obs=10);
run;

proc sql;
select distinct(vendor_name) from poc;
/* coverwrap_communications, patient_point, web_md */
run;

proc sql;
select sum(pp_hcc) from LOCAL.final_poc_brand_data_agg;
/* 6885990 */
select sum(pp_hcc) from LOCAL.final_poc_brand_data;
/* 7953463 */
run;

proc sql;
select count(*), sum(pp_hcc), SUM(PP_HCP) from LOCAL.final_poc_brand_data_agg 
where yearmo <='202301' and BRAND='BELSOMRA';
/* 991814	864761	65930 */
select count(*), sum(pp_hcc), SUM(PP_HCP) from LOCAL.final_poc_brand_data 
where yearmo <='202301' and BRAND='BELSOMRA';
/* 1243151	963370	65930 */
run;

proc sql;
select distinct yearmo from LOCAL.final_poc_brand_data_agg 
where yearmo <='202301';
select distinct yearmo from LOCAL.final_poc_brand_data 
where yearmo <='202301';
run;



/* POC data Agg at vendor level (Flag at Party ID level) - PP HCC has 1 as a flag with multiple campaign*/
proc print data=LOCAL.final_poc_brand_data_agg (obs=100);
run;

proc means data=LOCAL.final_poc_brand_data_agg NMISS N; 
run;

Data pp1;
set  LOCAL.final_poc_brand_data_agg;
if nmiss(zip_cd) > 0 
then delete;
where BRAND='BELSOMRA';
run;

proc sql;
select distinct yearmo from pp1;
/* Jan'21-Dec'23 */
run;

Data pp1;
set pp1;
year = input(yearmo, 6.);
zip_code = input(zip_cd,19.);
drop yearmo;
rename year=yearmo;
run;

proc sql;
select count(*), sum(pp_hcc) from pp1 where yearmo <=202301;
/* 991814	864761 */
run;


/* **********Zip to DMA name mapping************ */
proc print data=ZIP_DMA.zip_to_dma_2022zips_deduped (obs=100);
run;

Data zip_to_dma;
set ZIP_DMA.zip_to_dma_2022zips_deduped;
zip_cd = input(zipcode,19.);
keep zip_cd dmaname;
run;

/* Left Joining the zip-dma mapping  */
PROC SQL NOPRINT;
  CREATE TABLE poc1 as
   SELECT a.*, b.DMANAME
   from pp1 as a left join  zip_to_dma as b
   on a.zip_code=b.zip_cd;
run;

data poc1;
set poc1;
if dmaname = " " then dmaname = "ZZUNASSIGNED";
dmaname = upcase(dmaname);
drop zip_code;
run;


proc summary data= poc1  sum nway;
var _numeric_;
output out = summ(drop = _:) sum=;
run;

/* QC */
proc sql;
select count(*), count(distinct yearmo), sum(pp_hcc), sum(pp_hcp) from poc1 where dmaname = "ZZUNASSIGNED" ;
/* 968	36	920	60 */
run;

/* Patient Point HCP & HCC, WebMD and CoverWrap communications is only active for Belsomra in */
PROC SQL NOPRINT;
  CREATE TABLE poc1_dma_agg as 
  SELECT dmaname, yearmo, sum(pp_hcp) as pp_hcp_agg, sum(pp_hcc) as pp_hcc_agg, sum(cw_comm) as cw_comm_agg, sum(webmd) as webmd_agg from poc1 group by 1, 2;
quit;

proc summary data= poc1_dma_agg  sum nway;
var _numeric_;
output out = summ(drop = _:) sum=;
run;

/* QC check */
proc sql;
select count(*), count(distinct yearmo), sum(pp_hcc), sum(pp_hcp) from pp1 where yearmo <=202301;
/* 991814	25	864761	65930 */
select count(*), count(distinct yearmo), sum(pp_hcc_agg), sum(pp_hcp_agg) from poc1_dma_agg where yearmo <=202301;
/* 5179	25	864761	65930 */ 
run;

proc sql;
select count(*), count(distinct yearmo), sum(pp_hcc_agg), sum(pp_hcp_agg) from poc1_dma_agg where dmaname = "ZZUNASSIGNED" ;
/* 36	36	920	60 */
select * from poc1_dma_agg where dmaname = "ZZUNASSIGNED";
run;


/* Filtering for the Modelling Time Frame */
DATA poc1_dma_agg;
SET poc1_dma_agg;
WHERE YEARMO>202002 and yearmo<202303;
RUN;

/* QC Check */
proc sql;
select count(*), count(distinct yearmo), sum(pp_hcc), sum(pp_hcp), sum(cw_comm), sum(webmd) from poc1 WHERE YEARMO>202002 and yearmo<202303;
/* 1023447	26	888615	68020	162564	64834 */

select count(*), count(distinct yearmo), sum(pp_hcc_agg), sum(pp_hcp_agg), sum(cw_comm_agg), sum(webmd_agg) from poc1_dma_agg;
/* 7404	36	1027765	88920	162564	64834 */
run;

proc sql;
select max(pp_hcp_agg), max(pp_hcc_agg), max(cw_comm_agg), max(webmd_agg) from poc1_dma_agg;
/*  187	3002 998 612 */
select sum(pp_hcp_agg), sum(pp_hcc_agg), sum(cw_comm_agg), sum(webmd_agg) from poc1_dma_agg;
/* 88920	1027765	162564	64834 */
run;

proc sql;
select count(*), count(distinct dmaname), count(distinct yearmo) from poc1_dma_agg;
/* No.of Rows:5384, DMA name's:209, Months:26 */
run;

PROC SORT DATA=poc1_dma_agg nodupkey out=poc1_dma_agg; 
BY dmaname yearmo ; 
RUN;



/* **************POC data vendor x campaign level (If we have diff camp running at vend x Camp level like PP HCC)************* */
proc print data=LOCAL.final_poc_brand_data (obs=100);
run;

proc means data=LOCAL.final_poc_brand_data NMISS N; 
run;

Data pp2;
set  LOCAL.final_poc_brand_data;
if nmiss(zip_cd) > 0 
then delete;
where BRAND='BELSOMRA';
run;

Data pp2;
set pp2;
year = input(yearmo, 6.);
zip_code = input(zip_cd,19.);
drop yearmo zip_cd;
rename year=yearmo;
run;
 

PROC SQL NOPRINT;
  CREATE TABLE poc2 as 
  SELECT a.*, b.DMANAME
   from pp2 as a left join  zip_to_dma as b
   on a.zip_code=b.zip_cd;
quit;

data poc2;
set poc2;
if dmaname = " " then dmaname = "ZZUNASSIGNED";
dmaname = upcase(dmaname);
drop zip_code;
run;


proc summary data= poc2  sum nway;
var _numeric_;
output out = summ(drop = _:) sum=;
run;


/* Patient Point HCP & HCC, WebMD and CoverWrap communications is only active for Belsomra in */
PROC SQL NOPRINT;
  CREATE TABLE poc2_dma_agg as 
  SELECT dmaname, yearmo, sum(pp_hcp) as pp_hcp, sum(pp_hcc) as pp_hcc, sum(cw_comm) as cw_comm, sum(webmd) as webmd from poc2 group by 1, 2;
quit;

proc summary data= poc2_dma_agg  sum nway;
var _numeric_;
output out = summ(drop = _:) sum=;
run;

/* QC check */
proc sql;
select count(*), count(distinct yearmo), sum(pp_hcc), sum(pp_hcp) from pp2 where yearmo <=202301;
/* 1243151	25	963370	65930 */
select count(*), count(distinct yearmo), sum(pp_hcc), sum(pp_hcp) from poc2 where yearmo <=202301;
/* 1243151	25	963370	65930 */
select count(*), count(distinct yearmo), sum(pp_hcc), sum(pp_hcp) from poc2_dma_agg where yearmo <=202301;
/* 5179	25	963370	65930 */
Run;


/* Filtering for the Modelling Time Frame */
DATA poc2_dma_agg;
SET poc2_dma_agg;
WHERE YEARMO>202002 and yearmo<202303;
RUN;

/* QC Check */
proc sql;
select distinct yearmo from poc2_dma_agg;
run;

proc sql;
select max(pp_hcp), max(pp_hcc), max(cw_comm), max(webmd) from poc2_dma_agg;
/* 187	3652	998	612 */
select sum(pp_hcp), sum(pp_hcc), sum(cw_comm), sum(webmd) from poc2_dma_agg;
/* 68020	997571	162564	64834 */
run;

proc sql;
select count(*), count(distinct dmaname), count(distinct yearmo) from poc2_dma_agg;
/* No.of Rows:5384, DMA name's:209, Months:26 */
run;

PROC SORT DATA=poc2_dma_agg nodupkey out=poc2_dma_agg; 
BY dmaname yearmo ; 
RUN;


/* ***************Selecting unique dmaname**************** */
proc sql;
create table dmaname_poc as 
select distinct dmaname from poc1_dma_agg;
run;

proc sql;
create table dmaname_MDB as 
select distinct dmaname from MDB.BELSOMRA_HCC_MDB_May19_Mar23;
run;


PROC SQL;
CREATE TABLE SET AS 
SELECT dmaname FROM dmaname_MDB UNION 
SELECT dmaname FROM dmaname_poc
ORDER BY dmaname ;
RUN;


/* *************Selecting Unique Months****************** */
proc sql; create table yearmo 
as select distinct yearmo as yearmo from cube1 
where yearmo >=202002 and  yearmo <= 202301 order by yearmo;
run;

proc sql;
select distinct yearmo from yearmo;
select count(distinct yearmo) from yearmo;
/* 36 Months of Data */
run;


/* Creating Standardized Data */
proc sql;
create table dummy as select dmaname, yearmo from yearmo cross join SET
order by 1, 2 ;
run;

PROC SORT DATA=cube1;
BY dmaname YEARMO; 
RUN;

DATA cube1;
set cube1;
drop brand;
run;


/* QC Check */
proc means data=Cube1 NMISS N; 
run;

proc sql;
select count(distinct(dmaname)) from dmaname_MDB;
select count(distinct(dmaname)) from dmaname_POC;
select count(*) from dummy;
select count(*) from cube1;
select count(distinct(dmaname)) from set;
select count(distinct(dmaname)) from dummy;
select count(distinct yearmo) from yearmo;
Run;


/* Left joining POC data */
PROC SQL ;
CREATE TABLE Cube2 AS
SELECT A.*, B.* 
FROM DUMMY AS A LEFT JOIN Cube1 AS B 
ON A.dmaname = B.dmaname AND A.YEARMO = B.YEARMO;
RUN;

PROC SQL ;
CREATE TABLE Cube3 AS
SELECT A.*, B.* FROM Cube2 AS A LEFT JOIN poc1_dma_agg AS B 
ON A.dmaname = B.dmaname AND A.YEARMO = B.YEARMO;
RUN;

PROC SQL ;
CREATE TABLE Cube4 AS
SELECT A.*, B.* FROM Cube3 AS A LEFT JOIN poc2_dma_agg AS B 
ON A.dmaname = B.dmaname AND A.YEARMO = B.YEARMO;
RUN;

PROC SQL ;
CREATE TABLE Cube5 AS
SELECT *, 
case when pp_hcc > 0 or pp_hcp >0 
then pp_hcc+pp_hcp else 0
end as pp_any , 
(hcp_dox_eng+hcp_dpint_eng+hcp_edh_eng+hcp_epoc_eng+hcp_field_eng+hcp_mng_eng+hcp_mscap_eng+hcp_sfmc_eng) as hcp_npp_eng,
(hcp_dox_clkd+hcp_dpint_clkd+hcp_edh_clkd+hcp_epoc_clkd+hcp_field_clkd+hcp_mng_clkd+hcp_mscap_clkd+hcp_sfmc_clkd) as hcp_npp_clkd,
(hcp_dox_del+hcp_dpint_del+hcp_edh_del+hcp_epoc_del+hcp_field_del+hcp_mng_del+hcp_mscap_del+hcp_sfmc_del) as hcp_npp_del 
from cube4;
RUN;

/* Checks */
Proc sql;
select sum(pp_hcc)+sum(pp_hcp), sum(pp_any) from cube5;
run;


proc stdize data=cube5
	out=cube6
	reponly missing=0;
run;

data cube6;
set cube6;
drop year month day;
run;

proc sql;
create table HCC.BELSOMRA_HCC_Feb20_Jan23_Final as 
select * from cube6
run;

/* Check */
proc means data=Cube6 NMISS N; 
run;

proc sql;
select count(distinct(dmaname)), count(*) from Cube6;
/* IDs:211,	Rows:8440 */
Run;

proc sql;
select sum(pp_hcp), sum(pp_hcc), sum(cw_comm), sum(webmd) from poc2_dma_agg 
where yearmo >=202002 and yearmo <=202301;
/* 65930	963370	149017	64834 */
select sum(pp_hcp), sum(pp_hcc), sum(cw_comm), sum(webmd) from cube6 
where yearmo >=202002 and yearmo <=202301;
/* 65930	963370	149017	64834 */
run;

proc sql;
select sum(pp_hcp_agg), sum(pp_hcc_agg), sum(cw_comm_agg), sum(webmd_agg) 
from poc1_dma_agg where yearmo >=202002 and yearmo <=202301;
/* 65930	864761	149017	64834 */
select sum(pp_hcp_agg), sum(pp_hcc_agg), sum(cw_comm_agg), sum(webmd_agg) 
from cube6 where yearmo >=202002 and yearmo <=202301;
/* 65930	864761	149017	64834 */
run;


/* Qc Check  */
Proc Sql;
select count(distinct(dmaname)) from HCC.BELSOMRA_HCC_Feb20_Jan23_Final;
Run;

proc sql;
select yearmo, sum(hcp_npp_eng), sum(hcp_dox_eng), sum(pp_hcp), sum(pp_hcc), sum(pp_any) from HCC.BELSOMRA_HCC_Feb20_Jan23_Final group by 1 order by 1;
Run;

proc sql;
select count(*), count(distinct yearmo), sum(hcp_grail_nrx) from HCC.BELSOMRA_HCC_Feb20_Jan23_Final where dmaname = "ZZUNASSIGNED" ;
/* 36	36	43.059 */
select * from HCC.BELSOMRA_HCC_Feb20_Jan23_Final where dmaname = "ZZUNASSIGNED" ;
run;


