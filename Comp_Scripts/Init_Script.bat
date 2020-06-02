
@echo off 

::HAS NOT BEEN TESTED

::Admin Check
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Success: Administrative permissions confirmed.

    ::COMMANDS USED
    ::reg add <KeyName> [{/v ValueName | /ve}] [/t DataType] [/s Separator] [/d Data] [/f]:
    ::SC [\\server] [command] [service_name] [Options]
    ::ipconfig

    ::ENABLE...
    ::Enable UAC
    reg ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f 
    ::Enable Smart Screen in EDGE/IE/AppHost Explorer
    REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d "On"
    REG ADD "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\ Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\PhishingFilter" /v EnabledV9 /t REG_DWORD /d 1
    REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\AppHost" /v EnableWebContentEvaluation /t REG_DWORD /d 1
    ::Keystroke on startup


    ::DISABLE...
    ::Disable RDP
    reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal" Server /v fDenyTSConnections /t REG_DWORD /d 1 /f
    ::Automatic Updating
    ::Remote Registry
    ::Telephony
    ::other remote access
    ::/Prevent/ Dump file creation
    ::AutoRun
    ::NetBIOS

    ::REMOVE...
    ::GUEST ACCOUNT


    ::CLEAN...
    ::Clean DNS Cache
    ipconfig /flushdns
    ::Clean HOSTS File

    ::Clean credentials
    ::pwd cache




    ::LOGIC BASED
    ::Admin Logic
        ::Check is ADMINSTRATOR exists
            ::Check if an Admin
    ::Firewall Rules
    ::Windows Features/Services
    ::Common Group Policies
    ::De-Bloating


    ::+++++++REPORTS++++++++
    ::write out current running services to servicesstarted.txt
    ::System File Checker


) 
else (
    echo Failure: Current permissions inadequate.
)

     