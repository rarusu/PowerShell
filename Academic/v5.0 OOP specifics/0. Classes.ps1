class Shape
{ 
    #region Properties
    [int] $Height;
    [int] $Width;
    #endregion

    #region Constructors
    Shape($argHeight, $argWidth)
    {
        #Reference Members of the class by using the keyword $this
        $this.Height = $argHeight
        $this.Width  = $argWidth
    }
    #endregion

    #region Methods
    [void] Draw()
    {
        #Implementation
        Write-Host "Performed base class drawing tasks";
    }

    [String] GetSomething()
    {
        #Implementation
        return "This is a string"
    }
    #endregion

} # END class Shape


$Shape = [Shape]::new(10,2)

$Shape.Draw()

$Shape