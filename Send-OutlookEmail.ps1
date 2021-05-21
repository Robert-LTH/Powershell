# Send email and add a reply-to address using outlook comobject
function Send-OutlookEmail {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
        [string]$recepient,
        [string]$Subject,
        [string]$Body,
        [string]$To
    )
    begin {
        if (-not $OutlookApplication) {
            $OutlookApplication = New-Object -ComObject Outlook.Application
        }
    }
    process {
        try {
            $Mail = $OutlookApplication.CreateItem("olMailItem")
            $Mail.Subject = $Subject
            $Mail.Body = $Body
            $Mail.To = $To
            $Mail.ReplyRecipients.Add($recepient)
            $Mail.Send()
            while (-not $Mail.Sent) {
                Start-Sleep -Seconds 2
                $Mail
            }
            $Mail = $null
        } catch {
            Write-Host "Failed to send email to '': $_"
        }
    }
    end {
        $OutlookApplication.Quit()
        $OutlookApplication = $null
    }
}
