/*
Build MMF models for segments with varying reach and analyze the impact.
*/

OPTIONS NOCENTER MPRINT;
LIBNAME MMF "Y:\Marketing Mix PI\InvOpt\P2 2014 AB\Promo\Diabetes Deep Dive\RespModel\MMF\Data"; 
LIBNAME GRAIL "\\usuguscads1\data\grail\JANTOT";
run;
/* 
Dataset MMF.MODEL has data for modeling. 
*/

* Get A+ to C doc counts in each region from JANTOT Grail file.;
data gr_reg_doc_count;
  set grail.jantot_grail1301(keep=imsdrnum rdt2 cat);
  USCOREGN=SUBSTR(rdt2,1,2);
  if cat in: ('A' 'B' 'C'); * retain A+ to C docs;
  drop rdt2;
run;
proc freq data=gr_reg_doc_count; tables cat uscoregn / list missing; run;

proc sql;
create table phys_cnt as
select uscoregn, count(*) as AC_Phys_Count from gr_reg_doc_count
group by uscoregn order by uscoregn;
quit;

proc sort data=mmf.model out=mdl1; by uscoregn; run;
proc sql;
create table reg_att as
select uscoregn, count(*) as reg_att_count from mdl1 where testcand='T'
group by uscoregn order by uscoregn;
quit;

data reg_rch;
  merge reg_att(in=a) phys_cnt(in=b);
  by uscoregn;
  if a;
  reg_att_reach_pcnt = (reg_att_count / AC_phys_count) * 100;
run;
proc univariate data=reg_rch; var reg_att_reach_pcnt; run;
/*
100% Max       6.891652
99%            6.891652
95%            6.041287
90%            5.390759
75% Q3         4.283193
50% Median     3.219674
25% Q1         2.280651
10%            1.630037
5%             0.821355
1%             0.521221
0% Min         0.521221
*/

data reg_rch_2;
  set reg_rch;
  if reg_att_reach_pcnt < 2.280651 then reg_reach_seg = "REACH 1";  * below 25th percentile;
  else if reg_att_reach_pcnt < 3.219674 then reg_reach_seg = "REACH 2"; * between 25th and 50th percentile;
  else if reg_att_reach_pcnt < 4.283193 then reg_reach_seg = "REACH 3"; * between 50th and 75th percentile;
  else reg_reach_seg = "REACH 4"; * above 75th percentile;
run;
proc sort data=reg_rch_2; by reg_att_reach_pcnt; run;

proc sql;
select reg_reach_seg, sum(reg_att_count) as tot_att from reg_rch_2 group by reg_reach_seg;
quit;
/*
reg_reach_
seg            tot_att
ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ
REACH 1            505
REACH 2            886
REACH 3           1246
REACH 4           1587
*/

/*
* store as permanent dataset;
data mmf.region_reach; set reg_rch_2; run; 
*/

proc sort data=reg_rch_2; by uscoregn; run;
proc sort data=mdl1; by uscoregn; run;
data mdl2;
  merge mdl1(in=a) reg_rch_2(in=b);
  by uscoregn;
  if a;
run;
proc freq data=mdl2; tables reg_reach_seg / list missing; run;

/*
* STORE EXPANDED MODEL DATA AS PERMANENT DATASET;
DATA MMF.MODEL_2; SET mdl2; RUN;
*/


/*
BUILD OLS MODELS BY REACH SEGMENTS TO ESTIMATE THE ATTENDEE IMPACTS;
*/
proc sort data=MMF.MODEL_2; by reg_reach_seg; run;
ODS OUTPUT PARAMETERESTIMATES=NORM2;
PROC REG DATA=MMF.MODEL_2;
  BY reg_reach_seg;
  MODEL PROD_POSTMEAN = PROD_PREMEAN CLASS_PREMEAN 
                        SAM_POSTMEAN DET_POSTMEAN SFP_POSTMEAN MFP_POSTMEAN TESTFLG
      /  RSQUARE VIF COLLIN CLB ALPHA=0.25;
RUN; QUIT;
* Note: Most results are non-significant for TESTFLG. Try combining segments further;

data MMF.MODEL_2;
  set mdl2;
  if reg_reach_seg in ('REACH 1' 'REACH 2') then reg_seg_2 = "REACH 12";
  else reg_seg_2 = "REACH 34";
run;
proc sort data=MMF.MODEL_2; by reg_reach_seg; run;
ODS OUTPUT PARAMETERESTIMATES=NORM3;
PROC REG DATA=MMF.MODEL_2;
  BY reg_seg_2; *reg_reach_seg;
  MODEL PROD_POSTMEAN = PROD_PREMEAN CLASS_PREMEAN 
                        SAM_POSTMEAN DET_POSTMEAN SFP_POSTMEAN MFP_POSTMEAN TESTFLG
      /  RSQUARE VIF COLLIN CLB ALPHA=0.25;
RUN; QUIT;


