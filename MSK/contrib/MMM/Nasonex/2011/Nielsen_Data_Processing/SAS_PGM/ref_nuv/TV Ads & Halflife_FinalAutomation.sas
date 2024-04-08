/*  Importing the Excel file PLANNED WEEKLY GRPS  */
/*proc import datafile="\\wpushh01\dinfopln\PRA\DTC\Gardasil\2010 profit plan\excel\percent impact from campaign period_8weeks_v1.xls"*/
/*	out=PLANNED_WEEKLY_GRPS dbms=excel replace; sheet='PLANNED WEEKLY GRPS';range="b2:f96";MIXED=YES;*/
/*  SCANTEXT=YES; USEDATE=YES; SCANTIME=YES;*/
/*	getnames=yes;*/
/*run;*/

LIBNAME DTC "\\WPUSHH01\DINFOPLN\PRA\DTC\NuvaRing\2011 profit plan\SAS datasets";
DATA PLANNED_WEEKLY_GRPS;
	SET DTC.weekly_natl_weighted_grps_jun10(KEEP=REPORT_PERIOD WTRPS_F1849);
RUN;
/* For generating the DECAY_WEIGHTS Dataset */

data step1;
	Retain Half_life 0;
	do i=1 to 56;
	Half_life+0.25;
	decay=exp(log(0.5)/Half_life);
	SpeedofAdj=1-decay;
	Half_life_inweeks=-(log(2)/log(decay));
	output;
	end;
	drop i;
run;

%macro sss;
	data DECAY_WEIGHTS;
	set step1;
	%do j=1 %to 156;
	X&j.=round((decay)**&j.,0.0001);
	%end;
	output;
	run;
%mend;
%sss;

PROC GREPLAY NOFS IGOUT=WORK.GSEG;
	DELETE _ALL_;
RUN;  
QUIT;

FILENAME ODSOUT "\\wpushh01\dinfopln\PRA\DTC\NuvaRing\2011 profit plan\SAS Datasets\";
ods html file="TV Ads & Halflife.xls" PATH=ODSOUT;
/* For generating graph in the DECAY_WEIGHTS Sheet with half_life=4,half_life=4.75 and half_life=8 */
%Macro yyy(halflife,out1,out2);

data &out1.(KEEP=X0-X156);
	LENGTH X0 3.;
	set DECAY_WEIGHTS;
	if half_life=&halflife. then DO X0=1; output; END;
run;

PROC TRANSPOSE DATA=&out1. OUT=&out2.;
run;

DATA &out2.;
	RETAIN DUM 0;
	SET &out2.;
	IF _N_=1 THEN DUM=0;
	ELSE DUM+1;
RUN;
goptions reset=global gunit=pct border cback=cream
         colors=(black blue green red)
         ftitle=swissb ftext=swiss htitle=3 htext=1.5;
title1 'Effective Weight for GRPs X Weeks Ago Decay/Half-life:(0.864/4.8)';

AXIS1 LABEL=(ANGLE=90 ROTATE=0 FONT='CENTB' HEIGHT=13PT "Weight (Decay**Week Number") order=(0.1 to 1 by 0.1); 
AXIS2 LABEL=(FONT='CENTB' HEIGHT=13PT "Distance from Current Week" ) order=(0 to 25 by 1); 

proc gplot data=&out2.;
	SYMBOL color=Blue 
	interpol=join VALUE=DOT;
	plot COL1*DUM/vaxis=axis1 haxis=axis2;
run;
quit;
%mend yyy;
%yyy(4,step3,step4);
%yyy(4.75,step5,step6);
%yyy(8,step7,step8);

/* For generating the DECAY_8_WEEK_WEIGHTS and DECAY_4_WEEK_WEIGHTS */

%macro ddd(input,out);
DATA STEP9;
	DATE='01JAN07'D;
	DO I=1 TO 300;		
		DATE+7;
		FORMAT DATE DATE9.;
		OUTPUT;
	END;
RUN;

data new(keep=Col1);
	set &input.;
run;
data New;
	Merge step9(keep=Date) new;
run;

data &out.; 
	set new;
	f1=col1;
	%do i=2 %to 180;
		f&i.=lag(f%eval(&i.-1));
	%end;
	run;
%mend ddd;
%ddd(step4,DECAY_4_WEEK_WEIGHTS);
%ddd(step8,DECAY_8_WEEK_WEIGHTS);

/* For generating the DECAY 8-WEEK SCENARIO,DECAY 4-WEEK SCENARIO Datasets and Graphs */

%Macro rrr(input,out);
proc sql noprint;
select count(*) into :Nvars from PLANNED_WEEKLY_GRPS;
quit;

%let Nvars=&Nvars.;

proc sql noprint;
	select WTRPS_F1849 into :grp1-:grp&Nvars.
	from PLANNED_WEEKLY_GRPS;
quit;

data _null_;
	set PLANNED_WEEKLY_GRPS end=last;
	if last then call symput("refvalue",Report_Period);
run;

data &out.(keep=DATE C1-C180 Total);
	Length DATE 5. C1-C180 8.;
	FORMAT DATE DATE9.;
			set &input.;
			%do i=1 %to &Nvars.;
			C&i.=F&i.*&&grp&i;
			Total=sum(Total,C&i.);
		%end;		
	run;

proc sql noprint;
create table &out. as
select *, sum(Total) as Temp from &out.;
quit;

DATA &out.;
	retain ss te;
	SET &out.;
	ss=Sum(ss,total);
	if _n_=&Nvars. then  do;
		Temp2=(sum(ss)/Temp)*100;
		te=temp2;
		call symput('Fn1',left(right(round(temp2))));
	end;	
	if _n_ =&Nvars.+1 then do;
		temp2 =100-te;
		call symput('Fn2',left(right(round(temp2))));
	end;

	drop ss te;
run;

goptions reset=global gunit=pct border cback=cream
         colors=(black blue green red)
         ftitle=swissb ftext=swiss htitle=3 htext=1.5;
title1 'Gardasil Adstock by week: Eight week half life';

AXIS1 LABEL=(ANGLE=90 ROTATE=0 FONT='CENTB' HEIGHT=13PT "Adstock (8-week half life)") order=(0 to 1400 by 200); 
AXIS2 LABEL=(FONT='CENTB' HEIGHT=13PT "Date" ) order=('08JAN2007'D to '21JUN2010'D by 60); 

proc gplot data=&out.;
	SYMBOL color=Blue 
	interpol=join VALUE=NONE;
	   plot Total*DATE/vaxis=axis1 haxis=axis2 href=&refvalue. CH=BLUE;
	Footnote1 justify=L font=centb color=black height=2.5 pct
			"Carmpaign Period %sysfunc(right(&Fn1.))% impact";
	Footnote2 justify=R font=centb color=black height=2.5 pct
			"Carry Over Period %sysfunc(right(&Fn2.))% impact";
  run;
quit;

%Mend rrr;

%rrr(DECAY_8_WEEK_WEIGHTS,DECAY_8_WEEK_SCENARIO);
*%rrr(DECAY_4_WEEK_WEIGHTS,DECAY_4_WEEK_SCENARIO);
ods html close;
