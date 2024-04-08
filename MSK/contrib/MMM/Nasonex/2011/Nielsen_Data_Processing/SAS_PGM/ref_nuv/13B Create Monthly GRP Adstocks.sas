
/***************************************************************************
  - This program replaces programs 13a prep GRP adstocks(no lag)_NEW.sas
     and 14 stack GRP adstocks.sas
  - Creates weekly adstocks by DMA and Week and sums them to monthly level
  - Applies weekly to monthly conversion based on number of days in a month
    and the number of reported weeks within the month.
  - The Mothly Adstocks are based on sum of all weekly adstocks within the 
    month. The old code 13a considered monthly adstocks as same as the 
    adstock corresponding to the last reported week of the month. While
    the old code gives a much smaller adstock number, in the long run these numbers
    are more or less proportional to the adstock numbers obtained from this code.
    However, the current sum of weekly adstocks might capture the weekly dynamics more 
    appropriately than the old code.
***************************************************************************/

LIBNAME DTC "\\WPUSHH01\DINFOPLN\PRA\DTC\NuvaRing\2011 profit plan\SAS datasets";

OPTIONS MLOGIC MPRINT SYMBOLGEN;

/*
1) Retain DMA, Month, Report_period, week and weekly GRP's (both TV and print)
2) Sort by DMA, report_week and compute weekly Adstocks for each DMA
3) Sum weekly adstocks by DMA, month level
4) Standardize all monthly adstocks based on number of weeks used for aggregation
    and number of days in the month.
*/

PROC CONTENTS DATA=DTC.weekly_local_weighted_grps_jun10; RUN;

%LET AGE = F1849;
%LET INDSET = dtc.weekly_local_weighted_grps_jun10;
%LET GRPVARS = WTRPS_F1849 WCTRPS_F1849 WLTRPS_F1849 WZTRPS_F1849 WSTRPS_F1849
               WRTRPS_F1849 WVTRPS_F1849 
               NPRINT_GRP CPRINT_GRP LPRINT_GRP ZPRINT_GRP SPRINT_GRP
			   RPRINT_GRP;
%LET NWEEKS = 24; * Number of weekly adstocks to compute;
* define holidays. This would be used to get proper count of work days;
* note: 2007 holidays ignored as 2007 will be dropped later in the analysis;
%MACRO HOLIDAYS (ARRAY=HOLIDAY);
     &ARRAY(21) _TEMPORARY_ 
		("01JAN2008"D "21JAN2008"D "26MAY2008"D "04JUL2008"D "01SEP2008"D
         "26NOV2008"D "27NOV2008"D "24DEC2008"D "25DEC2008"D
         "01JAN2009"D "19JAN2009"D "25MAY2009"D "03JUL2009"D "07SEP2009"D
         "26NOV2009"D "27NOV2009"D "24DEC2009"D "25DEC2009"D 
		 "01JAN2010"D "18JAN2010"D "31MAY2010"D
          )
%MEND  HOLIDAYS ;


/*
1) Retain DMA, Month, Report_period, week and weekly GRP's (both TV and print)
*/
data local_wk_grps;
  set &INDSET.(keep = market monyy report_period week year month &GRPVARS. );
  yearmo = put(mdy(month,1,year),yymmn6.);
  array NUMS(*) _numeric_; 
  do k=1 TO DIM(NUMS); if NUMS(k)=. then NUMS(k)=0; end; 
  drop k;
run;

/*
2) Sort by DMA, report_week and compute weekly Adstocks for each DMA
*/
proc sort data=local_wk_grps; by market report_period week; run;
data  lcl_wk_adstocks;
  set local_wk_grps;
  by market;
  *var1 = lag(WTRPS_&AGE.);
  %MACRO ADSTOCK(DECAY,HLIFE);     * CREATES ADSTOCK TRPS FOR CONJECTURED DECAY VALUES; 
     RETAIN ADSTOCK_&AGE._&HLIFE. CADSTOCK_&AGE._&HLIFE. LADSTOCK_&AGE._&HLIFE. 
	      TOCK_PR_&HLIFE. = RPRINT_GRP; 
     END;
	 ELSE DO;
       ADSTOCK_&AGE._&HLIFE. = WTRPS_&AGE + &D  ZADSTOCK_&AGE._&HLIFE. SADSTOCK_&AGE._&HLIFE. RADSTOCK_&AGE._&HLIFE.
			VADSTOCK_&AGE._&HLIFE. 
            ADSTOCK_PR_&HLIFE. CADSTOCK_PR_&HLIFE. LADSTOCK_PR_&HLIFE.
			ZADSTOCK_PR_&HLIFE. SADSTOCK_PR_&HLIFE. RADSTOCK_PR_&HLIFE.;

     IF FIRST.MARKET THEN DO;
       ADSTOCK_&AGE._&HLIFE. = WTRPS_&AGE;
       CADSTOCK_&AGE._&HLIFE. = WCTRPS_&AGE;
       LADSTOCK_&AGE._&HLIFE. = WLTRPS_&AGE;
       ZADSTOCK_&AGE._&HLIFE. = WZTRPS_&AGE;
       SADSTOCK_&AGE._&HLIFE. = WSTRPS_&AGE;
       RADSTOCK_&AGE._&HLIFE. = WRTRPS_&AGE;
       VADSTOCK_&AGE._&HLIFE. = WVTRPS_&AGE;

       ADSTOCK_PR_&HLIFE. = NPRINT_GRP;
	   CADSTOCK_PR_&HLIFE. = CPRINT_GRP;
	   LADSTOCK_PR_&HLIFE. = LPRINT_GRP;
	   ZADSTOCK_PR_&HLIFE. = ZPRINT_GRP;
	   SADSTOCK_PR_&HLIFE. = SPRINT_GRP;
	   RADSECAY.*ADSTOCK_&AGE._&HLIFE.;
       CADSTOCK_&AGE._&HLIFE. = WCTRPS_&AGE + &DECAY.*CADSTOCK_&AGE._&HLIFE.;
       LADSTOCK_&AGE._&HLIFE. = WLTRPS_&AGE + &DECAY.*LADSTOCK_&AGE._&HLIFE.;
       ZADSTOCK_&AGE._&HLIFE. = WZTRPS_&AGE + &DECAY.*ZADSTOCK_&AGE._&HLIFE.;
       SADSTOCK_&AGE._&HLIFE. = WSTRPS_&AGE + &DECAY.*SADSTOCK_&AGE._&HLIFE.;
       RADSTOCK_&AGE._&HLIFE. = WRTRPS_&AGE + &DECAY.*RADSTOCK_&AGE._&HLIFE.;
       VADSTOCK_&AGE._&HLIFE. = WVTRPS_&AGE + &DECAY.*VADSTOCK_&AGE._&HLIFE.;

       ADSTOCK_PR_&HLIFE. = NPRINT_GRP + &DECAY.*ADSTOCK_PR_&HLIFE.;
	   CADSTOCK_PR_&HLIFE. = CPRINT_GRP + &DECAY.*CADSTOCK_PR_&HLIFE.;
	   LADSTOCK_PR_&HLIFE. = LPRINT_GRP + &DECAY.*LADSTOCK_PR_&HLIFE.;
	   ZADSTOCK_PR_&HLIFE. = ZPRINT_GRP + &DECAY.*ZADSTOCK_PR_&HLIFE.;
	   SADSTOCK_PR_&HLIFE. = SPRINT_GRP + &DECAY.*SADSTOCK_PR_&HLIFE.;
	   RADSTOCK_PR_&HLIFE. = RPRINT_GRP + &DECAY.*RADSTOCK_PR_&HLIFE.; 
	 END;
  %MEND ADSTOCK;
  %ADSTOCK(0.5000,1) ;  %ADSTOCK(0.7071,2) ;  %ADSTOCK(0.7937,3) ;
  %ADSTOCK(0.8409,4) ;  %ADSTOCK(0.8706,5) ;  %ADSTOCK(0.8909,6) ;
  %ADSTOCK(0.9057,7) ;  %ADSTOCK(0.9170,8) ;  %ADSTOCK(0.9259,9) ;
  %ADSTOCK(0.9330,10) ; %ADSTOCK(0.9389,11) ; %ADSTOCK(0.9439,12) ;
  %ADSTOCK(0.9481,13) ; %ADSTOCK(0.9517,14) ; %ADSTOCK(0.9548,15);
  %ADSTOCK(0.9576,16);  %ADSTOCK(0.9600, 17); %ADSTOCK(0.9622, 18);
  %ADSTOCK(0.9642, 19);	%ADSTOCK(0.9659, 20); %ADSTOCK(0.9675, 21);
  %ADSTOCK(0.9690, 22);	%ADSTOCK(0.9703, 23); %ADSTOCK(0.9715, 24);
run;

/*
3) Sum weekly adstocks by DMA, month level
*/
proc sort data=lcl_wk_adstocks; by market year month monyy yearmo; run;
proc means data=lcl_wk_adstocks nway sum noprint;
  by market year month monyy yearmo;
  var WTRPS_&AGE WCTRPS_&AGE WLTRPS_&AGE WZTRPS_&AGE WSTRPS_&AGE WRTRPS_&AGE WVTRPS_&AGE 
      NPRINT_GRP CPRINT_GRP LPRINT_GRP ZPRINT_GRP SPRINT_GRP RPRINT_GRP
      ADSTOCK_&AGE: CADSTOCK_&AGE: LADSTOCK_&AGE: ZADSTOCK_&AGE: SADSTOCK_&AGE: 
      RADSTOCK_&AGE:  VADSTOCK_&AGE:
      ADSTOCK_PR_: CADSTOCK_PR_: LADSTOCK_PR_: ZADSTOCK_PR_: 
      SADSTOCK_PR_: RADSTOCK_PR_:; 
  output out=lcl_mn_adstks_ini(drop = _type_ rename=(_freq_ = num_rep_weeks)) sum=;
run;

/*
4) Standardize all monthly adstocks based on number of weeks used for aggregation
    and number of days in the month.
*/
data local_monthly_adstocks;
  set lcl_mn_adstks_ini;
  * get days in a month;
  som = MDY(month,1,year); *gets first day of the month;
  eom = intnx('month',som,0,'end'); *gets last day of the month;
  days_in_month = day(eom); *gets number of days in the month;
  
  * get weekdays in a month;
  if 1 < weekday(som) < 7 then startx=som-1; else startx=som;
  weekdays = intck('weekday',startx,eom);

  *get workdays in a month;
  ARRAY %HOLIDAYS();
  workdays = weekdays;
  DO i = 1 TO DIM ( HOLIDAY ) ;
       workdays = workdays - ( WEEKDAY(HOLIDAY(I)) NOT IN (7 1)
                    AND som <= HOLIDAY(I) <= eom ) ;
  END ;

  * standardize the variables;
  WTRPS_&AGE = (WTRPS_&AGE / num_rep_weeks)*(days_in_month/7);
  WCTRPS_&AGE = (WCTRPS_&AGE / num_rep_weeks)*(days_in_month/7);
  WLTRPS_&AGE = (WLTRPS_&AGE / num_rep_weeks)*(days_in_month/7);
  WZTRPS_&AGE = (WZTRPS_&AGE / num_rep_weeks)*(days_in_month/7);
  WSTRPS_&AGE = (WSTRPS_&AGE / num_rep_weeks)*(days_in_month/7);
  WRTRPS_&AGE = (WRTRPS_&AGE / num_rep_weeks)*(days_in_month/7);
  WVTRPS_&AGE = (WVTRPS_&AGE / num_rep_weeks)*(days_in_month/7);
  NPRINT_GRP = (NPRINT_GRP / num_rep_weeks)*(days_in_month/7);
  CPRINT_GRP = (CPRINT_GRP / num_rep_weeks)*(days_in_month/7);
  LPRINT_GRP = (LPRINT_GRP / num_rep_weeks)*(days_in_month/7);
  ZPRINT_GRP = (ZPRINT_GRP / num_rep_weeks)*(days_in_month/7);
  SPRINT_GRP = (SPRINT_GRP / num_rep_weeks)*(days_in_month/7);
  RPRINT_GRP = (RPRINT_GRP / num_rep_weeks)*(days_in_month/7);

  %macro repeat_weeks();
    %do k=1 %to &NWEEKS.; /* 24 weeks of adstock data */
       ADSTOCK_&AGE._&k. = (ADSTOCK_&AGE._&k. / num_rep_weeks)*(days_in_month/7);
       CADSTOCK_&AGE._&k. = (CADSTOCK_&AGE._&k. / num_rep_weeks)*(days_in_month/7);
       LADSTOCK_&AGE._&k. = (LADSTOCK_&AGE._&k. / num_rep_weeks)*(days_in_month/7);
       ZADSTOCK_&AGE._&k. = (ZADSTOCK_&AGE._&k. / num_rep_weeks)*(days_in_month/7);
       SADSTOCK_&AGE._&k. = (SADSTOCK_&AGE._&k. / num_rep_weeks)*(days_in_month/7);
       RADSTOCK_&AGE._&k. = (RADSTOCK_&AGE._&k. / num_rep_weeks)*(days_in_month/7);
       VADSTOCK_&AGE._&k. = (VADSTOCK_&AGE._&k. / num_rep_weeks)*(days_in_month/7);

       ADSTOCK_PR_&k. = (ADSTOCK_PR_&k. / num_rep_weeks)*(days_in_month/7);
       CADSTOCK_PR_&k. = (CADSTOCK_PR_&k. / num_rep_weeks)*(days_in_month/7);
       LADSTOCK_PR_&k. = (LADSTOCK_PR_&k. / num_rep_weeks)*(days_in_month/7);
       ZADSTOCK_PR_&k. = (ZADSTOCK_PR_&k. / num_rep_weeks)*(days_in_month/7);
       SADSTOCK_PR_&k. = (SADSTOCK_PR_&k. / num_rep_weeks)*(days_in_month/7);
       RADSTOCK_PR_&k. = (RADSTOCK_PR_&k. / num_rep_weeks)*(days_in_month/7);
    %end;
  %mend repeat_weeks;
  %repeat_weeks();
run;
proc freq data=local_monthly_adstocks; tables yearmo*days_in_month*weekdays*workdays / list missing; run;

/* 
store as permanent dataset
*/
* remove print adstocks as we did not consider them for 2010 and may mislead for
 later use;
data dtc.local_monthly_adstocks(drop=adstock_pr_: cadstock_pr_: ladstock_pr_: zadstock_pr_:
               sadstock_pr_: radstock_pr_:
               NPRINT_GRP CPRINT_GRP LPRINT_GRP ZPRINT_GRP SPRINT_GRP RPRINT_GRP); 
  set local_monthly_adstocks(drop=som eom weekdays startx i);
run;

