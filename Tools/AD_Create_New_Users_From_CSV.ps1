#Have a users.csv file with the structure:

<#
    GivenName              :Ionut
    Surname                :COSMESCU
    Name                   :Ionut COSMESCU
    sAMAccountName         :icosmescu
    UserPrincipalName      :icosmescu@student.school.com
    AccountPassword        :pass123!
    Description            :Student
    Office                 :Grade 6
    Department             :MS
    HomeDrive              :Z:
    HomeDirectory          :\\myfiles\students\grade6\icosmescu20
    Path                   :"OU=ToBeAdded,OU=Students,dc=intranet,dc=school,dc=com"
    Group                  :"Students", "Domain Admins"
    DeployStatus           :
    DeployStatusFailReason :
#>

function Create-ADBulkUsers
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$True)]$CSV,
        [Parameter(Mandatory=$False)]$LogPath
    )

    #requires -module ActiveDirectory

    $Users = Import-Csv -Path $CSV

    $ADForest  = Get-ADForest
    $ADDomains = $ADForest.Domains + $ADForest.UPNSuffixes

    $ErrorUsers = @()


    foreach ($User in $Users)
    {
        # Handling the path
        try
        {
            Get-ADOrganizationalUnit -Identity $User.Path -EA Stop
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
        {
            Write-Warning "Cannot create user $($user.name) because of invalid path"
            $User.DeployStatus = "Fail"
            $User.DeployStatusFailReason = "Cannot find the specified path"
            $ErrorUsers += $User
        }

        # Handling the UPN
        foreach ($ADDomain in $ADDomains)
        {
            if ($User.UserPrincipalName -notlike "*@$ADDomain")
            {
                $User.DeployStatus = "Fail"
                $User.DeployStatusFailReason = "Incorrect UPN Suffix"
                $ErrorUsers += $User
            }
        }

        # Handling the sam
        if ($User.sAMAccountName.length -ge 20)
        {
            $User.DeployStatus = "Fail"
            $User.DeployStatusFailReason = "sAMAccountName exceeds the 20 character maximum limit"
            $ErrorUsers += $User
        }

        # Handling the uniqueness
        if (
             (Get-ADUser -Filter {UserPrincipalName -eq "$($User.UserPrincipalName)"})     -or
             (Get-ADUser -Filter {sAMAccountName    -eq "$($User.sAMAccountName)"})        -or
             (Get-ADUser -Filter {DistinguishedName -eq "CN=$($User.Name),$($User.path)"})
           )
        {
            $User.DeployStatus = "Fail"
            $User.DeployStatusFailReason = "A user with the same UPN or sAMAccountName already exists"
            $ErrorUsers += $User
        }


        if ($User.DeployStatus -ne "Fail")
        { 
            $SecurePassword = ConvertTo-SecureString -String $user.AccountPassword -AsPlainText -Force
   
            $NewADUserParams = @{
                                  Name                  = $User.Name               #1st part of the DistinguishedName
                                  Surname               = $User.Surname
                                  GivenName             = $User.GivenName 
                                  SamAccountName        = $User.sAMAccountName 
                                  UserPrincipalName     = $User.UserPrincipalName 
                                  EmailAddress          = $User.UserPrincipalName 
                                  Path                  = $User.Path
                                  AccountPassword       = $SecurePassword
                                  CannotChangePassword  = $True 
                                  PasswordNeverExpires  = $True 
                                  ChangePasswordAtLogon = $False 
                                  Enabled               = $True 
                                  Description           = $User.Description 
                                  Office                = $User.Office 
                                  Department            = $User.Department 
                                  HomeDrive             = $User.HomeDrive 
                                  HomeDirectory         = $User.HomeDirectory 
                                  OtherAttributes       = @{'ExtensionAttribute1'="S"} 
                                  Verbose               = $True
                                }
        

            if ($user.Description -eq "Teacher")
            {
                $NewADUserParams.Set_Item("OtherAttributes", @{'ExtensionAttribute1'="T"})
            }

            try
            {
                New-ADUser @NewADUserParams -EA Stop
            }
            catch
            {
                $User.DeployStatus = "Fail"
                $User.DeployStatusFailReason = "Unknown error occured"
                $ErrorUsers += $User
            }

            $ADGroup = @()
            foreach ($ADGroup in $($User.Group))
            {
                $ADGroup = Get-ADGroup -Identity $ADGroup
            
                Add-ADGroupMember -Identity $ADGroup -Members $User.sAMAccountName -Verbose
            }

        }# END  if ($User.DeployStatus -ne "Fail")
    
    }# END foreach ($User in $Users)

    if ($PSBoundParameters.ContainsKey("LogPath"))
    {   
        Write-Verbose "Writing Error Log in $LogPath"
        $ErrorUsers | Out-File $LogPath 
    }
    else
    {
        Write-Verbose "Skipping Error Log"
    }
     

}