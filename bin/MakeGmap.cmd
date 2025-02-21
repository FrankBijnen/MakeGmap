@echo off
if ["%MKGM_echo%"] equ [""] set MKGM_echo=off
@echo %MKGM_echo%

setlocal enabledelayedexpansion enableextensions

REM set options logfiles
set MKGM_mkgmapopt="%MKGM_tempdir%\tmp_tiles\mkgmap.options"
set MKGM_progresslog="%MKGM_tempdir%\makegmap_progress.log"
set MKGM_detaillog="%MKGM_tempdir%\makegmap_detail.log"

echo !time! Creating map %MKGM_mapname% >%MKGM_progresslog%
echo Detailed log !time! %MKGM_mapname% >%MKGM_detaillog%

REM To report the progress to the main program 
REM 6 = # call :Perform 1
set MKGM_totalsteps=6
set MKGM_step=0

REM Show variables
echo ******* Environment block ****************************** >>%MKGM_detaillog%
set >>%MKGM_detaillog%
"%MKGM_progdir%\sendmessage.exe" %MKGM_hwnd% %MKGM_progressmessage% !MKGM_step! !MKGM_totalsteps!

:CLEANBEFORE
REM del, rmdir do not set errorlevel
set MKGM_func=Clean up before
set MKGM_cmd=del /q "%MKGM_tempdir%\%MKGM_mapname%.o5m"
call :Perform 0 False
set MKGM_cmd=rmdir /s /q "%MKGM_tempdir%\tmp_bounds\"
call :Perform 0 False
set MKGM_cmd=mkdir "%MKGM_tempdir%\tmp_bounds\"
call :Perform 0 False
set MKGM_cmd=rmdir /s /q "%MKGM_tempdir%\bounds\"
call :Perform 0 False
set MKGM_cmd=mkdir "%MKGM_tempdir%\bounds\"
call :Perform 0 False
set MKGM_cmd=rmdir /s /q "%MKGM_tempdir%\tmp_tiles"
call :Perform 0 False
set MKGM_cmd=mkdir "%MKGM_tempdir%\tmp_tiles"
call :Perform 0 False
set MKGM_cmd=rmdir /s /q "%MKGM_finaldir%\%MKGM_mapname%"
call :Perform 0 False

REM Setting default parameters, and creating options file
echo !time! Setting default parameters >>%MKGM_progresslog%
call "%MKGM_progdir%\MakeGmap_Defaults.cmd"
echo !time! Creating mkgmap.options >>%MKGM_progresslog%
call "%MKGM_progdir%\MakeGmap_Options.cmd"

:OSMCONVERT
echo !time! !MKGM_mapfilescount! OSM files used: !MKGM_mapfiles! >>%MKGM_progresslog%
"%MKGM_progdir%\sendmessage.exe" %MKGM_hwnd% %MKGM_progressmessage% !MKGM_step! !MKGM_totalsteps!

REM if only 1 O5M file to process, and no Poly file, skip osmconvert
set MKGM_inputO5M=%MKGM_tempdir%\%MKGM_mapname%.o5m
set MKGM_osmconv=True
if !MKGM_mapfilescount! leq 1 (
  set MKGM_inputO5M=%MKGM_downdir%\!MKGM_mapfiles!
  set MKGM_osmconv=False
)

if ["%MKGM_osmconv%"] equ ["True"] (

  %MKGM_downdrive%
  set MKGM_func=Change dir to downloads
  set MKGM_cmd=cd "%MKGM_downdir%"
  call :Perform 0

  set MKGM_func=Starting OSM Convert
  set MKGM_cmd="%MKGM_progdir%\osmconvert.exe" -v !MKGM_mapfiles! -o="%MKGM_inputO5M%"
  call :Perform 1

) else (
  set /A MKGM_step=MKGM_step+1
)

%MKGM_tempdrive%
set MKGM_func=Change dir to temp
set MKGM_cmd=cd "%MKGM_tempdir%"
call :Perform 0

REM Execute OSMFILTER and BOUNDARIES only if no bounds.zip found.
REM
if ["%MKGM_processbounds%"] equ ["True"] (

  :OSMFILTER
  set MKGM_func=Starting OSM Filter
  set MKGM_cmd="%MKGM_progdir%\osmfilter.exe" ^
   -v "%MKGM_inputO5M%" --keep-nodes= "--keep-ways-relations=boundary=administrative =postal_code postal_code=" ^
   -o="%MKGM_tempdir%\tmp_bounds\%MKGM_mapname%-bounds.o5m"
  call :Perform 1
  
  :BOUNDARIES
  set MKGM_func=Starting Boundary preprocessor
  set MKGM_cmd=java ^
   -Xms%MKGM_minjavamem%G ^
   -Xmx%MKGM_maxjavamem%G ^
   -cp "%MKGM_progdir%\%MKGM_mkgmap%\mkgmap.jar" uk.me.parabola.mkgmap.reader.osm.boundary.BoundaryPreprocessor ^
   "%MKGM_tempdir%\tmp_bounds\%MKGM_mapname%-bounds.o5m" ^
   "%MKGM_tempdir%\bounds"
  call :Perform 1

) else (
  set /A MKGM_step=MKGM_step+2
)

:SPLITTER
if ["%MKGM_poly%"] neq [""] (
  set MKGM_parmpoly=--polygon-file="%MKGM_progdir%\poly\%MKGM_poly%"
)

set MKGM_func=Starting Splitter
set MKGM_cmd=java ^
 -Xms%MKGM_minjavamem%G ^
 -Xmx%MKGM_maxjavamem%G ^
 -jar "%MKGM_progdir%\%MKGM_splitter%\splitter.jar" ^
 --max-threads=%MKGM_maxjavathreads% ^
 --max-areas=%MKGM_maxareas% ^
 --max-nodes=%MKGM_maxnodes% ^
 --output=%MKGM_splitteroutput% ^
 --geonames-file="%MKGM_progdir%\geonames\cities500.txt" ^
 --output-dir=%MKGM_tempdir%\tmp_tiles ^
 --mapid=%MKGM_mapid%0001 ^
 %MKGM_parmpoly% ^
 "%MKGM_inputO5M%"
call :Perform 1

:MKGMAPOPT
set MKGM_func=Create MkgMap.args. Join mkgmap.options + template.args
set MKGM_cmd=copy /b %MKGM_mkgmapopt%+"%MKGM_tempdir%\tmp_tiles\template.args" "%MKGM_tempdir%\tmp_tiles\mkgmap.args"
call :Perform 0

set MKGM_gmapsuppsingle=
if ["%MKGM_splitgmapsupp%"] equ ["0"] (
  if ["%MKGM_gmapsupp%"] neq [""] (
    set MKGM_gmapsuppsingle=%MKGM_gmapsupp%
  )
)

:MKGMAP
set MKGM_func=Starting MkgMap
set MKGM_cmd=java ^
 -Xms%MKGM_minjavamem%G ^
 -Xmx%MKGM_maxjavamem%G ^
 -jar "%MKGM_progdir%\%MKGM_mkgmap%\mkgmap.jar" ^
 %MKGM_gmapi% %MKGM_gmapsuppsingle% ^
 -c "%MKGM_tempdir%\tmp_tiles\mkgmap.args" ^
 "%MKGM_progdir%\styles\%MKGM_style%\%MKGM_style%.txt"
call :Perform 1

REM Copy to finaldir for reference. Continue on error. Dont check. 
set MKGM_func=Copy mkgmap.args to final dir.
set MKGM_cmd=copy /b "%MKGM_tempdir%\tmp_tiles\mkgmap.args" "%MKGM_finaldir%\%MKGM_mapname%\mkgmap.args"
call :Perform 0 False

REM Create device subdir
if ["%MKGM_gmapsupp%"] neq [""] (
  set MKGM_func=Create device subdir
  set MKGM_cmd=mkdir "%MKGM_finaldir%\%MKGM_mapname%\device"
  call :Perform 0
)

REM Move gmapsupp.img to device subdirectory
if exist "%MKGM_finaldir%\%MKGM_mapname%\gmapsupp.img" (
  set MKGM_func=Move gmapsupp.img to device subdir.
  set MKGM_cmd=move "%MKGM_finaldir%\%MKGM_mapname%\gmapsupp.img" "%MKGM_finaldir%\%MKGM_mapname%\device\gmapsupp.img"
  call :Perform 0
)

REM Need to split the gmapsupp.img?
if ["%MKGM_splitgmapsupp%"] equ ["0"] goto CLEANAFTER
if ["%MKGM_gmapsupp%"] equ [""] goto CLEANAFTER

:SPLITGMAPSUPP
REM SpitGmapSupp scans the generated .img in the finaldir and creates a new mkgmap_gmapsupp*.args when the size exceeds MKGM_splitgmapsupp 
REM All parameters in the mkgmap.option file are added, to make sure the gmapsupp files can be used as 1 map by the device.
set MKGM_func=Split GmapSupp
set MKGM_cmd="%MKGM_progdir%\SplitGmapSupp.exe" %MKGM_mkgmapopt% "%MKGM_tempdir%\tmp_tiles" "%MKGM_finaldir%\%MKGM_mapname%" "%MKGM_mapid%" %MKGM_splitgmapsupp% "%MKGM_countrylist%"
call :Perform 1

set MKGM_count=0
for /f "delims=" %%D in ('dir "%MKGM_tempdir%\tmp_tiles\mkgmap_gmapsupp*.args" /b') do (

   REM Copy to finaldir for reference. Continue on error. Dont check. 
   set MKGM_func=Copy mkgmap.args to final dir.
   set MKGM_cmd=copy /b "%MKGM_tempdir%\tmp_tiles\%%D" "%MKGM_finaldir%\%MKGM_mapname%\."
   call :Perform 0 False

  REM Create gmapsupp.img for the .img files selected by SplitGmapSupp.exe
  set MKGM_func=Starting create split %%D
  set MKGM_cmd=java ^
    -Xms%MKGM_minjavamem%G ^
    -Xmx%MKGM_maxjavamem%G ^
    -jar "%MKGM_progdir%\%MKGM_mkgmap%\mkgmap.jar" ^
    --gmapsupp ^
    -c "%MKGM_tempdir%\tmp_tiles\%%D" ^
    "%MKGM_progdir%\styles\%MKGM_style%\%MKGM_style%.txt"
  call :Perform 0

  REM Move gmapsupp.img to device subdir, and rename to seqnr.
  if exist "%MKGM_finaldir%\%MKGM_mapname%\gmapsupp.img" (
    REM Assign 2 digit MKGM_seqsup, so the files are sorted nicely. 
    REM e.g. Europ00.img Europe01.img etc.
    set MKGM_seqsup=00!MKGM_count!
    set MKGM_seqsup=!MKGM_seqsup:~-2!
    set MKGM_func=Save split %%D
    set MKGM_cmd=move "%MKGM_finaldir%\%MKGM_mapname%\gmapsupp.img" "%MKGM_finaldir%\%MKGM_mapname%\device\%MKGM_mapname%!MKGM_seqsup!.img"
    call :Perform 0
  )              
  set /A MKGM_count=!MKGM_count!+1
)

:CLEANAFTER
set MKGM_func=Clean up after
if [%MKGM_keeptmp%] neq [True] (
  set MKGM_cmd=del /q "%MKGM_tempdir%\%MKGM_mapname%.o5m"
  call :Perform 0 False
  set MKGM_cmd=rmdir /s /q "%MKGM_tempdir%\tmp_bounds\"
  call :Perform 0 False
  set MKGM_cmd=rmdir /s /q "%MKGM_tempdir%\bounds\"
  call :Perform 0 False
  set MKGM_cmd=rmdir /s /q "%MKGM_tempdir%\tmp_tiles"
  call :Perform 0 False
)

if [%MKGM_keepimg%] neq [True] (
  set MKGM_cmd=del /q "%MKGM_finaldir%\%MKGM_mapname%\*.img"
  call :Perform 0 False
)

echo %time% Map %MKGM_mapname% created >>%MKGM_progresslog%
REM 0 0 Ensures the progress bar is reset.
"%MKGM_progdir%\sendmessage.exe" %MKGM_hwnd% %MKGM_progressmessage% 0 0
exit 0

:Perform
REM 1st parm can be 0 or 1. increment step
REM 2nd parm can be False. Dont Check Error
REM MKGM_func is reset, to group multiple commands. See cleanup

REM Progress log
if ["%MKGM_func%"] neq [""] (
  Echo %time% %MKGM_func% >>%MKGM_progresslog%
  
  REM Command log
  echo rem
  echo rem *** %MKGM_func% **************************************
  set MKGM_func=
)
echo !MKGM_cmd!

REM Detail log
echo **************************************************** >>%MKGM_detaillog%
echo !MKGM_cmd! >>%MKGM_detaillog%

REM Update GUI
"%MKGM_progdir%\sendmessage.exe" %MKGM_hwnd% %MKGM_progressmessage% !MKGM_step! !MKGM_totalsteps!
set /A MKGM_step=MKGM_step+%1

REM Execute
!MKGM_cmd! >>%MKGM_detaillog% 2>>&1
if ["%2"] equ ["False"] (
  exit /b
)
if ERRORLEVEL 1 goto ERROR
exit /b

:ERROR
set MKGM_exitcode=%ERRORLEVEL%
set MKGM_Errmsg="%time% An error occurred executing: !MKGM_cmd! Exitcode: %MKGM_exitcode%"

REM show error in all logfiles

echo ****************************************************
echo %MKGM_Errmsg%
echo **************************************************** >>%MKGM_detaillog%
echo %MKGM_Errmsg% >>%MKGM_detaillog%
echo **************************************************** >>%MKGM_progresslog%
echo %MKGM_Errmsg% >>%MKGM_progresslog%

REM -1 Informs the GUI of the exitcode. Not used!
"%MKGM_progdir%\sendmessage.exe" %MKGM_hwnd% %MKGM_progressmessage% %MKGM_exitcode% -1
REM exitcode 0. Because cmd executed succesfully
exit 0

