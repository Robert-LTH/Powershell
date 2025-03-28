$CimSession = New-CimSession
$params = New-Object Microsoft.Management.Infrastructure.CimMethodParametersCollection
$instance = Get-CimInstance -Namespace root\cimv2\mdm\dmmap -ClassName MDM_EnterpriseModernAppManagement_AppManagement01
$CimSession.InvokeMethod("root\cimv2\mdm\dmmap", $instance, "UpdateScanMethod", $params)
