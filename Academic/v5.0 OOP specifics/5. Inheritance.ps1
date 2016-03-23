class Shape
{ 
    [int] $Height;
    [int] $Width;

    [void] Draw()
    {
        Write-Host "Performing base class drawing tasks";
    }
}

class Circle : Shape
{
    [String] $CircleProp;   
}

class Rectangle : Shape
{
    [String] $RectangleProp;   
}

$Circle = [Circle]::new()
$Circle | gm

$Rectangle = [Rectangle]::new()
$Rectangle | gm
