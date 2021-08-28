function New-OUCollection {
    [CmdletBinding()]
    param (
        # InputObject must contain OU Name, DistinguishedName, and CanonicalName
        [Parameter(Mandatory = $true)]
        $InputObject,
        # Admin console path
        [Parameter(Mandatory = $true)]
        [String]
        $ConsolePath,
        # Name of your limiting collection
        [Parameter(Mandatory = $true)]
        [string]
        $LimitingCollectionName,
        # Use recursion
        [Parameter(Mandatory = $false)]
        [switch]
        $Recurse,
        # Initial collection name
        [Parameter(Mandatory = $true)]
        [String]
        $CollectionName
    )
    
    process {

        if (-not (Get-CMDeviceCollection -Name $CollectionName)) {
            Write-Host ('Collection "{0}" does not exist.. Creating!' -f $CollectionName)

            $CMSchedule = New-CMSchedule -DurationInterval Days -DurationCount 0 -RecurInterval Days -RecurCount 7

            $Collection = New-CMDeviceCollection -LimitingCollectionName $LimitingCollectionName -Name $CollectionName -RefreshSchedule $CMSchedule
    
            Add-CMDeviceCollectionQueryMembershipRule -InputObject $Collection -QueryExpression ('select * from  SMS_R_System where SMS_R_System.SystemOUName = "{0}"' -f $InputObject.CanonicalName) -RuleName "$($InputObject.Name) OU"

            If (-not (Test-Path $CollectionPath)) {
                Write-Host ('Creating CollectionPath: {0}' -f $CollectionPath)

                New-Item $CollectionPath
            }

            Move-CMObject -InputObject $Collection -FolderPath $CollectionPath

        } else {
            Write-Host 'Collection with name "{0}" already exists.. Skipping!'
        }

        if ($Recurse) {

            $SUBOUArgs = @{
                LDAPFilter  = $Settings.AD.LDAPFilter
                SearchBase  = $InputObject.DistinguishedName
                Properties  = 'DistinguishedName', 'CanonicalName'
                SearchScope = 'OneLevel'
            }
            # Search for SUB OUs
            $SUBOUs = Get-ADOrganizationalUnit @SUBOUArgs

            if ($SUBOUs) {
                foreach ($SUB in $SUBOUs) {

                    ### Collection name formatting
                    $Splits    = $SUB.CanonicalName.Split('/') | Select-Object -Last 2
                    $Splits[1] = "- $($Splits[1])"
                    $SUBName   = ('{0}-' -f $Settings.AreaID)

                    $Splits | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object {
                        $SUBName += "$_ "
                    }
                    ### End collection name formatting

                    $NewCollArgs = @{
                        InputObject            = $SUB
                        CollectionPath         = (Join-Path $CollectionPath $SUB.Name)
                        CollectionName         = $SUBName.Trim()
                        LimitingCollectionName = $CollectionName
                        Recurse                = $true
                    }
                
                    New-OUCollection @NewCollArgs
                }
            }
        }
    }   
}