# Debian Kernel Bereiniger  (kernel.sh)

Ein sauberes, sicheres und automatisiertes Bash-Skript für Debian- und basierte Systeme, um veraltete Linux-Kernel zu entfernen und wertvollen Speicherplatz freizugeben.

## 🚀 Funktionen

* **Intelligenter Schutz:** Erkennt und bewahrt automatisch den aktuell laufenden Kernel (`uname -r`) sowie genau den aktuellen und den direkten Vorgänger auf.
* **Sicheres Bereinigen:** Entfernt (`purge`) ungenutzte `linux-image`-Pakete vollständig, anstatt sie nur zu deinstallieren, wodurch Speicherplatz auf der Boot- und Root-Partition frei wird.
* **Interaktive Sicherheitsabfrage:** Erfordert eine explizite Bestätigung durch den Benutzer (`j/N`), bevor destruktive Aktionen durchgeführt werden.
* **Automatische Bereinigung:** Führt nach dem Aufräumen `apt-get autoremove` aus, um verwaiste Abhängigkeiten und Module zu entfernen.

## 📥 Installation & Verwendung

1. Erstelle die Skriptdatei auf deinem System:
   ```bash
   vim clean-kernels.sh
   ```
2. Füge den Skriptinhalt in die Datei ein und speichere sie.
3. Mache das Skript ausführbar:
   ```bash
   chmod +x clean-kernels.sh
   ```
4. Führe das Skript mit Root-Rechten aus:
   ```bash
   sudo ./clean-kernels.sh
   ```

## 🛠️ Funktionsweise

* **Rechteprüfung:** Stellt sicher, daß das Skript mit `sudo`- oder Root-Rechten ausgeführt wird.
* **Analyse des aktuellen Zustands:** Identifiziert die aktive Kernel-Version über `uname -r`.
* **Paket-Erfassung:** Scannt alle installierten `linux-image`-Pakete mithilfe von `dpkg`.
* **Auswahllogik:**
  * Behält das aktive Kernel-Paket bei.
  * Wählt die neueste verfügbare Alternative aus den verbleibenden installierten Kerneln als Sicherheit aus.
* **Entfernung & Bereinigung:** Bereinigt alle anderen nicht ausgewählten, älteren Kernel und führt eine Systembereinigung für Abhängigkeiten durch.

## ⚠️  Haftungsausschluß

Systemwartungsskripte greifen direkt in zentrale Betriebssystemkomponenten ein. Sicherstellen, daß vor der Ausführung von Systemskripten auf Produktivservern Sicherheitskopien wichtiger Daten vorhanden sind.

## 📄 Lizenz

Dieses Projekt ist Open-Source und steht unter der **GNU General Public License, Version 3 (GPLv3)**.
