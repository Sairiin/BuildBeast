# BuildBeast - installer per Windows / ROG Ally / PC handheld
# Scarica l'ultima versione da GitHub e la copia in World of Warcraft Forever.
# Non tocca WTF (le tue impostazioni restano). Fa un backup della versione precedente.
param([string]$WoWPath = "")

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$repo = "Sairiin/BuildBeast"

function Say($t, $c = "White") { Write-Host $t -ForegroundColor $c }

function Find-Forever {
    $cands = New-Object System.Collections.Generic.List[string]
    foreach ($d in (Get-PSDrive -PSProvider FileSystem).Root) {
        foreach ($p in @("Program Files (x86)\World of Warcraft", "Program Files\World of Warcraft",
                         "World of Warcraft", "Games\World of Warcraft", "Battle.net\World of Warcraft")) {
            $cands.Add((Join-Path $d "$p\_forever_"))
        }
    }
    foreach ($c in $cands) { if (Test-Path (Join-Path $c "Interface")) { return $c } }
    return $null
}

try {
    Say "=== BuildBeast: installazione / Installation ===" Cyan

    if ($WoWPath -ne "") { $forever = $WoWPath } else { $forever = Find-Forever }
    if (-not $forever) {
        Say "Non trovo WoW Forever da solo. / Could not find WoW Forever automatically." Yellow
        Say "Incolla il percorso della cartella _forever_ (es. C:\Program Files (x86)\World of Warcraft\_forever_)"
        $forever = (Read-Host "Percorso / Path").Trim('"').Trim()
    }
    if (-not (Test-Path $forever)) { throw "Cartella non trovata / Folder not found: $forever" }
    $addons = Join-Path $forever "Interface\AddOns"
    if (-not (Test-Path $addons)) { New-Item -ItemType Directory -Force $addons | Out-Null }
    Say "Trovato / Found: $forever" Green

    if (Get-Process -Name "Wow*" -ErrorAction SilentlyContinue) {
        Say "ATTENZIONE: WoW e' aperto. Chiudilo, poi premi Invio. / WoW is running. Close it, then press Enter." Yellow
        Read-Host | Out-Null
    }

    Say "Cerco l'ultima versione... / Looking for the latest version..."
    $rel = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest" -Headers @{ "User-Agent" = "BuildBeast-installer" }
    $asset = $rel.assets | Where-Object { $_.name -like "BuildBeast-*.zip" } | Select-Object -First 1
    if (-not $asset) { throw "Nessun file ZIP nella release / No ZIP in release" }
    Say "Versione / Version: $($rel.tag_name)"

    $tmp = Join-Path $env:TEMP ("buildbeast_" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory $tmp | Out-Null
    $zip = Join-Path $tmp $asset.name
    Invoke-WebRequest $asset.browser_download_url -OutFile $zip -UseBasicParsing
    Expand-Archive $zip -DestinationPath (Join-Path $tmp "x") -Force
    $src = Join-Path $tmp "x\BuildBeast"
    if (-not (Test-Path (Join-Path $src "BuildBeast.toc"))) { throw "ZIP non valido / Invalid ZIP (no BuildBeast.toc)" }

    $dest = Join-Path $addons "BuildBeast"
    if (Test-Path $dest) {
        $bak = Join-Path $addons ("BuildBeast.backup-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
        Move-Item $dest $bak
        Say "Vecchia versione salvata in / Old version saved to: $bak" DarkGray
    }
    Copy-Item $src $dest -Recurse
    Remove-Item $tmp -Recurse -Force

    Say ""
    Say "FATTO! BuildBeast $($rel.tag_name) installato. / DONE! Installed." Green
    Say "Avvia WoW Forever. In gioco: /bb  (se l'addon e' nuovo serve riavviare il gioco)." Green
}
catch {
    Say ""
    Say "ERRORE / ERROR: $($_.Exception.Message)" Red
    Say "Installazione manuale: scarica lo ZIP da https://github.com/$repo/releases/latest e metti la cartella BuildBeast in Interface\AddOns" Yellow
}
if ($Host.Name -eq "ConsoleHost" -and -not $env:BB_NOPAUSE) { Read-Host "Premi Invio per chiudere / Press Enter to close" | Out-Null }
