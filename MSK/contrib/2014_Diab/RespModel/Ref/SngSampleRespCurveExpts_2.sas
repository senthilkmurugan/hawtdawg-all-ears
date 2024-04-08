/****************************************************************/
/*   SAMPLE MODEL SPECILATY AND MOVING QTR  */
/* Try Sample response CURVES, so that optimal sample could be determined */
/****************************************************************/

/**************************************************************/
/* Latest Grail is Aug2010                                    */
/*  CURRENT PERIOD IS Sep2009 to Aug2010 AND PRIOR PERIOD IS Sep2008 to Aug2009 */   
/*  FOR RESPCOMB: MERGE TO TARGET FILE & WEIGHT BY SPEC       */
/**************************************************************/ 

OPTIONS ls=80 ps=100 NOCENTER MLOGIC MPRINT SYMBOLGEN;
options compress=yes; 

LIBNAME GRAIL 'C:\Documents and Settings\smuruga2\PROJECTS\CallPlan\PR_ROI\Samples\Singulair\data';  RUN;
LIBNAME TARG '\\WPUSHH01\DINFOPLN\MARKETING MIX PI\MMF & EMF 09\TARGETS & SPEC';  RUN;
LIBNAME PC1 "C:\Documents and Settings\smuruga2\PROJECTS\CallPlan\PR_ROI\Samples\Singulair\data"; RUN;
LIBNAME GRPPRAC '\\WPUSHH01\DINFOPLN\MARKETING MIX PI\MMF & EMF 10\GROUP PRACTICE DATA';

* Create formats for months and indexes in the grail dataset;
%macro fmtme (input, fmtname, type, start, label, llength, oth);
  data cntlin;
      length label $ &llength.;
      set &input end = lastrec;
       retain fmtname "&fmtname." type "&type.";
	   start = &start.;
	   label = &label.;
	  output;
	  if lastrec then do;
	    hlo = 'O';
	    label = "&Oth.";
        output;
      end;
  run;
  proc print data = cntlin (obs = 200);
  run;
  proc format cntlin=cntlin;run;
%mend fmtme;
%let stmon = "201008";
data monthidx(keep=yearmo ymidx);
  length yearmo $6. ymidx 8.;
  do i = 1 to 24;
	  tmpmn = substr(&stmon.,5,2)*1 - i + 1;
	  tmpyr = substr(&stmon.,1,4)*1;
	  if tmpmn < 1 then do; tmpmn = tmpmn + 12; tmpyr = tmpyr - 1; end;
	  if tmpmn < 1 then do; tmpmn = tmpmn + 12; tmpyr = tmpyr - 1; end;
      yearmo = put(tmpyr, z4.) || put(tmpmn, z2.);
	  ymidx = i;
	  output;
  end;
run;
/*  Format for converted PCID */
%fmtme (monthidx, ymtoidx, C, yearmo, ymidx, 6, 0);
    *conv_pcid = put(pcid, $convert.);


/*
1. Get A+ to B physicians and old targets for analysis.
*/
PROC SORT DATA=TARG.TARGETS (KEEP=IMSDRNUM PRODUCT WHERE=(PRODUCT='SINGULAIR')) OUT=TARGETS;
BY IMSDRNUM; RUN;
PROC SORT DATA=GRAIL.RESPCOMB_GRAIL1008(keep= imsdrnum rdt: a1n: an: a1t: at: 
            cat spec dettot: samtot: mfp: sfp:)
OUT=GRAIL;
BY IMSDRNUM;  RUN;
proc freq data=grail; tables cat / list missing; run;
proc sort data=GRPPRAC.SOLO_PHYSICIANS out=solos nodupkey; by imsdrnum; run;

data sel_grail;
  merge grail(in=a rename=(spec=ospec)) targets(in=b) solos(in=s);
  by imsdrnum;
  if a;
  if b or cat in: ('A','B');
  if ospec in ('A' 'AI' 'OTO' 'PDO' 'PD' 'PDA' 'PDP' 'PUD') then spec='SP'; else spec='PC';
  if spec='PC' then pcpind=1;  else pcpind=0;
  length grouptype $4.;
  if s then grouptype='SOLO';
run;
proc freq data=sel_grail; tables cat spec*pcpind grouptype/ list missing; run;


data sel_grail2;
  set sel_grail;
run;
%macro dervars(stmon);
  data _null_;
    stidx = put("&stmon.", $ymtoidx.)*1 - 2;
    edidx = stidx+2;
    call symput("st1",trim(left(stidx)));
    call symput("ed1",trim(left(edidx)));
    stidx2 = stidx+12;
    edidx2 = edidx+12;
    call symput("st2",trim(left(stidx2)));
    call symput("ed2",trim(left(edidx2)));
  run;

  data sel_grail2;
    set sel_grail2;

    nrxcur_&stmon. = SUM(OF A1N&st1.-A1N&ed1.);
    volcur_&stmon. = SUM(OF AN&st1.-AN&ed1.);
    detcur_&stmon. = SUM(OF dettot&st1.-dettot&ed1.);
    mfpcur_&stmon. = SUM(OF mfp&st1.-mfp&ed1.);
    sfpcur_&stmon. = SUM(OF sfp&st1.-sfp&ed1.);
    samcur_&stmon. = SUM(OF samtot&st1.-samtot&ed1.);

    nrxpre_&stmon. = SUM(OF A1N&st2.-A1N&ed2.);
    volpre_&stmon. = SUM(OF AN&st2.-AN&ed2.);
    detpre_&stmon. = SUM(OF dettot&st2.-dettot&ed2.);
    sampre_&stmon. = SUM(OF samtot&st2.-samtot&ed2.);

    nrxchg_&stmon. = nrxcur_&stmon. - nrxpre_&stmon.;
    dotcur_&stmon. = samcur_&stmon. * 7;
    dotpre_&stmon. = sampre_&stmon. * 7;
    intpcpdet_&stmon. = pcpind*detcur_&stmon.;
    intpcpsam_&stmon. = pcpind*dotcur_&stmon.;

	*square and interaction term(s);
    dotcur_sq_&stmon. = dotcur_&stmon. * dotcur_&stmon.;
	dotdet_&stmon. = dotcur_&stmon. * dotcur_&stmon.;

    if nrxpre_&stmon.=0 then dotnrxpre_&stmon.=.;
    else dotnrxpre_&stmon. = dotpre_&stmon./nrxpre_&stmon.;
    if nrxcur_&stmon.=0 then dotnrxcur_&stmon.=.;
    else dotnrxcur_&stmon. = dotcur_&stmon./nrxcur_&stmon.;
    if detcur_&stmon. > 0 then dotperdet_&stmon.=dotcur_&stmon./detcur_&stmon.;
    else dotperdet_&stmon.=0;
  run;

  PROC UNIVARIATE DATA=sel_grail2;
  VAR DOTPERDET_&stmon.;
  OUTPUT OUT=OUTLIERS P99=DPD99_&stmon. P95=DPD95_&stmon.;
  RUN;

  DATA sel_grail2;
     SET sel_grail2;
     RETAIN DPD99_&stmon. DPD95_&stmon.;
     IF _N_=1 THEN DO;
        SET OUTLIERS;
     END;
  RUN;
%mend dervars;
%dervars(200909);  

%dervars(200910);  
%dervars(200911);
%dervars(200912);
%dervars(201001);
%dervars(201002);
%dervars(201003);
%dervars(201004);
%dervars(201005);
%dervars(201006);

data pc1.sel_grail2;
  set sel_grail2(keep=imsdrnum rdt: cat spec pcpind grouptype
        nrxcur: volcur: detcur: mfpcur: sfpcur: samcur:
        nrxpre: volpre: detpre: sampre:
        nrxchg: dotcur: dotpre: intpcpdet: intpcpsam:
        dotnrxpre: dotnrxcur: dotperdet: dpd99: dpd95:);
run;

/*
Model explorations
*/
proc sort data=pc1.sel_grail2 out=sel_grail2; by spec; run;
*%let anlmn = 200909;
%MACRO regmdl1(anlmn);
data mdl_all;
  set sel_grail2(keep = grouptype spec nrxchg_&anlmn. nrxcur_&anlmn. nrxpre_&anlmn. volpre_&anlmn. 
         detcur_&anlmn. mfpcur_&anlmn. sfpcur_&anlmn. dotcur_&anlmn. dotcur_sq_&anlmn. 
         dotperdet_&anlmn. dpd99_&anlmn. pcpind );
  intpcpsam_&anlmn. = pcpind*dotcur_&anlmn.;
  if dotperdet_&anlmn. >= dpd99_&anlmn. then delete;
run;

ODS OUTPUT PARAMETERESTIMATES=e1;
PROC REG DATA=mdl_all;
MODEL NRXCHG_&anlmn. = NRXPRE_&anlmn. VOLPRE_&anlmn. DETCUR_&anlmn. MFPCUR_&anlmn. 
        SFPCUR_&anlmn. DOTCUR_&anlmn. DOTCUR_SQ_&anlmn. / RSQUARE VIF COLLIN CLB ALPHA=0.10;
MODEL NRXCHG_&anlmn. = NRXPRE_&anlmn. VOLPRE_&anlmn. DETCUR_&anlmn. MFPCUR_&anlmn.
        SFPCUR_&anlmn. DOTCUR_&anlmn. DOTCUR_SQ_&anlmn. PCPIND / RSQUARE VIF COLLIN CLB ALPHA=0.10;
MODEL NRXCHG_&anlmn. = NRXPRE_&anlmn. VOLPRE_&anlmn. DETCUR_&anlmn. MFPCUR_&anlmn. 
        SFPCUR_&anlmn. DOTCUR_&anlmn. DOTCUR_SQ_&anlmn. PCPIND INTPCPSAM_&anlmn. / RSQUARE VIF COLLIN CLB ALPHA=0.10;
RUN; QUIT;

ODS OUTPUT PARAMETERESTIMATES=e2;
PROC REG DATA=mdl_all;
MODEL NRXCHG_&anlmn. = NRXPRE_&anlmn. VOLPRE_&anlmn. DETCUR_&anlmn. MFPCUR_&anlmn. 
        SFPCUR_&anlmn. DOTCUR_&anlmn. DOTCUR_SQ_&anlmn. / RSQUARE VIF COLLIN CLB ALPHA=0.10;
BY SPEC;
RUN; QUIT;

data est_all_&anlmn.;  set e1 e2; run;
PROC SORT DATA=est_all_&anlmn.;  BY SPEC;  RUN;

PROC MEANS DATA=mdl_all NOPRINT; VAR DOTCUR_&anlmn. DOTCUR_SQ_&anlmn.;
OUTPUT OUT=SSUMS1 SUM=DOTSUM_&anlmn. DOTSUM_SQ_&anlmn.;
RUN;
PROC MEANS DATA=mdl_all NOPRINT; BY SPEC; VAR DOTCUR_&anlmn. DOTCUR_SQ_&anlmn.;
OUTPUT OUT=SSUMS2 SUM=DOTSUM_&anlmn. DOTSUM_SQ_&anlmn.;
RUN;
DATA SSUMS;  SET SSUMS1 SSUMS2;
PROC SORT DATA=SSUMS out=sum_all_&anlmn.;  BY SPEC;  RUN;

PROC FREQ DATA=mdl_all;
TABLES SPEC / LIST OUT=PCPWEIGHT; RUN;

DATA PCPWEIGHT; SET PCPWEIGHT; SPECPCT=PERCENT/100; RUN;

PROC TRANSPOSE DATA=PCPWEIGHT OUT=PCPWT_all_&anlmn. PREFIX=PCT;
ID SPEC; VAR SPECPCT; RUN;

PROC EXPORT DATA=est_all_&anlmn.
OUTFILE= "Y:\PRA\Murugan\Samples\Respcomb\2010\MDLExplore\data\MovingModels\RespCurve\curve_est_all_1.xls"
DBMS=EXCEL97 REPLACE;
SHEET = "&anlmn.";
RUN;
PROC EXPORT DATA=sum_all_&anlmn.
OUTFILE= "Y:\PRA\Murugan\Samples\Respcomb\2010\MDLExplore\data\MovingModels\RespCurve\curve_sum_all_1.xls"
DBMS=EXCEL97 REPLACE;
SHEET = "&anlmn.";
RUN;
PROC EXPORT DATA=PCPWT_all_&anlmn.
OUTFILE= "Y:\PRA\Murugan\Samples\Respcomb\2010\MDLExplore\data\MovingModels\RespCurve\curve_PCPWT_all_1.xls"
DBMS=EXCEL97 REPLACE;
SHEET = "&anlmn.";
RUN;

/*
Models for SOLO MDs
*/
data mdl_solo;
  set mdl_all;
  if grouptype = 'SOLO';
run;

ODS OUTPUT PARAMETERESTIMATES=e1;
PROC REG DATA=mdl_solo;
MODEL NRXCHG_&anlmn. = NRXPRE_&anlmn. VOLPRE_&anlmn. DETCUR_&anlmn. MFPCUR_&anlmn. 
        SFPCUR_&anlmn. DOTCUR_&anlmn. DOTCUR_SQ_&anlmn. / RSQUARE VIF COLLIN CLB ALPHA=0.10;
MODEL NRXCHG_&anlmn. = NRXPRE_&anlmn. VOLPRE_&anlmn. DETCUR_&anlmn. MFPCUR_&anlmn.
        SFPCUR_&anlmn. DOTCUR_&anlmn. DOTCUR_SQ_&anlmn. PCPIND / RSQUARE VIF COLLIN CLB ALPHA=0.10;
MODEL NRXCHG_&anlmn. = NRXPRE_&anlmn. VOLPRE_&anlmn. DETCUR_&anlmn. MFPCUR_&anlmn. 
        SFPCUR_&anlmn. DOTCUR_&anlmn. DOTCUR_SQ_&anlmn. PCPIND INTPCPSAM_&anlmn. / RSQUARE VIF COLLIN CLB ALPHA=0.10;
RUN; QUIT;

ODS OUTPUT PARAMETERESTIMATES=e2;
PROC REG DATA=mdl_solo;
MODEL NRXCHG_&anlmn. = NRXPRE_&anlmn. VOLPRE_&anlmn. DETCUR_&anlmn. MFPCUR_&anlmn. 
        SFPCUR_&anlmn. DOTCUR_&anlmn. DOTCUR_SQ_&anlmn. / RSQUARE VIF COLLIN CLB ALPHA=0.10;
BY SPEC;
RUN; QUIT;

data est_solo_&anlmn.;  set e1 e2; run;
PROC SORT DATA=est_solo_&anlmn.;  BY SPEC;  RUN;

PROC MEANS DATA=mdl_solo NOPRINT; VAR DOTCUR_&anlmn. DOTCUR_SQ_&anlmn.;
OUTPUT OUT=SSUMS1 SUM=DOTSUM_&anlmn. DOTSUM_SQ_&anlmn.;
RUN;
PROC MEANS DATA=mdl_solo NOPRINT; BY SPEC; VAR DOTCUR_&anlmn. DOTCUR_SQ_&anlmn.;
OUTPUT OUT=SSUMS2 SUM=DOTSUM_&anlmn. DOTSUM_SQ_&anlmn.;
RUN;
DATA SSUMS;  SET SSUMS1 SSUMS2;
PROC SORT DATA=SSUMS out=sum_solo_&anlmn.;  BY SPEC;  RUN;

PROC FREQ DATA=mdl_solo;
TABLES SPEC / LIST OUT=PCPWEIGHT; RUN;

DATA PCPWEIGHT; SET PCPWEIGHT; SPECPCT=PERCENT/100; RUN;

PROC TRANSPOSE DATA=PCPWEIGHT OUT=PCPWT_solo_&anlmn. PREFIX=PCT;
ID SPEC; VAR SPECPCT; RUN;

PROC EXPORT DATA=est_solo_&anlmn.
OUTFILE= "Y:\PRA\Murugan\Samples\Respcomb\2010\MDLExplore\data\MovingModels\RespCurve\curve_est_solo_1.xls"
DBMS=EXCEL97 REPLACE;
SHEET = "&anlmn.";
RUN;
PROC EXPORT DATA=sum_solo_&anlmn.
OUTFILE= "Y:\PRA\Murugan\Samples\Respcomb\2010\MDLExplore\data\MovingModels\RespCurve\curve_sum_solo_1.xls"
DBMS=EXCEL97 REPLACE;
SHEET = "&anlmn.";
RUN;
PROC EXPORT DATA=PCPWT_solo_&anlmn.
OUTFILE= "Y:\PRA\Murugan\Samples\Respcomb\2010\MDLExplore\data\MovingModels\RespCurve\curve_PCPWT_solo_1.xls"
DBMS=EXCEL97 REPLACE;
SHEET = "&anlmn.";
RUN;
%MEND regmdl1;

%regmdl1(200909);

%regmdl1(200910); %regmdl1(200911); %regmdl1(200912); %regmdl1(201001); 
%regmdl1(201002); %regmdl1(201003); %regmdl1(201004); %regmdl1(201005);
%regmdl1(201006);


