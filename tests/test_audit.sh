#!/usr/bin/env bash

set -u

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_FILE="/tmp/linux-audit-test-output.txt"

cd "$PROJECT_DIR" || exit 1

echo "=== TESTS DU LINUX SERVER HARDENING ==="

if ! bash scripts/audit.sh > "$OUTPUT_FILE" 2>&1; then
    echo "[FAIL] L'exécution de l'audit a échoué."
    exit 1
fi

FAILURES=0
TOTAL=7

check_output() {
    local description="$1"
    local pattern="$2"

    if grep -Eq "$pattern" "$OUTPUT_FILE"; then
        echo "[PASS] $description"
    else
        echo "[FAIL] $description"
        FAILURES=$((FAILURES + 1))
    fi
}

check_output "Informations système présentes" "===== SYSTEME ====="
check_output "Comptes UID 0 présents" "===== COMPTES AVEC UID 0 ====="
check_output "Section pare-feu présente" "===== PARE-FEU UFW ====="
check_output "Section SSH présente" "===== SERVICE SSH ====="
check_output "Permissions vérifiées" "===== PERMISSIONS DES FICHIERS SENSIBLES ====="
check_output "Résumé de sécurité présent" "PASS : [0-9]+"

REPORT_PATH=$(grep -oE 'Rapport créé : reports/audit-[^[:space:]]+' \
    "$OUTPUT_FILE" | tail -n 1 | sed 's/^Rapport créé : //')

if [ -n "$REPORT_PATH" ] && [ -f "$PROJECT_DIR/$REPORT_PATH" ]; then
    echo "[PASS] Rapport d'audit créé"
else
    echo "[FAIL] Rapport d'audit introuvable"
    FAILURES=$((FAILURES + 1))
fi

echo
echo "Tests reussis : $((TOTAL - FAILURES))/$TOTAL"
if [ "$FAILURES" -gt 0 ]; then
	exit 1
fi

echo "Tous les tests sont reussis."
