#!/bin/bash

# Sicherstellen, dass das Skript mit Root-Rechten ausgeführt wird
if [ "$EUID" -ne 0 ]; then
  echo "Fehler: Bitte führe dieses Skript mit Root-Rechten aus (sudo ./clean-kernels.sh)."
  exit 1
fi

echo -e "\n=== Debian Kernel-Bereinigung  ==="

# 1. Aktuell laufenden Kernel ermitteln
CURRENT_KERNEL_VERSION=$(uname -r)
echo -e "\nAktuell verwendeter Kernel: $CURRENT_KERNEL_VERSION"

# Zugehöriges Paket des laufenden Kernels finden (z.B. linux-image-6.12.107+deb13-amd64)
CURRENT_PACKAGE=$(dpkg --list | grep -E "^ii\s+linux-image-[0-9]+" | awk '{print $2}' | grep "$CURRENT_KERNEL_VERSION")

# Alle installierten linux-image-Pakete ermitteln
INSTALLED_KERNELS=$(dpkg --list | grep -E "^ii\s+linux-image-[0-9]+" | awk '{print $2}')

if [ -z "$INSTALLED_KERNELS" ]; then
  echo "Keine Kernel-Pakete gefunden."
  exit 0
fi

# 2. Den ältesten oder den direkt vor dem aktuellen liegenden Kernel als Backup bestimmen:
# Wir nehmen alle installierten Kernel OHNE den aktuellen, sortieren sie und nehmen den neuesten davon (den direkten Vorgänger)
OLDER_KERNELS=$(echo "$INSTALLED_KERNELS" | grep -v "$CURRENT_PACKAGE" | sort -V)
BACKUP_PACKAGE=$(echo "$OLDER_KERNELS" | tail -n 1)

# Zu behaltende Kernel zusammenstellen
KEEP_KERNELS="$CURRENT_PACKAGE"
if [ -n "$BACKUP_PACKAGE" ]; then
  KEEP_KERNELS="$KEEP_KERNELS $BACKUP_PACKAGE"
fi

echo -e "\Diese Kernel werden behalten (Aktuell + ein Älterer):"
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
        TO_REMOVE="$TO_REMOVE $kernel"
    fi
done

if [ -z "$TO_REMOVE" ]; then
  echo "Keine alten Kernel zum Löschen vorhanden."
  exit 0
fi

# Sicherheitsabfrage vor dem Löschen
read -p "Möchtest du diese Kernel jetzt unwiderruflich löschen? (j/N): " choice
case "$choice" in 
  j|J|yes|YES)
    echo "Lösche alte Kernel..."
    apt-get purge -y $TO_REMOVE
    
    echo "Bereinige nicht mehr benötigte Abhängigkeiten..."
    apt-get autoremove -y
    
    echo -e "\nFertig! Die Kernel-Bereinigung war erfolgreich."
    ;;
  *)
    echo "Abgebrochen. Es wurde nichts gelöscht."
    ;;
esac
