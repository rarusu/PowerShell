class WinProcess
{   
    static [Int32] $Zero = 0;
    
    [Void] static StopProcess([String] $Name)
    {
        Stop-Process -Name $Name
    }

    [Void] static StopProcess([Int32] $Id)
    {
        Stop-Process -Id $Id
    }
}


[WinProcess] | gm -Static

[WinProcess]::Zero
[WinProcess]::StopProcess
