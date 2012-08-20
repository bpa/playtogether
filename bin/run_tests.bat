cd /d %~dp0
cd ..
CALL prove -e "perl6 -Ilib"
pause
