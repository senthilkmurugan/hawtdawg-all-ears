
/*
Code to QA weighted GRP's by week.
input dataset: DTC.WEEKLY_LOCAL_WEIGHTED_GRPS;
Vars:
	WTRPS_F1849 - Nuvaring,
	WCTRPS_F1849 - All Competitors, 
    WZTRPS_F1849 - Yaz, 
    WLTRPS_F1849 - Loestrin,
    WSTRPS_F1849 - Seasonique,
    WRTRPS_F1849 - Mirena,
    WVTRPS_F1849 - Yaz Corrective.
*/

LIBNAME DTC "\\WPUSHH01\DINFOPLN\PRA\DTC\NuvaRing\2011 profit plan\SAS datasets";
LIBNAME DTC_OLD "\\WPUSHH01\DINFOPLN\PRA\DTC\NuvaRing\2011 profit plan\SAS datasets\bkp1";

/*LIBNAME NEWIN "\\WPUSHH01\DINFOPLN\PRA\DTC\NIELSEN DATA\2008 analysis data";*/
libname newin "\\WPUSHH01\DINFOPLN\PRA\DTC\NuvaRing\2011 profit plan\SAS datasets";

OPTIONS MLOGIC MPRINT SYMBOLGEN pagesize=max;
* logic modified dataset;
proc means data=DTC.WEEKLY_LOCAL_WEIGHTED_GRPS;
  class report_period;
  var 	WTRPS_F1849	WCTRPS_F1849 WZTRPS_F1849 WLTRPS_F1849 WSTRPS_F1849 
    WRTRPS_F1849 WVTRPS_F1849;
  output out=qc_rep_period_1 sum=;
run; 

* dataset with initial logic;
proc means data=DTC_OLD.WEEKLY_LOCAL_WEIGHTED_GRPS;
  class report_period;
  var 	WTRPS_F1849	WCTRPS_F1849 WZTRPS_F1849 WLTRPS_F1849 WSTRPS_F1849 
    WRTRPS_F1849 WVTRPS_F1849;
  output out=qc_rep_per_old_1 sum=;
run; 


* Check for NYC;
* logic modified dataset;
proc means data=DTC.WEEKLY_LOCAL_WEIGHTED_GRPS(WHERE=(market="NEW YORK"));
  class report_period;
  var 	WTRPS_F1849	WCTRPS_F1849 WZTRPS_F1849 WLTRPS_F1849 WSTRPS_F1849 
    WRTRPS_F1849 WVTRPS_F1849;
  output out=qc_rep_period_1 sum=;
run; 

