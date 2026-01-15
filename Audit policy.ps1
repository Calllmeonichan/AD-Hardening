# Fusion EXPORT + ANALYSE AUTOMATIQUE
$ErrorActionPreference = "SilentlyContinue"; Clear-Host; $ErrorActionPreference = "Continue"

Write-Host "🔍 AUDIT DC - EXPORT + ANALYSE AUTO" -ForegroundColor Cyan
Write-Host "(Lancez sur CHAQUE DC)" -ForegroundColor Yellow

# EXPORT
$filePath = "C:\AuditDC_$(Get-Date -f 'yyyyMMdd_HHmm').txt"
auditpol /get /category:* > $filePath
Write-Host "✅ Exporté : $filePath" -ForegroundColor Green

# ANALYSE IMMÉDIATE
$files = Get-ChildItem "C:\AuditDC_*.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $files) { Write-Error "❌ Fichier introuvable !"; exit }

$fileAnalysee = $files.FullName
Write-Host "📁 Fichier analysé : $fileAnalysee" -ForegroundColor Yellow
Write-Host "📊 Date création  : $($files.LastWriteTime)" -ForegroundColor Gray

$content = Get-Content $fileAnalysee -Raw -Encoding UTF8

# Catégories critiques (anglais/français)
$patterns = @{
    "Account Logon|Connexion au compte" = "Success and Failure|Réussite et échec"
    "Account Management|Gestion des comptes" = "Success and Failure|Réussite et échec"
    "Directory Service Access|Accès au service d'annuaire" = "Success and Failure|Réussite et échec"
    "Directory Service Changes|Modifications du service d'annuaire" = "Success and Failure|Réussite et échec"
    "Logon/Logoff|Connexion/Connexion" = "Success and Failure|Réussite et échec"
    "Policy Change|Modification de stratégie" = "Success and Failure|Réussite et échec"
}

Write-Host "`n🎯 ANALYSE DÉTAILLÉE :" -ForegroundColor Cyan
$ko = 0
foreach ($pattern in $patterns.Keys) {
    if ($content -match "($pattern).*?(\w+(?:\s+\w+)?)") {
        $cat = $matches[1]
        $status = $matches[2]
        $ok = $status -match $patterns[$pattern]
        Write-Host "  $cat`: $status" -ForegroundColor $(if($ok){"Green"}else{"Red"})
        if (-not $ok) { $ko++ }
    }
}

Write-Host "`n📈 RÉSULTAT : $ko/6 KO" -ForegroundColor $(if($ko -eq 0){"Green"}else{"Red"})
if ($ko -eq 0) { 
    Write-Host "✅ PingCastle A-AuditDC VERT !" -ForegroundColor Green 
} else { 
    Write-Host "🔧 Corrigez via GPO Default Domain Controllers Policy" -ForegroundColor Yellow 
}

