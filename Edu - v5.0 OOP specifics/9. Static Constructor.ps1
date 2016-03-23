 class Bus
 {
     # Static variable used by all Bus instances.
     # Represents the time the first bus of the day starts its route.
     static [DateTime] $GlobalStartTime;

     # Property for the number of each bus.
     [int] $RouteNumber;

     # Static constructor to initialize the static variable.
     # It is invoked before the first instance constructor is run.
     static Bus()
     {
         [Bus]::GlobalStartTime = [DateTime]::Now;

         # The following statement produces the first line of output, 
         # and the line occurs only once.
         Write-Host "Static constructor sets global start time to $([Bus]::GlobalStartTime.ToLongTimeString())"
     
     }
     # Instance constructor.
     Bus([int] $RouteNumber)
     {
         $this.RouteNumber = $RouteNumber;
         Write-Host "Bus #$($this.RouteNumber) is created.";
     }

     # Instance method.
     [void] Drive()
     {
         [TimeSpan] $ElapsedTime = [DateTime]::Now - [Bus]::globalStartTime;

         Write-Host $("{0}, is starting its route {1:N2} seconds after global start time {2}." -f 
                        $this.RouteNumber,
                        $ElapsedTime.TotalSeconds,
                        $([Bus]::GlobalStartTime.ToShortTimeString()) )           
     }
 }

$bus1 = [Bus]::new(71)
$bus2 = [Bus]::new(72)

$bus1.Drive()

$bus2.Drive()

<# Output should be:

Static constructor sets global start time to 4:26:28 PM
Bus #71 is created.
Bus #72 is created.
71, is starting its route 0.03 seconds after global start time 4:26 PM.
72, is starting its route 0.03 seconds after global start time 4:26 PM.

#>