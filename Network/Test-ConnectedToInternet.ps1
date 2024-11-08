# Guid is Network List Manager (https://github.com/nihon-tc/Rtest/blob/master/header/Microsoft%20SDKs/Windows/v7.0A/Include/netlistmgr.idl)
$NLMType = [Type]::GetTypeFromCLSID('DCB00C01-570F-4A9B-8D69-199FDBA5723B')
$INetworkListManager = [Activator]::CreateInstance($NLMType)
$IsConnectedToInternet = $INetworkListManager.IsConnectedToInternet
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($INetworkListManager) | Out-Null
return $IsConnectedToInternet
