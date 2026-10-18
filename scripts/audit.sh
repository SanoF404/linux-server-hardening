#!/usr/bin/env bash

set -u
umask 077

REPORT_DIR="reports"
mkdir -p "$REPORT_DIR"

REPORT_FILE="$REPORT_DIR/audit-$(date +%Y%m%d-%H%M%S).txt"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

section() {
    printf '\n\n===== %s =====\n' "$1"
}

check_pass() {
    printf '[PASS] %s\n' "$1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

check_warn() {
    printf '[WARN] %s\n' "$1"
    WARN_COUNT=$((WARN_COUNT + 1))
}

check_fail() {
    printf '[FAIL] %s\n' "$1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

{
    echo "LINUX SERVER HARDENING - SECURITY AUDIT"
    echo "Date : $(date)"
    echo "Utilisateur : $(id -un)"
    echo "Hostname : $(hostname)"

    section "SYSTEME"
    cat /etc/os-release
    uname -a

    section "COMPTES AVEC UID 0"

    ROOT_ACCOUNTS=$(awk -F: '$3 == 0 {print $1}' /etc/passwd)
    printf '%s\n' "$ROOT_ACCOUNTS"

    if [ "$ROOT_ACCOUNTS" = "root" ]; then
        check_pass "Seul root possède l'UID 0."
    else
        check_fail "Un ou plusieurs comptes supplémentaires possèdent l'UID 0."
    fi

    section "PARE-FEU UFW"

    if command -v ufw >/dev/null 2>&1; then
        UFW_STATUS=$(sudo ufw status 2>&1)
        printf '%s\n' "$UFW_STATUS"

        if printf '%s\n' "$UFW_STATUS" | grep -q '^Status: active'; then
            check_pass "Le pare-feu UFW est actif."
        elif printf '%s\n' "$UFW_STATUS" | grep -q '^Status: inactive'; then
            check_warn "UFW est inactif. Vérifier la configuration réseau."
        else
            check_warn "Impossible de déterminer l'état de UFW."
        fi
    else
        check_warn "UFW n'est pas installé."
    fi

    section "SERVICE SSH"

    if command -v systemctl >/dev/null 2>&1; then
        SSH_SOCKET=$(systemctl is-active ssh.socket 2>/dev/null || true)
        SSH_SERVICE=$(systemctl is-active ssh.service 2>/dev/null || true)

        echo "Socket SSH : $SSH_SOCKET"
        echo "Service SSH : $SSH_SERVICE"

        if [ "$SSH_SOCKET" = "active" ] || [ "$SSH_SERVICE" = "active" ]; then
            check_warn "SSH est actif ou disponible via socket activation. Vérifier si nécessaire."
        else
            check_pass "Le socket SSH et le service SSH sont inactifs."
        fi
    else
        check_warn "systemctl est indisponible."
    fi

    section "PERMISSIONS DES FICHIERS SENSIBLES"

    ls -l /etc/passwd /etc/shadow

    PASSWD_MODE=$(stat -c '%a' /etc/passwd)
    SHADOW_MODE=$(stat -c '%a' /etc/shadow)

    if [ "$PASSWD_MODE" = "644" ] || [ "$PASSWD_MODE" = "640" ] || [ "$PASSWD_MODE" = "600" ]; then
        check_pass "Les permissions de /etc/passwd sont raisonnables ($PASSWD_MODE)."
    else
        check_warn "Vérifier les permissions de /etc/passwd ($PASSWD_MODE)."
    fi

    if [ "$SHADOW_MODE" = "640" ] || [ "$SHADOW_MODE" = "600" ]; then
        check_pass "Les permissions de /etc/shadow sont restrictives ($SHADOW_MODE)."
    else
        check_fail "Les permissions de /etc/shadow méritent une vérification ($SHADOW_MODE)."
    fi

    section "PORTS EN ECOUTE"

    if command -v ss >/dev/null 2>&1; then
        ss -tuln
    else
        check_warn "La commande ss est indisponible."
    fi

    section "RESUME"

    echo "PASS : $PASS_COUNT"
    echo "WARN : $WARN_COUNT"
    echo "FAIL : $FAIL_COUNT"

    echo
    echo "Ces résultats sont des indicateurs automatiques."
    echo "Les avertissements doivent être interprétés selon le contexte."
    echo "Aucune configuration système n'a été modifiée par cet audit."

} 2>&1 | tee "$REPORT_FILE"

echo
echo "Rapport créé : $REPORT_FILE"
