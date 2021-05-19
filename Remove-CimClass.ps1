function Remove-CimClass {
    param(
        $ComputerName = ".",
        $Namespace,
        $ClassName
    )
    try {
        $PathString = "\\{0}\{1}:{2}" -f $ComputerName,$Namespace,$ClassName
        $MgmtPath = [System.Management.ManagementPath]::new($PathString)
    } catch {
        Write-Error "Failed to create a ManagementPath object using '$PathString'"
        return
    }
    if ($MgmtPath.IsClass) {
        try {
            $MgmtClass = [System.Management.ManagementClass]::new($MgmtPath)
            $MgmtClass.Get()
            try {
                $MgmtClass.Delete()
            } catch {
                Write-Error "Failed to delete class: $_"    
            }
        } catch {
            Write-Error "Failed to create ManagementClass object."
            return
        }
    }
    else {
        Write-Error "ManagementPath does not point to a class!"
    }
}
