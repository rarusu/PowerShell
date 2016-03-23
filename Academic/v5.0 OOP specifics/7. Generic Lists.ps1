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
    [Void] Draw()
    {
	([Shape]$this).Draw(); 
        
	Write-Host "Drawing a circle"; 
    }
}

class Rectangle : Shape
{
    [Void] Draw()
    {
	([Shape]$this).Draw();

        Write-Host "Drawing a Rectangle";        
    }
}

class Triangle : Shape
{
    [Void] Draw()
    {
        ([Shape]$this).Draw();

	Write-Host "Drawing a Triangle";
    }
}


$Shapes = [System.Collections.Generic.List[Shape]]::new()

$Shapes.Add([Rectangle]::new())
$Shapes.Add([Circle]::new())
$Shapes.Add([Triangle]::new())

foreach ($Shape in $Shapes)
{
    $Shape.Draw();
}