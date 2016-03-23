#requires -version 3.0
<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
  Create-AWSAutoscaltingGroup -AccessKey MyKey -SecretKey MySecretKey
.EXAMPLE
  Create-AWSAutoscaltingGroup -AccessKey MyKey -SecretKey MySecretKey -Region us-west-2 -LaunchConfigurationName my-launch-cfg -AutoScalingGroupName my-autoscale-grp

#>
function Create-AWSAutoScalingGroup
{
[CmdletBinding()]
Param
    (
      # Access Key for connecting to AWS
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$AccessKey,

      # Secret Key for connecting to AWS
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SecretKey,

      # Select the region in which the service will be created
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("us-east-1", "us-west-1", "us-west-2", "eu-west-1", "eu-central-1", "ap-northeast-1", "ap-southeast-1", "ap-southeast-2", "sa-east-1")]
        [string]$Region = "ap-northeast-1",

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$LaunchConfigurationName = "WEB-LAUNCH-CONFIG4",

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$InstanceType = "t2.micro",

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$ImageID ="ami-c1b191af",
        
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$SecurityGroup ="sg-f45f6991",

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$AutoScalingGroupName = "WEB-AUTOSCALING-GROUP4",

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$KeyName = "bc-homework-tok",

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$LoadBalancerName = "WEB-ELB",

        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$VPCZoneIdentifier = "subnet-16771861"


    )

    #Check if the AWSPowerShell module is installed
    Try
    {
        Import-Module -Name AWSPowerShell -ErrorAction Stop
    }
    Catch 
    {
        if ($host.Version.Major -eq 5)
        {
            #If running on Windows 10 and have PowerShell 5.0, install the module
            Install-Module -Name AWSPowerShell -Scope CurrentUser
        }
        else 
        {
            throw "Cannot find AWS PowerShell module. Please install it following this link: https://aws.amazon.com/powershell/"
        }
    }

    Write-Verbose "Connecting to AWS ..."

    Initialize-AWSDefaults -AccessKey $AccessKey -SecretKey $SecretKey -Region $Region 

    #Test connection and terminate script if credentials aren't valid
    try
    {
        #I use VPC, because there is always a VPC in a AWS region
        Get-EC2VPC -ErrorAction Stop | Out-Null
    }
    catch [System.InvalidOperationException]
    {
        throw $Error[0]
    }

    #Check if the Resources exist. Otherwhise, terminate the execution. We don't want the user to create partially configured services
    Write-Verbose "The following AWS elements were found:"
    try
    {
        Get-EC2Subnet -SubnetId $VPCZoneIdentifier -ErrorAction Stop 
        Get-EC2KeyPair -KeyName $KeyName -ErrorAction Stop
        Get-EC2SecurityGroup -GroupId $SecurityGroup -ErrorAction Stop 

    }
    catch
    {
        throw $Error[0]
    }

    #region Variable Declaration

    #region LaunchConfig
    $LaunchConfigParams = @{
                             "LaunchConfigurationName"    = $LaunchConfigurationName
                             "InstanceType"               = $InstanceType
                             "ImageId"                    = $ImageID
                             "SecurityGroup"              = $SecurityGroup
                             "InstanceMonitoring_Enabled" = $true
                           }

    #endregion

    #region AutoScaling
    $MaxSize = 10
    $MinSize = 2
    $DesiredCapacity =2

    #This assures us we're creating the AutoScaling group in the same AZ as the Subnet we're using
    $AvailabilityZone = Get-EC2Subnet -SubnetId $VPCZoneIdentifier 

    $AutoScalingParams = @{
                            "AutoScalingGroupName"        = $AutoScalingGroupName
                            "AvailabilityZone"            = $AvailabilityZone.AvailabilityZone
                            "LaunchConfigurationName"     = $LaunchConfigurationName
                            "LoadBalancerName"            = $LoadBalancerName
                            "MaxSize"                     = $MaxSize
                            "MinSize"                     = $MinSize
                            "DesiredCapacity"             = $DesiredCapacity
                            "VPCZoneIdentifier"           = $VPCZoneIdentifier
                          }

    #endregion

    #region Scale Out Policy
    $ScaleOutPolicyName = "WEB-SCALEOUT-POLICY"
    $ScaleOutScalingAdjustment = 1
    $ScaleOutAdjustmentType = "ChangeInCapacity"

    $ScaleOutPolicyParams = @{
                                "AutoScalingGroupName" = $AutoScalingGroupName
                                "PolicyName"           = $ScaleOutPolicyName
                                "ScalingAdjustment"    = $ScaleOutScalingAdjustment
                                "AdjustmentType"       = $ScaleOutAdjustmentType
                             }

    #endregion

    #region Scale In Policy
    $ScaleIntPolicyName = "WEB-SCALEIN-POLICY"
    $ScaleIntScalingAdjustment = -1
    $ScaleIntAdjustmentType = "ChangeInCapacity"


    $ScaleInPolicyParams = @{
                               "AutoScalingGroupName" = $AutoScalingGroupName
                               "PolicyName"           = $ScaleIntPolicyName
                               "ScalingAdjustment"    = $ScaleIntScalingAdjustment
                               "AdjustmentType"       = $ScaleIntAdjustmentType
                            }

    #endregion

    #region Metric Out info
    $MetricOutAlarmName = "WEB-METRIC-OUT-ALARM"
    $MetricOutMetricName = "NetworkIn"
    $MetricOutEvaluationPeriod = 1
    $MetricOutPeriod = 60
    $MetricOutStatistic = "Average"
    $MetricOutComparisonOperator = "GreaterThanThreshold"
    $MetricOutThreshold = 1000
    $MetricOutUnit = "Bytes"
    $MetricOutNamespace = 'AWS/EC2'


    $MetricOutPolicyParams = @{
                                "AlarmActions"       = $null #this will be defined later
                                "AlarmName"          = $MetricOutAlarmName
                                "MetricName"         = $MetricOutMetricName
                                "Statistic"          = $MetricOutStatistic
                                "ComparisonOperator" = $MetricOutComparisonOperator
                                "Threshold"          = $MetricOutThreshold
                                "EvaluationPeriod"   = $MetricOutEvaluationPeriod
                                "Unit"               = $MetricOutUnit
                                "Namespace"          = $MetricOutNamespace
                                "Period"             = $MetricOutPeriod
                              }
    #endregion

    #region Metric in info
    $MetricInAlarmName = "WEB-METRIC-IN-ALARM"
    $MetricInMetricName = "NetworkIn"
    $MetricInEvaluationPeriod = 2
    $MetricInPeriod = 60
    $MetricInStatistic = "Average"
    $MetricInComparisonOperator = "LessThanThreshold"
    $MetricInThreshold = 1000
    $MetricInUnit = "Bytes"
    $MetricInNamespace = 'AWS/EC2'


    $MetricInPolicyParams = @{
                               "AlarmActions"       = $null #this will be defined later
                               "AlarmName"          = $MetricInAlarmName
                               "MetricName"         = $MetricInMetricName
                               "Statistic"          = $MetricInStatistic
                               "ComparisonOperator" = $MetricInComparisonOperator
                               "Threshold"          = $MetricInThreshold
                               "EvaluationPeriod"   = $MetricInEvaluationPeriod
                               "Unit"               = $MetricInUnit
                               "Namespace"          = $MetricInNamespace
                               "Period"             = $MetricInPeriod
                             }
    #endregion

    #endregion
     
    Write-Verbose "Creating Launch Configuration $LaunchConfigurationName"
    New-ASLaunchConfiguration @LaunchConfigParams

    Write-Verbose "Creating Autoscaling Group $AutoScalingGroupName"    
    New-ASAutoScalingGroup @AutoScalingParams
    
    Write-Verbose "Setting Scale Out Policy"
    $ScaleOutPolicy = Write-ASScalingPolicy @ScaleOutPolicyParams

    Write-Verbose "Editting metrics for Scale Out Policy"
    $MetricOutPolicyParams.set_item("AlarmActions", $ScaleOutPolicy)
    Write-CWMetricAlarm @MetricOutPolicyParams

    Write-Verbose "Setting Scale In Policy"
    $ScaleInPolicy = Write-ASScalingPolicy @ScaleInPolicyParams
    
    Write-Verbose "Editting metrics for Scale In Policy"    
    $MetricInPolicyParams.set_item("AlarmActions", $ScaleInPolicy)
    Write-CWMetricAlarm @MetricInPolicyParams
     

}

