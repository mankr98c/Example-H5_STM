@ECHO OFF
:: Getting the Trusted Package Creator and STM32CubeProgammer CLI path
:: arg1 is the binary type (1 nonsecure, 2 secure)
:: arg2 is the config type (Debug, Release)
set "projectdir=%~dp0"
set "signing=%1"
set "config=%2"
pushd %projectdir%\..\..\..\..\ROT_Provisioning
set provisioningdir=%cd%
popd
call "%provisioningdir%\env.bat"

:: Enable delayed expansion
setlocal EnableDelayedExpansion

set s_code_xml="%provisioningdir%\OEMiROT\Images\OEMiRoT_S_Code_Image.xml"
set ns_code_xml="%provisioningdir%\OEMiROT\Images\OEMiRoT_NS_Code_Image.xml"
set s_code_bin="%projectdir%\Secure\%config%\Template_NUCLEO-H563ZI_OEMiROT_Appli_TrustZone_S.bin"
set ns_code_bin="%projectdir%\NonSecure\%config%\Template_NUCLEO-H563ZI_OEMiROT_Appli_TrustZone_NS.bin"
set bin_dest_dir=%projectdir%\..\Binary
set one_code_bin="%projectdir%\..\Binary\rot_tz_app.bin"

::Variables updated by OEMiROT_Boot postbuild
set app_image_number=2
set image_s_size=0x6000

:start
goto exe:
goto py:
:exe
::line for window executable
set "applicfg=%cube_fw_path%\Utilities\PC_Software\ROT_AppliConfig\dist\AppliCfg.exe"
set "python="
if exist %applicfg% (
goto postbuild
)
:py
::called if we just want to use AppliCfg python (think to comment "goto exe:")
set "applicfg=%cube_fw_path%\Utilities\PC_Software\ROT_AppliConfig\AppliCfg.py"
set "python=python "

:postbuild
echo Postbuild %signing% image > %projectdir%\output.txt 2>&1

if "%app_image_number%" == "2" (
goto :continue
)
if "%signing%" == "nonsecure" (
echo Creating assembled binary >> %projectdir%\output.txt 2>&1
%python%%applicfg% oneimage -fb %s_code_bin% -o %image_s_size% -sb %ns_code_bin% -i 0x0 -ob %one_code_bin% --vb >> %projectdir%\output.txt 2>&1
if !errorlevel! neq 0 goto :error
)

:continue
if "%signing%" == "secure" (
echo Copy secure binary to Binary location >> %projectdir%\output.txt 2>&1
copy %s_code_bin% %bin_dest_dir%\rot_tz_s_app.bin >> %projectdir%\output.txt 2>&1
if !errorlevel! neq 0 goto :error

echo Creating secure image  >> %projectdir%\output.txt 2>&1
%stm32tpccli% -pb %s_code_xml% >> %projectdir%\output.txt 2>&1
if !errorlevel! neq 0 goto :error
)

if "%signing%" == "nonsecure" (
echo Copy nonsecure binary to Binary location >> %projectdir%\output.txt 2>&1
copy %ns_code_bin% %bin_dest_dir%\rot_tz_ns_app.bin >> %projectdir%\output.txt 2>&1
if !errorlevel! neq 0 goto :error

echo Creating nonsecure image  >> %projectdir%\output.txt 2>&1
%stm32tpccli% -pb %ns_code_xml% >> %projectdir%\output.txt 2>&1
if !errorlevel! neq 0 goto :error
)
exit 0

:error
exit 1