@echo off
cls
xcopy v:\Working\DevTrunk\ThirdParty\Serfs\Serfs\bin\Serfs.dll \Play\IRPackager\IRPackager\lib\ /s/e/d/y
xcopy v:\Working\DevTrunk\ThirdParty\IREmbedded\IREmbeddedApp\bin\IREmbeddedApp.dll \Play\IRPackager\IRPackager\lib\ /s/e/d/y
rd /q/s  .\_irp_build_
rd /q/s  .\_dogfood_cache_
rd /q/s  .\_dogfood_build_
rd /q/s  .\_vendor_
rd /q/s  .\_IRPackager_

set _IRPACKAGER_NOZIP_=
set _Vendor_=.\_irp_cache_
set _IRPackager_=.\_irp_build_

rd /q/s  .\_irp_cache_
ir -rvendorize ..\lib\IRPackager.rb dogfood.rb %_Vendor_% >log1
rem pause
rd /q/s  .\_irp_build_
ir ..\lib\IRPackager.rb ..\lib\IRPackager.rb %_Vendor_%
rem pause

dogfood.exe
del dogfood.exe
rem pause

set _Vendor_=./_dogfood_cache_
set _IRPackager_=./_dogfood_build_

ir -rvendorize dogfood.rb >log2
IRPackager.exe dogfood.rb %_Vendor_%
dogfood.exe

set _Vendor_=
set _IRPackager_=
