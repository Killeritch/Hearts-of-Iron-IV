cd %1
DEL /Q %2.zip
7z a -mx5 -tzip %2.zip * -x!%2.dlc
cd ../..