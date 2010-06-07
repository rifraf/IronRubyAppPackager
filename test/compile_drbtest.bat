rem
rem Quick check for IRPackager
rem

rem vendorize
ir  -I..\..\Vendorize\lib -rvendorize test_drb.rb

rem build
ir ..\lib\IRPackager.rb test_drb.rb

rem run (2 versions)
_IRPackager_\bin\test_drb.exe
test_drb.exe