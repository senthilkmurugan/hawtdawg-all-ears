LIBNAME MODELS "/efs-MAIO/Team/promo_opt/MktMixPP/2023_Planning/Belsomra/output/HCC/MODEL_DATASET";

/* IMPORT MDB */
DATA MDB;
	SET MODELS.BELSOMRA_MDB_APR20_MAR22;
RUN;

/* IMPORT CORRECTION */
PROC IMPORT DATAFILE="/efs-MAIO/Team/promo_opt/MktMixPP/2023_Planning/Belsomra/input/HCC/BEL_PROD_DMA_MDB_PS_MAR_CORRECTION_1.csv" 
		OUT=CORRECTION DBMS=CSV REPLACE;
	GUESSINGROWS=MAX;
RUN;

/* IMPORTING DATA AND FIXING FOR MARCH22 */
DATA CORRECTION;
	SET CORRECTION;
	WHERE VAR1 NE -999;
	WHERE YEARMO=202203;
	DROP VAR1;
	RENAME hcc_psrch_clk=hcc_psrch_clk_replace;
RUN;

proc sql;
	create table inter_mdb as select a.*, b.hcc_psrch_clk_replace from mdb as a 
		left join correction as b on a.dmaname=b.dmaname and a.yearmo=b.yearmo;
	run;

	/* checked the join and verified*/
proc sql;
	select yearmo, sum(hcc_psrch_clk) as cur, sum(hcc_psrch_clk_replace) as 
		replace from inter_mdb group by yearmo;
	run;

data new_mdb;
	set inter_mdb;

	if yearmo=202203 then
		hcc_psrch_clk=hcc_psrch_clk_replace;
	drop hcc_psrch_clk_replace;
run;

proc sql;
	select yearmo, sum(hcc_psrch_clk) as cur from new_mdb group by yearmo;
	run;

	/* Save the dataset as new  */
data MODELS.BELSOMRA_MDB_APR20_MAR22_FIXED;
	set new_mdb;
run;