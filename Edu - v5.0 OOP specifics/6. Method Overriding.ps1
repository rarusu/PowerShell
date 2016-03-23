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
	([Shape]$this).Draw(); #Call base method
        
	Write-Host "Drawing a circle"; 
    }
}

class Rectangle : Shape
{
    [Void] Draw()
    {
	([Shape]$this).Draw(); #Call base method

        Write-Host "Drawing a Rectangle";        
    }
}

class Triangle : Shape
{
    [Void] Draw()
    {
        ([Shape]$this).Draw(); #Call base method

	Write-Host "Drawing a Triangle";
    }
}