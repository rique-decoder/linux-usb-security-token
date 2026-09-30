# Método 2 --- Autenticação USB com PAM

Esta documentação registra a segunda abordagem do projeto **Linux USB
Security**: utilizar um pendrive como parte real do processo de
autenticação do Linux através do **PAM (Pluggable Authentication
Modules)** e do `pam_usb`.

Diferentemente do primeiro método, baseado em `udev`, Bash e `loginctl`,
esta implementação participa efetivamente da autenticação do usuário.

A implementação foi dividida em duas partes:

1.  **Parte 1 --- USB ou senha:** o pendrive autentica o usuário sem
    senha, mas a senha tradicional continua disponível como alternativa.
2.  **Parte 2 --- USB obrigatório:** a autenticação pelo pendrive passa
    a ser obrigatória.

> **Status atual:** Parte 1 concluída e validada. Parte 2 ainda será
> implementada e testada.

------------------------------------------------------------------------

## 1. Ambiente utilizado

-   Debian 13.7
-   Arquitetura `x86_64`
-   Oracle VirtualBox
-   Pendrive SanDisk Cruzer Blade
-   USB ID: `0781:5567`
-   Usuário de teste: `rique`
-   GDM como gerenciador de login gráfico
-   PAM
-   `pam_usb` 0.9.3

O dispositivo USB foi confirmado com:

``` bash
lsusb
```

Resultado relevante:

``` text
ID 0781:5567 SanDisk Corp. Cruzer Blade
```

------------------------------------------------------------------------

# Parte 1 --- Autenticação com USB ou senha

## 2. Objetivo

Nesta primeira configuração, o pendrive funciona como uma alternativa à
senha.

``` text
Pendrive válido conectado
        ↓
pam_usb
        ↓
Autenticação aceita
        ↓
Login sem senha
```

Caso o pendrive não esteja conectado:

``` text
Pendrive ausente
        ↓
pam_usb falha
        ↓
pam_unix
        ↓
Senha tradicional
        ↓
Login
```

Isso permite testar a autenticação USB sem perder a possibilidade de
entrar no sistema utilizando a senha.

------------------------------------------------------------------------

## 3. Preparação do sistema

``` bash
sudo apt update
```

Dependências iniciais:

``` bash
sudo apt install git build-essential pkg-config libpam0g-dev libudisks2-dev libdbus-1-dev
```

Durante a compilação, outras dependências foram identificadas como
ausentes:

``` bash
sudo apt install libxml2-dev libglib2.0-dev libudev-dev
```

Também foi necessário:

``` bash
sudo apt install libevdev-dev
```

------------------------------------------------------------------------

## 4. Download e versão do pam_usb

``` bash
cd ~
git clone https://github.com/mcdope/pam_usb.git
cd pam_usb
```

As tags foram verificadas:

``` bash
git tag --sort=-version:refname | head
```

Foi escolhida a versão `0.9.3`:

``` bash
git checkout 0.9.3
git describe --tags --always
```

Resultado:

``` text
0.9.3
```

A utilização de uma versão atual é importante porque versões `<= 0.9.1`
foram afetadas por uma vulnerabilidade posteriormente corrigida. A
correção foi disponibilizada a partir da versão 0.9.2.

------------------------------------------------------------------------

## 5. Compilação e instalação

A compilação foi realizada com:

``` bash
make
```

Na primeira tentativa surgiram erros de dependências, incluindo:

``` text
libxml/parser.h: Arquivo ou diretório inexistente
```

Após instalar `libxml2-dev`, `libglib2.0-dev`, `libudev-dev` e
`libevdev-dev`, o `make` foi executado novamente e terminou sem erros.

A instalação foi feita com:

``` bash
sudo make install
```

Verificação:

``` bash
which pamusb-check
pamusb-check --version
```

Resultados:

``` text
/usr/bin/pamusb-check
Version 0.9.3
```

Neste ponto o software estava instalado, mas o login ainda não havia
sido testado.

------------------------------------------------------------------------

## 6. Cadastro do pendrive e do usuário

Com o SanDisk conectado:

``` bash
sudo pamusb-conf --add-device SanDisk
```

Depois, o usuário foi associado ao dispositivo:

``` bash
sudo pamusb-conf --add-user rique
```

O dispositivo `SanDisk` foi selecionado para o usuário `rique`.

Durante essa etapa, o `pam_usb` apresentou informações sobre acesso a
`/dev/input` e o helper `evdev`.

Não foi necessário adicionar `rique` ao grupo `input`. Essa alternativa
foi evitada porque dar acesso amplo ao grupo `input` permite leitura dos
dispositivos de entrada do sistema, incluindo teclado.

------------------------------------------------------------------------

## 7. One-Time Pad (OTP)

Uma das partes mais interessantes do `pam_usb` é seu mecanismo chamado
de **One-Time Pad verification**.

Ao executar:

``` bash
pamusb-check rique
```

com o pendrive conectado, foi observado:

``` text
Authentication device "SanDisk" is connected.
Performing one time pad verification...
Regenerating new pads...
Access granted.
```

### Como interpretar isso

Isso não significa que todo o login ou a senha estejam simplesmente
sendo criptografados por um One-Time Pad.

O `pam_usb` mantém material de autenticação associado ao dispositivo e
ao computador e utiliza os pads como parte da verificação de posse do
dispositivo.

De forma simplificada:

``` text
Pendrive conectado
       ↓
Dispositivo identificado
       ↓
Material de autenticação verificado
       ↓
Pad válido?
   ↓         ↓
  Sim       Não
   ↓         ↓
Acesso     Acesso
aceito     negado
   ↓
Novos pads são gerados
```

Depois de uma autenticação bem-sucedida aparece:

``` text
Regenerating new pads...
```

Ou seja, o material usado na verificação é renovado.

### E o One-Time Pad da criptografia clássica?

Na criptografia clássica, um **One-Time Pad** combina a mensagem com uma
chave verdadeiramente aleatória, do mesmo tamanho da mensagem e
utilizada uma única vez. Quando todas essas condições são cumpridas
corretamente, o método possui a propriedade teórica de sigilo perfeito.

No `pam_usb`, o termo aparece no contexto do mecanismo de autenticação e
renovação dos pads. Portanto, não se deve interpretar que a senha ou
todo o tráfego do login estejam sendo cifrados com um OTP clássico.

O mecanismo também é diferente de **TOTP**, como os códigos temporários
de aplicativos autenticadores. No TOTP, códigos são derivados de um
segredo compartilhado e do tempo atual.

------------------------------------------------------------------------

## 8. Teste com pamusb-check

Com o pendrive conectado:

``` bash
pamusb-check rique
```

Resultado:

``` text
Access granted.
```

Depois, o pendrive foi removido e o comando repetido.

Resultado:

``` text
Access denied.
```

Isso confirmou o funcionamento antes de testar autenticações reais.

------------------------------------------------------------------------

## 9. Integração com PAM

No Debian foi utilizada a ferramenta:

``` bash
sudo pam-auth-update
```

O perfil apareceu habilitado:

``` text
[*] USB Authentication (libpam-usb)
```

A autenticação Unix tradicional permaneceu habilitada.

A pilha foi inspecionada com:

``` bash
grep -n "pam_usb\|pam_unix" /etc/pam.d/common-auth
```

Resultado relevante:

``` text
auth sufficient                  pam_usb.so
auth [success=1 default=ignore]  pam_unix.so nullok try_first_pass
```

------------------------------------------------------------------------

## 10. O significado de `sufficient`

A configuração atual contém:

``` text
auth sufficient pam_usb.so
```

Quando o `pam_usb` autentica com sucesso, essa autenticação pode ser
suficiente para permitir o acesso sem solicitar a senha tradicional.

Se o `pam_usb` falhar, a pilha continua até o `pam_unix`, permitindo
autenticação por senha.

``` text
USB válido
   ↓
pam_usb → sucesso
   ↓
login
```

ou:

``` text
USB ausente/inválido
   ↓
pam_usb → falha
   ↓
pam_unix
   ↓
senha
   ↓
login
```

------------------------------------------------------------------------

## 11. Teste com `su`

Foi executado:

``` bash
su - rique
```

### Com o SanDisk conectado

O `pam_usb` encontrou o dispositivo, realizou a verificação e concedeu
acesso sem solicitar a senha.

**Resultado:** funcionando.

### Sem o SanDisk

Após:

``` bash
exit
```

o pendrive foi removido e `su - rique` executado novamente.

O `pam_usb` negou sua autenticação e o sistema apresentou:

``` text
Senha:
```

A senha tradicional permitiu o acesso.

**Resultado:** fallback para senha funcionando.

------------------------------------------------------------------------

## 12. Integração e teste com GDM

Foi confirmado que o GDM utiliza `common-auth`:

``` bash
grep -n "common-auth" /etc/pam.d/gdm-password
```

Resultado:

``` text
4:@include common-auth
```

### Login gráfico com USB

Foi realizado logout mantendo o SanDisk conectado.

Na tela do GDM, o usuário `rique` foi selecionado e o login foi
realizado sem necessidade de digitar a senha.

**Resultado:** funcionando.

### Login gráfico sem USB

Em um segundo teste, o SanDisk foi removido antes da autenticação.

O GDM solicitou a senha tradicional e permitiu o login após a senha
correta.

**Resultado:** fallback por senha funcionando.

------------------------------------------------------------------------

## 13. Primeiro login após reinicialização

A VM foi reiniciada com o SanDisk conectado.

Após o boot, o GDM iniciou normalmente. Ao selecionar o usuário `rique`,
o `pam_usb` autenticou o usuário no **primeiro login após a
inicialização**, sem necessidade de digitar a senha.

**Resultado:** funcionando e persistente após reinicialização.

Essa é uma diferença fundamental em relação ao Método 1:

``` text
Método 1 — udev

Sistema inicia
      ↓
Login normal
      ↓
Sessão já aberta
      ↓
USB controla lock/unlock
```

``` text
Método 2 — PAM

Sistema inicia
      ↓
GDM
      ↓
PAM
      ↓
pam_usb
      ↓
USB autentica
      ↓
Sessão iniciada
```

------------------------------------------------------------------------

# Parte 2 --- Autenticação com USB obrigatório

> **Status:** ainda não implementada.

A Parte 1 foi propositalmente configurada para manter a senha como
alternativa:

``` text
USB OU senha
```

A próxima etapa será experimentar:

``` text
USB obrigatório
```

Nesse cenário, conhecer apenas a senha não deverá ser suficiente se o
dispositivo exigido estiver ausente.

------------------------------------------------------------------------

## 14. Diferença conceitual

### Parte 1 --- configuração atual

``` text
auth sufficient pam_usb.so
```

Comportamento:

``` text
USB válido → acesso

USB ausente → tenta senha
```

### Parte 2 --- objetivo

A política PAM deverá fazer da verificação USB uma condição necessária.

``` text
USB presente e válido
        +
demais condições exigidas
        ↓
      acesso
```

Enquanto:

``` text
USB ausente/inválido
        ↓
pam_usb falha
        ↓
autenticação falha
```

mesmo que a senha esteja correta.

------------------------------------------------------------------------

## 15. `sufficient` e `required`

Um ponto central da próxima etapa será estudar os controles do PAM.

`sufficient` permite que o sucesso do módulo seja suficiente em
determinadas condições, enquanto sua falha pode permitir que a pilha
continue avaliando outros módulos.

Um módulo marcado como:

``` text
required
```

torna o sucesso desse módulo necessário para que a pilha termine com
sucesso.

Entretanto, simplesmente substituir `sufficient` por `required` sem
analisar a pilha PAM completa pode causar perda de acesso ao sistema.

Por isso, essa alteração **ainda não foi realizada**.

------------------------------------------------------------------------

## 16. Cuidados para a Parte 2

Antes de tornar o USB obrigatório, serão adotadas medidas de
recuperação:

-   manter uma sessão administrativa aberta durante os testes;
-   garantir acesso ao console da máquina virtual;
-   fazer backup dos arquivos PAM modificados;
-   testar primeiro sem encerrar todas as sessões;
-   validar o comportamento antes de logout/reinicialização;
-   garantir uma forma de restaurar a configuração.

Uma configuração incorreta do PAM pode impedir login, `sudo`, `su` e
outros mecanismos de autenticação.

A Parte 2 será documentada conforme for efetivamente implementada e
testada.

------------------------------------------------------------------------

## 17. Progresso

### Parte 1 --- USB ou senha

-   [x] Preparar o ambiente
-   [x] Instalar dependências
-   [x] Baixar `pam_usb`
-   [x] Fixar versão 0.9.3
-   [x] Compilar
-   [x] Instalar
-   [x] Cadastrar SanDisk
-   [x] Associar o dispositivo ao usuário `rique`
-   [x] Testar One-Time Pad
-   [x] Testar `pamusb-check` com USB
-   [x] Testar `pamusb-check` sem USB
-   [x] Habilitar integração PAM
-   [x] Preservar autenticação por senha
-   [x] Testar com `su`
-   [x] Testar fallback com `su`
-   [x] Testar GDM com USB
-   [x] Testar GDM sem USB
-   [x] Testar primeiro login após reinicialização
-   [x] Confirmar persistência

### Parte 2 --- USB obrigatório

-   [ ] Preparar mecanismo de recuperação
-   [ ] Fazer backup da configuração PAM
-   [ ] Analisar a pilha PAM completa
-   [ ] Tornar a verificação USB obrigatória
-   [ ] Testar com USB conectado
-   [ ] Testar com USB ausente
-   [ ] Verificar comportamento da senha
-   [ ] Testar GDM
-   [ ] Testar após reinicialização
-   [ ] Documentar os resultados

------------------------------------------------------------------------

## 18. Comparação com o Método 1

  Característica                  udev + loginctl   PAM + pam_usb
  ------------------------------- ----------------- ----------------------------------
  Detecta USB                     Sim               Sim
  Atua em sessão existente        Sim               Pode participar de operações PAM
  Participa do login inicial      Não               Sim
  Pode autenticar sem senha       Não               Sim
  Possui verificação OTP          Não               Sim
  Funciona após reinicialização   Sim               Sim
  Senha como fallback             Não se aplica     Sim, na Parte 1
  USB obrigatório                 Não               Será testado na Parte 2

O primeiro método utiliza o USB como um **gatilho de controle da
sessão**.

O segundo integra o dispositivo ao **sistema real de autenticação do
Linux**.

------------------------------------------------------------------------

## 19. Considerações de segurança

O `pam_usb` permite utilizar um dispositivo de armazenamento USB como
fator físico de autenticação, mas isso não o torna automaticamente
equivalente a uma chave de segurança dedicada baseada em padrões como
FIDO2/U2F.

Este projeto possui finalidade educacional e permite estudar:

-   PAM;
-   autenticação Linux;
-   posse de dispositivo físico;
-   One-Time Pads;
-   controle de acesso;
-   integração entre hardware e software.

A configuração PAM deve ser alterada com cuidado, principalmente quando
o USB deixa de ser uma alternativa e passa a ser uma condição
obrigatória.

------------------------------------------------------------------------

## Referências

-   `mcdope/pam_usb` --- fork utilizado neste projeto.
-   Linux Uprising --- *How To Login With A USB Flash Drive Instead Of A
    Password On Linux Using pam_usb (Fork)*.
-   Documentação do PAM no Debian.
-   Security advisory do `pam_usb` referente às versões anteriores à
    correção disponibilizada na versão 0.9.2.
