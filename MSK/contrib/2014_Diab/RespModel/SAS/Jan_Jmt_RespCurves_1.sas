/****************************************************************/
/*   Januvia / Janumet Detail, Sample response curves  */
/* Try response CURVES, so that optimal detail and/or sample could be determined */
/* Time period of interest: 2012. */
/****************************************************************/
OPTIONS ls=80 ps=100 NOCENTER MLOGIC MPRINT SYMBOLGEN;
options compress=yes; 

LIBNAME JANGR '\\usuguscads1\data\grail\Januvia';  RUN; *januvia_grail1212.sas7bdat;
LIBNAME JMTGR '\\usuguscads1\data\grail\Janumet';  RUN; *janumet_grail1212.sas7bdat;
LIBNAME TOTGR '\\usuguscads1\data\grail\Jantot';  RUN; *jantot_grail1212.sas7bdat;
LIBNAME MMFTARG '\\wpushh01\dinfopln\Marketing Mix PI\MMF 2013\MMF'; RUN; *mfatnd_dec11nov12.sas7bdat;
LIBNAME GRPPRAC '\\Wpushh01\dinfopln\Marketing Mix PI\MMF 2012\Group Practice Data'; RUN;
LIBNAME out "Y:\Marketing Mix PI\InvOpt\P2 2014 AB\Promo\Diabetes Deep Dive\RespModel\Data"; run;

PROC SORT DATA=MMFTARG.Mfatnd_dec11nov12 (KEEP=IMSDRNUM PRODUCT CALLYY CALLMM
WHERE=(CALLYY = 2012 AND PRODUCT IN ('JANUVIA' 'JANUMET' 'JANTOT'))) 
OUT=mmftarg1; BY IMSDRNUM; RUN; *note: this has 11 months of data for 2012.;
proc freq data=mmftarg1; tables product callmm / list missing; run; * only JANTOT;
proc sql; 
create table mmftarg2 as
  select imsdrnum, product, count(*) as totmmf from mmftarg1 group by imsdrnum, product;
quit;
proc sort data=GRPPRAC.Grppract_indicator_16may11 out=grprac_type nodupkey; by imsdrnum; run;

PROC SORT DATA=JANGR.januvia_grail1212(keep= imsdrnum rdt: a1n: an: a1t: at: 
            cat spec dettot: samtot: mfp: sfp:)
OUT=gr_jan; BY IMSDRNUM;  RUN;
proc freq data=gr_jan; tables cat / list missing; run;
PROC SORT DATA=JMTGR.janumet_grail1212(keep= imsdrnum rdt: a1n: an: a1t: at: 
            cat spec dettot: samtot: mfp: sfp:)
OUT=gr_jmt; BY IMSDRNUM;  RUN;
proc freq data=gr_jmt; tables cat / list missing; run;
PROC SORT DATA=TOTGR.jantot_grail1212(keep= imsdrnum rdt: a1n: an: a1t: at: 
            cat spec dettot: samtot: mfp: sfp:)
OUT=gr_tot; BY IMSDRNUM;  RUN;
proc freq data=gr_tot; tables cat / list missing; run;

data sel_jan_2;
  merge gr_jan(in=a rename=(spec=ospec)) mmftarg2(in=b drop=product) grprac_type(in=s);
  by imsdrnum;
  if a;
  if b or cat in: ('A','B','C');
  if ospec in ('CD' 'CDS' 'IC' 'ICE' 'NEP' 'VM' 'VS' 'DIA' 'END') then spec='SP'; else spec='PC';
  if spec='PC' then pcpind=1;  else pcpind=0;
  *length grouptype $4.;
  *if s then grouptype='SOLO';
run;
proc freq data=sel_jan_2; tables cat spec*pcpind grouptype/ list missing; run;

data sel_jmt_2;
  merge sel_jmt(in=a rename=(spec=ospec)) mmftarg2(in=b drop=product) grprac_type(in=s);
  by imsdrnum;
  if a;
  if b or cat in: ('A','B','C');
  if ospec in ('CD' 'CDS' 'IC' 'ICE' 'NEP' 'VM' 'VS' 'DIA' 'END') then spec='SP'; else spec='PC';
  if spec='PC' then pcpind=1;  else pcpind=0;
  *length grouptype $4.;
  *if s then grouptype='SOLO';
run;
proc freq data=sel_jmt_2; tables cat spec*pcpind grouptype/ list missing; run;

data sel_tot_2;
  merge sel_tot(in=a rename=(spec=ospec)) mmftarg2(in=b drop=product) grprac_type(in=s);
  by imsdrnum;
  if a;
  if b or cat in: ('A','B','C');
  if ospec in ('CD' 'CDS' 'IC' 'ICE' 'NEP' 'VM' 'VS' 'DIA' 'END') then spec='SP'; else spec='PC';
  if spec='PC' then pcpind=1;  else pcpind=0;
  *length grouptype $4.;
  *if s then grouptype='SOLO';
run;
proc freq data=sel_tot_2; tables cat spec*pcpind grouptype/ list missing; run;

%macro getvars(prod);
  data sel_&prod._2;
    merge gr_&prod.(in=a rename=(spec=ospec)) mmftarg2(in=b drop=product) grprac_type(in=s);
    by imsdrnum;
    if a;
    *if b or cat in: ('A','B','C');
	if cat in: ('A','B','C');
	if totmmf=. then totmmf=0;
    if ospec in ('CD' 'CDS' 'IC' 'ICE' 'NEP' 'VM' 'VS' 'DIA' 'END') then spec='SP'; else spec='PC';
    if spec='PC' then pcpind=1;  else pcpind=0;
    *length grouptype $4.;
    *if s then grouptype='SOLO';
  run;
  proc freq data=sel_&prod._2; tables cat spec*pcpind grouptype/ list missing; run;

  data sel_&prod._3;
    set sel_&prod._2;
    nrxcur = SUM(OF A1N1-A1N12);
    volcur = SUM(OF AN1-AN12);
    detcur = SUM(OF dettot1-dettot12);
    mfpcur = SUM(OF mfp1-mfp12);
    sfpcur = SUM(OF sfp1-sfp12);
    samcur = SUM(OF samtot1-samtot12);

    nrxpre = SUM(OF A1N13-A1N24);
    volpre = SUM(OF AN13-AN24);
    detpre = SUM(OF dettot13-dettot24);
    sampre = SUM(OF samtot13-samtot24);

    nrxchg = nrxcur - nrxpre;
    dotcur = samcur * 7;
    dotpre = sampre * 7;
    intpcpdet = pcpind*detcur;
    intpcpsam = pcpind*dotcur;

	*square and interaction term(s);
    dotcur_sq = dotcur * dotcur;
	dotdet = detcur * dotcur;
    
    if nrxpre=0 then dotnrxpre=.;
    else dotnrxpre = dotpre/nrxpre;
    if nrxcur=0 then dotnrxcur=.;
    else dotnrxcur = dotcur/nrxcur;
    if detcur > 0 then dotperdet=dotcur/detcur;
    else dotperdet=0;
	keep imsdrnum rdt: cat spec pcpind totmmf grouptype
        nrxcur volcur detcur mfpcur sfpcur samcur
        nrxpre volpre detpre sampre
        nrxchg dotcur dotpre intpcpdet intpcpsam
        dotnrxpre dotnrxcur dotperdet; 
  run;

  PROC UNIVARIATE DATA=sel_&prod._3;
  VAR DOTPERDET;
  OUTPUT OUT=OUTLIERS P99=DPD99 P95=DPD95;
  RUN;

  DATA sel_&prod._3;
     SET sel_&prod._3;
     RETAIN DPD99 DPD95;
     IF _N_=1 THEN DO;
        SET OUTLIERS;
     END;
  RUN;
%mend getvars;
%getvars(jan);   %getvars(jmt);   %getvars(tot);  

/*
* store as permanent dataset for modeling. (this is yearly aggregated data).;
data out.sel_jan_yr_vars; set sel_jan_3; run;
data out.sel_jmt_yr_vars; set sel_jmt_3; run;
data out.sel_tot_yr_vars; set sel_tot_3; run;
*/

/*
Model explorations
*/
data sel_jan_yr_vars; set out.sel_jan_yr_vars; run;
data sel_jmt_yr_vars; set out.sel_jmt_yr_vars; run;
data sel_tot_yr_vars; set out.sel_tot_yr_vars; run;

%MACRO regmdl1(mdldata,filter,mdesc);
  data mdl_all;
    set &mdldata.;
	if &filter.;
    intpcpsam = pcpind*dotcur;
	detcur_sq = detcur*detcur;
	dotcur_sq = dotcur*dotcur;
	detcur_ln = log(detcur + 1);
	dotcur_ln = log(dotcur + 1);
	detcur_root = sqrt(detcur);
	dotcur_root = sqrt(dotcur);
    if dotperdet >= dpd99 then delete;
  run;
  /*-- store as permanent dataset - one time execution only 
     data out.&mdldata._v2; set mdl_all; run;
  --*/
  
  proc sort data=mdl_all; by spec; run;

  ODS OUTPUT PARAMETERESTIMATES=e1;
  PROC REG DATA=mdl_all;
    m1: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF /*SFPCUR*/ DETCUR  
                       DOTCUR / RSQUARE VIF COLLIN CLB ALPHA=0.10;
    m2: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF /*SFPCUR*/ DETCUR  
                       DOTCUR DOTCUR_SQ / RSQUARE VIF COLLIN CLB ALPHA=0.10;
    m3: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF /*SFPCUR*/ DETCUR 
                       DOTCUR DOTCUR_SQ PCPIND / RSQUARE VIF COLLIN CLB ALPHA=0.10;
    m4: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF /*SFPCUR*/ DETCUR 
                       DOTCUR DOTCUR_SQ PCPIND INTPCPSAM / RSQUARE VIF COLLIN CLB ALPHA=0.10;
    m5: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF /*SFPCUR*/ DETCUR DETCUR_SQ  
                       DOTCUR DOTCUR_SQ / RSQUARE VIF COLLIN CLB ALPHA=0.10;
    m6: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF /*SFPCUR*/ DETCUR DETCUR_SQ
                       DOTCUR DOTCUR_SQ PCPIND / RSQUARE VIF COLLIN CLB ALPHA=0.10;
    m7: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF /*SFPCUR*/ DETCUR DETCUR_SQ
                       DOTCUR DOTCUR_SQ PCPIND INTPCPSAM / RSQUARE VIF COLLIN CLB ALPHA=0.10;
    m8: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF /*SFPCUR*/ DETCUR  
                       DOTCUR_ln / RSQUARE VIF COLLIN CLB ALPHA=0.10;
    m9: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF /*SFPCUR*/ DETCUR_ln  
                       DOTCUR_ln / RSQUARE VIF COLLIN CLB ALPHA=0.10;
    m10: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF /*SFPCUR*/ DETCUR  
                       DOTCUR_root / RSQUARE VIF COLLIN CLB ALPHA=0.10;
    m11: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF /*SFPCUR*/ DETCUR_root  
                       DOTCUR_root / RSQUARE VIF COLLIN CLB ALPHA=0.10;

    swJAN: MODEL NRXCHG = NRXPRE VOLPRE DETCUR_ln  
                       DOTCUR DOTCUR_sq DOTCUR_ln / RSQUARE VIF COLLIN CLB ALPHA=0.10;
    swJMT: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF DETCUR_ln DETCUR_root  
                       DOTCUR DOTCUR_sq DOTCUR_ln DOTCUR_root / RSQUARE VIF COLLIN CLB ALPHA=0.10;
    swTOT: MODEL NRXCHG = NRXPRE VOLPRE DETCUR_ln  
                       DOTCUR DOTCUR_ln / RSQUARE VIF COLLIN CLB ALPHA=0.10;

  RUN; QUIT;

  ODS OUTPUT PARAMETERESTIMATES=e2;
  PROC REG DATA=mdl_all;
    s1: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF /*SFPCUR*/ DETCUR
           DOTCUR / RSQUARE VIF COLLIN CLB ALPHA=0.10;
    s2: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF /*SFPCUR*/ DETCUR
           DOTCUR DOTCUR_SQ / RSQUARE VIF COLLIN CLB ALPHA=0.10;
    s3: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF /*SFPCUR*/ DETCUR_ln  
           DOTCUR_ln / RSQUARE VIF COLLIN CLB ALPHA=0.10;
    s4: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF /*SFPCUR*/ DETCUR_root 
           DOTCUR_root / RSQUARE VIF COLLIN CLB ALPHA=0.10;
    BY SPEC;
  RUN; QUIT;

  data est_all;  set e1 e2; run;
  PROC SORT DATA=est_all;  BY SPEC;  RUN;

  PROC MEANS DATA=mdl_all NOPRINT; 
    VAR NRXCHG NRXPRE NRXCUR VOLPRE MFPCUR TOTMMF SFPCUR DETCUR DETCUR_SQ  
        DOTCUR DOTCUR_SQ PCPIND INTPCPSAM DETCUR_ln DOTCUR_ln DETCUR_root DOTCUR_root;
    OUTPUT OUT=SSUMS1 SUM=NRXCHG NRXPRE NRXCUR VOLPRE MFPCUR TOTMMF SFPCUR DETCUR DETCUR_SQ  
                          DOTCUR DOTCUR_SQ PCPIND INTPCPSAM 
                          DETCUR_ln DOTCUR_ln DETCUR_root DOTCUR_root;
  RUN;
  PROC MEANS DATA=mdl_all NOPRINT; BY SPEC;
    VAR NRXCHG NRXPRE NRXCUR VOLPRE MFPCUR TOTMMF SFPCUR DETCUR DETCUR_SQ  
        DOTCUR DOTCUR_SQ PCPIND INTPCPSAM DETCUR_ln DOTCUR_ln DETCUR_root DOTCUR_root;
    OUTPUT OUT=SSUMS2 SUM=NRXCHG NRXPRE NRXCUR VOLPRE MFPCUR TOTMMF SFPCUR DETCUR DETCUR_SQ  
                          DOTCUR DOTCUR_SQ PCPIND INTPCPSAM
                          DETCUR_ln DOTCUR_ln DETCUR_root DOTCUR_root;
  RUN;

  DATA SSUMS;  SET SSUMS1 SSUMS2;
  PROC SORT DATA=SSUMS out=sum_all;  BY SPEC;  RUN;

  PROC FREQ DATA=mdl_all;
  TABLES SPEC / LIST OUT=PCPWEIGHT; RUN;

  DATA PCPWEIGHT; SET PCPWEIGHT; SPECPCT=PERCENT/100; RUN;

  PROC TRANSPOSE DATA=PCPWEIGHT OUT=PCPWT_all PREFIX=PCT;
  ID SPEC; VAR SPECPCT; RUN;

  *merge the estimates with the corresponding variable SUMS and N;
  data ssums; set ssums; if spec='' then spec='AL'; run;
  data est_all; set est_all; if spec='' then spec='AL'; obs=_n_; run;

  proc transpose data=ssums out=tr_ssums(rename=(col1=sum)); by spec; run; 
  data tmp; set tr_ssums(where=(_name_='_FREQ_')); drop _name_; rename sum = N; run;
  data tr_ssums_v2; 
    merge tr_ssums(in=a) tmp(in=b); 
    by spec; 
    if a; 
	variable = lowcase(_name_);
	drop _name_;
  run; 

  proc sort data=est_all; by spec variable; run;
  proc sort data=tr_ssums_v2; by spec variable; run;
  data est_all_v2;
    merge est_all(in=a) tr_ssums_v2(in=b);
	by spec variable;
	if a;
  run;
  proc sort data=est_all_v2; by obs; run;
  data est_all_v2; set est_all_v2; drop obs; run;

  PROC EXPORT DATA=est_all_v2
    OUTFILE= "Y:\Marketing Mix PI\InvOpt\P2 2014 AB\Promo\Diabetes Deep Dive\RespModel\Data\est\curve_est_all_1.xls"
    DBMS=EXCEL97 REPLACE;
    SHEET = "&mdesc.";
  RUN;
  PROC EXPORT DATA=sum_all
    OUTFILE= "Y:\Marketing Mix PI\InvOpt\P2 2014 AB\Promo\Diabetes Deep Dive\RespModel\Data\est\curve_sum_all_1.xls"
    DBMS=EXCEL97 REPLACE;
    SHEET = "&mdesc.";
  RUN;
  PROC EXPORT DATA=PCPWT_all
    OUTFILE= "Y:\Marketing Mix PI\InvOpt\P2 2014 AB\Promo\Diabetes Deep Dive\RespModel\Data\est\curve_PCPWT_all_1.xls"
    DBMS=EXCEL97 REPLACE;
    SHEET = "&mdesc.";
  RUN;
%MEND regmdl1;

* JANUVIA;
%regmdl1(sel_jan_yr_vars,1 EQ 1,JAN_AC);
%regmdl1(sel_jan_yr_vars,CAT IN: ('A' 'B'),JAN_AB);
%regmdl1(sel_jan_yr_vars,grouptype EQ 'SOLO', JAN_AC_SOLO);

* JANUMET;
%regmdl1(sel_jmt_yr_vars,1 EQ 1,JMT_AC);
%regmdl1(sel_jmt_yr_vars,CAT IN: ('A' 'B'),JMT_AB);
%regmdl1(sel_jmt_yr_vars,grouptype EQ 'SOLO', JMT_AC_SOLO);

* JANTOT;
%regmdl1(sel_tot_yr_vars,1 EQ 1,TOT_AC);
%regmdl1(sel_tot_yr_vars,CAT IN: ('A' 'B'),TOT_AB);
%regmdl1(sel_tot_yr_vars,grouptype EQ 'SOLO', TOT_AC_SOLO);


/* *****************************
 * TRY Semi-Parametric GAM MODELS (with SPLINES);
****************************** */
*understand the distribution of details and sample dot's in the data;
proc univariate data=sel_jan_yr_vars; var detcur dotcur; run; * try upto 2600 (99%);
* Build Scoring Dataset;
proc summary data=sel_jan_yr_vars(where= (dotperdet <= dpd99));
  var nrxpre volpre mfpcur totmmf detcur dotcur pcpind intpcpsam;
  output out=sm_mdl_data_1 mean=;
run;
data score_data_mn(drop= _type_ _freq_ i tmp_:);
  set sm_mdl_data_1;
  tmp_det = detcur; tmp_dot = dotcur;
  do i=0 to 50 by 1;
    detcur = i;  dotcur = tmp_dot; output;
  end;
  do i=0 to 2600 by 10;
    detcur = tmp_det; dotcur = i;  output;
  end;
run;

*GAM MODELS;
ods graphics on;
proc gam data=sel_jan_yr_vars(where= (dotperdet <= dpd99))
                plots(unpack)=components(commonaxes additive clm); 
  model nrxchg = param(nrxpre volpre mfpcur totmmf detcur) 
          spline(dotcur, df=4);
       * / method = GCV ;
  ods output gam.ParameterEstimates = gam_par_est;
  score data=score_data_mn out=score_gam_out;
run;
ods graphics off;
%LET PATH=Y:\Marketing Mix PI\InvOpt\P2 2014 AB\Promo\Diabetes Deep Dive\RespModel\Data\est;
PROC EXPORT DATA=score_gam_out 
  OUTFILE= "&PATH.\gam_trials.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "gam_JAN_dot_gcv";
RUN;
/* NOTE: SEVERAL ITERATIONS OF GAM MODELS WITH SPLINES FOR DETCUR and/or DOTCUR
   RESULTS IN VERY NOISY AND SOMETIMES UNPREDICTABLE OUTPUTS.

*/

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


/*
Explore sample response curves by CATEGORY ratings.
Objective is to see if there is saturation near the experience range.
*/
data sel_jan_yr_vars; set out.sel_jan_yr_vars; run;
data sel_jmt_yr_vars; set out.sel_jmt_yr_vars; run;
data sel_tot_yr_vars; set out.sel_tot_yr_vars; run;

* create category variables;
%MACRO catgrp(dset);
  data &dset.;
    set &dset.;
    length CAT2 $2.;
    if cat = 'A+' then cat2='AP';
    else if cat = 'A' then cat2='A';
    else if cat = 'A-' then cat2='AM';
    else if cat in: ('B') then cat2='B';
    else if cat in: ('C') then cat2='C';
    else cat2 = 'D';
    length CAT2SPEC $5.;
	cat2spec = left(trim(cat2))||'_'||left(trim(spec));
  run;
%MEND catgrp;
%catgrp(sel_jan_yr_vars);
%catgrp(sel_jmt_yr_vars);
%catgrp(sel_tot_yr_vars);

%MACRO regmdl2(mdldata,filter,mdesc);
  data mdl_all;
    set &mdldata.;
	if &filter.;
    intpcpsam = pcpind*dotcur;
	detcur_sq = detcur*detcur;
	dotcur_sq = dotcur*dotcur;
	detcur_ln = log(detcur + 1);
	dotcur_ln = log(dotcur + 1);
	detcur_root = sqrt(detcur);
	dotcur_root = sqrt(dotcur);
    if dotperdet >= dpd99 then delete;
  run;
  /*-- store as permanent dataset - one time execution only 
     data out.&mdldata._v2; set mdl_all; run;
  --*/
  
  proc sort data=mdl_all; by cat2; run;

  ODS OUTPUT PARAMETERESTIMATES=e1;
  PROC REG DATA=mdl_all;
    BY CAT2;
    mc1: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF /*SFPCUR*/ DETCUR  
                       DOTCUR / RSQUARE VIF COLLIN CLB ALPHA=0.10;
    mc2: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF /*SFPCUR*/ DETCUR  
                       DOTCUR DOTCUR_SQ / RSQUARE VIF COLLIN CLB ALPHA=0.10;
    mc3: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF /*SFPCUR*/ DETCUR  
                       DOTCUR_ln / RSQUARE VIF COLLIN CLB ALPHA=0.10;
    mc4: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF /*SFPCUR*/ DETCUR_ln  
                       DOTCUR_ln / RSQUARE VIF COLLIN CLB ALPHA=0.10;
  RUN; QUIT;

  proc sort data=mdl_all; by cat2spec; run;
  ODS OUTPUT PARAMETERESTIMATES=e2;
  PROC REG DATA=mdl_all;
    BY CAT2SPEC;
    cs1: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF /*SFPCUR*/ DETCUR
           DOTCUR / RSQUARE VIF COLLIN CLB ALPHA=0.10;
    cs2: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF /*SFPCUR*/ DETCUR
           DOTCUR DOTCUR_SQ / RSQUARE VIF COLLIN CLB ALPHA=0.10;
    cs3: MODEL NRXCHG = NRXPRE VOLPRE MFPCUR TOTMMF /*SFPCUR*/ DETCUR_ln  
           DOTCUR_ln / RSQUARE VIF COLLIN CLB ALPHA=0.10;
  RUN; QUIT;

  proc sort data=e1; by cat2; run;
  proc sort data=e2; by cat2spec; run;
  data est_all;  set e1 e2; run;
  /*PROC SORT DATA=est_all;  BY CAT2 CAT2SPEC;  RUN;*/

  proc sort data=mdl_all; by cat2; run;
  PROC MEANS DATA=mdl_all NOPRINT; BY CAT2; 
    VAR NRXCHG NRXPRE NRXCUR VOLPRE MFPCUR TOTMMF SFPCUR DETCUR DETCUR_SQ  
        DOTCUR DOTCUR_SQ PCPIND INTPCPSAM DETCUR_ln DOTCUR_ln DETCUR_root DOTCUR_root;
    OUTPUT OUT=SSUMS1 SUM=NRXCHG NRXPRE NRXCUR VOLPRE MFPCUR TOTMMF SFPCUR DETCUR DETCUR_SQ  
                          DOTCUR DOTCUR_SQ PCPIND INTPCPSAM 
                          DETCUR_ln DOTCUR_ln DETCUR_root DOTCUR_root;
  RUN;
  proc sort data=mdl_all; by cat2spec; run;
  PROC MEANS DATA=mdl_all NOPRINT; BY CAT2SPEC;
    VAR NRXCHG NRXPRE NRXCUR VOLPRE MFPCUR TOTMMF SFPCUR DETCUR DETCUR_SQ  
        DOTCUR DOTCUR_SQ PCPIND INTPCPSAM DETCUR_ln DOTCUR_ln DETCUR_root DOTCUR_root;
    OUTPUT OUT=SSUMS2 SUM=NRXCHG NRXPRE NRXCUR VOLPRE MFPCUR TOTMMF SFPCUR DETCUR DETCUR_SQ  
                          DOTCUR DOTCUR_SQ PCPIND INTPCPSAM
                          DETCUR_ln DOTCUR_ln DETCUR_root DOTCUR_root;
  RUN;

  proc sort data=ssums1; by cat2; run;
  proc sort data=ssums2; by cat2spec; run;
  DATA SSUMS;  SET SSUMS1 SSUMS2; run;
  data sum_all; set ssums; run;
  /*PROC SORT DATA=SSUMS out=sum_all;  BY SPEC;  RUN;*/

  PROC FREQ DATA=mdl_all;
  TABLES SPEC / LIST OUT=PCPWEIGHT; RUN;

  DATA PCPWEIGHT; SET PCPWEIGHT; SPECPCT=PERCENT/100; RUN;

  PROC TRANSPOSE DATA=PCPWEIGHT OUT=PCPWT_all PREFIX=PCT;
  ID SPEC; VAR SPECPCT; RUN;

  *merge the estimates with the corresponding variable SUMS and N;
  data ssums; length allgrp $7.; set ssums; 
     if cat2spec='' then allgrp=cat2; 
     else allgrp = 'Z_'||left(trim(cat2spec));
  run;
  data est_all; length allgrp $7.; set est_all; 
     if cat2spec='' then allgrp=cat2; 
     else allgrp = 'Z_'||left(trim(cat2spec));
     obs=_n_; 
  run;

  proc transpose data=ssums out=tr_ssums(rename=(col1=sum)); by allgrp; run; 
  data tmp; set tr_ssums(where=(_name_='_FREQ_')); drop _name_; rename sum = N; run;
  data tr_ssums_v2; 
    merge tr_ssums(in=a) tmp(in=b); 
    by allgrp; 
    if a; 
	variable = lowcase(_name_);
	drop _name_;
  run; 

  proc sort data=est_all; by allgrp variable; run;
  proc sort data=tr_ssums_v2; by allgrp variable; run;
  data est_all_v2;
    merge est_all(in=a) tr_ssums_v2(in=b);
	by allgrp variable;
	if a;
  run;
  proc sort data=est_all_v2; by obs; run;
  data est_all_v2; set est_all_v2; drop obs; run;

  PROC EXPORT DATA=est_all_v2
    OUTFILE= "Y:\Marketing Mix PI\InvOpt\P2 2014 AB\Promo\Diabetes Deep Dive\RespModel\Data\est\grpall_curve_est_1.xls"
    DBMS=EXCEL97 REPLACE;
    SHEET = "&mdesc.";
  RUN;
  PROC EXPORT DATA=sum_all
    OUTFILE= "Y:\Marketing Mix PI\InvOpt\P2 2014 AB\Promo\Diabetes Deep Dive\RespModel\Data\est\grpall_curve_sum_1.xls"
    DBMS=EXCEL97 REPLACE;
    SHEET = "&mdesc.";
  RUN;
  PROC EXPORT DATA=PCPWT_all
    OUTFILE= "Y:\Marketing Mix PI\InvOpt\P2 2014 AB\Promo\Diabetes Deep Dive\RespModel\Data\est\grpall_curve_PCPWT_1.xls"
    DBMS=EXCEL97 REPLACE;
    SHEET = "&mdesc.";
  RUN;
%MEND regmdl2;

* JANUVIA;
%regmdl2(sel_jan_yr_vars,1 EQ 1,JAN_AC);

* JANUMET;
%regmdl2(sel_jmt_yr_vars,1 EQ 1,JMT_AC);

* JANTOT;
%regmdl2(sel_tot_yr_vars,1 EQ 1,TOT_AC);




