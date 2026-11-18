#!/usr/bin/env bash
# BuildBeast - installer per Steam Deck / Linux
# Cerca WoW Forever (Steam/Proton, Lutris, Heroic, Bottles, Wine), scarica l'ultima versione
# da GitHub e la copia in Interface/AddOns. Non tocca WTF. Backup della versione precedente.
set -u
REPO="Sairiin/BuildBeast"
say() { printf '%s\n' "$*"; }

say "=== BuildBeast: installazione / Installation ==="

FOREVER="${1:-}"
if [ -z "$FOREVER" ]; then
  roots=(
    "$HOME/.steam/steam/steamapps/compatdata"
    "$HOME/.local/share/Steam/steamapps/compatdata"
    "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/compatdata"
    "$HOME/Games" "$HOME/.local/share/lutris" "$HOME/.wine" "$HOME/.local/share/bottles"
    "$HOME/.var/app/com.usebottles.bottles/data/bottles" "$HOME/.var/app/net.lutris.Lutris/data"
    "/run/media" "/mnt"
  )
  for r in "${roots[@]}"; do
    [ -d "$r" ] || continue
    f=$(find "$r" -maxdepth 9 -type d -name "_forever_" -path "*World of Warcraft*" 2>/dev/null | head -n1)
    if [ -n "$f" ]; then FOREVER="$f"; break; fi
  done
fi

if [ -z "$FOREVER" ] || [ ! -d "$FOREVER" ]; then
  say "Non trovo WoW Forever da solo. / Could not find WoW Forever automatically."
  say "Scrivi il percorso della cartella _forever_ / Type the path of the _forever_ folder:"
  read -r FOREVER
fi
[ -d "$FOREVER" ] || { say "ERRORE: cartella non trovata / folder not found: $FOREVER"; exit 1; }
say "Trovato / Found: $FOREVER"

if pgrep -fi "Wow.exe" >/dev/null 2>&1; then
  say "ATTENZIONE: WoW e' aperto. Chiudilo e premi Invio. / WoW is running. Close it, then press Enter."
  read -r _
fi

ADDONS="$FOREVER/Interface/AddOns"
mkdir -p "$ADDONS"

say "Cerco l'ultima versione... / Looking for the latest version..."
API=$(curl -fsSL -H "User-Agent: BuildBeast-installer" "https://api.github.com/repos/$REPO/releases/latest") \
  || { say "ERRORE: GitHub non raggiungibile / cannot reach GitHub"; exit 1; }
URL=$(printf '%s' "$API" | grep -o '"browser_download_url": *"[^"]*BuildBeast-[^"]*\.zip"' | head -n1 | sed 's/.*"\(https[^"]*\)"/\1/')
TAG=$(printf '%s' "$API" | grep -o '"tag_name": *"[^"]*"' | head -n1 | sed 's/.*"\([^"]*\)"$/\1/')
[ -n "$URL" ] || { say "ERRORE: nessun ZIP nella release / no ZIP in release"; exit 1; }
say "Versione / Version: $TAG"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
curl -fsSL "$URL" -o "$TMP/bb.zip" || { say "ERRORE: download fallito / download failed"; exit 1; }
if command -v unzip >/dev/null 2>&1; then unzip -q "$TMP/bb.zip" -d "$TMP/x"
else python3 -c "import zipfile,sys;zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$TMP/bb.zip" "$TMP/x"; fi
[ -f "$TMP/x/BuildBeast/BuildBeast.toc" ] || { say "ERRORE: ZIP non valido / invalid ZIP"; exit 1; }

if [ -d "$ADDONS/BuildBeast" ]; then
  BAK="$ADDONS/BuildBeast.backup-$(date +%Y%m%d-%H%M%S)"
  mv "$ADDONS/BuildBeast" "$BAK"
  say "Vecchia versione salvata in / Old version saved to: $BAK"
fi
cp -r "$TMP/x/BuildBeast" "$ADDONS/BuildBeast"

say ""
say "FATTO! BuildBeast $TAG installato. / DONE! Installed."
say "Avvia WoW Forever. In gioco: /bb  (se l'addon e' nuovo serve riavviare il gioco)."
