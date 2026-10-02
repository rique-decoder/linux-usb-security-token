#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/lib/comum.sh"

if [[ ${1:-} == '--help' ]]; then
    printf 'Uso: sudo bash scripts/testar-autenticacao.sh [usuario]\nGuia três testes reais do serviço gdm-password com pamtester.\n'
    exit 0
fi
[[ $# -le 1 ]] || falhar 'use somente um nome de usuário.'
exigir_root
exigir_terminal
exigir_comando pamtester
exigir_comando getent
usuario=${1:-${SUDO_USER:-}}
[[ -n "$usuario" && "$usuario" != root ]] || falhar 'informe a conta cadastrada, por exemplo: sudo bash scripts/testar-autenticacao.sh henrique'
[[ "$usuario" =~ ^[a-zA-Z_][a-zA-Z0-9_.-]*\$?$ ]] || falhar 'nome de usuário inválido.'
getent passwd "$usuario" >/dev/null || falhar 'usuário não encontrado.'
[[ -r /etc/pam.d/gdm-password ]] || falhar 'serviço gdm-password não encontrado.'
if ! grep -Eq '^[[:space:]]*auth[[:space:]]+required[[:space:]]+pam_usb\.so([[:space:]]|$)' /etc/pam.d/gdm-password; then
    falhar 'regra USB obrigatória ausente no GDM; confira a Parte 02 antes de testar.'
fi
[[ -r /etc/pam.d/common-auth ]] || falhar 'common-auth ausente ou sem acesso; confira manualmente.'
if grep -Eq '^[[:space:]]*auth[[:space:]].*pam_usb\.so' /etc/pam.d/common-auth; then
    falhar 'perfil USB ainda ativo em common-auth; confira a Parte 02 antes de testar.'
fi
printf 'Conta testada: %s\nServiço: gdm-password\n' "$usuario"
printf 'A senha deve ser digitada somente no prompt do pamtester. Ela não será armazenada.\n'
printf 'Execute preferencialmente no TTY. Retirar o USB pode bloquear a sessão gráfica.\n'
printf 'Termine gravações e desmonte o volume antes de retirar o pendrive.\n'
printf 'A verificação do pam_usb pode renovar pads. O script não modifica arquivos PAM.\n'
if ! confirmar 'Iniciar os três testes?'; then
    printf 'Testes cancelados.\n'
    exit 0
fi

declare -a codigos=()
declare -a resultados=()
for numero in 1 2 3; do
    printf '\n=== Teste %s de 3 ===\n' "$numero"
    case "$numero" in
        1) printf 'Conecte o pendrive cadastrado. Digite a senha CORRETA de %s.\n' "$usuario" ;;
        2) printf 'Mantenha o pendrive conectado. Digite uma senha propositalmente INCORRETA.\n' ;;
        3) printf 'Desmonte o volume e retire o pendrive. Digite a senha CORRETA de %s.\n' "$usuario" ;;
    esac
    read -r -p 'Pressione Enter quando estiver pronto (Ctrl+C cancela): ' _ || falhar 'entrada encerrada; teste interrompido.'
    if pamtester gdm-password "$usuario" authenticate; then
        codigo=0
        resultado='SUCESSO'
    else
        codigo=$?
        resultado='FALHA'
    fi
    codigos+=("$codigo")
    resultados+=("$resultado")
    printf 'Resultado observado: %s (código %s).\n' "$resultado" "$codigo"
    if (( numero == 1 && codigo != 0 )); then
        printf 'O teste positivo falhou; interrompendo para diagnóstico. Confira USB, pads e senha.\n' >&2
        exit 1
    fi
    if (( numero > 1 && codigo == 0 )); then
        printf 'Sucesso inesperado. Confira a condição física, a senha digitada e a configuração PAM.\n' >&2
        exit 1
    fi
done
printf '\n=== Resumo ===\n'
printf 'USB + senha correta: %s\nUSB + senha incorreta: %s\nSem USB + senha correta: %s\n' "${resultados[0]}" "${resultados[1]}" "${resultados[2]}"
printf 'A sequência corresponde ao esperado se você seguiu as condições de cada teste.\n'
printf 'Uma falha negativa também pode ser erro do serviço: confira as mensagens acima.\n'
printf 'Ainda valide a tela gráfica, remoção/reconexão, logout e reinicialização conforme a Parte 02.\n'
