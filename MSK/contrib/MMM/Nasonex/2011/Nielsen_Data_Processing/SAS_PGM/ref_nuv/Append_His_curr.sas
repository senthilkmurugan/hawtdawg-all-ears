LIBNAME DTC "\\WPUSHH01\DINFOPLN\PRA\DTC\NuvaRing\2011 profit plan\SAS datasets";
LIBNAME DTC1 "\\WPUSHH01\DINFOPLN\PRA\DTC\NuvaRing\2010 profit plan\SAS datasets";

DATA DTC.weekly_natl_weighted_grps_jun10;
	SET DTC1.weekly_natl_weighted_grps DTC.weekly_natl_weighted_grps;
	National_weekly_GRPs=SUM(CABTV_F1849,NETTV_F1849,SYNTV_F1849,CABTV_F1849_SPANISH,NETTV_F1849_SPANISH);
RUN;
