for %%i in (src\*.nut) do sq.exe -c -o out\%%~ni.nut.m %%i 
pause