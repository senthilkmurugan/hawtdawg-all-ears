
/***************************************************************************
6. Partial Simulations and model trials using existing data.
   Simulate just the dependent vars.
****************************************************************************/
LIBNAME RX  "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other";
LIBNAME out "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA";
LIBNAME GRP "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\OUTPUT";
LIBNAME outsim "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA\Explore_1\Partial Simulations";

options nocenter compress=yes;
options mlogic mprint nosymbolgen;
%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA\Explore_1\Partial Simulations;

data mdl1;
  set rx.MODEL_DATA_v1;
run;

%macro rtfopen(filename);
  options ls=75 ps=3000 nodate nocenter nonumber;
  ODS LISTING CLOSE;
  ODS RTF FILE="&PATH.\&filename." STYLE=JOURNAL BODYTITLE;
%mend rtfopen;
%macro rtfclose();
  ODS RTF CLOSE;
  ODS LISTING;
%mend rtfclose;

options nolabel;
proc sort data=mdl1; by dma yearmo; run;
%rtfopen(partial_simulations_ver1.rtf);
/*
Trial 1: Treat RI Full Model(FM) as base model and generate predictor variable.
Fit FM, FM with Interaction of Semesters (FM+I), and RI of Prev (PREV RI) model structure
to study the parameter estimates.
*/
proc mixed data=mdl1 covtest noclprint empirical; 
  class dma yearmo;
  base_fm: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
      / solution outpm=res_fm1;
  random intercept / subject=dma;
run;
* get means and stddev of residuals;
proc means data=res_fm1; var resid; run;
* mean=0  sd=5.75144;
data res_fm1;
  set res_fm1;
  sim_fm_dvar = pred + RAND('NORMAL',0,5.75144);
run;

* fit models for sim_fm_dvar;
proc sort data=res_fm1; by dma yearmo; run;
proc mixed data=res_fm1 covtest noclprint empirical; 
  class dma yearmo;
  sim_fm: model sim_fm_dvar = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
      / solution;
  random intercept / subject=dma;
run;
proc mixed data=res_fm1 covtest noclprint empirical; 
  class dma yearmo;
  sim_fmi: model sim_fm_dvar = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpomn_60 grpotc_60 onl_score_50 
         grpnas_60*semS1 grpnas_60*semS2 
      / solution;
  random intercept / subject=dma;
run;
proc mixed data=res_fm1 covtest noclprint empirical; 
  class dma yearmo;
  sim_pm: model sim_fm_dvar = workdays mar apr sep dec mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
      / solution;
  random intercept / subject=dma;
run;

/*
Trial 2: Treat RI Full Model with Semester Interaction (FMI) as base model and generate predictor variable.
Fit FM, FM with Interaction of Semesters (FMI), and RI of Prev (PREV RI) model structure
to study the parameter estimates.
*/
proc mixed data=mdl1 covtest noclprint empirical; 
  class dma yearmo;
  base_fmi: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpomn_60 grpotc_60 onl_score_50
         grpnas_60*semS1 grpnas_60*semS2 
      / solution outpm=res_fmi1;
  random intercept / subject=dma;
run;
* get means and stddev of residuals;
proc means data=res_fmi1; var resid; run;
* mean=0  sd=5.748295;
data res_fmi1;
  set res_fmi1;
  sim_fmi_dvar = pred + RAND('NORMAL',0,5.748295);
run;

* fit models for sim_fm_dvar;
proc sort data=res_fmi1; by dma yearmo; run;
proc mixed data=res_fmi1 covtest noclprint empirical; 
  class dma yearmo;
  sim_fm: model sim_fmi_dvar = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
      / solution;
  random intercept / subject=dma;
run;
proc mixed data=res_fmi1 covtest noclprint empirical; 
  class dma yearmo;
  sim_fmi: model sim_fmi_dvar = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpomn_60 grpotc_60 onl_score_50 
         grpnas_60*semS1 grpnas_60*semS2 
      / solution;
  random intercept / subject=dma;
run;
proc mixed data=res_fmi1 covtest noclprint empirical; 
  class dma yearmo;
  sim_pm: model sim_fmi_dvar = workdays mar apr sep dec mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
      / solution;
  random intercept / subject=dma;
run;

/*
Trial 3: Treat RI of PREV model structure (PREV RI) as base model and generate predictor variable.
Fit FM, FM with Interaction of Semesters (FMI), and RI of Prev (PREV RI) model structure
to study the parameter estimates.
*/
proc mixed data=mdl1 covtest noclprint empirical; 
  class dma yearmo;
  base_fmi: model pnasnrx = workdays mar apr sep dec mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
      / solution outpm=res_pm1;
  random intercept / subject=dma;
run;
* get means and stddev of residuals;
proc means data=res_pm1; var resid; run;
* mean=0  sd=7.76936;
data res_pm1;
  set res_pm1;
  sim_pm1_dvar = pred + RAND('NORMAL',0,7.76936);
run;

* fit models for sim_fm_dvar;
proc sort data=res_pm1; by dma yearmo; run;
proc mixed data=res_pm1 covtest noclprint empirical; 
  class dma yearmo;
  sim_fm: model sim_pm1_dvar = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
      / solution;
  random intercept / subject=dma;
run;
proc mixed data=res_pm1 covtest noclprint empirical; 
  class dma yearmo;
  sim_fmi: model sim_pm1_dvar = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpomn_60 grpotc_60 onl_score_50 
         grpnas_60*semS1 grpnas_60*semS2 
      / solution;
  random intercept / subject=dma;
run;
proc mixed data=res_pm1 covtest noclprint empirical; 
  class dma yearmo;
  sim_pm: model sim_pm1_dvar = workdays mar apr sep dec mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
      / solution;
  random intercept / subject=dma;
run;
%rtfclose();

/*
EXTEND FM vs. FM+I through multiple simulations.
*/
*FM as base;
proc mixed data=mdl1 covtest noclprint empirical; 
  class dma yearmo;
  base_fm: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
      / solution outpm=res_fm1;
  random intercept / subject=dma;
  ods output solutionf=sol_base_fm;
run;
* get means and stddev of residuals;
proc means data=res_fm1; var resid; run;  * mean=0  sd=5.75144;
proc transpose data=sol_base_fm(keep= effect estimate) out=tr_sol_base_fm;
  id effect; var estimate;
run;
data tr_sol_base_fm; set tr_sol_base_fm; length cat $20.; cat = "BASE_FM"; run;
proc append base=sol_sim data=tr_sol_base_fm force; run;

* FMI as base;
proc mixed data=mdl1 covtest noclprint empirical; 
  class dma yearmo;
  base_fm: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpomn_60 grpotc_60 onl_score_50 
		 grpnas_60*semS1  grpnas_60*semS2
      / solution outpm=res_fmi1;
  random intercept / subject=dma;
  ods output solutionf=sol_base_fmi;
run;
* get means and stddev of residuals;
proc means data=res_fmi1; var resid; run;  * mean=0  sd=5.748295;
proc transpose data=sol_base_fmi(keep= effect estimate) out=tr_sol_base_fmi;
  id effect; var estimate;
run;
data tr_sol_base_fmi; set tr_sol_base_fmi; length cat $20.; cat = "BASE_FMI"; run;
data sol_sim; set sol_sim; grpnas_60_semS1 = 0; grpnas_60_semS2 = 0; run;
proc append base=sol_sim data=tr_sol_base_fmi force; run;


%macro sim1(resdset, dvar, errsd, base);
  ODS LISTING CLOSE;
  data &resdset.;
    set &resdset.;
    &dvar. = pred + RAND('NORMAL',0, &errsd.);
  run;
  * fit models for sim_fm_dvar;
  /*proc sort data=&resdset.; by dma yearmo; run;*/
  proc mixed data=&resdset. covtest noclprint empirical; 
    class dma yearmo;
    sim_fm: model &dvar. = t1 - t24 mc_nrp lag_pnasnrx 
           detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
        / solution;
    random intercept / subject=dma;
    ods output solutionf=sol_sim_fm;
  run;
  proc mixed data=&resdset. covtest noclprint empirical; 
    class dma yearmo;
    sim_fmi: model &dvar. = t1 - t24 mc_nrp lag_pnasnrx 
           detmd_30 sammd_80 grpomn_60 grpotc_60 onl_score_50 
           grpnas_60*semS1 grpnas_60*semS2 
        / solution;
    random intercept / subject=dma;
    ods output solutionf=sol_sim_fmi;
  run;
  proc transpose data=sol_sim_fm(keep= effect estimate) out=tr_sol_sim_fm;
    id effect; var estimate;
  run;
  data tr_sol_sim_fm; set tr_sol_sim_fm; length cat $20.; cat = "&base._SIM_FM"; run;
  proc append base=sol_sim data=tr_sol_sim_fm force; run;
  proc transpose data=sol_sim_fmi(keep= effect estimate) out=tr_sol_sim_fmi;
    id effect; var estimate;
  run;
  data tr_sol_sim_fmi; set tr_sol_sim_fmi; length cat $20.; cat = "&base._SIM_FMI"; run;
  proc append base=sol_sim data=tr_sol_sim_fmi force; run;
  ODS LISTING;
%mend sim1; 

%macro run_sim();
  %do i=1 %to 250;
    %sim1(res_fm1,sim_fm_dvar,5.75144,BASE_FM);
    %sim1(res_fmi1,sim_fmi_dvar,5.748295,BASE_FMI);
  %end;
%mend;

%run_sim();

data sol_sim_2;
  set sol_sim;
  if cat = "BASE_FM_FM_SIM_FMI" then cat = "BASE_FM_SIM_FMI";
  if cat = "BASE_FMI_FM_SIM_FMI" then cat = "BASE_FMI_SIM_FMI";
run;

/*data outsim.sol_sim; set sol_sim_2; run;*/
ODS TRACE ON;
proc means data=sol_sim_2 n min max mean std p5 p10 p25 p50 p75 p90 p95; 
  class cat;
  ods output summary=sim_smmry;
run;
ODS TRACE OFF;
proc transpose data=sim_smmry out=tr_sim_smmry; id cat; run;
/*data outsim.sim_smmry; set tr_sim_smmry; run;*/
/*
Conclusions from simulation:
Following general observations suggests that FM+I models are probably more flexible and better.
When Truth is FM:  FMI has both SEM1 and SEM2 interactions close to 
                   true FM estimate for grpnas.
When Truth is FMI: FM model slightly underpredicts the overall impact.
Above two facts, points that we are better off using FMI model 
      and directionally conclude that SEM2 impacts are better. 
*/

/*
Go back and try FMI model with pothnrx.
*/
options nolabel;
proc sort data=mdl1; by dma yearmo; run;
%rtfopen(fm_sem_int_trials_v2.rtf);
proc mixed data=mdl1 covtest noclprint empirical; 
  class dma yearmo;
  base_fmi: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx POTHNRX 
         detmd_30 sammd_80 grpomn_60 grpotc_60 onl_score_50
         grpnas_60*semS1 grpnas_60*semS2 
      / solution outpm=res_fmi1;
  random intercept / subject=dma;
run;
%rtfclose();

proc means data=res_fmi1; var resid; run;  * mean=0  sd=8.3589;


