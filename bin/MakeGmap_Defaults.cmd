REM Default parameters

REM ***************************************************
REM Debugging parameters
REM ***************************************************

REM MKGM_keeptmp keeps the files in tempdir
set MKGM_keeptmp=False

REM MKGM_keepimg keeps the .img files in finaldir
set MKGM_keepimg=False

REM ***************************************************
REM Splitter parameters
REM ***************************************************

REM splitter version, should be a subdir of the progdir
set MKGM_splitter=splitter-r654

REM maxnodes specifies the max nodes in each tile. Higher nr means larger tiles.
REM Europe with style tdb_r024 can be build with 4096000. 8192000 Fails.
REM If too large mkgmap (the next step) will fail 'Overflow in .net'. Some IMG's will have zero bytes.  1.600.000 is the default. 
REM see also: https://www.cferrero.net/maps/splitter_advanced.html
if ["%MKGM_maxnodes%"] equ [""] set MKGM_maxnodes=1600000

REM 4096 is the max. Higher nr. means more memory required.
if ["%MKGM_maxareas%"] equ [""] set MKGM_maxareas=4096

REM Splitter output. O5M is said to be faster, PBF smaller.
set MKGM_splitteroutput=pbf

REM ***************************************************
REM MkgMap parameters
REM ***************************************************

REM mkgmap version, should be a subdir of the progdir
set MKGM_mkgmap=mkgmap-r4923

REM Specifies the draw priority when multiple maps cover the same area. 30 is highest
if ["%MKGM_drawprio%"] equ [""] set MKGM_drawprio=25

REM mkgmap tranparent. Can be used to superimpose on other maps. 
if ["%MKGM_transparent%"] equ [""] set MKGM_transparent=# No transparency
