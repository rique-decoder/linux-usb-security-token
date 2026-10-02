#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/lib/comum.sh"

if [[ ${1:-} == '--help' ]]; then
    printf 'Uso: bash scripts/diagnostico.sh\nConsulta o ambiente; não altera PAM, regras, montagem ou pads.\n'
    exit 0
fi
[[ $# == 0 ]] || falhar 'argumento desconhecido; use --help.'

printf '\n=== Sistema ===\n'
if [[ -r /etc/os-release ]]; then
    grep -E '^(PRETTY_NAME|VERSION_ID|VERSION_CODENAME)=' /etc/os-release || true
fi
printf 'Usuário do terminal: %s\n' "$(id -un)"
printf 'Tipo de sessão informado: %s\n' "${XDG_SESSION_TYPE:-não informado}"

printf '\n=== Discos e volumes ===\n'
if command -v lsblk >/dev/null 2>&1; then
    lsblk -o NAME,TRAN,SIZE,FSTYPE,UUID,MOUNTPOINTS,MODEL || printf 'Não foi possível consultar os volumes.\n'
fi

printf '\n=== Ferramentas ===\n'
for ferramenta in pamusb-check pamusb-conf pamtester loginctl udevadm python3; do
    if command -v "$ferramenta" >/dev/null 2>&1; then
        printf '%s: disponível\n' "$ferramenta"
    else
        printf '%s: não encontrado\n' "$ferramenta"
    fi
done

printf '\n=== PAM compartilhado: linhas auth ativas ===\n'
if [[ -r /etc/pam.d/common-auth ]]; then
    grep -nE '^[[:space:]]*auth[[:space:]]' /etc/pam.d/common-auth || true
else
    printf 'Arquivo ausente ou sem permissão de leitura.\n'
fi
printf '\n=== GDM: autenticação e includes ===\n'
if [[ -r /etc/pam.d/gdm-password ]]; then
    grep -nE '^[[:space:]]*(auth[[:space:]]|@include[[:space:]])' /etc/pam.d/gdm-password || true
else
    printf 'Arquivo ausente ou sem permissão de leitura.\n'
fi

printf '\n=== Regras USB locais ativas ===\n'
if [[ -r /etc/udev/rules.d/80-usb.rules ]]; then
    grep -nE '^[[:space:]]*[^#[:space:]]' /etc/udev/rules.d/80-usb.rules || true
else
    printf '80-usb.rules ausente ou sem permissão de leitura.\n'
fi
printf '\n=== XML do pam_usb ===\n'
if [[ -e /etc/security/pam_usb.conf ]]; then
    printf 'Encontrado /etc/security/pam_usb.conf; conteúdo e pads não serão exibidos.\n'
else
    printf '/etc/security/pam_usb.conf não encontrado.\n'
fi
printf '\n=== Agente em execução ===\n'
if command -v pgrep >/dev/null 2>&1; then
    pgrep -af '[p]amusb-agent' || printf 'Nenhum pamusb-agent encontrado.\n'
fi
printf '\n=== Sessões ===\n'
if command -v loginctl >/dev/null 2>&1; then
    loginctl list-sessions --no-pager || printf 'Não foi possível consultar logind.\n'
fi
printf '\nDiagnóstico concluído. A presença das regras não comprova autenticação nem segurança.\n'
printf 'Este script não executa pamusb-check: a verificação USB pode renovar pads.\n'
printf 'Revise identificadores e informações pessoais antes de compartilhar a saída.\n'
