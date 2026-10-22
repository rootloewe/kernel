#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Fehler: Bitte mit Root-Rechten ausführen (sudo ./kernel.sh)."
  echo
  exit 1
fi

echo -e "\n=== Erweiterte Kernel-Bereinigung ==="

# 1. Aktuell laufenden Kernel ermitteln
CURRENT_KERNEL=$(uname -r)
echo -e "\n Verwendeter Kernel: $CURRENT_KERNEL"

# 2. Alle Kernel-Dateien in /boot finden und sortieren
# Wir extrahieren die Versionsnummern aus den vmlinuz-Dateien
ALL_KERNELS=$(ls -1 /boot/vmlinuz-* | sed 's|/boot/vmlinuz-||' | sort -V)

if [ -z "$ALL_KERNELS" ]; then
  echo -e "\nKeine Kernel in /boot gefunden."
  exit 0
fi

# Die letzten beiden Kernel als zu behalten definieren (aktuellster und ein Vorgänger)
KEEP_KERNELS=$(echo "$ALL_KERNELS" | tail -n 2)

# Rest zum Löschen vormerken
TO_REMOVE=""
for kernel_ver in $ALL_KERNELS; do
    KEEP=0
    for keep_k in $KEEP_KERNELS; do
        if [ "$kernel_ver" = "$keep_k" ]; then
            KEEP=1
            break
        fi
    done
    
    if [ "$KEEP" -eq 0 ]; then
        #echo " - $kernel_ver"
        # Versuchen, sowohl das Paket (falls via apt) als auch die Dateien in /boot zu erfassen
        TO_REMOVE="$TO_REMOVE $kernel_ver"
    fi
done

echo -e "\nDiese Kernel werden behalten (Aktueller und ein Vorgänger):"
for k in $KEEP_KERNELS; do
    echo " - $k"
done | tac

if [ -z "$TO_REMOVE" ]; then
    echo -e "\nKeine alten Kernel zum Löschen vorhanden."
    exit 0
fi

echo -e "\nFolgende Kernel und Header werden entfernt:"
for ver in $TO_REMOVE; do
    echo " - $ver"
done

echo
read -p "Möchtest du diese alten Kernel jetzt löschen? (j/N): " choice
echo
case "$choice" in 
  j|J|yes|YES)
    for ver in $TO_REMOVE; do
        echo "Entferne Kernel $ver..."
        # Prüfen ob es ein APT-Paket gibt und dieses purgen, sonst Dateien manuell löschen
        apt-get purge -y "linux-image-$ver" "linux-headers-$ver" 2>/dev/null
        rm -f /boot/*-$ver*
    done
     
    echo -e "\nBereinige Abhängigkeiten..."
    apt-get autoremove -y
    
    echo -e "\nAktualisiere GRUB..."
    update-grub
    echo -e "\nFertig! Die Kernel-Bereinigung war erfolgreich."
    ;;
  *)
    echo -e "\nAbgebrochen. Es wurde nichts gelöscht."
    ;;
esac
