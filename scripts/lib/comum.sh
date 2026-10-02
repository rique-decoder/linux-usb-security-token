#!/usr/bin/env bash
# Funções compartilhadas; não execute diretamente.

falhar() {
    printf 'Erro: %s\n' "$*" >&2
    exit 1
}

exigir_comando() {
    command -v "$1" >/dev/null 2>&1 || falhar "comando necessário não encontrado: $1"
}

exigir_root() {
    (( EUID == 0 )) || falhar 'execute este script com sudo.'
}

exigir_terminal() {
    [[ -t 0 && -t 1 ]] || falhar 'execute em um terminal interativo; não use pipe para responder às perguntas.'
}

confirmar() {
    local resposta
    printf '%s\n' "$1"
    read -r -p 'Digite CONFIRMAR para continuar (Enter cancela): ' resposta || return 1
    [[ "$resposta" == 'CONFIRMAR' ]]
}

criar_backup() {
    # Deve ser chamada diretamente, não via $(...), para manter BACKUP_CRIADO.
    exigir_root
    exigir_comando mktemp
    local item origem destino
    local -a itens=(
        'pam.d:/etc/pam.d'
        'libpam-usb:/usr/share/pam-configs/libpam-usb'
        '80-usb.rules:/etc/udev/rules.d/80-usb.rules'
        'usb-lock.sh:/usr/local/bin/usb-lock.sh'
        'pam_usb.conf:/etc/security/pam_usb.conf'
    )
    [[ -d /etc/pam.d && -f /etc/pam.d/gdm-password ]] || falhar 'configuração PAM do GDM não encontrada.'
    BACKUP_CRIADO=$(mktemp -d /root/usb-token-backup.XXXXXX)
    chmod 700 "$BACKUP_CRIADO"
    printf 'Backup criado em %s\nData UTC: %s\n' "$BACKUP_CRIADO" "$(date -u +%FT%TZ)" > "$BACKUP_CRIADO/REGISTRO.txt"
    for item in "${itens[@]}"; do
        destino=${item%%:*}
        origem=${item#*:}
        if [[ -e "$origem" || -L "$origem" ]]; then
            if ! cp -a -- "$origem" "$BACKUP_CRIADO/$destino"; then
                printf 'INCOMPLETO: falha ao copiar %s\n' "$origem" >> "$BACKUP_CRIADO/REGISTRO.txt"
                falhar "backup incompleto em $BACKUP_CRIADO; nenhuma alteração de autenticação foi feita."
            fi
            printf 'Copiado: %s\n' "$origem" >> "$BACKUP_CRIADO/REGISTRO.txt"
        else
            printf 'Ausente: %s\n' "$origem" >> "$BACKUP_CRIADO/REGISTRO.txt"
        fi
    done
    printf 'Concluído. Pads não foram copiados.\n' >> "$BACKUP_CRIADO/REGISTRO.txt"
    printf 'Backup concluído: %s\n' "$BACKUP_CRIADO"
}
