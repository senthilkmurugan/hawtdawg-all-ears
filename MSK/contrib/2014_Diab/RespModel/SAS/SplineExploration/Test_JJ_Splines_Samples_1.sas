/****************************************************************/
/*   Januvia / Janumet Detail, Sample response curves  */
/* Try response CURVES, so that optimal detail and/or sample could be determined */
/* Time period of interest: 2012. */
/****************************************************************/
OPTIONS ls=80 ps=100 NOCENTER MLOGIC MPRINT SYMBOLGEN;
options compress=yes; 

LIBNAME out "Y:\Marketing Mix PI\InvOpt\P2 2014 AB\Promo\Diabetes Deep Dive\RespModel\Data"; run;

/*
Model explorations
*/
data sel_jan_yr_vars; set out.sel_jan_yr_vars; run;
/*data sel_jmt_yr_vars; set out.sel_jmt_yr_vars; run;
data sel_tot_yr_vars; set out.sel_tot_yr_vars; run;*/

/* **************
Basic spline codes with known knots (3 knots assumed) using proc reg.
**************** */
%let mdset=sel_jan_yr_vars;
%let k1=200;  %let k2=600;  %let k3=1200;
data sp_mdldata;
    set &mdset.(where= (dotperdet <= dpd99));
    * vars for spline models;
    * assumptions: knots at DOTCUR = 200, 600, 1200;
    * construct "+" (plus) functions as in Smith(1979);
    if dotcur <= &k1. then do; pl1_dot = 0; pl1_dot_sq = 0; end;
    else do; pl1_dot = dotcur - &k1.; pl1_dot_sq = pl1_dot * pl1_dot; end; 
    if dotcur <= &k2. then do; pl2_dot = 0; pl2_dot_sq = 0; end;
    else do; pl2_dot = dotcur - &k2.; pl2_dot_sq = pl2_dot * pl2_dot; end; 
    if dotcur <= &k3. then do; pl3_dot = 0; pl3_dot_sq = 0; end;
    else do; pl3_dot = dotcur - &k3.; pl3_dot_sq = pl3_dot * pl3_dot; end; 
run;

ODS OUTPUT PARAMETERESTIMATES=sp1;
PROC REG DATA=sp_mdldata outest=sp_reg_par_est;
    /* "+" type spline regressions with fixed knots */

    * Following is linear line segments continuous in y at knots (i.e. PRC like);
    psp1: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF DETCUR  
                         dotcur  
                         pl1_dot pl2_dot pl3_dot 
                         / RSQUARE VIF CLB ALPHA=0.10; 

    * Following is quadratic and continuous in y at knots;
    psp2: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF DETCUR  
                         dotcur dotcur_sq 
                         pl1_dot pl2_dot pl3_dot 
		  			     pl1_dot_sq pl2_dot_sq pl3_dot_sq  
                         / RSQUARE VIF CLB ALPHA=0.10; 

	* Following is quadratic and continuous in y and y-dash at knots;
    psp3: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF DETCUR  
                         dotcur dotcur_sq 
   		  			     /*pl1_dot pl2_dot pl3_dot */ 
		  			     pl1_dot_sq pl2_dot_sq pl3_dot_sq  
                         / RSQUARE VIF CLB ALPHA=0.10; 
RUN; QUIT;


/*
Represent the above 3 knots spline models using flexible knots through proc nlin.
*/
PROC NLIN DATA=sel_jan_yr_vars;
  PARMS e_intercept=0 e_nrxpre=0 e_volpre=0 e_mfpcur=0 e_totmmf=0 e_detcur=0 
        e_dotcur=0 e_dotcur_sq=0
		k1=200 k2=600 k3=1200
        /*e_k1_1=0 e_k2_1=0 e_k3_1=0*/
        e_k1_2=0 e_k2_2=0 e_k3_2=0 ;
  * knot constraints;
  BOUNDS k1 < k2 < k3;
  * compute plus variables based on knot locations;
  if dotcur <= k1 then do; pl1_dot = 0; pl1_dot_sq = 0; end;
  else do; pl1_dot = dotcur - k1; pl1_dot_sq = pl1_dot * pl1_dot; end; 
  if dotcur <= k2 then do; pl2_dot = 0; pl2_dot_sq = 0; end;
  else do; pl2_dot = dotcur - k2; pl2_dot_sq = pl2_dot * pl2_dot; end; 
  if dotcur <= k3 then do; pl3_dot = 0; pl3_dot_sq = 0; end;
  else do; pl3_dot = dotcur - k3; pl3_dot_sq = pl3_dot * pl3_dot; end; 

  * model;
  /*
  MODEL nrxchg = e_intercept + e_nrxpre*nrxpre + e_volpre*volpre 
                 + e_mfpcur*mfpcur + e_totmmf*totmmf + e_detcur*detcur  
                 + e_dotcur*dotcur + e_dotcur_sq*dotcur_sq 
				 + e_k1_1*pl1_dot + e_k2_1*pl2_dot + e_k3_1*pl3_dot;
  */
  MODEL nrxchg = e_intercept + e_nrxpre*nrxpre + e_volpre*volpre 
                 + e_mfpcur*mfpcur + e_totmmf*totmmf + e_detcur*detcur  
                 + e_dotcur*dotcur + e_dotcur_sq*dotcur_sq 
				 + e_k1_2*pl1_dot_sq + e_k2_2*pl2_dot_sq + e_k3_2*pl3_dot_sq;

RUN;
/* 
 Above models have convergence issues and non-significant all dotcur related terms.
 In particular, model 1 (linear splines) have singular Hessian.
*/

/* **********************************
2. Try another straight forward approach for linear (or quadractic) segments based models.
  some derivations are needed for this.
*********************************** */
PROC NLIN DATA=sel_jan_yr_vars;
  PARMS e_nrxpre=0 e_volpre=0 e_mfpcur=0 e_totmmf=0 e_detcur=0 
        alph1=100 beta1=4 alph2=200 beta2=3 alph3=400 beta3=2
        alph4=800 beta4=1;

  k1 = (alph2 - alph1) / (beta1 - beta2);
  k2 = (alph3 - alph2) / (beta2 - beta3);
  k3 = (alph4 - alph3) / (beta3 - beta4);

  * knot constraints;
  *BOUNDS ((alph2 - alph1) / (beta1 - beta2)) < ((alph3 - alph2) / (beta2 - beta3));
  BOUNDS beta1 > 0; 
  BOUNDS beta2 > 0;
  BOUNDS beta3 > 0; 
  BOUNDS beta4 > 0; 
  BOUNDS alph1 < alph2 < alph3 < alph4;
  
  * model;
  if dotcur < k1 then 
      MODEL nrxchg = e_nrxpre*nrxpre + e_volpre*volpre 
                 + e_mfpcur*mfpcur + e_totmmf*totmmf + e_detcur*detcur  
                 + alph1 + beta1*dotcur;
  else if dotcur >= k1 and dotcur < k2 then 
      MODEL nrxchg = e_nrxpre*nrxpre + e_volpre*volpre 
                 + e_mfpcur*mfpcur + e_totmmf*totmmf + e_detcur*detcur  
                 + alph2 + beta2*dotcur;
  else if dotcur >= k2 and dotcur < k3 then
      MODEL nrxchg = e_nrxpre*nrxpre + e_volpre*volpre 
                 + e_mfpcur*mfpcur + e_totmmf*totmmf + e_detcur*detcur  
                 + alph3 + beta3*dotcur;
  else if dotcur >= k3 then
      MODEL nrxchg = e_nrxpre*nrxpre + e_volpre*volpre 
                 + e_mfpcur*mfpcur + e_totmmf*totmmf + e_detcur*detcur  
                 + alph4 + beta4*dotcur;

  if _obs_=1 and _iter_ =.  then do;
      k1 = (alph2 - alph1) / (beta1 - beta2);
      k2 = (alph3 - alph2) / (beta2 - beta3);
      k3 = (alph4 - alph3) / (beta3 - beta4);
        put /  k1= k2= k3= ;
  end;
RUN;


PROC NLIN DATA=sel_jan_yr_vars;
  PARMS e_nrxpre=0 e_volpre=0 e_mfpcur=0 e_totmmf=0 e_detcur=0 
        alph1=100 beta1=4 alph2=200 beta2=3 alph3=400 beta3=2
        alph4=800 beta4=1 
        gama1=0 gama2=0 gama3=0 gama4=0;

  k1 = 2*(alph2 - alph1) / (beta1 - beta2);
  k2 = 2*(alph3 - alph2) / (beta2 - beta3);
  k3 = 2*(alph4 - alph3) / (beta3 - beta4);

  * knot constraints;
  *BOUNDS ((alph2 - alph1) / (beta1 - beta2)) < ((alph3 - alph2) / (beta2 - beta3));
  BOUNDS beta1 > 0; 
  BOUNDS beta2 > 0;
  BOUNDS beta3 > 0; 
  BOUNDS beta4 > 0; 
  BOUNDS alph1 < alph2 < alph3 < alph4;
  
  * model;
  if dotcur < k1 then 
      MODEL nrxchg = e_nrxpre*nrxpre + e_volpre*volpre 
                 + e_mfpcur*mfpcur + e_totmmf*totmmf + e_detcur*detcur  
                 + alph1 + beta1*dotcur + gama1*dotcur_sq;
  else if dotcur >= k1 and dotcur < k2 then 
      MODEL nrxchg = e_nrxpre*nrxpre + e_volpre*volpre 
                 + e_mfpcur*mfpcur + e_totmmf*totmmf + e_detcur*detcur  
                 + alph2 + beta2*dotcur + gama2*dotcur_sq;
  else if dotcur >= k2 and dotcur < k3 then
      MODEL nrxchg = e_nrxpre*nrxpre + e_volpre*volpre 
                 + e_mfpcur*mfpcur + e_totmmf*totmmf + e_detcur*detcur  
                 + alph3 + beta3*dotcur + gama3*dotcur_sq;
  else if dotcur >= k3 then
      MODEL nrxchg = e_nrxpre*nrxpre + e_volpre*volpre 
                 + e_mfpcur*mfpcur + e_totmmf*totmmf + e_detcur*detcur  
                 + alph4 + beta4*dotcur + gama4*dotcur_sq;

  if _obs_=1 and _iter_ =.  then do;
      k1 = 2*(alph2 - alph1) / (beta1 - beta2);
      k2 = 2*(alph3 - alph2) / (beta2 - beta3);
      k3 = 2*(alph4 - alph3) / (beta3 - beta4);
        put /  k1= k2= k3= ;
  end;
RUN;





















/* ********************************************;
* Check structures with spline models (fixed knots)
* TRY '+' type SPLINES for DOTCUR (i.e., some spline segments with knots);
* REF: Smith(1979) "Splines as a useful and convinient Statistical tool" The American Statistician;
******************************************** */;
/*
%LET PATH=Y:\Marketing Mix PI\InvOpt\P2 2014 AB\Promo\Diabetes Deep Dive\RespModel\Data\est;
%let mdset=sel_jan_yr_vars;
%let mdesc=SP_JAN;
%let k1=200;  %let k2=600;  %let k3=1200;
%let det_score_max=60;  %let det_score_incr=1;
%let dot_score_max=4000;  %let dot_score_incr=10;
*/
* Following is a temporary macro used inside the run_sp_mdl() macro;
%macro comp1(mdl);
   if first.score_var then ini_&mdl. = &mdl.;
   p_nrx_&mdl. = &mdl.;
   p_incr_&mdl. = p_nrx_&mdl. - ini_&mdl.;
%mend comp1;

%macro runspmdl();
  data sp_mdldata;
    set &mdset.(where= (dotperdet <= dpd99));
    * vars for spline modes;
    * assumptions: knots at DOTCUR = 200, 600, 1200;
    * construct "+" (plus) functions as in Smith(1979);
    if dotcur <= &k1. then do; pl1_dot = 0; pl1_dot_sq = 0; end;
    else do; pl1_dot = dotcur - &k1.; pl1_dot_sq = pl1_dot * pl1_dot; end; 
    if dotcur <= &k2. then do; pl2_dot = 0; pl2_dot_sq = 0; end;
    else do; pl2_dot = dotcur - &k2.; pl2_dot_sq = pl2_dot * pl2_dot; end; 
    if dotcur <= &k3. then do; pl3_dot = 0; pl3_dot_sq = 0; end;
    else do; pl3_dot = dotcur - &k3.; pl3_dot_sq = pl3_dot * pl3_dot; end; 

	if dotcur <= &k4. then do; pl4_dot = 0; pl4_dot_sq = 0; end;
    else do; pl4_dot = dotcur - &k4.; pl4_dot_sq = pl4_dot * pl4_dot; end; 
    if dotcur <= &k5. then do; pl5_dot = 0; pl5_dot_sq = 0; end;
    else do; pl5_dot = dotcur - &k5.; pl5_dot_sq = pl5_dot * pl5_dot; end; 
    if dotcur <= &k6. then do; pl6_dot = 0; pl6_dot_sq = 0; end;
    else do; pl6_dot = dotcur - &k6.; pl6_dot_sq = pl6_dot * pl6_dot; end; 

	if dotcur <= &k7. then do; pl7_dot = 0; pl7_dot_sq = 0; end;
    else do; pl7_dot = dotcur - &k7.; pl7_dot_sq = pl7_dot * pl7_dot; end; 
    if dotcur <= &k8. then do; pl8_dot = 0; pl8_dot_sq = 0; end;
    else do; pl8_dot = dotcur - &k8.; pl8_dot_sq = pl8_dot * pl8_dot; end; 

  run;

  ODS OUTPUT PARAMETERESTIMATES=sp1;
  PROC REG DATA=sp_mdldata outest=sp_reg_par_est;
      m1: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF DETCUR 
                         DOTCUR / RSQUARE VIF CLB ALPHA=0.10;
      m5: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF DETCUR DETCUR_SQ  
                         DOTCUR DOTCUR_SQ / RSQUARE VIF CLB ALPHA=0.10;
      m9: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF DETCUR_ln  
                         DOTCUR_ln / RSQUARE VIF CLB ALPHA=0.10;
      m11: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF DETCUR_root  
                         DOTCUR_root / RSQUARE VIF CLB ALPHA=0.10;

      swJAN: MODEL NRXCHG = NRXPRE VOLPRE DETCUR_ln  
                         DOTCUR DOTCUR_sq DOTCUR_ln / RSQUARE VIF CLB ALPHA=0.10;
      swJMT: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF DETCUR_ln DETCUR_root  
                         DOTCUR DOTCUR_sq DOTCUR_ln DOTCUR_root / RSQUARE VIF CLB ALPHA=0.10;
      swTOT: MODEL NRXCHG = NRXPRE VOLPRE DETCUR_ln  
                         DOTCUR DOTCUR_ln / RSQUARE VIF CLB ALPHA=0.10;

      /* "+" type spline regressions with fixed knots */
      psp1: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF DETCUR  
                         dotcur  
                         pl1_dot pl2_dot pl3_dot pl4_dot pl5_dot pl6_dot pl7_dot pl8_dot 
                         / RSQUARE VIF CLB ALPHA=0.10; * this is linear line segments continuous in y at knots (i.e. PRC like);
      psp2: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF DETCUR  
                         dotcur dotcur_sq 
                         pl1_dot pl2_dot pl3_dot pl4_dot pl5_dot pl6_dot pl7_dot pl8_dot 
		  			     pl1_dot_sq pl2_dot_sq pl3_dot_sq pl4_dot_sq pl5_dot_sq 
                            pl6_dot_sq pl7_dot_sq pl8_dot_sq 
                         / RSQUARE VIF CLB ALPHA=0.10; * this is quadratic and continuous in y at knots;
      psp3: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF DETCUR  
                         dotcur dotcur_sq 
   		  			     /*pl1_dot pl2_dot pl3_dot pl4_dot pl5_dot pl6_dot pl7_dot pl8_dot */ 
		  			     pl1_dot_sq pl2_dot_sq pl3_dot_sq pl4_dot_sq pl5_dot_sq 
                            pl6_dot_sq pl7_dot_sq pl8_dot_sq 
                         / RSQUARE VIF CLB ALPHA=0.10; * this is quadratic and continuous in y and y-dash at knots;
  RUN; QUIT;
  
  /* Build Score data set */
  * Build Scoring Dataset;
  proc summary data=sp_mdldata; 
    var nrxchg nrxpre nrxcur volpre mfpcur totmmf sfpcur detcur detcur_sq
        dotcur dotcur_sq pcpind intpcpsam detcur_ln detcur_root dotcur_ln dotcur_root
        pl1_dot pl2_dot pl3_dot pl4_dot pl5_dot pl6_dot pl7_dot pl8_dot 
        pl1_dot_sq pl2_dot_sq pl3_dot_sq pl4_dot_sq pl5_dot_sq 
          pl6_dot_sq pl7_dot_sq pl8_dot_sq ;
    output out=sp_sm_mdldata mean=;
  run;
  data sp_score_data_mn(drop= _type_ _freq_ i tmp_:);
    set sp_sm_mdldata;
    tmp_det = detcur; tmp_det2 = detcur_sq; tmp_det_ln = detcur_ln; tmp_det_root = detcur_root; 
    tmp_dot = dotcur; tmp_dot2 = dotcur_sq; tmp_dot_ln = dotcur_ln; tmp_dot_root = dotcur_root;
    do i=0 to &det_score_max. by &det_score_incr.;
      detcur = i; detcur_sq = i*i; detcur_ln = log(i+1); detcur_root = sqrt(i); 
      dotcur = tmp_dot; dotcur_sq = tmp_dot2; dotcur_ln = tmp_dot_ln; dotcur_root = tmp_dot_root;
	  score_var = "det";
      output;
    end;
    do i=0 to &dot_score_max. by &dot_score_incr.;
      detcur = tmp_det; detcur_sq = tmp_det2; detcur_ln = tmp_det_ln; detcur_root = tmp_det_root; 
      dotcur = i; dotcur_sq = i*i; dotcur_ln = log(i+1); dotcur_root = sqrt(i);
      if dotcur <= &k1. then do; pl1_dot = 0; pl1_dot_sq = 0; end;
      else do; pl1_dot = dotcur - &k1.; pl1_dot_sq = pl1_dot * pl1_dot; end; 
      if dotcur <= &k2. then do; pl2_dot = 0; pl2_dot_sq = 0; end;
      else do; pl2_dot = dotcur - &k2.; pl2_dot_sq = pl2_dot * pl2_dot; end; 
      if dotcur <= &k3. then do; pl3_dot = 0; pl3_dot_sq = 0; end;
      else do; pl3_dot = dotcur - &k3.; pl3_dot_sq = pl3_dot * pl3_dot; end; 

	  if dotcur <= &k4. then do; pl4_dot = 0; pl4_dot_sq = 0; end;
      else do; pl4_dot = dotcur - &k4.; pl4_dot_sq = pl4_dot * pl4_dot; end; 
      if dotcur <= &k5. then do; pl5_dot = 0; pl5_dot_sq = 0; end;
      else do; pl5_dot = dotcur - &k5.; pl5_dot_sq = pl5_dot * pl5_dot; end; 
      if dotcur <= &k6. then do; pl6_dot = 0; pl6_dot_sq = 0; end;
      else do; pl6_dot = dotcur - &k6.; pl6_dot_sq = pl6_dot * pl6_dot; end; 

	  if dotcur <= &k7. then do; pl7_dot = 0; pl7_dot_sq = 0; end;
      else do; pl7_dot = dotcur - &k7.; pl7_dot_sq = pl7_dot * pl7_dot; end; 
      if dotcur <= &k8. then do; pl8_dot = 0; pl8_dot_sq = 0; end;
      else do; pl8_dot = dotcur - &k8.; pl8_dot_sq = pl8_dot * pl8_dot; end; 

	  score_var = "dot";
      output;
    end;
  run;

  proc score data=sp_score_data_mn score=sp_reg_par_est out=sp_score_out_reg type=parms;
    var nrxchg nrxpre volpre mfpcur totmmf detcur detcur_sq
        dotcur dotcur_sq detcur_ln detcur_root dotcur_ln dotcur_root
        pl1_dot pl2_dot pl3_dot pl4_dot pl5_dot pl6_dot pl7_dot pl8_dot 
        pl1_dot_sq pl2_dot_sq pl3_dot_sq pl4_dot_sq pl5_dot_sq 
          pl6_dot_sq pl7_dot_sq pl8_dot_sq ;

  run;

  data sp_score_out_reg_2;
      set sp_score_out_reg;
	  by score_var;
      retain ini_m1 ini_m5 ini_m9 ini_m11 ini_swJAN ini_swJMT ini_swTOT 
             ini_psp1 ini_psp2 ini_psp3;

 	  %comp1(m1);  %comp1(m5);  %comp1(m9);  %comp1(m11);
      %comp1(swJAN);  %comp1(swJMT);  %comp1(swTOT);  
      %comp1(psp1);  %comp1(psp2);  %comp1(psp3); 

	  drop m1 m5 m9 m11 swJAN swJMT swTOT psp1 psp2 psp3;
  run;
  * contenders are m5 psp1 psp3;

  /* Get sums and integrate with the model estimates.; */
  PROC MEANS DATA=sp_mdldata NOPRINT; 
    VAR nrxchg nrxpre nrxcur volpre mfpcur totmmf sfpcur detcur detcur_sq
          dotcur dotcur_sq pcpind intpcpsam detcur_ln detcur_root dotcur_ln dotcur_root
          pl1_dot pl2_dot pl3_dot pl4_dot pl5_dot pl6_dot pl7_dot pl8_dot 
          pl1_dot_sq pl2_dot_sq pl3_dot_sq pl4_dot_sq pl5_dot_sq 
            pl6_dot_sq pl7_dot_sq pl8_dot_sq ;
    OUTPUT OUT=SP_SSUMS SUM=nrxchg nrxpre nrxcur volpre mfpcur totmmf sfpcur 
                            detcur detcur_sq dotcur dotcur_sq pcpind intpcpsam 
                            detcur_ln detcur_root dotcur_ln dotcur_root
                            pl1_dot pl2_dot pl3_dot pl4_dot pl5_dot pl6_dot pl7_dot pl8_dot 
                            pl1_dot_sq pl2_dot_sq pl3_dot_sq pl4_dot_sq pl5_dot_sq 
                              pl6_dot_sq pl7_dot_sq pl8_dot_sq ;
  RUN;

  *merge the estimates with the corresponding variable SUMS and N;
  data sp1_est; set sp1; obs=_n_; run;

  proc transpose data=sp_ssums out=tr_sp_ssums(rename=(col1=sum)); run; 
  data tmp; set tr_sp_ssums(where=( _name_="_FREQ_" )); drop _name_; rename sum = N; run;
  data tr_sp_ssums_v2; 
    set tr_sp_ssums;
    if _n_ = 1 then set tmp;
    variable = lowcase(_name_);
    drop _name_;
  run; 
  proc sort data=sp1_est; by variable; run;
  proc sort data=tr_sp_ssums_v2; by variable; run;
  data sp1_est_v2;
    merge sp1_est(in=a) tr_sp_ssums_v2(in=b);
    by variable;
    if a;
  run;
  proc sort data=sp1_est_v2; by obs; run;
  data sp1_est_v2; set sp1_est_v2; drop obs; run;

  PROC EXPORT DATA=sp1_est_v2
    OUTFILE= "&PATH.\sp_mdl_est_all_1.xls" 
    DBMS=EXCEL97 REPLACE;
    SHEET = "&mdesc.";
  RUN;
  PROC EXPORT DATA=sp_ssums
    OUTFILE= "&PATH.\sp_mdl_sum_all_1.xls" 
    DBMS=EXCEL97 REPLACE;
    SHEET = "&mdesc.";
  RUN;
  PROC EXPORT DATA=sp_score_out_reg_2 
    OUTFILE= "&PATH.\reg_spline_scores.xls" 
    DBMS=EXCEL97 REPLACE;
    SHEET = "&mdesc.";
  RUN;
  PROC EXPORT DATA=sp_reg_par_est 
    OUTFILE= "&PATH.\reg_spline_est.xls" 
    DBMS=EXCEL97 REPLACE;
    SHEET = "&mdesc.";
  RUN;

%mend runspmdl;

* run reg and spline models for JANUVIA;
%LET PATH=Y:\Marketing Mix PI\InvOpt\P2 2014 AB\Promo\Diabetes Deep Dive\RespModel\Data\est;
%let det_score_max=60;  %let det_score_incr=1;
%let dot_score_max=4000;  %let dot_score_incr=10;
%let mdset=sel_jan_yr_vars;
%let mdesc=SP_JAN;
/*%let k1=200;  %let k2=600;  %let k3=1200;*/
%let k1=100;  %let k2=200;  %let k3=450; 
%let k4=600;  %let k5=800;  %let k6=1000;
%let k7=1200;  %let k8=1600;
%runspmdl();

* run reg and spline models for JANUMET;
%let mdset=sel_jmt_yr_vars;
%let mdesc=SP_JMT;
/*%let k1=100;  %let k2=300;  %let k3=600;*/
%let k1=50;  %let k2=100;  %let k3=200; 
%let k4=300;  %let k5=400;  %let k6=500;
%let k7=600;  %let k8=800;
%runspmdl();

* run reg and spline models for JANTOT;
%let mdset=sel_tot_yr_vars;
%let mdesc=SP_TOT;
/*%let k1=300;  %let k2=800;  %let k3=1500;*/
%let k1=150;  %let k2=300;  %let k3=550; 
%let k4=800;  %let k5=1100;  %let k6=1400;
%let k7=1700;  %let k8=2200;
%runspmdl();




