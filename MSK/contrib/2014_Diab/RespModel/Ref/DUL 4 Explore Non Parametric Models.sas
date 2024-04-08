
/***************************************************************************
5. Explore semi (PROC GAM) and non-parametric (LOESS) models to see if 
   there is any trend in response curves.
****************************************************************************/
LIBNAME DMA  "\\WPUSHH01\DINFOPLN\PRA\ALIGNMENTS\DMA\DATA";
LIBNAME OUT  "Y:\PRA\DTC\Dulera\2012_Analysis\data\weekly";
LIBNAME GRP "Y:\PRA\DTC\Dulera\2012_Analysis\Nielsen_Data_Processing\OUTPUT";

%LET PATH=Y:\PRA\DTC\Dulera\2012_Analysis\data\MODEL_DATA\Explore_1\Non_Semi_Parametric;
OPTIONS NOCENTER MPRINT MLOGIC SYMBOLGEN COMPRESS=YES;
RUN;

data mdl1;
  set out.MODEL_DATA_v1;
run;
proc contents data=mdl1 varnum; run;
proc sort data=mdl1; by dma rx_wk_end_dt; run;

%macro rtfopen(filename);
  options ls=75 ps=3000 nodate nocenter nonumber;
  ODS LISTING CLOSE;
  ODS RTF FILE="&PATH.\&filename." STYLE=JOURNAL BODYTITLE;
%mend rtfopen;
%macro rtfclose();
  ODS RTF CLOSE;
  ODS LISTING;
%mend rtfclose;

data mdl2;
  set mdl1;
  grpdul_10_cu = grpdul_10_sq * grpdul_10;
run;
/*
1. Explore Polynomial models.
  (In the trials, sq and cu models makes all grpdul estimates non-sig. 
    Cu. models are slightly better but still non-sig estimates. 
    Probably saturation is not seen yet)
*/
options nolabel;
proc sort data=mdl2; by dma rx_wk_end_dt; run;
%rtfopen(expl_polynomials.rtf);
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma rx_wk_end_dt;
  model_p1: model pdulnrx = t2 - t42 lag_pdulnrx pcomnrx nrp 
            detmd_06 sammd_03 vcrmd_03 grpadv_06 grpsym_06 
            grpdul_10 / solution;
  random intercept / subject=dma;
run;
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma rx_wk_end_dt;
  model_p2: model pdulnrx = t2 - t42 lag_pdulnrx pcomnrx nrp 
            detmd_06 sammd_03 vcrmd_03 grpadv_06 grpsym_06 
            grpdul_10 grpdul_10_sq / solution;
  random intercept / subject=dma;
run;
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma rx_wk_end_dt;
  model_p3: model pdulnrx = t2 - t42 lag_pdulnrx pcomnrx nrp 
            detmd_06 sammd_03 vcrmd_03 grpadv_06 grpsym_06 
            grpdul_10 grpdul_10_sq grpdul_10_cu / solution;
  random intercept / subject=dma;
run;

proc glm data=mdl2;
  absorb dma;
  model_p1: model pdulnrx = t2 - t42 lag_pdulnrx pcomnrx 
            detmd_10 sammd_03 vcrmd_03 grpadv_06 grpsym_06 
            grpdul_10 / solution;
run; quit;
proc glm data=mdl2;
  absorb dma;
  model_p2: model pdulnrx = t2 - t42 lag_pdulnrx pcomnrx 
            detmd_10 sammd_03 vcrmd_03 grpadv_06 grpsym_06 
            grpdul_10 grpdul_10_sq / solution;
run; quit;
proc glm data=mdl2;
  absorb dma;
  model_p3: model pdulnrx = t2 - t42 lag_pdulnrx pcomnrx 
            detmd_10 sammd_03 vcrmd_03 grpadv_06 grpsym_06 
            grpdul_10 grpdul_10_sq grpdul_10_cu / solution;
run; quit;
%rtfclose();

/*
2. Try Semi-Parametric GAM Models.
*/
* Build Scoring Dataset;
proc summary data=mdl2;
var t1 - t42 lag_pdulnrx pcomnrx nrp 
            detmd_06 sammd_03 vcrmd_03 grpadv_06 grpsym_06 
            grpdul_10 q4_grpdul_10 q1_grpdul_10 q4 q1
            grpdul_06 q4_grpdul_06 q1_grpdul_06; 
output out=sm_mdl_data_1 mean=;
run;
data score_data_mn(drop= _type_ _freq_ i);
  set sm_mdl_data_1;
  do i=0 to 1200 by 10;
    grpdul_10 = i;
	grpdul_06 = i;
    output;
  end;
run;
data score_data_mn_int;
  set score_data_mn(in=a) score_data_mn(in=b);
  if a then do; q4=1; q1=0; q4_grpdul_10=grpdul_10; q1_grpdul_10=0; 
                      q4_grpdul_06=grpdul_06; q1_grpdul_06=0; end;
  if b then do; q4=0; q1=1; q4_grpdul_10=0; q1_grpdul_10=grpdul_10; 
                      q4_grpdul_06=0; q1_grpdul_06=grpdul_06; end;
run;
data score_data_zr(drop= _type_ _freq_ i);
  set sm_mdl_data_1;
  do i=0 to 1200 by 10;
    t1=0; t2=0; t3=0; t4=0; t5=0; t6=0; t7=0; t8=0;
    t9=0; t10=0; t11=0; t12=0; t13=0; t14=0; t15=0; t16=0;
    t17=0; t18=0; t19=0; t20=0; t21=0; t22=0; t23=0; t24=0;
    t25=0; t26=0; t27=0; t28=0; t29=0; t30=0; t31=0; t32=0;
    t33=0; t34=0; t35=0; t36=0; t37=0; t38=0; t39=0; t40=0;
	t41=0; t42=0; 
    lag_pdulnrx=0; pcomnrx=0; nrp=0; detmd_06=0; sammd_03=0; vcrmd_03=0;
    grpadv_06=0; grpsym_06=0; q4=0; q1=0; 
	grpdul_10=i; q4_grpdul_10=i; q1_grpdul_10=i; 
	grpdul_06=i; q4_grpdul_06=i; q1_grpdul_06=i; 
    output;
  end;
run;

*GAM MODELS;
ods graphics on;
proc gam data=mdl2 plots(unpack)=components(commonaxes additive clm); 
  model pdulnrx = param(t1 - t42 lag_pdulnrx pcomnrx nrp detmd_06 sammd_03 vcrmd_03 grpadv_06 grpsym_06) 
          spline(grpdul_06)
        / method = GCV ;
  ods output gam.ParameterEstimates = gam_par_est;
  score data=score_data_mn out=score_gam_out;
run;
ods graphics off;
PROC EXPORT DATA=score_gam_out 
  OUTFILE= "&PATH.\gam_trials.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "gam_ri_spgrp6_gcv";
RUN;

ods graphics on;
proc gam data=mdl2 plots(unpack)=components(commonaxes additive clm); 
  model pdulnrx = param(t1 - t42 lag_pdulnrx pcomnrx nrp detmd_06 sammd_03 vcrmd_03 grpadv_06 grpsym_06) 
          spline(grpdul_10,DF=4);
        */ method = GCV ;
  ods output gam.ParameterEstimates = gam_par_est;
  score data=score_data_mn out=score_gam_out;
run;
ods graphics off;
PROC EXPORT DATA=score_gam_out  
  OUTFILE= "&PATH.\gam_trials.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "gam_ri_spgrp_dof4";
RUN;

ods graphics on;
proc gam data=mdl2 plots(unpack)=components(commonaxes additive clm); 
  model pdulnrx = param(t2 - t42 lag_pdulnrx pcomnrx nrp detmd_06 sammd_03 vcrmd_03 grpadv_06 grpsym_06) 
          loess(grpdul_06)
        / method = GCV ;
  ods output gam.ParameterEstimates = gam_par_est;
  score data=score_data_mn out=score_gam_out;
run;
ods graphics off;
PROC EXPORT DATA=score_gam_out  
  OUTFILE= "&PATH.\gam_trials.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "gam_ri_logrp_gcv";
RUN;

/*
data score_gam_out_2;
  set score_gam_out;
  retain gp_pnasnrx_ini_0;
  if _n_ > 3;
  if _n_ = 4 then do;
      gp_pnasnrx_ini_0 = p_pnasnrx; 
  end;
  gp_incr_pnasNRx = p_pnasnrx  - gp_pnasnrx_ini_0;
run;
*/

* GAM with sem1 sem2 interactions;
ods graphics on;
proc gam data=mdl2 plots(unpack)=components(commonaxes additive clm); 
  model pdulnrx = param(t1 - t42 lag_pdulnrx pcomnrx nrp detmd_06 sammd_03 vcrmd_03 grpadv_06 grpsym_06) 
          spline(q4_grpdul_06,df=3) spline(q1_grpdul_06,df=4)
        / method = GCV ;
  ods output gam.ParameterEstimates = gam_par_est;
  score data=score_data_mn_int out=score_gam_out_int;
run;
ods graphics off;
PROC EXPORT DATA=score_gam_out_int  
  OUTFILE= "&PATH.\gam_trials.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "gam_ri_int_spgrp6_df3df4";
RUN;


