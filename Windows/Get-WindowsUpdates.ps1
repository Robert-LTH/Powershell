#$ScriptToRun = {
function Get-WUResult {
    param(
        $HResult
    )
    $ErrorEnumode = @"
    public enum HResults : uint
    {
        WU_E_NO_SERVICE = 0x80240001, // Windows Update Agent was unable to provide the service.
        WU_E_MAX_CAPACITY_REACHED = 0x80240002, // The maximum capacity of the service was exceeded.
        WU_E_UNKNOWN_ID = 0x80240003, // An ID cannot be found.
        WU_E_NOT_INITIALIZED = 0x80240004, // The object could not be initialized.
        WU_E_RANGEOVERLAP = 0x80240005, // The update handler requested a byte range overlapping a previously requested range.
        WU_E_TOOMANYRANGES = 0x80240006, // The requested number of byte ranges exceeds the maximum number (2^31 - 1).
        WU_E_INVALIDINDEX = 0x80240007, // The index to a collection was invalid.
        WU_E_ITEMNOTFOUND = 0x80240008, // The key for the item queried could not be found.
        WU_E_OPERATIONINPROGRESS = 0x80240009, // Another conflicting operation was in progress. Some operations such as installation cannot be performed twice simultaneously.
        WU_E_COULDNOTCANCEL = 0x8024000A, // Cancellation of the operation was not allowed.
        WU_E_CALL_CANCELLED = 0x8024000B, // Operation was cancelled.
        WU_E_NOOP = 0x8024000C, // No operation was required.
        WU_E_XML_MISSINGDATA = 0x8024000D, // Windows Update Agent could not find required information in the update's XML data.
        WU_E_XML_INVALID = 0x8024000E, // Windows Update Agent found invalid information in the update's XML data.
        WU_E_CYCLE_DETECTED = 0x8024000F, // Circular update relationships were detected in the metadata.
        WU_E_TOO_DEEP_RELATION = 0x80240010, // Update relationships too deep to evaluate were evaluated.
        WU_E_INVALID_RELATIONSHIP = 0x80240011, // An invalid update relationship was detected.
        WU_E_REG_VALUE_INVALID = 0x80240012, // An invalid registry value was read.
        WU_E_DUPLICATE_ITEM = 0x80240013, // Operation tried to add a duplicate item to a list.
        WU_E_INSTALL_NOT_ALLOWED = 0x80240016, // Operation tried to install while another installation was in progress or the system was pending a mandatory restart.
        WU_E_NOT_APPLICABLE = 0x80240017, // Operation was not performed because there are no applicable updates.
        WU_E_NO_USERTOKEN = 0x80240018, // Operation failed because a required user token is missing.
        WU_E_EXCLUSIVE_INSTALL_CONFLICT = 0x80240019, // An exclusive update cannot be installed with other updates at the same time.
        WU_E_POLICY_NOT_SET = 0x8024001A, // A policy value was not set.
        WU_E_SELFUPDATE_IN_PROGRESS = 0x8024001B, // The operation could not be performed because the Windows Update Agent is self-updating.
        WU_E_INVALID_UPDATE = 0x8024001D, // An update contains invalid metadata.
        WU_E_SERVICE_STOP = 0x8024001E, // Operation did not complete because the service or system was being shut down.
        WU_E_NO_CONNECTION = 0x8024001F, // Operation did not complete because the network connection was unavailable.
        WU_E_NO_INTERACTIVE_USER = 0x80240020, // Operation did not complete because there is no logged-on interactive user.
        WU_E_TIME_OUT = 0x80240021, // Operation did not complete because it timed out.
        WU_E_ALL_UPDATES_FAILED = 0x80240022, // Operation failed for all the updates.
        WU_E_EULAS_DECLINED = 0x80240023, // The license terms for all updates were declined.
        WU_E_NO_UPDATE = 0x80240024, // There are no updates.
        WU_E_USER_ACCESS_DISABLED = 0x80240025, // Group Policy settings prevented access to Windows Update.
        WU_E_INVALID_UPDATE_TYPE = 0x80240026, // The type of update is invalid.
        WU_E_URL_TOO_LONG = 0x80240027, // The URL exceeded the maximum length.
        WU_E_UNINSTALL_NOT_ALLOWED = 0x80240028, // The update could not be uninstalled because the request did not originate from a WSUS server.
        WU_E_INVALID_PRODUCT_LICENSE = 0x80240029, // Search may have missed some updates before there is an unlicensed application on the system.
        WU_E_MISSING_HANDLER = 0x8024002A, // A component required to detect applicable updates was missing.
        WU_E_LEGACYSERVER = 0x8024002B, // An operation did not complete because it requires a newer version of server.
        WU_E_BIN_SOURCE_ABSENT = 0x8024002C, // A delta-compressed update could not be installed because it required the source.
        WU_E_SOURCE_ABSENT = 0x8024002D, //  A full-file update could not be installed because it required the source.
        WU_E_WU_DISABLED = 0x8024002E, // Accss to an unmanaged server is not allowed.
        WU_E_CALL_CANCELLED_BY_POLICY = 0x8024002F, // Operation did not complete because the DisableWindowsUpdateAccess policy was set.
        WU_E_INVALID_PROXY_SERVER = 0x80240030, // The format of the proxy list was invalid.
        WU_E_INVALID_FILE = 0x80240031, // The file is in the wrong format.
        WU_E_INVALID_CRITERIA = 0x80240032, // The search criteria string was invalid.
        WU_E_EULA_UNAVAILABLE = 0x80240033, // License terms could not be downloaded.
        WU_E_DOWNLOAD_FAILED = 0x80240034, // Update failed to download.
        WU_E_UPDATE_NOT_PROCESSED = 0x80240035, // The update was not processed.
        WU_E_INVALID_OPERATION = 0x80240036, // The object's current state did not allow the operation.
        WU_E_NOT_SUPPORTED = 0x80240037, // The functionality for the operation is not supported.
        WU_E_WINHTTP_INVALID_FILE = 0x80240038, // The downloaded file has an unexpected content type.
        WU_E_TOO_MANY_RESYNC = 0x80240039, // Agent is asked by server to resync too many times.
        WU_E_NO_SERVER_CORE_SUPPORT = 0x80240040, //  WUA API method does not run on Server Core installation.
        WU_E_SYSPREP_IN_PROGRESS = 0x80240041, // Service is not available while sysprep is running.
        WU_E_UNKNOWN_SERVICE = 0x80240042, // The update service is no longer registered with AU.
        WU_E_UNEXPECTED = 0x80240FFF, // An operation failed due to reasons not covered by another error code.
    };
"@
    if (-not ([Management.Automation.PSTypeName]"HResult")) {
        add-type -TypeDefinition $ErrorEnumode -ErrorAction SilentlyContinue
    }
    if ($HResult) {
        try {
            $HexHResult = [Convert]::ToUInt32($HResult,16)
        }
        catch {
            return
        }
        [HResults].GetEnumName($HexHResult)
        switch ([HResults].GetEnumName($HexHResult)) {
            "WU_E_NO_UPDATE" {
                Write-Host "No updates to process."
                return $false
            }
            "WU_E_INVALID_CRITERIA" {
                Write-Host "Invalid search parameters."
                return $false
            }
            "WU_E_NOT_INITIALIZED" {
                Write-Host "The object has not been initialized. Updates already downloaded?"
            }
            default {
                Write-Host "'$HResult' has not been defined"
            }
        }
    }
}
<#
	"BrowseOnly=1" finds updates that are considered optional.
	"BrowseOnly=0" finds updates that are not considered optional.
	"IsAssigned=1" finds updates that are intended for deployment by Automatic Updates, which depends on the other query criteria. At most, one assigned Windows-based driver update is returned for each local device on a destination computer.
	"IsAssigned=0" finds updates that are not intended to be deployed by Automatic Updates.	
	"AutoSelectOnWebSites=1" finds updates that are flagged to be automatically selected by Windows Update.
	"AutoSelectOnWebSites=0" finds updates that are not flagged for Automatic Updates.
	"IsInstalled=1" finds updates that are installed on the destination computer.
	"IsInstalled=0" finds updates that are not installed on the destination computer.
	"IsHidden=1" finds updates that are marked as hidden on a destination computer. When you use this clause, you can set the UpdateSearcher.IncludePotentiallySupersededUpdates property to VARIANT_TRUE so that a search returns the hidden updates. The hidden updates might be superseded by other updates in the same results.
	"IsHidden=0" finds updates that are not marked as hidden. If the UpdateSearcher.IncludePotentiallySupersededUpdates property is set to VARIANT_FALSE, it is better to include that clause in the search filter string so that the updates that are superseded by hidden updates are included in the search results. VARIANT_FALSE is the default value.
	"IsPresent=1" finds updates that are present on a destination computer. If the update is valid for one or more products, the update is considered present if it is installed for one or more of the products.
	"IsPresent=0" finds updates that are not installed for any product on a destination computer.
	"RebootRequired=1" finds updates that require a computer to be restarted to complete an installation or uninstallation.
	"RebootRequired=0" finds updates that do not require a computer to be restarted to complete an installation or uninstallation.
	Type - Finds updates of a specific type, such as "'Driver'" and "'Software'".
	"DeploymentAction='Installation'" finds updates that are deployed for installation on a destination computer. "DeploymentAction='Uninstallation'" depends on the other query criteria.
	"DeploymentAction='Uninstallation'" finds updates that are deployed for uninstallation on a destination computer. "DeploymentAction='Uninstallation'" depends on the other query criteria.
	If this criterion is not explicitly specified, each group of criteria that is joined to an AND operator implies "DeploymentAction='Installation'".
#>

function Get-WindowsUpdates {
    param(
        [int]$BrowseOnly = -1,
        [int]$IsAssigned = -1,
        [int]$AutoSelectOnWebSites = -1,
        [int]$IsInstalled = -1,
        [int]$IsHidden = -1,
        [int]$IsPresent = -1,
        [int]$RebootRequired = -1,
        [ValidateSet('Driver','Software')]
        [string]$UpdateType,
        [ValidateSet('Uninstallation','Installation')]
        [string]$DeploymentAction,
        [switch]$DoInstall,
        [switch]$ForceQuiet,
        [string]$RunWizard,
        [switch]$Download
    )
    begin {
        try {
            $updSession = New-Object -com Microsoft.Update.Session
            $searcher = $updSession.CreateUpdateSearcher()
        } catch {}
        $SearchString = ""
        if ($BrowseOnly -le 1 -and $BrowseOnly -ge 0) {
            $SearchString += "BrowseOnly=$BrowseOnly and "
        }
        if ($IsAssigned -le 1 -and $IsAssigned -ge 0) {
            $SearchString += "IsAssigned=$IsAssigned and "
        }
        if ($AutoSelectOnWebSites -le 1 -and $AutoSelectOnWebSites -ge 0) {
            $SearchString += "AutoSelectOnWebSites=$AutoSelectOnWebsites and "
        }
        if ($IsHidden -le 1 -and $IsHidden -ge 0) {
            $SearchString += "IsHidden=$IsHidden and "
        }
        if ($IsInstalled -le 1 -and $IsInstalled -ge 0) {
            $SearchString += "IsInstalled=$IsInstalled and "
        }
        if ($IsPresent -le 1 -and $IsPresent -ge 0) {
            $SearchString += "IsPresent=$IsPresent and "
        }
        if ($RebootRequired -le 1 -and $RebootRequired -ge 0) {
            $SearchString += "RebootRequired=$RebootRequired and "
        }
        if ($UpdateType) {
            $SearchString += "Type=$UpdateType and "
        }
        $SearchString = $SearchString.Trim('and ')
        if ([string]::IsNullOrEmpty($SearchString)) {
            $SearchString = 'IsInstalled=0 and IsHidden=0'
        }
    }
    process {
        
        try {
            $SearchResult= $searcher.Search($SearchString)
            if ($SearchResult.Updates.Count -gt 0) {
                Write-Host "Found $($SearchResult.Updates.Count) updates"
            }
        } catch {
            if ($_ -Match "([0-9x]+)") {
                Get-WUResult -HResult (($Matches[1])) | Out-Null
            }
        }

        if ($SearchResult.ResultCode -eq 2 -or $SearchResult.ResultCode -eq 3) {
            if ($Download.IsPresent -or $DoInstall.IsPresent) {
                try {
                    $updDownload = $updSession.CreateUpdateDownloader()
                } catch {
                    throw "Failed to create downloader."
                }
                $updDownload.Updates = $SearchResult.Updates
                try {
                    Write-Host "Starting download"
                    $res = $updDownload.Download()
                    Get-WUResult $res.HResult
                    if ($res.HResult -eq 0x80240022) {
                        Write-Error "All update-related stuff failed"
                    }
                } catch {
                    if ($_ -Match "([0-9x]+)") {
                        Get-WUResult -HResult (($Matches[1])) | Out-Null
                    }
                }
            }
            if ($DoInstall.IsPresent) {
                try {
                    $installer = $updSession.CreateUpdateInstaller()
                } catch {
                    throw "Failed to create installer"
                }
                $installer.ForceQuiet = $true
                $installer.Updates = $updDownload.Updates
                if ($RunWizard.Length -gt 0) {
                    $installer.RunWizard($RunWizard)
                }
                else {
                    if (-not $installer.IsBusy) {
                        try {
                            Write-Host "Starting install"
                            $res = $installer.Install()
                            Get-WUResult $res.HResult
                            if ($res.HResult -eq 0x80240022) {
                                Write-Error "All update-related stuff failed"
                            }
                        }
                        catch {
                            if ($_ -Match "([0-9x]+)") {
                                Get-WUResult -HResult (($Matches[1])) | Out-Null
                            }
                        }
                    }
                }
            }
            $SearchResult.Updates
        }
    }
}
