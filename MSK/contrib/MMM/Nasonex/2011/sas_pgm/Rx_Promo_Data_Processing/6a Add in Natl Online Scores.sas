***************************************************************************;
* 6a. Add in National Online Score.                                        ;
***************************************************************************;
LIBNAME DMA  "\\WPUSHH01\DINFOPLN\PRA\ALIGNMENTS\DMA\DATA";
LIBNAME RX  "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other";
LIBNAME GRP "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\OUTPUT";

%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other\Natl_Online;
OPTIONS MPRINT MLOGIC SYMBOLGEN COMPRESS=YES;

* IMPORT NATIONAL ONLINE IMPRESSIONS AND SPENDS;
OPTIONS MPRINT MLOGIC SYMBOLGEN;
%MACRO NGETDATA(FILENAME,SHEETNAME,FCELL,LCELL,OUTNAME);
  PROC IMPORT OUT= WORK.&OUTNAME 
  DATAFILE= "&PATH\&FILENAME..XLS"
  DBMS=EXCEL REPLACE; SHEET="&SHEETNAME"; GETNAMES=YES; RANGE="&FCELL:&LCELL"; MIXED=YES;
  SCANTEXT=YES; USEDATE=YES; SCANTIME=YES; RUN;
%MEND;

* NATL Online Scores;
%NGETDATA(Natl_Online_Impressions_Spend,Online_Score,A1,L31,IN_ONL_SCORES);


/*
1. Merge Online Scores with rx.RX_PROMO_MC_WKLYGRP_ADSTK_V1 dataset.
*/
proc sort data=in_onl_scores(keep=yearmo online_score adstk_online_score_50) 
  out=onl_scores(rename = (online_score = ONL_SCORE adstk_online_score_50 = ONL_SCORE_50));
by yearmo;
run;

proc sql noprint;
create table rx_onl as 
select a.*, b.ONL_SCORE, b.ONL_SCORE_50
from rx.RX_PROMO_MC_WKLYGRP_ADSTK_V1 a, onl_scores b
where a.yearmo = b.yearmo;
quit; * merge with weekly grp adstocks data set;

/* * Store as permanent dataset;
DATA rx.RX_PROMO_MC_WKLYGRP_ADSTK_V2; SET rx_onl; RUN;
*/

proc sql noprint;
create table rx_onl_2 as 
select a.*, b.ONL_SCORE, b.ONL_SCORE_50
from rx.RX_PROMO_MC_MONGRP_ADSTK_V1 a, onl_scores b
where a.yearmo = b.yearmo;
quit; * merge with monthly grp adstocks data set;

/* * Store as permanent dataset;
DATA rx.RX_PROMO_MC_MONGRP_ADSTK_V2; SET rx_onl_2; RUN;
*/
