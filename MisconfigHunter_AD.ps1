$host.UI.RawUI.BackgroundColor = "Black"
$host.UI.RawUI.ForegroundColor = "DarkYellow"
$host.ui.RawUI.WindowTitle = "MisconfigHunter"
function prompt {">"}
Clear-Host


function MisconfigHunterAD {

#Domain controllers version check
    $domainControllers = Get-ADDomainController -Filter * 
    $obsoleteFound = $false
    foreach ($dc in $domainControllers) {
        $osVersion = (Get-WmiObject -Class Win32_OperatingSystem -ComputerName $dc.Name).Caption
        if ($osVersion -match "Windows Server 2008|Windows Server 2012") {$obsoleteFound = $true}
    }
    if ($obsoleteFound) {
        Write-Host "[!] One or more domain controllers' OS are obsolete." -ForegroundColor Red
    } else {
        Write-Host "[o] All domain controllers' OS are not obsolete." -ForegroundColor Green
    }


# KRBTGT password last set
    $krbtgtPasswordLastSet = (Get-ADUser -Identity krbtgt -Properties "PasswordLastSet").PasswordLastSet
    $daysSincePasswordChange = (New-TimeSpan -Start $krbtgtPasswordLastSet -End (Get-Date)).Days
    if ($daysSincePasswordChange -gt 180) {
        Write-Host "[!] The krbtgt password is older than 180 days." -ForegroundColor Red
    } else {
        Write-Host "[o] The krbtgt password is up to date." -ForegroundColor Green
    }

# Reversible passwords
    $reversiblePasswords = Get-ADDefaultDomainPasswordPolicy | Select-Object ReversibleEncryptionEnabled
    if ($reversiblePasswords -eq $true) {
        Write-Host "[!] The default domain password policy allows reversible passwords." -ForegroundColor Red
    } else {
        Write-Host "[o] The default domain password policy doesn't allow reversible passwords." -ForegroundColor Green
    }

# Accounts with an SPN defined
    $accountsWithSPN = Get-ADObject -Filter "(servicePrincipalName -like '*')" -Property servicePrincipalName
    if ($reversiblePasswords) {
        Write-Host "[!] One or more accounts have an SPN defined." -ForegroundColor Red
    } else {
        Write-Host "[o] No accounts have an SPN defined." -ForegroundColor Green
    }

# Accounts with delegation
    $accountsWithDelegation = Get-ADUser -Filter * -Properties TrustedForDelegation | Where-Object { $_.TrustedForDelegation -eq $true }
    if ($accountsWithDelegation) {
        Write-Host "[!] One or more accounts have an delegation defined." -ForegroundColor Red
    } else {
        Write-Host "[o] No accounts have an delegation defined." -ForegroundColor Green
    }


    $passwordNotRequired = Get-ADUser -Filter * | Where-Object PasswordNotRequired -eq $true
    if ($passwordNotRequired) {
        Write-Host "[!] One or more accounts with 'Password not required' option enabled." -ForegroundColor Red
    } else {
        Write-Host "[o] Not accounts with 'Password not required' option enabled." -ForegroundColor Green
    }
}

MisconfigHunterAD
Start-Sleep 15

<#
function Default{
Clear-Host
Write-Host "╔══════════════════════════════════════════════════════════════╗"
Write-Host "║                                                              ║"
Write-Host "           MisconfigHunter | Created by @111um1" -ForegroundColor Cyan
Write-Host "║                                                              ║"
Write-Host "╚══════════════════════════════════════════════════════════════╝"

Write-Host ""
Write-Host "1. Start audit"
Write-host "2. Exit"
Write-Host ""

$choice = Read-Host "Please enter your choice : "
}

Default

switch ($choice) {
    1 {
        for ($i = 5; $i -gt 0; $i--) {
        Write-Host "Audit launched in $i"
        Start-Sleep -Seconds 1
    }
        MisconfigHunterAD
        break
    }
    2 {
        exit
        break
    }
    default {
        Write-Host "[!] Invalid choice"
        break
    }
}

#>