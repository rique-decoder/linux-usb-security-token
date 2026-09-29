# USB como Token de Autenticação no Linux

Projeto experimental para transformar um pendrive USB comum em um
mecanismo de autenticação/controle de sessão no Linux.

O projeto está sendo desenvolvido e testado em uma máquina virtual com
Debian 13 e será dividido em duas abordagens:

1.  Controle de sessão utilizando `udev`, `loginctl` e um script Bash.
2.  Autenticação utilizando PAM (`pam_usb`).

> **Status atual:** Etapa 1 funcionando.

------------------------------------------------------------------------

## 1. Ambiente utilizado

-   Debian 13
-   VirtualBox
-   Pendrive SanDisk Cruzer Blade
-   USB ID: `0781:5567`
-   Usuário de teste: `rique`
-   Sessão gráfica gerenciada pelo `systemd-logind`

------------------------------------------------------------------------

## 2. Objetivo da primeira etapa

A primeira implementação não modifica diretamente o processo de login do
Linux.

O objetivo é controlar uma sessão gráfica já iniciada:

-   Pendrive conectado → sessão desbloqueada
-   Pendrive removido → sessão bloqueada

O funcionamento geral é:

``` text
USB
 ↓
udev
 ↓
Regra 80-usb.rules
 ↓
usb-lock.sh
 ↓
loginctl
 ↓
Bloqueio/desbloqueio da sessão
```

**Importante:** nesta etapa, o pendrive não é necessário para realizar o
primeiro login após inicializar o sistema. Isso será explorado
posteriormente utilizando PAM.

------------------------------------------------------------------------

## 3. Identificação do dispositivo USB

Primeiramente, o dispositivo foi identificado com:

``` bash
lsusb
```

O pendrive utilizado apareceu como:

``` text
Bus ... Device ...: ID 0781:5567 SanDisk Corp. Cruzer Blade
```

Portanto:

-   Vendor ID: `0781`
-   Product ID: `5567`

Também foi possível confirmar as propriedades reconhecidas pelo `udev`:

``` bash
udevadm info --query=property --name=/dev/sdb
```

E especificamente:

``` bash
udevadm info --query=property --name=/dev/sdb | grep -E 'ID_VENDOR_ID|ID_MODEL_ID'
```

Resultado:

``` text
ID_MODEL_ID=5567
ID_VENDOR_ID=0781
```

------------------------------------------------------------------------

## 4. Regra udev

Foi criado o arquivo:

``` text
/etc/udev/rules.d/80-usb.rules
```

Com regras para detectar a inserção e remoção do dispositivo:

``` udev
ACTION=="add", SUBSYSTEMS=="usb", ATTR{idVendor}=="0781", ATTR{idProduct}=="5567", RUN+="/usr/local/bin/usb-lock.sh unlock"

ACTION=="remove", SUBSYSTEMS=="usb", ENV{ID_VENDOR_ID}=="0781", ENV{ID_MODEL_ID}=="5567", RUN+="/usr/local/bin/usb-lock.sh lock"
```

Após modificar as regras:

``` bash
sudo udevadm control --reload-rules
```

A sintaxe também pode ser verificada com:

``` bash
sudo udevadm verify /etc/udev/rules.d/80-usb.rules
```

------------------------------------------------------------------------

## 5. Script de controle da sessão

Foi criado:

``` text
/usr/local/bin/usb-lock.sh
```

O script identifica a sessão gráfica do usuário `rique` associada ao
`seat0`:

``` bash
#!/bin/bash

SESSION_ID=$(loginctl list-sessions --no-legend | awk '$3=="rique" && $4=="seat0" {print $1; exit}')

if [ "$1" == "lock" ]; then
    loginctl lock-session "$SESSION_ID"
elif [ "$1" == "unlock" ]; then
    loginctl unlock-session "$SESSION_ID"
fi
```

O script precisa ser executável:

``` bash
sudo chmod +x /usr/local/bin/usb-lock.sh
```

### Por que não utilizar um ID fixo?

O ID da sessão pode mudar após logout ou reinicialização.

Por exemplo:

``` text
2  1000  rique  seat0
```

pode posteriormente se tornar:

``` text
5  1000  rique  seat0
```

Por isso, o script procura dinamicamente a sessão gráfica do usuário em
vez de utilizar um número fixo.

------------------------------------------------------------------------

## 6. Problemas encontrados

### 6.1 `aws: comando não encontrado`

O script inicialmente continha:

``` bash
aws '{print $1}'
```

O correto era:

``` bash
awk '{print $1}'
```

### 6.2 SESSION_ID sendo interpretado literalmente

Inicialmente havia:

``` bash
loginctl lock-session "SESSION_ID"
```

Isso fazia o `loginctl` procurar literalmente uma sessão chamada
`SESSION_ID`.

A variável precisa ser referenciada com `$`:

``` bash
loginctl lock-session "$SESSION_ID"
```

### 6.3 IDs USB com `< >`

Inicialmente a regra continha:

``` udev
ATTR{idVendor}=="<0781>"
ATTR{idProduct}=="<5567>"
```

Os símbolos `< >` presentes no tutorial eram apenas placeholders.

O correto é:

``` udev
ATTR{idVendor}=="0781"
ATTR{idProduct}=="5567"
```

### 6.4 `udev` executava o script, mas a tela não bloqueava

Foi adicionado temporariamente um log ao script:

``` bash
echo "$(date) argumento=$1" >> /tmp/usb-lock.log
```

Isso demonstrou que o `udev` estava executando corretamente:

``` text
argumento=unlock
argumento=lock
```

Portanto, o problema não estava mais na regra `udev`.

### 6.5 Sessão incorreta sendo selecionada

O script originalmente procurava o usuário desta forma:

``` bash
loginctl list-sessions | grep 'rique' | awk '{print $1}' | head -n 1
```

Porém, existiam múltiplas sessões relacionadas ao usuário.

O script acabou selecionando uma sessão `manager`, por exemplo:

``` text
SESSION_ID='3'
```

em vez da sessão gráfica real.

A solução foi procurar especificamente a sessão do usuário associada ao
`seat0`:

``` bash
SESSION_ID=$(loginctl list-sessions --no-legend | awk '$3=="rique" && $4=="seat0" {print $1; exit}')
```

Após essa alteração, a remoção do pendrive passou a bloquear
corretamente a sessão.

------------------------------------------------------------------------

## 7. Testes realizados

### Remoção do pendrive

``` text
Pendrive removido
       ↓
udev detecta "remove"
       ↓
usb-lock.sh lock
       ↓
loginctl lock-session
       ↓
Sessão bloqueada
```

**Resultado:** funcionando.

### Inserção do pendrive

``` text
Pendrive conectado
       ↓
udev detecta "add"
       ↓
usb-lock.sh unlock
       ↓
loginctl unlock-session
       ↓
Sessão desbloqueada
```

**Resultado:** funcionando.

### Reinicialização

A máquina virtual foi desligada/reiniciada para verificar a persistência
da configuração.

Após a reinicialização:

-   regras `udev` continuaram funcionando;
-   remoção do USB continuou bloqueando a sessão;
-   inserção do USB continuou desbloqueando a sessão;
-   não foi necessário configurar novamente o ID da sessão.

**Resultado:** funcionando.

------------------------------------------------------------------------

## 8. Limitações da implementação atual

Esta implementação controla uma sessão existente, mas não substitui a
autenticação do sistema.

Portanto, após inicializar o Debian, ainda é possível realizar o login
normalmente sem o pendrive.

Além disso, atualmente o script está configurado especificamente para:

``` text
rique
```

Ele encontra dinamicamente a sessão desse usuário, mas ainda não é uma
implementação global para qualquer usuário do sistema.

Outro ponto importante é que a identificação atual utiliza Vendor ID e
Product ID. Dois dispositivos USB do mesmo modelo podem compartilhar
esses identificadores. Portanto, esta implementação deve ser tratada
como um experimento de autenticação/controle de sessão, e não como
equivalente de segurança a uma chave de hardware dedicada.

------------------------------------------------------------------------

## 9. Próxima etapa --- PAM

A próxima etapa do projeto será estudar a autenticação através do PAM
(Pluggable Authentication Modules).

O objetivo será comparar o método atual com uma solução que participe
efetivamente do processo de autenticação do Linux.

### A fazer

-   [x] Instalar Debian 13 na VM
-   [x] Configurar passthrough USB no VirtualBox
-   [x] Identificar Vendor ID e Product ID
-   [x] Criar regra `udev`
-   [x] Criar script Bash
-   [x] Detectar inserção do pendrive
-   [x] Detectar remoção do pendrive
-   [x] Bloquear sessão ao remover USB
-   [x] Desbloquear sessão ao inserir USB
-   [x] Testar após reinicialização
-   [ ] Remover código temporário de debug
-   [ ] Estudar `pam_usb`
-   [ ] Instalar e configurar PAM
-   [ ] Testar autenticação no login
-   [ ] Comparar as duas abordagens

------------------------------------------------------------------------

## Referências

-   Aniket Bhattacharyea --- *Use your USB as security key in Linux*
-   Linux Uprising --- *How To Login With A USB Flash Drive Instead Of A
    Password On Linux Using pam_usb*
-   LinuxConfig --- *USB Authentication on Linux with PAM Setup*
