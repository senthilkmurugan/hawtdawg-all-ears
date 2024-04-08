1. The Nielsen TAB delimited data file has some meta data in the first few (about 9) rows. Delete them so that the first row has variable names.

2. While loading TAB delimited file in SAS using PROC IMPORT, some of the strings (like Report Period) is automatically considered as date variable, however its format in the input dataset is complex and should be considered as text. Due to this anamoly data was not loaded.
	There are few options to proceed:
	a. Import using DATA procedure with long list of formats and informats. This is time consuming and does not allow single automation for all files.
	b. Import the raw data to excel (which automatically takes care of such formats) and create an input xcel file. Then try importing this excel file into SAS. However, LOCAL GRP files has more than 64K rows and excel truncates data. This method was also not efficient.
	c. Import the raw data to Access DB as a delimiter files and create access tables for each input file. Then import this data to SAS. This procedure seems fast and efficient as well as SAS Import statements are more generic and automatable.

3. Use SAS PROC IMPORT to import access tables.

4. DMA to DMA_CODE Cross Reference Excel file has very few missing values and incorrect values.
   These were manually corrected in the corresponding ACCESS Data base Table. Refer to ACCESS DB
   for a better cross reference file.




