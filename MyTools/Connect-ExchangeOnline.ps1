<#
.Synopsis
   Connects to the Exchange Online service from an Office 365 subscription.
.DESCRIPTION
   No longer should you copy paste from the Internet the whole set of commands for establishing the connection to Exchange Online. You can now simply type Connect-ExchangeOnline. Remember to first import the function by dot sourcing the script. From PowerShell, run: . .\desktop\connect-exchangeonline.ps1 
.EXAMPLE
   Connect-ExchangeOnline
.EXAMPLE
   Connect-ExchangeOnline -Credential john@contoso.com -SessionOption:$true
.INPUTS
   No pipeline for the moment
#>
function Connect-ExchangeOnline
{
    [cmdletBinding()]
    param
    (
        [Parameter(Mandatory=$True)][PSCredential]$Credential,
        [switch]$SessionOption=$false
    )
    
    $NewPSSessionArguments = @{
                ConfigurationName = "Microsoft.Exchange"
                ConnectionUri     = "https://outlook.office365.com/powershell-liveid/"
                Credential        = $Credential
                Authentication    = "Basic"
                AllowRedirection  = $True
                               }
    if ($SessionOption)
    {
        #Maybe optional, depends if you have proxy or not
        $SessionOption = New-PSSessionOption -ProxyAccessType IEConfig
        $NewPSSessionArguments.Add("SessionOption", $SessionOption)
    }

    while ($Session -eq $null)
    {
        try
        {	
            $Session = New-PSSession @NewPSSessionArguments -EA Stop
        }
        catch [System.Management.Automation.Remoting.PSRemotingTransportException]
        {
            Write-Warning "Could not build session because of an Access Denied exception. Please check your credentials"
            $RetryCredentialAnswer = "Y"
            $RetryCredentialAnswer = Read-Host "Do you wish to retry entering your credentials ? [Y/N]"

            if ($RetryCredentialAnswer -eq "Y")
            {
                $Credential = Get-Credential
                $NewPSSessionArguments.Set_Item("Credential", $Credential)
            }
            else
            {
                throw "Execution of script was cancelled by user"
            }
        }
        catch
        {
            Write-Warning "Could not build session"
        }

    }
    try
    {
        $ExchangeModule = Import-PSSession -Session $Session -AllowClobber -EA Stop -WarningAction SilentlyContinue
    }
    catch
    {
        Write-Warning "Could not import session"
    }

    Import-Module -ModuleInfo $ExchangeModule -Global -PassThru
}


