@ECHO OFF

:: Getting the Trusted Package Creator and STM32CubeProgammer CLI path 
call ../env.bat

:: Enable delayed expansion
setlocal EnableDelayedExpansion

set isGeneratedByCubeMX=%PROJECT_GENERATED_BY_CUBEMX%
:: Environment variable for AppliCfg
set "projectdir=%~dp0"
:: External scripts
set ob_flash_programming="ob_flash_programming.bat"
set ob_key_provisioning="obkey_provisioning.bat"
set update_ob_setup="update_ob_setup.bat"

set fw_in_bin="Firmware binary input file"
set fw_out_bin="Image output file"
:: Application binary files
set ns_app_bin="%oemirot_boot_path_project%\EWARM\NonSecure\STM32H573I-DK_NS\Exe\Project.bin"
set ns_app_bin=%ns_app_bin:\=/%
set s_app_bin="%oemirot_boot_path_project%\EWARM\Secure\STM32H573I-DK_S\Exe\Project.bin"
set s_app_bin=%s_app_bin:\=/%
set s_code_image_file="%projectdir%Images\OEMuROT_S_Code_Image.xml"
set ns_code_image_file="%projectdir%Images\OEMuROT_NS_Code_Image.xml"
set ns_app_enc_sign_hex="%oemirot_boot_path_project%\Binary\rot_tz_ns_app_enc_sign.hex"
set ns_app_enc_sign_hex=%ns_app_enc_sign_hex:\=/%
set s_app_enc_sign_hex="%oemirot_boot_path_project%\Binary\rot_tz_s_app_enc_sign.hex"
set s_app_enc_sign_hex=%s_app_enc_sign_hex:\=/%

:provisioning
set ob_update_ob_log="update_ob_setup.log"
set ob_key_provisioning_log="obkey_provisioning.log"
set provisioning_log="provisioning.log"
set ob_flash_log="ob_flash_programming.log"

:: Initial configuration
set product_state=OPEN
set connect_no_reset=-c port=SWD speed=fast ap=1 mode=Hotplug

set "flash_layout=%cube_fw_path%\Projects\STM32H573I-DK\Applications\ROT\OEMiROT_Boot\Inc\flash_layout.h"

:: Environment variable used to know if the firmware image is full secure or not
set stirot_config=".\Config\STiRoT_Config.xml"

goto exe:
goto py:
:exe
::line for window executable
set "applicfg=%cube_fw_path%\Utilities\PC_Software\ROT_AppliConfig\dist\AppliCfg.exe"
set "python="
if exist %applicfg% (
echo run config Appli with windows executable
goto prov
)
:py
::line for python
echo run config Appli with python script
set "applicfg=%cube_fw_path%\Utilities\PC_Software\ROT_AppliConfig\AppliCfg.py"
set "python=python "

:prov

echo =====
echo ===== Provisioning of STiRoT_OEMuROT boot path
echo ===== Application selected through env.bat:
echo =====   %oemirot_boot_path_project%
echo ===== Product state must be Open. Execute  \ROT_Provisioning\DA\regression.bat if not the case.
echo =====
echo.

:: bypass this step when Generated By CubeMX
if "%isGeneratedByCubeMX%" == "true" goto :cubemx
if /i %oemirot_boot_path_project% == %oemirot_boot_path_project:OEMiROT_Appli_TrustZone=% (
echo =====
echo ===== Wrong Boot path: %oemirot_boot_path_project%
echo ===== please modify the env.bat to set the right path
goto step_error
)

:: ====================================================== STM32H5 product preparation ======================================================
:: =============================================== Steps to create the STiRoT_Config.obk file ==============================================
echo Step 1 : Configuration management
echo    * STiRoT_Config.obk generation:
echo        From TrustedPackageCreator (tab H5-OBkey)
echo        Select STiRoT_Config.xml(Default path is \ROT_Provisioning\STiROT_OEMuROT\Config\STiRoT_Config.xml)
echo        Warning: Default keys must NOT be used in a product. Make sure to regenerate your own keys!
echo        Update the configuration (if/as needed) then generate STiRoT_Config.obk file
echo        Press any key to continue...
if [%1] neq [AUTO] pause >nul

:: =============================================== Steps to create the OEMuRoT_Config.obk file ==============================================
echo;
echo    * OEMuRoT_Config.obk generation:
echo        From TrustedPackageCreator (tab H5-OBkey)
echo        Select OEMuRoT_Config_1.xml(Default path is \ROT_Provisioning\STiROT_OEMuROT\Config\OEMuRoT_Config_1.xml)
echo        Warning: Default keys must NOT be used in a product. Make sure to regenerate your own keys!
echo        Update the configuration (if/as needed) then generate OEMuRoT_Config.obk file
echo        Press any key to continue...
if [%1] neq [AUTO] pause >nul
:: =============================================== Steps to create the DA_Config.obk file ==============================================
echo;
echo    * DA_Config.obk generation:
echo        From TrustedPackageCreator (tab H5-OBkey)
echo        Select DA_Config.xml(Default path is \ROT_Provisioning\DA\Config\DA_Config.xml)
echo        Warning: Default keys must NOT be used in a product. Make sure to regenerate your own keys!
echo        Update the configuration (if/as needed) then generate DA_Config.obk file
echo        Press any key to continue...
if [%1] neq [AUTO] pause >nul
:: ======================================================= Updating the Option bytes =======================================================
echo;
set current_log_file=%ob_update_ob_log%
set "action=ob_flash_programming script update ..."
set "command=start /w /b call %update_ob_setup% AUTO"
echo    * %action%
%command% > %ob_update_ob_log% 2>&1

set ob_update_ob_error=!errorlevel!
if %ob_update_ob_error% neq 0 goto :step_error
echo        Option bytes successfully updated according to STiRoT_Config.xml
echo        (see %ob_update_ob_log% for details)

::uncomment OEMUROT_ENABLE flag
set "command=%python%%applicfg% setdefine -a uncomment -n OEMUROT_ENABLE -v 1 %flash_layout%"
%command%
IF !errorlevel! NEQ 0 goto :step_error

:: ========================================================= Images generation steps ========================================================  
echo;
echo Step 2 : Images generation
echo    * Boot firmware image generation
echo        Open the OEMiROT_Boot project with preferred toolchain and rebuild all files.
echo        At this step the project is configured for STiROT_OEMuROT boot path
echo        Press any key to continue...
if [%1] neq [AUTO] pause >nul
echo;
::update xml file
set "command=%python%%applicfg% xmlval -v %s_app_bin% --string -n %fw_in_bin% %s_code_image_file% --vb >> %current_log_file%"
%command%
IF !errorlevel! NEQ 0 goto :step_error
set "command=%python%%applicfg% xmlval -v %ns_app_bin% --string -n %fw_in_bin% %ns_code_image_file% --vb >> %current_log_file%"
%command%
IF !errorlevel! NEQ 0 goto :step_error
set "command=%python%%applicfg% xmlval -v %s_app_enc_sign_hex% --string -n %fw_out_bin% %s_code_image_file% --vb >> %current_log_file%"
%command%
IF !errorlevel! NEQ 0 goto :step_error
set "command=%python%%applicfg% xmlval -v %ns_app_enc_sign_hex% --string -n %fw_out_bin% %ns_code_image_file% --vb >> %current_log_file%"
%command%
IF !errorlevel! NEQ 0 goto :step_error
echo    * Code firmware image generation
echo        Open the OEMiROT_Appli_TrustZone project with preferred toolchain.
echo        Rebuild all files. The appli_enc_sign.hex file is generated with the postbuild command.
echo        Press any key to continue...
if [%1] neq [AUTO] pause >nul
echo.

echo    * Data generation (if Data image is enabled):
echo        Select STiRoT_Data_Image.xml(Default path is \ROT_Provisioning\STiROT_OEMuROT\Image\STiRoT_Data_Image.xml)
echo        Generate the data_enc_sign.hex image
echo        Press any key to continue...
if [%1] neq [AUTO] pause >nul
echo;

:cubemx
:: ========================================================= Board provisioning steps =======================================================  
echo Step 3 : Provisioning
echo    * BOOT0 pin should be disconnected from VDD:
echo        (STM32H573I-DK: set SW1 to position 0)
echo        Press any key to continue...
echo;
if [%1] neq [AUTO] pause >nul

:: ================================================ Option Bytes and flash programming ====================================================
set current_log_file=%ob_flash_log%
set "action=Programming the option bytes and flashing the images ..."
set "command=start /w /b call %ob_flash_programming% AUTO"
echo    * %action%
%command% > %ob_flash_log%

set ob_flash_error=!errorlevel!
::type %ob_flash_log%
if %ob_flash_error% neq 0 goto :step_error

echo        Successful option bytes programming and images flashing
echo        (see %ob_flash_log% for details)
echo;
:: ================================================ Final product state selection =========================================================  
:product_state_choice
for /f %%A in ('"prompt $H & echo on & for %%B in (1) do rem"') do set "BS=%%A"
set "action=Define product state value"
echo    * %action%
set /p "product_state=%BS%       [ OPEN | PROVISIONED | TZ-CLOSED | CLOSED | LOCKED ]: "
echo;

if /I "%product_state%" == "OPEN" (
set ps_value=0xED
goto connect_boot0 
)

if /i "%product_state%" == "PROVISIONED" ( 
set ps_value=0x2E
goto set_provisionning_ps
)

if /i "%product_state%" == "TZ-CLOSED" (
set ps_value=0xC6
goto set_provisionning_ps
)

if /i "%product_state%" == "CLOSED" (
set ps_value=0x72
goto set_provisionning_ps
)

if /i "%product_state%" == "LOCKED" (
set ps_value=0x5C
goto set_provisionning_ps
)

echo        WRONG product state selected
set current_log_file="./*.log files "
echo;
goto product_state_choice


:: ========================================= Product State configuration and Provisioning steps ==========================================   
:: Connect BOOT0 pin to VDD (CN4 pin5 & pin7) 
:connect_boot0
echo    * BOOT0 pin connected to VDD
echo        (STM32H573I-DK: set SW1 to position 1)
echo        Press any key to continue...
echo;
if [%1] neq [AUTO] pause >nul
goto provisioning_step

:: Provisioning execution 
:set_provisionning_ps
set current_log_file=%provisioning_log%
set "action=Setting the product state PROVISIONING"
echo    * %action%
set "command=%stm32programmercli% %connect_no_reset% -ob PRODUCT_STATE=0x17"
echo %command% >> %provisioning_log%
echo;
%command% > %provisioning_log%
if !errorlevel! neq 0 goto :step_error 
goto provisioning_step

:: Set the final product state of the STM32H5 product
:set_final_ps
set current_log_file=%provisioning_log%
set "action=Setting the final product state %product_state% "
echo    * %action%
set "command=%stm32programmercli% %connect_no_reset% -ob PRODUCT_STATE=%ps_value%"
echo %command% >> %provisioning_log%
echo;
%command% >> %provisioning_log%
echo.
:: In the final product state, the connection with the board is lost and the return value of the command cannot be verified
goto final_execution

:: Provisioning the obk files step
:provisioning_step
set current_log_file=%ob_key_provisioning_log%
set "action=Provisionning the .obk files ..."
echo    * %action%
set "command=start /w /b call %ob_key_provisioning% AUTO"
%command% > %ob_key_provisioning_log%
set obkey_prog_error=!errorlevel!
if %obkey_prog_error% neq 0 goto :step_error

echo        Successful obk provisioning
echo        (see %ob_key_provisioning_log% for details)
echo;
if /i "%product_state%" == "OPEN" goto :final_execution
goto set_final_ps

:: ============================================================= End functions =============================================================  
:: All the steps to set the STM32H5 product were executed correctly
:final_execution
echo =====
echo ===== The board is correctly configured.
if "%isGeneratedByCubeMX%" == "true" goto :no_menu
echo ===== Connect UART console (11500 baudrate) to get application menu.

:no_menu
echo ===== Power off/on the board to start the application.
echo =====
if [%1] neq [AUTO] cmd /k
exit 0

:: Error when external script is executed
:step_error
echo;
echo =====
echo ===== Error while executing "%action%".
echo ===== See %current_log_file% for details. Then try again.
echo =====
cmd /k
exit 1
