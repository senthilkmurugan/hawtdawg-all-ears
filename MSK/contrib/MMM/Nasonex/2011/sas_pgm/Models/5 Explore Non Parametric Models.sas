
/***************************************************************************
5. Explore semi (PROC GAM) and non-parametric (LOESS) models to see if 
   there is any trend in response curves.
****************************************************************************/
LIBNAME RX  "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other";
LIBNAME out "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA";
LIBNAME GRP "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\OUTPUT";

options nocenter compress=yes;
options mlogic mprint nosymbolgen;
%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA\Explore_1\Non_Semi_Parametric;

data mdl1;
  set rx.MODEL_DATA_v1;
run;
proc contents data=mdl1 varnum; run;

data mdl2;
  set mdl1;
  * semester indicators;
  sem2009_S2 = (semester="2009_S2"); sem2010_S1 = (semester="2010_S1");
  sem2010_S2 = (semester="2010_S2"); sem2011_S1 = (semester="2011_S1");
  semS1 = (sem2010_S1+sem2011_S1 > 0); semS2 = (sem2009_S2+sem2010_S2 > 0);
  * spring, fall period flags;
  spring = (mar+apr+may > 0);  fall = (sep+oct > 0);
  * cubic and other terms for nas grp;
  grpnas_60_cu = grpnas_60_sq * grpnas_60;
  grpnas_60_sqrt = sqrt(grpnas_60);
run;
proc sort data=mdl2; by dma yearmo; run;

/*
*store as permanent data set;
data rx.MODEL_DATA_v1;
  set mdl2;
run;
*/

/*******************************************************************
Try PROC LOESS for full model and get the response curve for grpnas_60
1) Try to build full model with no time vars (due to limitations in Loess) using PROC LOESS and study the predicted nasnrx_pop vs. NAS Adstock.
   Also study the residuals from the notime full model.

2) Try RI proc mixed for Full Model. Take residuals and add predicted impact of nasgrp.
   use this grp adjusted residuals as input for further Loess model and study the 
   relationship between nasgrp and predicted adjusted residual.
********************************************************************/
* Build Scoring Dataset;
proc summary data=mdl2;
var t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50
         sems1 sems2 spring fall; 
output out=sm_mdl_data_1 mean=;
run;
data score_data_mn(drop= _type_ _freq_ i);
  set sm_mdl_data_1;
  do i=0 to 750 by 10;
    grpnas_60 = i;
	grpnas_60_semS1 = grpnas_60*semS1; grpnas_60_semS2 = grpnas_60*semS2;
    grpnas_60_spring = grpnas_60*spring; grpnas_60_fall = grpnas_60*fall;
    output;
  end;
run;
data score_data_zr(drop= _type_ _freq_ i);
  set sm_mdl_data_1;
  do i=0 to 750 by 10;
    t1=0; t2=0; t3=0; t4=0; t5=0; t6=0; t7=0; t8=0;
    t9=0; t10=0; t11=0; t12=0; t13=0; t14=0; t15=0; t16=0;
    t17=0; t18=0; t19=0; t20=0; t21=0; t22=0; t23=0; t24=0; 
    mc_nrp=0; lag_pnasnrx=0; detmd_30=0; sammd_80=0; grpomn_60=0; 
	grpotc_60=0; onl_score_50=0;
    grpnas_60 = i;
    output;
  end;
run;
/*
1) Try to build full model with no time using PROC LOESS and study the predicted pnasnrx vs. NAS Adstock.
   Also study the residuals from the full model.
*/
proc loess data=mdl2; 
model pnasnrx = /*t1 - t23*/ mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
       / smooth= 0.4 residual all;
      
	 score data=score_data_mn /*id=(smoothingparameter)*/ / clm;
	 ods output OutputStatistics=Results scoreresults=score_data_mn_out;
run;
proc means data=results; var residual; run; *mean 0.094, sd=6.68;

* here, exportscore_data_mn_out to excel;
PROC EXPORT DATA=score_data_mn_out 
  OUTFILE= "&PATH.\non_param_trials.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "loess_fm_not";
RUN;


symbol1 color=black value=dot;   
symbol2 color=black interpol=join value=none; 
symbol3 color=green interpol=join value=none; 
symbol4 color=green interpol=join value=none; 
%let opts=vaxis=axis1 hm=3 vm=3 overlay; 
axis1 label=(angle=90 rotate=0); 
proc gplot data=score_data_mn_out;  
 plot /*DepVar*tv_nsx_s60=1*/ P_pnasnrx*grpnas_60=2 lcl_pnasnrx*grpnas_60=3 ucl_pnasnrx*grpnas_60=4  / &opts name='fit'; 
 *plot residual*tv_nsx_s60=2   / &opts name='fit'; 
run; quit;

%MACRO BOX_EQ_BIN_loess(dset,binvar,othvars,totrecs);
/*PROC GREPLAY NOFS IGOUT=WORK.GSEG; DELETE _ALL_; RUN; QUIT;*/
PROC SORT DATA=&dset. OUT=TSORTED; BY &binvar.; RUN;

DATA SORTED; SET TSORTED; *LRTIME=LOG(RTIME);
bin = ceil(10*_n_/&totrecs.);
RUN;
proc means data=sorted nolabels; class bin; var &binvar. &othvars. residual; run;

PROC SORT DATA=SORTED; BY bin; RUN; 
  TITLE3 "EXPLORE P_pnasnrx DMA DISTS";
  PROC BOXPLOT DATA=SORTED;
  AXIS1 LABEL=(ANGLE=90 ROTATE=0 "RESIDUAL");
  PLOT RESIDual*bin/TOTPANELS=1 VAXIS=AXIS1;
  LABEL MONTHLABEL='ANALYSIS MONTH';
  RUN; QUIT; TITLE3 ''; RUN;

%MEND BOX_EQ_BIN_loess;
%BOX_EQ_BIN_loess(results,grpnas_60,,5040);
proc means data=sorted; class bin; var grpnas_60 residual; run;

/*
2) Try RI proc mixed for Full Model. Take residuals and add predicted impact of nasgrp.
   use this grp adjusted residuals as input for further Loess model and study the 
   relationship between nasgrp and predicted adjusted residual.
*/
data mdl2;
  set mdl2;
  grpnas_60_semS1 = grpnas_60 * semS1;
  grpnas_60_semS2 = grpnas_60 * semS2;
  grpnas_60_spring = grpnas_60 * spring;
  grpnas_60_fall = grpnas_60 * fall;
run;

proc sort data=mdl2; by dma yearmo; run;
proc mixed data=mdl2 covtest noclprint empirical ;
class dma yearmo;
model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60_semS1 grpnas_60_semS2 /*grpnas_60 grpnas_60_sq grpnas_60_cu*/ 
         grpomn_60 grpotc_60 onl_score_50 / solution outp=pred_fm;
random intercept / subject=dma;
ods output fitstatistics=fit1 solutionf=fixed1;
run;
data res_grpadj;
  set pred_fm(keep=dma yearmo pnasnrx grpnas_60 grpnas_60_sq grpnas_60_cu 
                     grpnas_60_semS1 grpnas_60_semS2 pred lower upper resid);
  /*adj_resid = (-0.02931)*grpnas_60 + (0.000142)*grpnas_60_sq + (-1.41e-7)*grpnas_60_cu + resid;*/
  adj_resid = 0.01025*grpnas_60_semS1 + 0.02307*grpnas_60_semS2 + resid;
run;
data score_data_mn_2;
  set score_data_mn;
  grpnas_60_sq = grpnas_60*grpnas_60;
  grpnas_60_cu = grpnas_60*grpnas_60*grpnas_60;
  grpnas_60_semS1 = grpnas_60 * semS1;
  grpnas_60_semS2 = grpnas_60 * semS2;
run;

proc loess data=res_grpadj; 
model adj_resid = grpnas_60_semS1 grpnas_60_semS2 /*grpnas_60_sq grpnas_60_cu*/
       / smooth= 0.4 residual all;
      
	 score data=score_data_mn_2 /*id=(smoothingparameter)*/ / clm;
	 ods output OutputStatistics=Results scoreresults=score_data_mn_out;
run;
proc means data=results; var residual; run; *mean -0.0098, sd=5.74;
* here, exportscore_data_mn_out to excel;
PROC EXPORT DATA=score_data_mn_out 
  OUTFILE= "&PATH.\non_param_trials.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "lo_fm_int2_adjres";
RUN;
proc gplot data=score_data_mn_out; *(where=(grpnas_60 <= 500));  
 plot /*DepVar*tv_nsx_s60=1*/ P_adj_resid*grpnas_60=2 lcl_adj_resid*grpnas_60=3 ucl_adj_resid*grpnas_60=4  / &opts name='fit'; 
 *plot residual*tv_nsx_s60=2   / &opts name='fit'; 
run; quit;

%BOX_EQ_BIN_loess(uxwrk.results,tv_nsx_s60,,1800);
proc means data=sorted; class bin; var tv_nsx_s60 residual; run;

/*
Prepare Hybrid model data.
*/
proc sort data=mdl2; by dma yearmo; run;
proc means data=mdl2 nway noprint;
  class dma;
  var workdays gen_all_launch mc_nrp lag_pnasnrx 
      flut_short_ind pmktnrx pflunrxsh
      detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
      t1 - t24;
  output out=meanfile 
    mean= m_workdays m_gen_all_launch m_mc_nrp m_lag_pnasnrx 
      m_flut_short_ind m_pmktnrx m_pflunrxsh
      m_detmd_30 m_sammd_80 m_grpnas_60 m_grpomn_60 m_grpotc_60 m_onl_score_50 
      m_t1 - m_t24;
data mdl2_hybrid;
  merge mdl2 meanfile;
  by dma;
  d_workdays = workdays - m_workdays; 
  d_gen_all_launch = gen_all_launch - m_gen_all_launch;
  d_mc_nrp = mc_nrp - m_mc_nrp; 
  d_lag_pnasnrx = lag_pnasnrx - m_lag_pnasnrx; 
  d_flut_short_ind = flut_short_ind - m_flut_short_ind; 
  d_pmktnrx = pmktnrx - m_pmktnrx; 
  d_pflunrxsh = pflunrxsh - m_pflunrxsh;
  d_detmd_30 = detmd_30 - m_detmd_30; 
  d_sammd_80 = sammd_80 - m_sammd_80; 
  d_grpnas_60 = grpnas_60 - m_grpnas_60; 
  d_grpomn_60 = grpomn_60 - m_grpomn_60; 
  d_grpotc_60 = grpotc_60 - m_grpotc_60; 
  d_onl_score_50 = onl_score_50 - m_onl_score_50;
  array ar_tind(*) t1 - t24;
  array ar_tind_m(*) m_t1 - m_t24;
  array ar_tind_d(*) d_t1 - d_t24;
  DO J=1 TO DIM(ar_tind);
     ar_tind_d(J) = ar_tind(J) - ar_tind_m(J);
  END;
  drop j;
run;

/*
2. Explore PROC GAM (Generalized additive models) for full model.
FULL MODEL
*/
ods graphics on;
proc gam data=mdl2 plots(unpack)=components(commonaxes additive clm); 
  model pnasnrx = param(t1 - t23 mc_nrp lag_pnasnrx detmd_30 sammd_80  grpomn_60 grpotc_60) 
          spline(grpnas_60)
        / method = GCV ;
  ods output gam.ParameterEstimates = gam_par_est;
  score data=score_data_mn out=score_gam_out;
run;
ods graphics off;
PROC EXPORT DATA=score_gam_out 
  OUTFILE= "&PATH.\gam_trials.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "gam_fm_spgrp_gcv";
RUN;

ods graphics on;
proc gam data=mdl2 plots(unpack)=components(commonaxes additive clm); 
  model pnasnrx = param(t1 - t23 mc_nrp lag_pnasnrx detmd_30 sammd_80  grpomn_60 grpotc_60) 
          spline(grpnas_60,df=4)
        / method = GCV ;
  ods output gam.ParameterEstimates = gam_par_est;
  score data=score_data_mn out=score_gam_out;
run;
ods graphics off;
PROC EXPORT DATA=score_gam_out  
  OUTFILE= "&PATH.\gam_trials.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "gam_fm_spgrp_dof4";
RUN;

ods graphics on;
proc gam data=mdl2 plots(unpack)=components(commonaxes additive clm); 
  model pnasnrx = param(t1 - t23 mc_nrp lag_pnasnrx detmd_30 sammd_80  grpomn_60 grpotc_60) 
          loess(grpnas_60)
        / method = GCV ;
  ods output gam.ParameterEstimates = gam_par_est;
  score data=score_data_mn out=score_gam_out;
run;
ods graphics off;
PROC EXPORT DATA=score_gam_out  
  OUTFILE= "&PATH.\gam_trials.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "gam_fm_logrp_gcv";
RUN;


data score_gam_out_2;
  set score_gam_out;
  retain gp_pnasnrx_ini_0;
  if _n_ > 3;
  if _n_ = 4 then do;
      gp_pnasnrx_ini_0 = p_pnasnrx; 
  end;
  gp_incr_pnasNRx = p_pnasnrx  - gp_pnasnrx_ini_0;
run;

* GAM with sem1 sem2 interactions;
data score_data_mn_int;
  set score_data_mn(in=a) score_data_mn(in=b);
  if a then do; semS1=1; semS2=0; grpnas_60_semS1=grpnas_60; grpnas_60_semS2=0; end;
  if b then do; semS1=0; semS2=1; grpnas_60_semS1=0; grpnas_60_semS2=grpnas_60; end;
run;
ods graphics on;
proc gam data=mdl2 plots(unpack)=components(commonaxes additive clm); 
  model pnasnrx = param(t1 - t23 mc_nrp lag_pnasnrx detmd_30 sammd_80  grpomn_60 grpotc_60) 
          spline(grpnas_60_semS1,df=4) spline(grpnas_60_semS2,df=4)
        / method = GCV ;
  ods output gam.ParameterEstimates = gam_par_est;
  score data=score_data_mn_int out=score_gam_out_int;
run;
ods graphics off;
PROC EXPORT DATA=score_gam_out_int  
  OUTFILE= "&PATH.\gam_trials.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "gam_fm_int_spgrp_dof4";
RUN;


