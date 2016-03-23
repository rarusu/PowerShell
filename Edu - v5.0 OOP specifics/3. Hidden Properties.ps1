class Template
{
    [String] $VisibleProp;
    hidden [String] $HiddenProp;
}

$Template = [Template]::new()

#Will show only the visible property
$Template | gm -MemberType Property

"`n"

#Will show all properties
$Template | gm -MemberType Property -Force

#Both properties have the default {get; set;}