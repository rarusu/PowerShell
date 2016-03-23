<#
"Write a program that prints the numbers from 1 to 100. 

But for multiples of three print “Fizz” instead of the number and for the multiples of five print “Buzz”. 

For numbers which are multiples of both three and five print “FizzBuzz”."
#>

Measure-Command {

    function Convert
    {
        param 
        (
            [Hashtable]$Hash = @{3 = "Fizz"; 5 = "Buzz" }
        )
        Begin
        {
            $Items = $Hash.GetEnumerator().Name | sort
        }
        Process
        {
            $Output = $null

            foreach ($Item in $Items)
            {
                if ($_ % $Item -eq 0)
                {
                    $Output += $Hash.($Item)
                }
            }

            if ($Output -eq $null)
            {
                $Output = $_
            }

            return $Output
        }
    }


    1..100 | Convert -Hash $Hash

}