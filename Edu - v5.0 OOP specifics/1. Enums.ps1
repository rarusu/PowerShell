enum ColorEnum
{
    Yellow;
    White;
    Grey;
}

[ColorEnum]$NewColor = "White"
$NewColor
$NewColor.GetType()

class Template
{
    [ColorEnum] $myFavColor
}

$Template = [Template]::new()

#Should work
$Template.myFavColor = "White"

#Should generate an exception, because Black is not part of the enumeration
$Template.myFavColor = "Black"