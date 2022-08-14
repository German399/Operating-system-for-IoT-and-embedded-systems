@echo off
echo Cleaning up...

if exist src\*.o del /F /Q src\*.o
if exist *fxrtos.* del /F /Q *fxrtos.*

if "%1"=="clean" (
    echo OK
	exit /b 0
) 

if not exist src (	
	mkdir src
	echo Performing dependency injection...
	set FX_PREP=%GCC_PREFIX%gcc -E -Isrc -include %%s %%s
	%FXDJ% -p .,%FXRTOS_DIR%\components -t FXRTOS -a async-cortex-m3-gnu.map -o src -l src\fxrtos.lst
	echo #define FX_METADATA^(data^) > src/includes.inc
	echo #define FX_INTERFACE^(hdr^) ^<hdr.h^> >> src/includes.inc	
)

if "%1" == "srccopy" (
    echo OK
	exit /b 0
)

call set OBJS=
cd src
echo Compiling...

for %%f in (*.c) do (
	echo %%f
	%GCC_PREFIX%gcc -pedantic -std=c99 -O2 -Wall -include includes.inc -mcpu=cortex-m3 -mthumb -I. -c -o %%~nf.o %%f
	call set OBJS=%%OBJS%% %%~nf.o
)

for %%f in (*.S) do (
	echo %%f
	%GCC_PREFIX%gcc -mcpu=cortex-m3 -mthumb -I. -include includes.inc -c -o %%~nf.o %%f
	call set OBJS=%%OBJS%% %%~nf.o
)

echo Creating library...
%GCC_PREFIX%ar rcs ../libfxrtos.a %OBJS%
cd ..

echo Creating common header...
echo #define FX_METADATA^(data^) > FXRTOS.h
echo #define FX_INTERFACE^(file^) ^<stdint.h^> >> FXRTOS.h
for /F "tokens=*" %%A in (src\fxrtos.lst) do type src\%%A.h >> FXRTOS.h