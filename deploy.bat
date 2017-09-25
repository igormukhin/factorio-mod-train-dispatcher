set VER=0.0.1
set MOD=train-dispatcher
set DIR=%USERPROFILE%\AppData\Roaming\Factorio\mods

set MOD_DIR=%DIR%\%MOD%_%VER%
mkdir %MOD_DIR%

xcopy /e /y *.* %MOD_DIR%\ /exclude:deploy-excludes.txt