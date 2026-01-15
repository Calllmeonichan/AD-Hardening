Clear-Host
Write-Host "🖨️  DISABLE PRINT SPOOLER DCs - A-DC-Spooler" -ForegroundColor Red

# Vérif printers publiés AD (à supprimer d'abord)
$printers = Get-ADObject -Filter "ObjectCategory -eq 'printqueue'"
if ($printers) {
    Write-Warning "⚠️  $($printers.Count) printers publiés → supprimez d'abord !"
    $printers | Select-Object Name | Format-Table
    exit
}

$confirm = Read-Host "Désactiver Spooler TOUS DCs ? (oui/non)"
if ($confirm -ne "oui") { exit }

Get-ADDomainController -Filter * | ForEach-Object {
    try {
        Invoke-Command -ComputerName $_.HostName -ScriptBlock {
            Stop-Service Spooler -Force -ErrorAction SilentlyContinue
            Set-Service Spooler -StartupType Disabled
        }
        Write-Host "✅ $($_.HostName)" -ForegroundColor Green
    } catch {
        Write-Warning "❌ $($_.HostName) : $_"
    }
}

Write-Host "`n🎉 Print Spooler OFF ! ✅" -ForegroundColor Green
