PROC PRINTTO LOG="\\wpushh01\dinfopln\PRA\DTC\NuvaRing\2011 profit plan\SAS Logs and Lists\14 stack GRP adstocks.LOG" NEW
			PRINT="\\wpushh01\dinfopln\PRA\DTC\NuvaRing\2011 profit plan\SAS Logs and Lists\14 stack GRP adstocks.LST" NEW;
OPTIONS MLOGIC MPRINT SYMBOLGEN SPOOL;

LIBNAME NUVA "\\WPUSHH01\DINFOPLN\PRA\DTC\NUVARING\2011 PROFIT PLAN\SAS DATASETS\NUVA\DECAY";

PROC DATASETS NOLIST LIB=NUVA; DELETE ADSTOCK7; RUN; QUIT;
/*PROC DATASETS NOLIST LIB=VYTORIN; DELETE ADSTOCK7_2LAG2FULLDECAY; RUN; QUIT;*/

/* Please recall that print GRPs were only available/processed for the 
historical time period. In the final output dataset from program 14, 
I noticed that the print GRP adstock variables have values (i.e., adstock_pr: cadstock_pr: ladstock_pr: zadstock_pr: sadstock_pr: radstock_pr:)
in them. This is because these variables were produced in program 13 after stacking the 
historical and current datasets. This could be misleading, as the adstock reflects print GRPs realized 
in the historical time period only. Thus, the adstock for print shown for months in the current
time period only reflects the carryover from the historical time period. This is not correct.
There were print GRPs realized in the current time period; we simply didn’t capture and process these.
So, please delete these variables (i.e., adstock_pr: cadstock_pr: ladstock_pr: zadstock_pr: sadstock_pr: radstock_pr:) from the final dataset
output from program 14 to insure that these variables do not get used at some future time. */

%MACRO STACK (PROD,NAME,YEAR,MONTH);

DATA ADSTOCK7_&NAME(DROP=adstock_pr: cadstock_pr: ladstock_pr: zadstock_pr: sadstock_pr: radstock_pr:);
        SET &PROD..ADSTOCK7_&NAME;
        YEAR=&YEAR;
		MONTH=&MONTH;
 		MONTHLABEL=PUT((MDY(MONTH,1,YEAR)),MONYY5.);
RUN;

PROC APPEND BASE=&PROD..ADSTOCK7 DATA=ADSTOCK7_&NAME; RUN;

%MEND;


%STACK(NUVA,JAN07,2007,1);
%STACK(NUVA,FEB07,2007,2);
%STACK(NUVA,MAR07,2007,3);
%STACK(NUVA,APR07,2007,4);
%STACK(NUVA,MAY07,2007,5);
%STACK(NUVA,JUN07,2007,6);
%STACK(NUVA,JUL07,2007,7);
%STACK(NUVA,AUG07,2007,8);
%STACK(NUVA,SEP07,2007,9);
%STACK(NUVA,OCT07,2007,10);
%STACK(NUVA,NOV07,2007,11);
%STACK(NUVA,DEC07,2007,12);
%STACK(NUVA,JAN08,2008,1);
%STACK(NUVA,FEB08,2008,2);
%STACK(NUVA,MAR08,2008,3);
%STACK(NUVA,APR08,2008,4);
%STACK(NUVA,MAY08,2008,5);
%STACK(NUVA,JUN08,2008,6);
%STACK(NUVA,JUL08,2008,7);
%STACK(NUVA,AUG08,2008,8);
%STACK(NUVA,SEP08,2008,9);
%STACK(NUVA,OCT08,2008,10);
%STACK(NUVA,NOV08,2008,11);
%STACK(NUVA,DEC08,2008,12);
%STACK(NUVA,JAN09,2009,1);
%STACK(NUVA,FEB09,2009,2);
%STACK(NUVA,MAR09,2009,3);
%STACK(NUVA,APR09,2009,4);
%STACK(NUVA,MAY09,2009,5);
%STACK(NUVA,JUN09,2009,6);
%STACK(NUVA,JUL09,2009,7);
%STACK(NUVA,AUG09,2009,8);
%STACK(NUVA,SEP09,2009,9);
%STACK(NUVA,OCT09,2009,10);
%STACK(NUVA,NOV09,2009,11);
%STACK(NUVA,DEC09,2009,12);
%STACK(NUVA,JAN10,2010,1);
%STACK(NUVA,FEB10,2010,2);
%STACK(NUVA,MAR10,2010,3);
%STACK(NUVA,APR10,2010,4);
%STACK(NUVA,MAY10,2010,5);
%STACK(NUVA,JUN10,2010,6);
PROC PRINTTO;
QUIT;
