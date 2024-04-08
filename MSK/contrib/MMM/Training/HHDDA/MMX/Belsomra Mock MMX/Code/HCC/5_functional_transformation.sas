LIBNAME MODEL "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCC/MODEL_DATASET";
OPTIONS COMPRESS=YES NOLABEL NOCENTER ERROR=1 MACROGEN SYMBOLGEN;

PROC DATASETS LIBRARY=WORK NOLIST KILL;
	RUN;
QUIT;

%*** Define macro for time array ***;
;
**************************************************** GET FUNCTIONAL FORMS FOR PROMOTION ADSTOCKS

	*****************************************;

DATA TEMP;
	SET MODEL.ADS_BELSOMRA_MDB_Feb21_JAN23;
RUN;

** A) INTRODUCE FUNCTIONS TO X VARIABLES. 6 FUCTIONS ARE USED HERE: POWER OF 0.3, 0.4, 0.5, 0.6 (BASED ON BAYESION MODELS BY IMS WHERE
THE ROOT
OF TERMS ARE TRIED TO BE KEPT CLOSE TO 0.5 (0 - CONSTANT IMPACT W. NO SLOPE AND 1 - LINEAR IMPACT), SQUARE FOR CANNIBALIZATION, LN AND
X/(1+X)
WHICH IS SIMILAR TO (1/(1+E-X), WHERE SLOPE CONSTANTLY DECREASES FOR EVERY INCREMENTAL VALUE OF X VARIABLE. HERE ASYMPTOTE IS REALLY 1
BUT HOPING
THAT COEFFECIENT IS HIGH SO THAT GIVES COEFFICIENT*1 = COEFFICIENT WHICH IS MAX CONTRIBUTION OF A PARTICULAR CHANNEL **;

%MACRO FUNCTIONS(DS);
	DATA TEMP1;
		SET TEMP;

		%MACRO VARLOOP(NM);

			%DO I=1 %TO 9 %BY 1;
				&NM._RT&I.=(&NM.)**(&I./10);
			%END;
			&NM._LOG=LOG(&NM.+1);

			%DO HL=10 %TO 90 %BY 10;
				*ROOT: POWER OF 0.1 TO 0.9;

				%DO J=1 %TO 9 %BY 1;
					&NM.&HL._RT&J.=(&NM.&HL.)**(&J./10);
				%END;
				
				*LN - NATURAL LOG;
				&NM.&HL._LOG=LOG(&NM.&HL.+1);
				
				*SIGMOID ;
				&NM.&HL._sig = logistic(&NM.&HL.);



        %END;
		%MEND;

		%varloop(hcc_disp_imp);
		%varloop(hcc_olv_imp);
		%varloop(hcc_osrch_sessions);
		%varloop(hcc_psrch_clk);
		%varloop(hcc_soc_imp);
		%varloop(hcp_disp_imp);
		%varloop(hcp_alert_eng);
		%varloop(hcp_ban_eng);
		%varloop(hcp_edtl_eng);
		%varloop(hcp_eml_clkd);
		%varloop(hcp_eml_eng);
		%varloop(hcp_fmail_eng);
		%varloop(hcp_grail_sdot);
		%varloop(hcp_grail_vnrx);
		%varloop(hcp_npp_eng);
		%varloop(hcp_npp_del);
		%varloop(hcp_osrch_sessions);
		%varloop(hcp_rdtl_totdet);
		%varloop(PP_HCC);
		%varloop(PP_HCP);
		%varloop(PP_ANY);
		%varloop(web_md);
		%varloop(cw_comm);
		RUN;

%MEND;

%FUNCTIONS(TEMP);
RUN;
QUIT;
** B) WRITE TO PERM LIBRARY **;

DATA MODEL.ADS_FN_BELSOMRA_MDB_Feb21_JAN23;
	SET TEMP1;
RUN;

proc contents data=TEMP1;
run;


/* QC Check  */
proc sql;
select yearmo, sum(hcp_npp_eng) as hcp_npp_eng, sum(hcp_dox_eng) as hcp_dox_eng 
from MODEL.ADS_FN_BELSOMRA_MDB_Feb21_JAN23 group by 1 order by 1;
Run;

proc sql;
select sum(hcp_grail_nrx), sum(hcp_npp_eng), sum(hcp_dox_eng), sum(pp_hcc), sum(hcp_rdtl_totdet40_RT2) from MODEL.ADS_FN_BELSOMRA_MDB_Feb21_JAN23 where yearmo<=202301;
Run;