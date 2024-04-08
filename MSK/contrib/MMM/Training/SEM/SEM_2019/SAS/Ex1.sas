libname in "C:\Users\smuruga2\PROJECTS\Training\SEM_2019\SAS-Data-Sets";
libname out "C:\Users\smuruga2\PROJECTS\Training\SEM_2019\SAS";

PROC CALIS DATA=in.gss2014;
  PATH prochoice <- age attend childs educ health income paeduc female married white;
RUN;

*handle missing data using METHOD=FIML;
PROC CALIS DATA=in.gss2014 METHOD=FIML;
  PATH prochoice <- age attend childs educ health income paeduc female married white;
RUN;
/* ########################################### */
/* Exercise 1 */
proc contents data=in.college varnum; run;
* 1A - do not handle missing data ;
PROC CALIS data=in.college;
  PATH gradrat <- lenroll rmbrd private stufac csat; * did not include act;
RUN;
/*
                                           PATH List
                                                                  Standard
        -----------Path-----------    Parameter      Estimate         Error       t Value
        GRADRAT    <---    LENROLL    _Parm1          2.41705       0.95374       2.53429
        GRADRAT    <---    RMBRD      _Parm2          2.16169       0.70970       3.04591
        GRADRAT    <---    PRIVATE    _Parm3         13.58806       1.93537       7.02090
        GRADRAT    <---    STUFAC     _Parm4         -0.12306       0.13116      -0.93830
        GRADRAT    <---    CSAT       _Parm5          0.06727       0.00639      10.52694

*/


* 1B - handle missing data using FIML method;
PROC CALIS DATA=in.college METHOD=FIML;
  PATH gradrat <- lenroll rmbrd private stufac csat;
RUN; 

/* Magnitude of estimates changs little with FIML.
                                           PATH List
                                                                   Standard
        -----------Path-----------    Parameter      Estimate         Error       t Value
        GRADRAT    <---    LENROLL    _Parm1          2.16609       0.60427       3.58463
        GRADRAT    <---    RMBRD      _Parm2          2.36379       0.55965       4.22366
        GRADRAT    <---    PRIVATE    _Parm3         13.02281       1.30030      10.01523
        GRADRAT    <---    STUFAC     _Parm4         -0.19370       0.09359      -2.06975  * with FIML this var becomes significant.
        GRADRAT    <---    CSAT       _Parm5          0.06553       0.00486      13.48383
*/

* 1C - Introduce multiple PATHs;
PROC CALIS DATA=in.college METHOD=FIML;
  PATH gradrat <- private lenroll rmbrd = a b c,
   lenroll <- private = d,
   rmbrd <- private = e,
   lenroll <-> rmbrd;
  EFFPART gradrat <- private lenroll rmbrd;
  PARMS ind1 ind2;
    ind1 = d*b; ind2=e*c;
RUN;

/* ########################################### */
/* Exercise 2 */
libname in2 "C:\Users\smuruga2\PROJECTS\Training\SEM_2019\Text-Files";
data anomie(type=cov);
  infile "C:\Users\smuruga2\PROJECTS\Training\SEM_2019\Text-Files\ASG2SEM.txt" missover;
  _type_='cov';
  input ano67 pow67 ano71 pow71 ed occ;
run;
proc contents data=anomie varnum; run;




/* ########################################### */
/* Exercise 3 */
libname in2 "C:\Users\smuruga2\PROJECTS\Training\SEM_2019\Text-Files";
data cigpun(type=corr);
  infile "C:\Users\smuruga2\PROJECTS\Training\SEM_2019\Text-Files\ASG3SEM.txt" missover;
  _type_='corr';
  input c1-c4 p1-p4;
run;
proc contents data=cigpun varnum; run;

* 3A - default assumes cig and pun are correlated and exogenous error variances are not correlated.;
PROC CALIS DATA=cigpun NOBS=350;
  PATH cig -> c1 c2 c3 c4 = 1,
       pun -> p1 p2 p3 p4 = 1;
RUN;

* 3B - default assumes cig and pun are correlated and exogenous error variances are not correlated.;
PROC CALIS DATA=cigpun NOBS=350;
  PATH cig -> c1 c2 c3 c4 = 1,
       pun -> p1 p2 p3 p4 = 1,
	   c1 <-> p1, c2 <-> p2, c3 <-> p3, c4 <-> p4; * setting specified error variances are correlated;
RUN;


