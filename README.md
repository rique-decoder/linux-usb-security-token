# Linux USB Security

Projeto experimental para estudar diferentes formas de utilizar
dispositivos USB como mecanismos de segurança em sistemas Linux.

A proposta é implementar, testar e documentar diferentes abordagens,
desde o controle de uma sessão gráfica com eventos do sistema até a
utilização do USB durante o processo de autenticação.

Os testes são realizados inicialmente em uma máquina virtual com
**Debian 13**, utilizando o **Oracle VirtualBox**.

> Este projeto possui finalidade educacional e experimental.

------------------------------------------------------------------------

## Objetivo

O objetivo principal é estudar como um dispositivo USB comum pode
participar de diferentes mecanismos de segurança no Linux.

Atualmente, o projeto está dividido em duas abordagens:

### Método 1 --- Controle de sessão com udev

Utiliza:

-   `udev`
-   Bash
-   `loginctl`
-   `systemd-logind`

O sistema monitora a conexão e remoção de um dispositivo USB específico.

Quando o dispositivo é removido, a sessão gráfica do usuário é
bloqueada.

Quando o dispositivo é conectado novamente, a sessão é desbloqueada.

``` text
USB
 ↓
udev
 ↓
Regra do dispositivo
 ↓
Script Bash
 ↓
loginctl
 ↓
Bloqueio / desbloqueio da sessão
```

Este método **não realiza autenticação no login do sistema**. Ele atua
somente sobre uma sessão de usuário existente.

**Status:** funcionando.

------------------------------------------------------------------------

### Método 2 --- Autenticação com PAM

A segunda abordagem utiliza o **PAM (Pluggable Authentication Modules)**
para integrar o dispositivo USB ao processo de autenticação do Linux.

O objetivo é estudar uma implementação na qual a presença e/ou
identificação do dispositivo USB seja utilizada durante a autenticação
do usuário.

Esta abordagem permitirá comparar um simples controle de sessão com um
mecanismo integrado ao sistema de autenticação.

**Status:** em desenvolvimento.

------------------------------------------------------------------------

## Estrutura do projeto

A organização planejada para o repositório é:

``` text
linux-usb-security/
│
├── README.md
│
├── udev-session-control/
│   ├── README.md
│   ├── 80-usb.rules
│   └── usb-lock.sh
│
└── pam-authentication/
    ├── README.md
    └── ...
```

Cada implementação possui sua própria documentação, contendo os passos
realizados, configurações, testes, problemas encontrados e limitações.

------------------------------------------------------------------------

## Ambiente de testes

A implementação inicial está sendo desenvolvida utilizando:

-   Debian 13
-   Oracle VirtualBox
-   Pendrive SanDisk Cruzer Blade
-   `systemd`
-   `udev`
-   `loginctl`

O uso de uma máquina virtual permite testar alterações relacionadas a
autenticação e segurança sem modificar diretamente o sistema operacional
principal.

------------------------------------------------------------------------

## Progresso

### Controle de sessão com udev

-   [x] Configurar USB no VirtualBox
-   [x] Identificar o dispositivo USB
-   [x] Criar regras `udev`
-   [x] Criar script de controle da sessão
-   [x] Detectar remoção do dispositivo
-   [x] Bloquear a sessão automaticamente
-   [x] Detectar conexão do dispositivo
-   [x] Desbloquear a sessão automaticamente
-   [x] Testar persistência após reinicialização

### Autenticação com PAM

-   [ ] Estudar funcionamento do PAM
-   [ ] Configurar autenticação utilizando USB
-   [ ] Testar autenticação com o dispositivo conectado
-   [ ] Testar comportamento sem o dispositivo
-   [ ] Documentar a implementação
-   [ ] Comparar com o método baseado em `udev`

------------------------------------------------------------------------

## Diferença entre as abordagens

  Característica                     udev + loginctl   PAM
  ---------------------------------- ----------------- -------------------------
  Detecta o dispositivo USB          Sim               Sim
  Bloqueia uma sessão existente      Sim               Depende da configuração
  Desbloqueia uma sessão existente   Sim               Depende da configuração
  Participa do login inicial         Não               Sim
  Atua no sistema de autenticação    Não               Sim
  Implementação atual                Concluída         Em desenvolvimento

Essa diferença é importante: o primeiro método utiliza o USB como um
**gatilho para controle da sessão**, enquanto o segundo busca utilizar o
dispositivo como parte do **processo de autenticação**.

------------------------------------------------------------------------

## Segurança

Este projeto é um experimento educacional e não deve ser considerado uma
substituição direta para dispositivos de autenticação desenvolvidos
especificamente para segurança, como chaves compatíveis com FIDO2/U2F.

Na primeira implementação, por exemplo, o dispositivo é identificado
utilizando informações fornecidas pelo USB. Dependendo da configuração
utilizada, essas informações podem não identificar exclusivamente um
dispositivo físico.

As limitações de cada abordagem serão documentadas conforme os testes
forem realizados.

------------------------------------------------------------------------

## Documentação

Cada método possui documentação própria.

### udev-session-control

Documenta a implementação já funcional baseada em `udev`, Bash e
`loginctl`, incluindo:

-   identificação do USB;
-   criação das regras;
-   criação do script;
-   identificação dinâmica da sessão;
-   erros encontrados;
-   correções realizadas;
-   testes após reinicialização.

### pam-authentication

Será utilizado para documentar a segunda etapa do projeto, envolvendo
PAM e autenticação.

------------------------------------------------------------------------

## Status do projeto

``` text
[██████████] udev-session-control  → Concluído
[░░░░░░░░░░] pam-authentication   → Próxima etapa
```

O projeto continuará sendo atualizado conforme novos métodos forem
implementados e testados.

------------------------------------------------------------------------

## Referências

Os métodos estudados neste projeto foram baseados inicialmente nos
seguintes materiais:

-   Aniket Bhattacharyea --- *Use your USB as security key in Linux*
-   Linux Uprising --- *How To Login With A USB Flash Drive Instead Of A
    Password On Linux Using pam_usb*
-   LinuxConfig --- *USB Authentication on Linux with PAM Setup*

------------------------------------------------------------------------

## Aviso

Alterações em regras `udev`, PAM e outros componentes de autenticação
podem impedir o acesso ao sistema quando configuradas incorretamente.

Os experimentos deste projeto são realizados inicialmente em uma máquina
virtual para reduzir o risco de perda de acesso ao sistema principal.
