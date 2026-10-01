# Método 02 — Parte 01: Autenticação USB ou Senha com pam_usb

## Objetivo

Nesta etapa foi implementada uma autenticação utilizando o pendrive como dispositivo de segurança, mantendo a senha tradicional do usuário como alternativa.

Resultado esperado:

- Com USB conectado → login sem digitar senha.
- Sem USB conectado → login utilizando senha normalmente.

O USB ainda não é obrigatório nesta etapa.

---

# 1. Instalação do pam_usb

Foi utilizada a versão 0.9.3 do `pam_usb`.

Dependências:

```bash
sudo apt update

sudo apt install git build-essential pkg-config libpam0g-dev libudisks2-dev libdbus-1-dev libxml2-dev libglib2.0-dev libudev-dev libevdev-dev python3 python3-gi python3-dotenv udisks2 gir1.2-udisks-2.0 gawk
```

![instalação](./images/Captura%20de%20tela%20de%202026-10-01%2017-06-56.png)


Clone do projeto:

```bash
mkdir -p ~/projetos
cd ~/projetos

git clone --branch 0.9.3 --depth 1 https://github.com/mcdope/pam_usb.git

cd pam_usb
```

Compilação:

```bash
make
sudo make install
```

Validação:

```bash
command -v pamusb-check
command -v pamusb-conf
pamusb-check --version
```

Resultado esperado:

```text
Version 0.9.3
```
![verificando pam](./images/Captura%20de%20tela%20de%202026-10-01%2017-10-53.png)



---

# 2. Cadastro do dispositivo USB

O pendrive utilizado foi:

- SanDisk Cruzer Blade
- Serial: `4C530101421215115090`

Cadastro:

```bash
sudo pamusb-conf --add-device SanDisk
```

![config usb drive](./images/Captura%20de%20tela%20de%202026-10-01%2017-11-12.png)

Depois:

```bash
sudo pamusb-conf --add-user henrique
```


![config user](./images/Captura%20de%20tela%20de%202026-10-01%2017-11-25.png)


Teste com USB conectado e depois desconectado:

```bash
pamusb-check henrique
```

![checagem login](./images/Captura%20de%20tela%20de%202026-10-01%2017-12-05.png)


---

# 3. Configuração do PAM

A autenticação USB foi ativada usando:

```bash
sudo pam-auth-update
```

Mantendo:

- USB Authentication
- Unix authentication

Configuração gerada:

```text
auth sufficient pam_usb.so
auth [success=1 default=ignore] pam_unix.so nullok try_first_pass
```

![config. pam](./images/Captura%20de%20tela%20de%202026-10-01%2017-12-20.png)

Funcionamento:

```
USB OU senha
```


---

# 4. Testes de autenticação

## Login utilizando USB

Com o pendrive conectado:

- Logout realizado.
- Usuário selecionado no GDM.
- Entrada realizada sem digitar senha.


---

## Login utilizando senha

Com o pendrive removido:

- Login tradicional realizado.
- Senha aceita normalmente.


---

# 5. Validação após reinicialização

O computador foi reiniciado com o pendrive conectado.

Resultado:

O login utilizando apenas o USB continuou funcionando.


---

# 6. Problema encontrado: One Time Pads

Durante os testes ocorreu:

```text
Pad checking failed!
```

Foi identificado que os pads do sistema e do pendrive estavam diferentes.

A causa foi corrupção no sistema de arquivos FAT do pendrive após uma remoção sem desmontagem correta.

Foi executado:

```bash
sudo fsck.fat -a -v /dev/sda1
```

Após o reparo:

- Sistema FAT corrigido.
- Volume voltou para modo leitura/escrita.
- Pads foram regenerados.

Comparação:

```bash
cmp -s /home/henrique/.pamusb/SanDisk.pad /media/henrique/9EE3-C03C/.pamusb/henrique.debian.pad
```

Resultado:

```text
0
```

![corrigindo one-time-pad](./images/Captura%20de%20tela%20de%202026-10-01%2017-13-08.png)


---

# 7. GNOME Keyring e Google Online Accounts

O login utilizando USB funciona, porém o GNOME Keyring continua protegido.

Motivo:

- O login via USB autentica o usuário.
- A senha não foi digitada durante o login.
- O GNOME Keyring não recebe automaticamente essa senha.

A conta Google do GNOME também foi validada após reiniciar o serviço `goa-daemon`.


---

# Estado final

| Função | Resultado |
|-|-|
| Login via USB | Funcionando |
| Login via senha | Funcionando |
| One Time Pads | Funcionando |
| Reinicialização validada | Funcionando |
| Método 1 reativado | Funcionando |
| GNOME Keyring protegido | Mantido |

---

# Próxima etapa

Método 02 — Parte 02:

Alterar a política atual:

```
USB OU senha
```

para:

```
USB E senha
```

Objetivo:

- USB sozinho não autentica.
- Senha sozinha não autentica.
- USB + senha serão necessários.
