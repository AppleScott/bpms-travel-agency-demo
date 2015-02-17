@ECHO OFF
setlocal

set PROJECT_HOME=%~dp0
set DEMO=Travel Agency Demo
set AUTHORS=Nirja Patel, Shepherd Chengeta, Andrew Block,
set AUTHORS2=Eric D. Schabell
set PROJECT=git@github.com:jbossdemocentral/bpms-travel-agency-demo.git
set PRODUCT=JBoss BPM Suite & JBoss DV
set JBOSS_HOME=%PROJECT_HOME%target\jboss-eap-6.1
set JBOSS_HOME_DV=%PROJECT_HOME%target\jboss-eap-6.1.dv
set SERVER_DIR=%JBOSS_HOME%\standalone\deployments\
set SERVER_CONF=%JBOSS_HOME%\standalone\configuration\
set SERVER_CONF_DV=%JBOSS_HOME_DV%\standalone\configuration\
set SERVER_BIN=%JBOSS_HOME%\bin
set SERVER_BIN_DV=%JBOSS_HOME_DV%\bin
set SRC_DIR=%PROJECT_HOME%installs
set SUPPORT_DIR=%PROJECT_HOME%support
set PRJ_DIR=%PROJECT_HOME%projects
set BPMS=jboss-bpms-installer-6.0.3.GA-redhat-1.jar
set DV=jboss-dv-installer-6.1.0.Beta-redhat-1.jar
set VERSION=6.0.3
set DV_VERSION=6.1.0.Beta

REM wipe screen.
cls

echo.
echo ###################################################################
echo ##                                                               ##   
echo ##  Setting up the:                                              ##
echo ##                                                               ##   
echo ##             %DEMO%                  ##
echo ##                                                               ##   
echo ##                                                               ##   
echo ##          ####  ####   #   #   ###       ####  #   #           ##
echo ##          #   # #   # # # # # #      #   #   # #   #           ##
echo ##          ####  ####  #  #  #  ##   ###  #   # #   #           ##
echo ##          #   # #     #     #    #   #   #   #  # #            ##
echo ##          ####  #     #     # ###        ####    #             ##
echo ##                                                               ##   
echo ##                                                               ##   
echo ##  brought to you by,                                           ##   
echo ##                                                               ##   
echo ##           %AUTHORS%       ##
echo ##           %AUTHORS2%                         ##
echo ##                                                               ##
echo ##  %PROJECT%  ##
echo ##                                                               ##
echo ###################################################################
echo.

REM make some checks first before proceeding.	
if exist %SRC_DIR%\%BPMS% (
        echo Product sources are present...
        echo.
) else (
        echo Need to download %BPMS% package from the Customer Support Portal
        echo and place it in the %SRC_DIR% directory to proceed...
        echo.
        GOTO :EOF
)

if exist %SRC_DIR%\%DV% (
	echo JBoss product sources, %DV% present...
	echo.
) else (
	echo Need to download %DV% package from the Customer Support Portal and place it in the %SRC_DIR% directory to proceed...
	echo.
	GOTO :EOF
)

REM Remove existing installation.
if exist %JBOSS_HOME% (
         echo - existing JBoss product install removed...
         echo.
         rmdir /s /q target"
 )

REM Run DV installer.
echo Product installer running now...
echo.
call java -jar %SRC_DIR%\%DV% %SUPPORT_DIR%\installation-dv 

if not "%ERRORLEVEL%" == "0" (
	echo Error Occurred During DV Installation!
  echo.
  GOTO :EOF
)

REM Move DV install aside for BPM Suite.
move "%JBOSS_HOME%" "%JBOSS_HOME_DV%"

echo.
echo   - install teiid security files...
echo.
xcopy /Y /Q /S "%SUPPORT_DIR%\teiid*" "%SERVER_CONF_DV%"

echo.
echo   - move data files...
echo.
xcopy /Y /Q /S "%SUPPORT_DIR%\teiidfiles\data\*" "%JBOSS_HOME_DV%\standalone\data"

echo.
echo   - move virtual database...
echo.
xcopy /Y /Q "%SUPPORT_DIR%\teiidfiles\vdb" "%JBOSS_HOME_DV%\standalone\deployments"

echo   - setting up dv standalone.xml configuration adjustments...
echo.
xcopy /Y /Q "%SUPPORT_DIR%\teiidfiles\standalone.dv.xml" "%SERVER_CONF_DV%\standalone.xml"

REM Run installer BPM Suite.
echo.
echo Product installer running now...
echo.
call java -jar %SRC_DIR%/%BPMS% %SUPPORT_DIR%\installation-bpms -variablefile %SUPPORT_DIR%\installation-bpms.variables

if not "%ERRORLEVEL%" == "0" (
  echo.
	echo Error Occurred During %PRODUCT% Installation!
	echo.
	GOTO :EOF
)

echo.
echo - setting up demo projects...
echo.

echo - enabling demo accounts role setup in application-roles.properties file...
echo.
xcopy /Y /Q "%SUPPORT_DIR%\application-roles.properties" "%SERVER_CONF%"
echo. 

mkdir "%SERVER_BIN%\.niogit\"
xcopy /Y /Q /S "%SUPPORT_DIR%\bpm-suite-demo-niogit\*" "%SERVER_BIN%\.niogit\"
echo. 

echo.
echo - setting up web services...
echo.
call mvn clean install -f %PRJ_DIR%/pom.xml
xcopy /Y /Q "%PRJ_DIR%\acme-demo-flight-service\target\acme-flight-service-1.0.war" "%SERVER_DIR%"
xcopy /Y /Q "%PRJ_DIR%\acme-demo-hotel-service\target\acme-hotel-service-1.0.war" "%SERVER_DIR%"

echo.
echo - adding acmeDataModel-1.0.jar to business-central.war/WEB-INF/lib
xcopy /Y /Q %PRJ_DIR%\acme-data-model\target\acmeDataModel-1.0.jar %SERVER_DIR%\business-central.war\WEB-INF\lib

echo.
echo - deploying external-client-ui-form-1.0.war to EAP deployments directory
xcopy /Y /Q %PRJ_DIR%\external-client-ui-form\target\external-client-ui-form-1.0.war %SERVER_DIR%

echo.
echo - setting up standalone.xml configuration adjustments...
echo.
xcopy /Y /Q "%SUPPORT_DIR%\standalone.xml" "%SERVER_CONF%"
echo.

echo.
echo - updating the CustomWorkItemHandler.conf file to use the appropriate email server...
xcopy /Y /Q %SUPPORT_DIR%\CustomWorkItemHandlers.conf %SERVER_DIR%\business-central.war\WEB-INF\classes\META-INF\

REM Optional: uncomment this to install mock data for BPM Suite
REM
REM echo - setting up mock bpm dashboard data...
REM echo.
REM xcopy /Y /Q "%SUPPORT_DIR%\1000_jbpm_demo_h2.sql" "%SERVER_DIR%\dashbuilder.war\WEB-INF\etc\sql"
REM echo.

REM Final instructions to user to start and run demo.
echo.
echo ==============================================================================
echo =                                                                            = 
echo =  Start JBoss BPM Suite server:                                             =
echo =                                                                            = 
echo =    %SERVER_BIN%\standalone.bat -Djboss.socket.binding.port-offset=100    =
echo =                                                                            = 
echo =  In seperate terminal start JBoss DV server:                               =
echo =                                                                            = 
echo =    %SERVER_BIN_DV%\standalone.bat                                          =
echo =                                                                            = 
echo =                                                                            = 
echo =  ******* BPM APP LEVERAGES DV DATA SOURCES SCENARIO ********               =
echo =                                                                            = 
echo =  Login to business central to build ^& deploy BRMS rules project at:       =
echo =                                                                            = 
echo =    http://localhost:8180/business-central                                  =
echo =                    user: erics / password: bpmsuite1!        =
echo =                                                                            = 
echo =  As a developer you have an application project simulated as a unit test   =
echo =  in projects/brmsquickstart/helloworld-brms which you can run with the     =
echo =  maven command:                                                            =
echo =                                                                            = 
echo =  View the DV setup:                                                        =
echo =                                                                            =
echo =    TODO: detail or point to doc that does.                                 =
echo =                                                                            =
echo =   %DEMO% Setup Complete.                                              =
echo =                                                                            =
echo ==============================================================================
echo.
