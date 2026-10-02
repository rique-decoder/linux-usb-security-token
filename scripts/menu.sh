#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/lib/comum.sh"

if [[ ${1:-} == '--help' ]]; then
    printf 'Uso: bash scripts/menu.sh\nMenu de diagnóstico, backup, testes e recuperação.\n'
    exit 0
fi
[[ $# == 0 ]] || falhar 'argumento desconhecido; use --help.'
exigir_terminal

administrar() {
    if (( EUID == 0 )); then
        bash "$@"
    else
        exigir_comando sudo
        sudo bash "$@"
    fi
}

while true; do
    printf '\nLinux USB Security Token\n'
    printf '1. Consultar diagnóstico\n2. Criar backup\n3. Testar autenticação\n4. Recuperar acesso gráfico\n0. Sair\n'
    read -r -p 'Escolha: ' escolha || exit 0
    case "$escolha" in
        1) bash "$SCRIPT_DIR/diagnostico.sh" || printf 'Diagnóstico terminou com erro.\n' ;;
        2) administrar "$SCRIPT_DIR/backup.sh" || printf 'Backup terminou com erro.\n' ;;
        3)
            read -r -p "Usuário cadastrado [${SUDO_USER:-${USER:-henrique}}]: " usuario || exit 0
            usuario=${usuario:-${SUDO_USER:-${USER:-henrique}}}
            administrar "$SCRIPT_DIR/testar-autenticacao.sh" "$usuario" || printf 'Teste interrompido ou terminou com erro; confira as mensagens.\n'
            ;;
        4) administrar "$SCRIPT_DIR/recuperar-acesso.sh" || printf 'Recuperação terminou com erro; confira as mensagens.\n' ;;
        0) exit 0 ;;
        *) printf 'Opção inválida.\n' ;;
    esac
done
