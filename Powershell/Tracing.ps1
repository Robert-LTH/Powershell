<#
  https://learn-powershell.net/2013/05/07/tips-on-implementing-pipeline-support/
#>
Get-TraceSource

Trace-Command -Name parameterbinding {
    FunctionToTrace
} -PSHost
