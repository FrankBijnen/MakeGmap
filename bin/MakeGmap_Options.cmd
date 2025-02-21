REM Create MkgMap options file

REM Begin fixed parameters

echo #file automatically created by MakeGmap_Options.cmd >%MKGM_mkgmapopt%
echo # >>%MKGM_mkgmapopt%
echo #Fixed parameters >>%MKGM_mkgmapopt%
echo # >>%MKGM_mkgmapopt%
echo tdbfile >>%MKGM_mkgmapopt%
echo route >>%MKGM_mkgmapopt%
echo index >>%MKGM_mkgmapopt%
echo location-autofill: is_in,nearest >>%MKGM_mkgmapopt%
echo housenumbers >>%MKGM_mkgmapopt%
echo add-pois-to-areas >>%MKGM_mkgmapopt%
echo link-pois-to-ways >>%MKGM_mkgmapopt%
echo process-destination >>%MKGM_mkgmapopt%
echo process-exits >>%MKGM_mkgmapopt%
echo split-name-index >>%MKGM_mkgmapopt%
echo poi-address >>%MKGM_mkgmapopt%
echo add-pois-to-lines >>%MKGM_mkgmapopt%
echo min-size-polygon: 15 >>%MKGM_mkgmapopt%
echo hide-gmapsupp-on-pc >>%MKGM_mkgmapopt%
echo add-boundary-nodes-at-admin-boundaries=4 >>%MKGM_mkgmapopt%
echo drive-on: detect >>%MKGM_mkgmapopt%
echo keep-going >>%MKGM_mkgmapopt%

echo !time! Setting User Options >>%MKGM_progresslog%
call "%MKGM_progdir%\MakeGmap_User_Options.cmd"

REM End fixed parameters

REM Begin dynamic parameters

REM 
REM Sea(-latest).zip improves coastline. Can be downloaded from https://www.thkukuk.de/osm/data/sea-latest.zip
REM Find out which Sea.zip to use.
set MKGM_presea=%MKGM_progdir%\sea\sea-latest.zip
if exist "%MKGM_downdir%\sea.zip" set MKGM_presea=%MKGM_downdir%\sea.zip
if exist "%MKGM_downdir%\sea-latest.zip" set MKGM_presea=%MKGM_downdir%\sea-latest.zip

REM
REM bounds(-latest).zip improves addresses. Can be download from https://www.thkukuk.de/osm/data/bounds-latest.zip
REM Find out which bounds to use.
set MKGM_processbounds=True
set MKGM_bounds=%MKGM_tempdir%\bounds
if exist "%MKGM_downdir%\bounds-latest.zip" (
  set MKGM_processbounds=False
  set MKGM_bounds=%MKGM_downdir%\bounds-latest.zip
)

echo # >>%MKGM_mkgmapopt%
echo #Dynamic parameters >>%MKGM_mkgmapopt%
echo # >>%MKGM_mkgmapopt%
echo draw-priority: %MKGM_drawprio% >>%MKGM_mkgmapopt%
echo %MKGM_transparent% >>%MKGM_mkgmapopt%
echo max-jobs: %MKGM_maxjavathreads% >>%MKGM_mkgmapopt%
echo precomp-sea: %MKGM_presea% >>%MKGM_mkgmapopt%
echo %MKGM_codepage% >>%MKGM_mkgmapopt%
echo bounds: %MKGM_bounds% >>%MKGM_mkgmapopt%
echo output-dir: %MKGM_finaldir%\%MKGM_mapname% >>%MKGM_mkgmapopt%
echo style-file: %MKGM_progdir%\styles\%MKGM_style%\style >>%MKGM_mkgmapopt%
echo country-name: %MKGM_mapname% >>%MKGM_mkgmapopt%
echo country-abbr: %MKGM_mapcode% >>%MKGM_mkgmapopt%
echo family-id: %MKGM_mapid% >>%MKGM_mkgmapopt%
echo product-id: %MKGM_mapid% >>%MKGM_mkgmapopt%
echo series-name: %MKGM_mapname%-%MKGM_mapid% >>%MKGM_mkgmapopt%
echo family-name: %MKGM_mapname%-%MKGM_mapid% >>%MKGM_mkgmapopt%
echo area-name: %MKGM_mapcode% >>%MKGM_mkgmapopt%

REM End dynamic parameters

echo ************************************************
echo Begin %MKGM_mkgmapopt%
echo ************************************************

type %MKGM_mkgmapopt%

echo ************************************************
echo End %MKGM_mkgmapopt%
echo ************************************************
