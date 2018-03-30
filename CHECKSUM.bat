@echo off
call ZIP_DLCS.bat
set TEMP_FILE=AllChecksums.txt
@echo === Running game in order to compute the required checksums
@echo === Please wait...
hoi4_RD.exe -rd_dlc_chksum=%TEMP_FILE% -forcedlc
@echo === Running game complete
@echo === Applying checksums to dlc files...
python ChecksumsApply.py %TEMP_FILE%
del /F /Q %TEMP_FILE%
@echo === ALL DLCs HAS BEEN: RE-ZIPPED AND UPDATED CHECKSUMS...
pause