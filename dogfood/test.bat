@echo off
cls
set _Vendor_=./_dogfood_cache_
set _IRPackager_=./_dogfood_build_

ir -rvendorize dogfood.rb
IRPackager.exe dogfood.rb %_Vendor_% > log
dogfood.exe

set _Vendor_=
set _IRPackager_=
