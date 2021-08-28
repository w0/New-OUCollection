#Requires -Module ActiveDirectory

$ErrorActionPreference = "Stop"

Write-Host 'Importing Settings'
$Settings = Get-Content (Join-Path $PSScriptRoot 'Settings.json') | ConvertFrom-Json

Write-Host 'Importing Configuration Manager PSModule'
Import-Module (Join-Path (Split-Path $env:SMS_ADMIN_UI_PATH -Parent) 'ConfigurationManager.psd1') -ErrorAction Stop

Write-Host 'Ensuring Configuration Manager Drive is mapped'
if (-not (Get-PSDrive -Name $Settings.ConfigMgr.SiteCode -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name $Settings.ConfigMgr.SiteCode -PSProvider 'CMSite' -Root $Settings.ConfigMgr.Server -Description 'SCCM Site' | Out-Null
}

Write-Host 'Importing additional functions'
foreach ($Item in (Get-ChildItem "$PSScriptRoot\Functions" -Recurse -Filter *.ps1 -File)) {
    Write-Verbose ('Importing: {0}' -f $Item.BaseName)
    . $Item.FullName
}

$ADOrgsTopLevel = @{
    LDAPFilter  = $Settings.AD.LDAPFilter
    SearchBase  = $Settings.AD.SearchBase
    Properties  = 'DistinguishedName', 'CanonicalName'
    SearchScope = 'OneLevel'
}
# Staring point from where our collections will be made from
$OrgUnits = Get-ADOrganizationalUnit @ADOrgsTopLevel

# Root path in the Admin Console
$ConsoleRoot = Join-Path "$($Settings.ConfigMgr.SiteCode):\" $Settings.ConfigMgr.ConsoleLocation

Write-Host "ConsoleRoot: $($ConsoleRoot)"

Push-Location "$($Settings.ConfigMgr.SiteCode):"

foreach ($OU in $OrgUnits) {

    # CanonicalRoot should be the same as your search base. 
    $Splits = $OU.CanonicalName.Split('/') | Select-Object -Last 1

    ### Collection name formatting
    $CollectionName = ('{0}-' -f $Settings.AreaID)

    $Splits | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object {
        $CollectionName += "$_ "
    }
    ### End Collection name formatting
    
    Write-Verbose -Message "OU: $($OU.Name)"

    $NewCollArgs = @{
        InputObject            = $OU
        CollectionPath         = (Join-Path $ConsoleRoot $OU.Name)
        CollectionName         = $CollectionName.Trim()
        LimitingCollectionName = $Settings.AreaID
        Recurse                = $true
    }

    New-OUCollection @NewCollArgs

}

Pop-Location