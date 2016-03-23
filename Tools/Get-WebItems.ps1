<#
.Synopsis
   Download bulk files from the web, just like using wget. Also has the ability to do a recursive download.
.EXAMPLE
   Get-WebItems -URI http://download.bitdefender.com/ -Path $env:USERPROFILE\Downloads\ -Recursive:$false
.EXAMPLE
   Get-WebItems -URI http://ftp.freebsd.org/pub/FreeBSD/README.TXT -Path $env:USERPROFILE\Downloads\README.TXT 
#>
function Get-WebItems
{
    [CmdletBinding()]                  
    Param
    (
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][string]$Path,
        [switch]$Recursive = $true
    )

    if (!(Test-Path -Path $Path))
    {
        New-Item -ItemType Directory -Path $Path -EA Stop
    }
    
    Write-Verbose "Getting content from $Uri"
    $r = Invoke-WebRequest -URI $Uri -Verbose:$false -EA Stop

    $Links = $r.links.href | select -Skip 5
    Write-Verbose "We found the following items: $Links"

    foreach ($Link in $Links)
    {
        $FullLink = -join("$Uri","/","$Link")
        $FullPath = Join-Path $path -ChildPath $Link
        
        if (!$Link.endswith("/"))
        {
            Write-Verbose "Item $Link is a file."
            Write-Verbose "Copy from: $FullLink"
            Write-Verbose "Copy to: $FullPath"

            if (!(Test-Path -Path $FullPath))
            {
                Invoke-WebRequest -Uri $FullLink -OutFile $FullPath -Verbose:$false
            }
            else
            {
                Write-Warning "Item $Link already exists in $FullPath"
            }
        }
        else
        {
            Write-Verbose "Item $link is a folder."

            if ($Recursive)
            {
                Write-Verbose "Copy from: $FullLink"
                Get-WebItems -Uri $FullLink -Path $FullPath
            }
            else
            {
                Write-Warning "Skipping folder $Link because recursivity is not enabled"
            }
        }
    }
}