@chcp 1251


set PO_UTILITY=scripts\tools\poFileUtility.EXE

echo.
echo Project settings
echo.

set PROJNAME=AppLocalizer
set BUILD=Release
set LANGDIR=bin\lang
set LANGORIG=en


cd ..

echo.
echo Removing win64 localization files
echo Because win32 localization files is used as a base
echo.
del /f /q %LANGDIR%\*win64-*.po?

echo.
echo Copying win32 localization files to files shared by all binaries
echo.
copy %LANGDIR%\%PROJNAME%-win32-%BUILD%.*.po  %LANGDIR%\%PROJNAME%.*.po

echo.
echo  Copying win32 localization template into common template
echo.
copy %LANGDIR%\%PROJNAME%-win32-%BUILD%.pot   %LANGDIR%\%PROJNAME%.pot

echo.
echo Transfer lines in localization file for original language and save to ."your-lang".po
echo.

%PO_UTILITY% %LANGDIR%\%PROJNAME%.pot %LANGDIR%\%PROJNAME%.%LANGORIG%.po transfer