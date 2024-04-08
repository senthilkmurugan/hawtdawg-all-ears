
/***************************************************************************
Explore OLS Regression Experiments
****************************************************************************/
*libname out "\\WPUSHH01\DINFOPLN\PRA\DTC\NuvaRing\2011 profit plan\SAS Datasets\Model_Data";
libname out "D:\Documents and Settings\smuruga2\PROJECTS\CallPlan\PR_ROI\Nuvaring\DTC\Data\Model_Data";
LIBNAME DTC "\\WPUSHH01\DINFOPLN\PRA\DTC\NuvaRing\2011 profit plan\SAS datasets";

options nocenter compress=yes;
options mlogic mprint nosymbolgen;

proc contents data=out.nuvmdl_2 varnum; run;

/* Modify model data according to the need */ 
data mdl2;
  set out.nuvmdl_2;
run;

/*
OLS Regression exploration for square term model with NO MIRENA
*/
%let vList1 = workdays jan -- nov lag_pnuv_nrx prmkt_nrx ploe_nrx ffchg_ind pat_edu_ind;
%let vList2 = detmd_s20 evtmd_s20 vchmd_s10 zadstock_f1849_12 vadstock_f1849_6;
* radstock_f1849_14;
%let mdlvars = adstock_f1849_6 adstock_f1849_6_sq;

/*
Experiment 1: Vary model time periods.
*/
%let maxtime = 29;
proc sort data=mdl2 out=regdata; by dma yearmo; run;
%macro runexper1(mdldur);
  data mdldata(drop=rtime rename=(rtime2=rtime));
    set regdata(where = (rtime > (&maxtime. - &mdldur.)));
	rtime2 = rtime - (&maxtime. - &mdldur.);
  run;
  proc reg data=mdldata outest=out_est_2 tableout;
     * NO MIRENA;
     model pnuv_nrx = &vList1. &vList2. &mdlvars. / vif ss2;
  run;
  proc transpose data=out_est_2 out=tr_est_1;
     by _model_ _rmse_ ;
     id _type_ ;
     var &vList1. &vList2. &mdlvars.;
  run;
  data ex1_&mdldur.;
    set tr_est_1;
    if parms = . or parms = -1 then delete;
	source = "T&mdldur.";
  run;
%mend runexper1;
%runexper1(29); 
%runexper1(28); %runexper1(27); %runexper1(26); %runexper1(25); %runexper1(24); 
%runexper1(23); %runexper1(22); %runexper1(21); %runexper1(20); %runexper1(19); %runexper1(18);
data  ols_nomir_expr1_a6sq;
  set ex1_29 ex1_28 ex1_27 ex1_26 ex1_25 ex1_24
      ex1_23 ex1_22 ex1_21 ex1_20 ex1_19 ex1_18;
run;

* Get Means - Experiment 1;
proc sort data=mdl2 out=regdata; by dma yearmo; run;
%macro mnexper1(mdldur);
  data mndata(drop=rtime rename=(rtime2=rtime));
    set regdata(where = (rtime > (&maxtime. - &mdldur.)));
	rtime2 = rtime - (&maxtime. - &mdldur.);
  run;
  proc means data=mndata nway mean std noprint; 
     var pnuv_nrx &vlist1. &vlist2. &mdlvars.;
     output out = mn1_&mdldur.(drop=_type_ _freq_) mean= std= /autoname;  
  run;
  data mn1_&mdldur.; set mn1_&mdldur.; source = "T&mdldur."; run;
%mend mnexper1;
%mnexper1(29); %mnexper1(28); %mnexper1(27); %mnexper1(26); %mnexper1(25); 
%mnexper1(24); %mnexper1(23); %mnexper1(22); %mnexper1(21); %mnexper1(20);
%mnexper1(19); %mnexper1(18);
data allmean_exper1;
  set mn1_29 mn1_28 mn1_27 mn1_26 mn1_25 mn1_24 mn1_23 mn1_22 mn1_21 mn1_20 
      mn1_19 mn1_18;
run;

* Get Estimates and arrange data;
data ols_nomir_expr1_a6sq_2;
  set ols_nomir_expr1_a6sq;
  if _name_ in: ("ADSTOCK_F1849_", "adstock_f1849_");
run;
proc sql;
create table ols_nomir_expr1_a6sq_3 as
select a.*, b.pnuv_nrx_mean, b.adstock_f1849_6_mean, 
            b.adstock_f1849_6_sq_mean
from ols_nomir_expr1_a6sq_2 a, allmean_exper1 b
where a.source = b.source;
quit;
* export;
%let path=D:\Documents and Settings\smuruga2\PROJECTS\CallPlan\PR_ROI\Nuvaring\DTC\Data\Model_Data\Estimates2\OLS_expts;
proc export data=ols_nomir_expr1_a6sq_3 outfile="&path\ols_nomir_expr_EST.xls" dbms=excel97 replace; 
    sheet="ex1_ols_nomir"; 
run;


/*
Experiment 2: Run various 18 month scenarios.
*/
%let mdldur = 18;
proc sort data=mdl2 out=regdata; by dma yearmo; run;
%macro runexper2(endtime);
  data mdldata(drop=rtime rename=(rtime2=rtime));
    set regdata(where = (rtime >= (&endtime. - &mdldur. + 1) and rtime <= &endtime.));
	rtime2 = rtime - (&endtime. - &mdldur.);
  run;
  proc reg data=mdldata outest=out_est_2 tableout;
     * NO MIRENA;
     model pnuv_nrx = &vList1. &vList2. &mdlvars. / vif ss2;
  run;
  proc transpose data=out_est_2 out=tr_est_1;
     by _model_ _rmse_ ;
     id _type_ ;
     var &vList1. &vList2. &mdlvars.;
  run;
  data ex2_&endtime.;
    set tr_est_1;
    if parms = . or parms = -1 then delete;
	source = "E&endtime.";
  run;
%mend runexper2;
%runexper2(29) /* ends Jun10 */;  %runexper2(28) /* ends May10 */; 
%runexper2(27) /* ends Apr10 */;  %runexper2(26) /* ends Mar10 */; 
%runexper2(25) /* ends Feb10 */;  %runexper2(24) /* ends Jan10 */; 
%runexper2(23) /* ends Dec09 */;  %runexper2(22) /* ends Nov09 */;
data  ols_nomir_expr2_a6sq;
  set ex2_29 ex2_28 ex2_27 ex2_26 ex2_25 ex2_24
      ex2_23 ex2_22;
run;  

* Get Means ;
proc sort data=mdl2 out=regdata; by dma yearmo; run;
%macro mnexper2(endtime);
  data mndata(drop=rtime rename=(rtime2=rtime));
    set regdata(where = (rtime >= (&endtime. - &mdldur. + 1) and rtime <= &endtime.));
    rtime2 = rtime - (&endtime. - &mdldur.);
  run;
  proc means data=mndata nway mean std noprint; 
     var pnuv_nrx &vlist1. &vlist2. &mdlvars.;
     output out = mn2_&endtime.(drop=_type_ _freq_) mean= std= /autoname;  
  run;
  data mn2_&endtime.; set mn2_&endtime.; source = "E&endtime."; run;
%mend mnexper2;
%mnexper2(29); %mnexper2(28); %mnexper2(27); %mnexper2(26); %mnexper2(25); 
%mnexper2(24); %mnexper2(23); %mnexper2(22);
data allmean_exper2;
  set mn2_29 mn2_28 mn2_27 mn2_26 mn2_25 mn2_24 mn2_23 mn2_22;
run;

* Get Estimates and arrange data;
data ols_nomir_expr2_a6sq_2;
  set ols_nomir_expr2_a6sq;
  if _name_ in: ("ADSTOCK_F1849_", "adstock_f1849_");
run;
proc sql;
create table ols_nomir_expr2_a6sq_3 as
select a.*, b.pnuv_nrx_mean, b.adstock_f1849_6_mean, 
            b.adstock_f1849_6_sq_mean
from ols_nomir_expr2_a6sq_2 a, allmean_exper2 b
where a.source = b.source;
quit;
* export;
proc export data=ols_nomir_expr2_a6sq_3 outfile="&path\ols_nomir_expr_EST.xls" dbms=excel97 replace; 
    sheet="ex2_ols_nomir"; 
run;


/*
Experiment 3: Try Top100 DMA model with 24 months of data.
*/
data mdldata;
    set regdata;
	if rtime >= 6; * starts from july08 (24 months);
    if dmarank <= 100; * top 100 dma;
run;
proc reg data=mdldata outest=out_est_2 tableout;
     * NO MIRENA;
     model pnuv_nrx = &vList1. &vList2. &mdlvars. / vif ss2;
run;


