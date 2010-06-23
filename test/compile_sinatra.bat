rem
rem Quick check for IRPackager
rem
cls
set ir_app=sinatra

rem Clean up
rd /q/s _%ir_app%_cache_
rd /q/s _%ir_app%_build_

rem vendorize
set _Vendor_=.\_%ir_app%_cache_
ir  -I..\..\Vendorize\lib -rvendorize sinatra_app.rb

rem run from cache only. If this works, the packaging ought to..
ir  -I..\..\Vendorize\lib -rvendor_only sinatra_app.rb

rem build
set _IRPackager_=.\_%ir_app%_build_
ir ..\lib\IRPackager.rb sinatra_app.rb %_Vendor_% > log

rem run
rem %_IRPackager_%\bin\sinatra_app.exe
sinatra_app.exe