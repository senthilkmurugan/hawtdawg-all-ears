LIBNAME MODEL "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCC/MODEL_DATASET";
OPTIONS COMPRESS=YES NOLABEL NOCENTER ERROR=1 MACROGEN SYMBOLGEN;

PROC DATASETS LIBRARY=WORK NOLIST KILL;
	RUN;
QUIT;

DATA TEMP;
	SET MODEL.ADS_FN_BELSOMRA_MDB_Feb21_JAN23;
RUN;

DATA OL;
	SET TEMP;
	z_nrx=hcp_grail_nrx;
RUN;

/* Check */
proc sql;
select sum(z_nrx), min(z_nrx), max(z_nrx) from ol;
run;

PROC STANDARD DATA=OL MEAN=0 STD=1 OUT=ZOL;
	VAR z_nrx;
	by dmaname;
RUN;

proc sql;
select sum(z_nrx), min(z_nrx), max(z_nrx)  from ol;
run;


DATA OL6;
	SET ZOL;
	WHERE z_nrx between -6 and 6;
RUN;

proc sql;
select sum(z_nrx), min(z_nrx), max(z_nrx) from ol6;
run;

DATA OL12;
	SET ZOL;
	WHERE z_nrx between -12 and 12;
RUN;

data MODEL.OL6_BELSOMRA_MDB_FEB21_JAN23;
	set OL6;
run;

data MODEL.OL12_BELSOMRA_MDB_FEB21_JAN23;
	set OL12;
run;