@chcp 1251
echo off


set PO_UTILITY=scripts\tools\poFileUtility.EXE

echo.
echo Настройки проекта
echo.

set PROJNAME=AppLocalizer
set BUILD=Release
set LANGDIR=bin\lang


cd ..

echo.
echo Удаление файлов перевода win32
echo.
del /f /q %LANGDIR%\*win32-*.po?

echo.
echo Копирование win64 файлов перевода в общие для всех бинарников
echo.
copy %LANGDIR%\%PROJNAME%-win64-%BUILD%.*.po  %LANGDIR%\%PROJNAME%.*.po

echo.
echo Копирование win64 шаблона локализации перевода в общий шаблон
echo.
copy %LANGDIR%\%PROJNAME%-win64-%BUILD%.pot   %LANGDIR%\%PROJNAME%.pot

echo.
echo Перенос строк в файле перевода для языка оригинала и сохранение в .en.po
echo.
%PO_UTILITY% %LANGDIR%\%PROJNAME%.pot %LANGDIR%\%PROJNAME%.en.po transfer
