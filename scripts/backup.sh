#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/lib/comum.sh"

if [[ ${1:-} == '--help' ]]; then
    printf 'Uso: sudo bash scripts/backup.sh\nCopia configurações para um diretório privado em /root. Não altera autenticação.\n'
    exit 0
fi
[[ $# == 0 ]] || falhar 'argumento desconhecido; use --help.'
criar_backup
printf 'Guarde esse caminho. O backup contém configurações PAM; não o publique.\n'
printf 'Consulte a Parte 02 para restaurar os arquivos; este script não faz restauração automática.\n'
