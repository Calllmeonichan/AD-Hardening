$ErrorActionPreference = "SilentlyContinue"; Clear-Host; $ErrorActionPreference = "Continue"
Import-Module ActiveDirectory

Write-Host "🔍 VÉRIFICATION POLITIQUE MOT DE PASSE" -ForegroundColor Cyan
Write-Host ""
Write-Host "Votre domaine semble être 'dos.lan' (DC=dos,DC=lan)" -ForegroundColor Yellow
$domaine = Read-Host "Nom du domaine (ex: dos.lan ou DOS ou DC=dos,DC=lan)"

# Vérification
try {
    $policy = Get-ADDefaultDomainPasswordPolicy -Identity $domaine
    Write-Host "`n✅ Domaine trouvé : $domaine" -ForegroundColor Green
    Write-Host "Longueur min actuelle : $($policy.MinPasswordLength)" -ForegroundColor $(if($policy.MinPasswordLength -lt 14){"Red"}else{"Green"})
    
    if ($policy.MinPasswordLength -lt 14) {
        $confirm = Read-Host "`nCorriger à 14 caractères + complexité ? (oui/non)"
        if ($confirm -eq "oui") {
            Set-ADDefaultDomainPasswordPolicy -Identity $domaine -MinPasswordLength 14 -ComplexityEnabled $true
            Write-Host "✅ Politique corrigée ! Relancez PingCastle" -ForegroundColor Green
        }
    } else {
        Write-Host "✅ Politique déjà OK !" -ForegroundColor Green
    }
} catch {
    Write-Error "❌ Domaine '$domaine' non trouvé. Essayez 'dos.lan' ou 'DOS'"
}
