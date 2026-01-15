
# Masque l'affichage du script
$ErrorActionPreference = "SilentlyContinue"; Clear-Host; $ErrorActionPreference = "Continue"
Import-Module ActiveDirectory

Write-Host "🔍 Scan COMPLET : membres groupes ADMIN..." -ForegroundColor Cyan

# TOUS les groupes admin possibles
$groupesAdmin = Get-ADGroup -Filter "Name -like '*Admin*'" | 
Where-Object { $_.Name -notin @("Guests", "Users") } |
Select-Object -ExpandProperty Name

Write-Host "Groupes admin trouvés : $($groupesAdmin.Count)" -ForegroundColor Gray
$groupesAdmin | ForEach-Object { Write-Host "  - $_" }

# Récupère TOUS les membres (récursif) sans flag
$adminsSansFlag = @()
foreach ($groupe in $groupesAdmin) {
    try {
        $membres = Get-ADGroupMember -Identity $groupe -Recursive | 
                   Where-Object ObjectClass -eq "user" | 
                   Get-ADUser -Properties AccountNotDelegated
        
        $sansFlag = $membres | Where-Object { $_.AccountNotDelegated -ne $true -and $_.Enabled }
        foreach ($user in $sansFlag) {
            $adminsSansFlag += [PSCustomObject]@{
                Name = $user.Name
                SamAccountName = $user.SamAccountName
                Groupe = $groupe
                AccountNotDelegated = $user.AccountNotDelegated
            }
        }
    } catch {
        Write-Warning "Erreur groupe $groupe : $($_.Exception.Message)"
    }
}

# Déduplication
$adminsSansFlag = $adminsSansFlag | Sort-Object SamAccountName | Get-Unique

Write-Host "`n📊 $($adminsSansFlag.Count) membres GROUPES ADMIN sans flag" -ForegroundColor Red
$adminsSansFlag | Format-Table -AutoSize

if ($adminsSansFlag.Count -eq 0) {
    Write-Host "✅ Tous les membres admin protégés !" -ForegroundColor Green
    exit
}

# CONFIRMATION
$confirm = Read-Host "`n⚠️ Activer flag sur $($adminsSansFlag.Count) membres ? (oui/non)"
if ($confirm -ne "oui") { exit }

# CORRECTION
$ok = 0
foreach ($admin in $adminsSansFlag) {
    try {
        Set-ADUser -Identity $admin.SamAccountName -AccountNotDelegated $true
        Write-Host "✅ $($admin.SamAccountName) [$($admin.Groupe)]" -ForegroundColor Green
        $ok++
    } catch {
        Write-Warning "❌ $($admin.SamAccountName) : $($_.Exception.Message)"
    }
}

Write-Host "`n🎉 $ok membres admin corrigés ✅" -ForegroundColor Green
