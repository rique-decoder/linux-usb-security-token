# Desabilitar a autenticação por pendrive sem remover as configurações

Este documento explica como desativar a proteção por pendrive sem apagar os arquivos de configuração. A ideia é apenas comentar, desabilitar ou renomear as regras ativas, preservando o estado anterior para reativar depois.

## Visão geral

Existem dois mecanismos principais no projeto:

- Método 01: bloqueio e desbloqueio da sessão gráfica via `udev` + `usb-lock.sh` + `loginctl`
- Método 02: exigência de pendrive no `gdm-password` via `pam_usb.so`

Para desabilitar tudo de forma segura, normalmente é necessário fazer os dois passos:

1. comentar a regra do PAM no `gdm-password`
2. desabilitar ou comentar a regra do `udev` que bloqueia a sessão ao remover o pendrive

Assim, o login volta ao padrão e o bloqueio por remoção do dispositivo também deixa de atuar.

## 1) Entrar em um TTY e fazer backup

Faça login pela console (TTY) com sua conta e senha:

```bash
Ctrl + Alt + F3
# ou, no notebook, pode ser:
Ctrl + Alt + Fn + F3
```

Depois, execute:

```bash
sudo -i
backup_dir=/root/usb-token-disabled.$(date +%Y%m%d-%H%M%S)
mkdir -p "$backup_dir"

cp -a /etc/pam.d "$backup_dir/"
cp -a /etc/security/pam_usb.conf "$backup_dir/" 2>/dev/null || true
cp -a /etc/udev/rules.d/80-usb.rules "$backup_dir/" 2>/dev/null || true
cp -a /usr/share/pam-configs/libpam-usb "$backup_dir/" 2>/dev/null || true
cp -a /usr/local/bin/usb-lock.sh "$backup_dir/" 2>/dev/null || true

echo "Backup em: $backup_dir"
```

Isso não remove nada; apenas salva uma cópia do estado atual.

## 2) Método 02: desabilitar a regra do USB no GDM

Abra o arquivo do GDM:

```bash
sudo nano /etc/pam.d/gdm-password
```

Localize a linha:

```text
auth required pam_usb.so
```

e transforme em comentário:

```text
# auth required pam_usb.so
```

Salve:

```text
Ctrl + O
Enter
Ctrl + X
```

Esse ajuste remove a exigência do pendrive para autenticar no GDM. Em geral, isso é suficiente para o login voltar ao padrão (senha sem pendrive).

### Opcional: desabilitar o perfil pam_usb do sistema

Se quiser desativar o perfil em vez de apenas comentar a linha manualmente:

```bash
sudo pam-auth-update --disable libpam-usb
```

Se a interface aparecer, mantenha a autenticação do sistema habilitada e desative a opção de USB.

## 3) Método 01: desabilitar a regra udev sem apagar o arquivo

Abra a regra USB:

```bash
sudo nano /etc/udev/rules.d/80-usb.rules
```

Procure por linhas como:

```text
ACTION=="add", ... RUN+="/usr/local/bin/usb-lock.sh unlock"
ACTION=="remove", ... RUN+="/usr/local/bin/usb-lock.sh lock"
```

Comente-as:

```text
# ACTION=="add", ... RUN+="/usr/local/bin/usb-lock.sh unlock"
# ACTION=="remove", ... RUN+="/usr/local/bin/usb-lock.sh lock"
```

Ou, com shell:

```bash
sudo sed -i '/usb-lock\.sh/s/^/# /' /etc/udev/rules.d/80-usb.rules
sudo udevadm control --reload-rules
```

Isso desativa o bloqueio automático da sessão por remoção do pendrive sem remover o arquivo da regra.

## 4) Como confirmar que tudo foi desabilitado

Verifique:

```bash
grep -n "pam_usb.so" /etc/pam.d/gdm-password || true
grep -n "usb-lock.sh" /etc/udev/rules.d/80-usb.rules || true
```

Se as linhas estiverem comentadas, a proteção foi apenas desativada e não apagada.

## 5) Voltar para a interface gráfica

```bash
sudo chvt 2
```

Agora tente logar normalmente com senha, sem pendrive.

## 6) Quando cada parte deve ser desativada

### Método 02 ativo

Se o pendrive está sendo exigido no login gráfico, a etapa principal é:

```text
# auth required pam_usb.so
```

em `/etc/pam.d/gdm-password`.

### Método 01 ativo

Se a sessão está sendo bloqueada ao retirar o pendrive, a etapa principal é comentar a regra do `udev` em:

```text
/etc/udev/rules.d/80-usb.rules
```

### Ambos ativos

Se o sistema estiver com os dois métodos configurados, o procedimento completo e seguro é:

1. comentar `pam_usb.so` no `gdm-password`
2. comentar a regra do `udev` para `usb-lock.sh`
3. opcionalmente desabilitar o perfil do `pam_usb` com `pam-auth-update --disable libpam-usb`

## 7) Como reativar depois

Se quiser voltar a exigir USB, basta remover o `#` das linhas que você comentou e reativar os módulos:

```text
auth required pam_usb.so
```

E para o `udev`:

```bash
sudo udevadm control --reload-rules
```

Para reativar o perfil do pam_usb:

```bash
sudo pam-auth-update --enable libpam-usb
```

## 8) Observação final

Este processo é de “desabilitar”, não de “remover”. Ou seja:

- os arquivos ficam intactos;
- o estado anterior pode ser recuperado facilmente;
- você pode reativar a proteção sem reinstalar tudo.

Em resumo:

- para o Método 02, desative o `pam_usb.so` no `gdm-password`
- para o Método 01, desative a regra do `udev`
- para desabilitar tudo sem apagar nada, faça os dois
