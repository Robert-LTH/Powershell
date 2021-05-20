function Get-CustomUnattendXML {
    param(
        $Organization = ".",
        $Owner = ".",
        $Timezone = "W. Europe Standard Time",
        $AdminPassword = "P@ssw0rd",
        $isAdminPasswordPlaintext = 'true',
        $InputLocale = "041d:0000041d",
        $WorkgroupName = "Automata"
    )


@"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="specialize">
        <component name="Microsoft-Windows-UnattendedJoin" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" 
            xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <Identification>
                <JoinDomain></JoinDomain>
                <JoinWorkgroup>$WorkgroupName</JoinWorkgroup>
                <MachineObjectOU></MachineObjectOU>
            </Identification>
        </component>
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" 
            xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" 
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Description>EnableAdmin</Description>
                    <Order>1</Order>
                    <Path>cmd /c net user Administrator /active:yes</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Description>UnfilterAdministratorToken</Description>
                    <Order>2</Order>
                    <Path>cmd /c reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v FilterAdministratorToken /t REG_DWORD /d 0 /f</Path>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" 
            xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" 
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>$InputLocale</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UserLocale>sv-SE</UserLocale>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" 
            xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" 
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <CopyProfile>false</CopyProfile>
            <TimeZone>$Timezone</TimeZone>
        </component>
        <component name="Microsoft-Windows-SystemRestore-Main" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" 
            xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" 
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <DisableSR>1</DisableSR>
        </component>
        <component name="Microsoft-Windows-WiFiNetworkManager" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" 
            xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" 
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <WiFiSenseAllowed>0</WiFiSenseAllowed>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" 
            xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <UserAccounts>
                <AdministratorPassword>
                    <Value>$AdminPassword</Value>
                    <PlainText>$isAdminPasswordPlaintext</PlainText>
                </AdministratorPassword>
            </UserAccounts>
            <OOBE>
                <SkipMachineOOBE>true</SkipMachineOOBE>
                <SkipUserOOBE>true</SkipUserOOBE>
                <HideEULAPage>true</HideEULAPage>
                <ProtectYourPC>3</ProtectYourPC>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
            </OOBE>
            <RegisteredOrganization>$Organization</RegisteredOrganization>
            <RegisteredOwner>$Owner</RegisteredOwner>
            <TimeZone>$Timezone</TimeZone>
        </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" 
            xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" 
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>$InputLocale</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UserLocale>sv-SE</UserLocale>
        </component>
    </settings>
    <cpi:offlineImage cpi:source="wim://cm2012r2/pkgshare$/os%20deployment/os/wim%20files/win%2010%20enterprise/install.wim#Windows 10 Enterprise" 
        xmlns:cpi="urn:schemas-microsoft-com:cpi" />
</unattend>
"@
}
