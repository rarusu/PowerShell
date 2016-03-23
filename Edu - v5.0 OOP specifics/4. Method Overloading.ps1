class WinProcess
{   
    [Void] StopProcess([String] $Name)
    {
        Stop-Process -Name $Name
    }

    [Void] StopProcess([Int32] $Id)
    {
        Stop-Process -Id $Id
    }
}


$WinProcess = [WinProcess]::new()
$WinProcess.StopProcess

$proc = Start-Process notepad -PassThru
$WinProcess.StopProcess($proc.id)

$proc = Start-Process notepad -PassThru

#Warning, this command will kill every process named notepad
$WinProcess.StopProcess($proc.name)