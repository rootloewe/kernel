#!/bin/bash

# Sicherstellen, dass das Skript mit Root-Rechten ausgeführt wird
if [ "$EUID" -ne 0 ]; then
  echo "Fehler: Bitte führe dieses Skript mit Root-Rechten aus (sudo ./kernel.sh)."
  exit 1
fi

echo -e "\n=== Debian Kernel-Bereinigung ==="

# 1. Aktuell laufenden Kernel ermitteln
CURRENT_KERNEL_VERSION=$(uname -r)
CURRENT_PACKAGE=$(dpkg --list | grep -E "^ii\s+linux-image-[0-9]+" | awk '{print $2}' | grep "$CURRENT_KERNEL_VERSION")

if [ -z "$CURRENT_PACKAGE" ]; then
  echo "Fehler: Konnte das Paket des aktuellen Kernels nicht ermitteln."
  exit 1
fi

echo -e "\nAktuell verwendeter Kernel: $CURRENT_KERNEL_VERSION"

# Alle installierten Kernel-Pakete ermitteln (Meta-Paket ausschließen)
INSTALLED_KERNELS=$(dpkg --list | grep -E "^(ii|rc)\s+linux-image-([a-z0-9\.-]+)" | awk '{print $2}' | grep -v "linux-image-amd64$")

if [ -z "$INSTALLED_KERNELS" ]; then
  echo "Keine Kernel-Pakete gefunden."
  exit 0
fi

# 2. Aktuellen Kernel und den neuesten Backup-Kernel ermitteln
KEEP_KERNELS="$CURRENT_PACKAGE"

# Neuesten anderen Kernel als Backup ermitteln (sortiert nach Version)
OTHER_KERNELS=$(dpkg --list | grep -E "^ii\s+linux-image-[0-9]+" | awk '{print $2}' | grep -v "$CURRENT_PACKAGE" | grep -v "linux-image-amd64$" | sort -V)
BACKUP_PACKAGE=$(echo "$OTHER_KERNELS" | tail -n 1)

if [ -n "$BACKUP_PACKAGE" ]; then
  KEEP_KERNELS="$KEEP_KERNELS $BACKUP_PACKAGE"
fi

echo -e "\nDiese Kernel werden behalten (Aktuell und ein Vorgänger):"
for k in $KEEP_KERNELS; do
  echo " - $k" | sed 's/linux-image-//'
done

echo -e "\nFolgende Kernel werden entfernt:"
TO_REMOVE=""
for kernel in $INSTALLED_KERNELS; do
    KEEP=0
    for keep_k in $KEEP_KERNELS; do
        if [ "$kernel" = "$keep_k" ]; then
            KEEP=1
            break
        fi
    done
    
    if [ "$KEEP" -eq 0 ]; then
        echo " - ${kernel#linux-image-}"
        VERSION_TAG="${kernel#linux-image-}"
        # Prüfen, ob das Image- oder Header-Paket tatsächlich existiert, bevor es hinzugefügt wird
        if dpkg --list | grep -q "$kernel"; then
            TO_REMOVE="$TO_REMOVE $kernel"
        fi
        if dpkg --list | grep -q "linux-headers-$VERSION_TAG"; then
            TO_REMOVE="$TO_REMOVE linux-headers-$VERSION_TAG"
        fi
    fi
done

if [ -z "$TO_REMOVE" ]; then
  echo "Keine alten Kernel zum Löschen vorhanden."
  exit 0
fi

# Sicherheitsabfrage vor dem Löschen
echo
read -p "Möchtest du diese Kernel jetzt unwiderruflich löschen? (j/N): " choice
echo
case "$choice" in 
  j|J|yes|YES)
    echo "Lösche alte Kernel und Header..."
    apt-get purge -y $TO_REMOVE
    
    echo "Bereinige nicht mehr benötigte Abhängigkeiten..."
    apt-get autoremove -y
    
    echo -e "\nFertig! Die Kernel-Bereinigung war erfolgreich."
    echo -e "\nInstallierte Kernel:"
    echo
    dpkg -l | grep linux-image
    echo
    ;;
  *)
    echo "Abgebrochen. Es wurde nichts gelöscht."
    ;;
esac
