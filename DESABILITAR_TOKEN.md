# Desabilitar a autenticação por pendrive sem remover as configurações

Objetivo: desativar a proteção USB (GDM + pam_usb + udev) sem apagar os arquivos de configuração. A ideia é apenas comentar/ desabilitar as regras ativas, preservando o estado anterior para reativar depois.

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

## 2) Desabilitar a regra do USB no GDM
Abra o arquivo do GDM:

```bash
sudo nano /etc/pam.d/gdm-password
```

Localize a linha:

```text
auth required pam_usb.so
```

e transforme em:

```text
# auth required pam_usb.so
```

Salve:

```text
Ctrl + O
Enter
Ctrl + X
```

Com isso, o GDM volta a aceitar senha sem pendrive.

## 3) Desabilitar o perfil pam_usb no PAM
Isso desativa o perfil gerado sem deletar o arquivo:

```bash
sudo pam-auth-update --disable libpam-usb
```

Se o sistema mostrar a interface de seleção, mantenha apenas a autenticação do sistema habilitada e desative a opção de USB.

## 4) Desabilitar as regras udev sem apagar o arquivo
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

Se quiser uma forma rápida com shell:

```bash
sudo sed -i '/usb-lock\.sh/s/^/# /' /etc/udev/rules.d/80-usb.rules
sudo udevadm control --reload-rules
```

Isso desativa o bloqueio automático do pendrive sem remover o arquivo da regra.

## 5) Confirmar que tudo ficou desabilitado
Verifique:

```bash
grep -n "pam_usb.so" /etc/pam.d/gdm-password || true
grep -n "usb-lock.sh" /etc/udev/rules.d/80-usb.rules || true
```

Se as linhas estiverem comentadas, a proteção foi apenas desativada, e não apagada.

## 6) Voltar para a interface gráfica
```bash
sudo chvt 2
```

Agora tente logar normalmente com senha, sem pendrive.

## 7) Como reativar depois
Se quiser voltar a exigir USB, basta remover os `#` das linhas que você comentou:

```text
auth required pam_usb.so
```

e reativar o perfil:

```bash
sudo pam-auth-update --enable libpam-usb
sudo udevadm control --reload-rules
```

## Observação
Esse processo é “desabilitar” e não “remover”. Ou seja:
- os arquivos ficam intactos;
- o estado anterior pode ser recuperado facilmente;
- você pode reativar sem reinstalar tudo.
