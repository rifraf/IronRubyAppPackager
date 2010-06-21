rem
rem Quick check for IRPackager
rem
cls
set ir_app=test_drb

rem Clean up
rd /q/s _%ir_app%_cache_
rd /q/s _%ir_app%_build_

rem vendorize
set _Vendor_=.\_%ir_app%_cache_
ir  -I..\..\Vendorize\lib -rvendorize test_drb.rb

rem build
set _IRPackager_=.\_%ir_app%_build_
ir ..\lib\IRPackager.rb test_drb.rb %_Vendor_%

rem run (2 versions)
%_IRPackager_%\bin\test_drb.exe
test_drb.exe