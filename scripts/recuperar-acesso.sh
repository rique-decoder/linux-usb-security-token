#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/lib/comum.sh"

if [[ ${1:-} == '--help' ]]; then
    printf 'Uso: sudo bash scripts/recuperar-acesso.sh\nCom confirmação e backup, comenta a regra USB obrigatória do GDM.\n'
    exit 0
fi
[[ $# == 0 ]] || falhar 'argumento desconhecido; use --help.'
exigir_root
exigir_terminal
exigir_comando python3
exigir_comando cmp

if python3 "$SCRIPT_DIR/lib/editar-gdm.py" /etc/pam.d/gdm-password --check; then
    :
else
    resultado=$?
    if (( resultado == 3 )); then
        exit 0
    fi
    exit "$resultado"
fi
[[ -r /etc/pam.d/common-auth ]] || falhar 'common-auth ausente ou sem acesso; confira manualmente.'
if grep -Eq '^[[:space:]]*auth[[:space:]].*pam_usb\.so' /etc/pam.d/common-auth; then
    falhar 'há pam_usb ativo em common-auth. Este recuperador cobre apenas a configuração da Parte 02; revise o perfil global manualmente.'
fi
printf '\nEsta ação retira a exigência do pendrive no serviço gdm-password.\n'
printf 'Não desbloqueia a tela diretamente e não altera a regra de bloqueio udev.\n'
if ! confirmar 'Após conferir a alteração proposta, confirme a recuperação:'; then
    printf 'Cancelado. Nenhuma configuração foi alterada.\n'
    exit 0
fi
criar_backup
cmp -s "$BACKUP_CRIADO/pam.d/gdm-password" /etc/pam.d/gdm-password || falhar 'gdm-password mudou após o backup; nada foi alterado pelo recuperador.'
python3 "$SCRIPT_DIR/lib/editar-gdm.py" /etc/pam.d/gdm-password
printf '\nBackup anterior à recuperação: %s\n' "$BACKUP_CRIADO"
printf 'Volte à interface e inicie uma nova tentativa com sua senha. Não é necessário reiniciar o GDM.\n'
printf 'Para reativar: edite /etc/pam.d/gdm-password, retire o # da regra USB e repita os testes.\n'
printf 'Não reative o perfil USB global da Parte 01. Consulte o guia da Parte 02.\n'
