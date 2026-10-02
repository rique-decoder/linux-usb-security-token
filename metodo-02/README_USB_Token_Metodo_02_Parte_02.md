# Método 02 — Parte 02: USB + senha no GDM

**Status:** configuração aplicada ao Debian 13 instalado no Lenovo IdeaPad 3i e validada pelo usuário, incluindo login após reinicialização.

[Visão geral](../README.md) · [Parte 01](README_USB_Token_Metodo_02_Parte_01.md) · [Método 1](../metodo-01/README_USB_Token.md)

## 1. Objetivo e escopo

Substituir a política da Parte 01, USB **ou** senha, por USB **e** senha no login gráfico e no desbloqueio pelo GDM.

A composição final tem dois mecanismos:

- **Método 1, parcialmente ativo:** remover o USB solicita bloqueio da sessão gráfica; a regra de reconexão não solicita mais desbloqueio.
- **Método 2, Parte 02:** o serviço PAM `gdm-password` exige o USB cadastrado e a senha correta.

O TTY e o sudo continuam com autenticação por senha. Essa é a via de recuperação caso o pendrive seja perdido ou apresente defeito. A exigência não foi aplicada a todos os serviços PAM nem à inicialização do computador.

## 2. Ambiente confirmado

| Item | Valor |
| --- | --- |
| Notebook | Lenovo IdeaPad 3i |
| Sistema | Debian GNU/Linux 13 (trixie), instalado diretamente no SSD |
| Gerenciador de login | GDM |
| Usuário | `henrique` |
| USB | SanDisk Cruzer Blade, 4 GB nominais |
| Serial | `4C530101421215115090` |
| Volume USB | FAT, UUID `9EE3-C03C`, observado como `/dev/sda1` |
| SSD | `nvme0n1`, cerca de 238,5 GB; raiz em ext4 |
| pam_usb | Versão 0.9.3, instalada na Parte 01 |

O projeto começou em uma VM. Esta etapa foi executada no Debian usado como sistema principal, após a substituição do Windows 11. Os nomes de disco, IDs de sessão e pontos de montagem podem mudar.

### Estado antes das alterações

Em `/etc/pam.d/common-auth` havia:

```text
auth sufficient pam_usb.so
auth [success=1 default=ignore] pam_unix.so nullok try_first_pass
```

O perfil `/usr/share/pam-configs/libpam-usb` usava `sufficient pam_usb.so` nas seções `Auth` e `Auth-Initial`. A regra `/etc/udev/rules.d/80-usb.rules` ainda executava `usb-lock.sh unlock` na conexão.

Apenas transformar o USB em obrigatório, mantendo o desbloqueio automático por udev, deixaria um caminho para liberar a sessão sem a senha. Por isso a regra de conexão foi desativada e a exigência USB foi colocada especificamente no GDM.

## 3. Preparar um terminal de recuperação e o backup

Antes de alterar a autenticação, salve o trabalho e conecte o pendrive. Entre no TTY com **Ctrl + Alt + F3**; no IdeaPad, pode ser necessário **Ctrl + Alt + Fn + F3**. Faça login como `henrique`, usando sua senha, e abra um shell administrativo:

```bash
sudo -i
```

Mantenha esse terminal aberto durante a configuração e os testes. Os comandos das seções 3 a 7 abaixo são executados nesse shell root, sem sudo.

```bash
backup_usb=$(mktemp -d /root/usb-token-parte02.XXXXXX)
cp -a /etc/pam.d "$backup_usb/"
cp -a /usr/share/pam-configs/libpam-usb "$backup_usb/"
cp -a /etc/udev/rules.d/80-usb.rules "$backup_usb/"
cp -a /usr/local/bin/usb-lock.sh "$backup_usb/"
cp -a /etc/security/pam_usb.conf "$backup_usb/"
printf 'Backup: %s\n' "$backup_usb"
```

Confira se todas as cópias foram concluídas sem erro antes de continuar. No teste realizado, o diretório foi `/root/usb-token-parte02.qz3aVC`. Guarde o caminho real: a variável `backup_usb` só existe naquele shell e não sobrevive ao logout ou à reinicialização.

### Conferir o agente e corrigir o cadastro

```bash
sed -n '30,115p' /etc/security/pam_usb.conf
pgrep -af '[p]amusb-agent'
```

O arquivo correto é `/etc/security/pam_usb.conf`. A tentativa de consultar `/etc/pamusb.conf` retornou arquivo inexistente porque o caminho estava errado.

As ações `lock` e `unlock` com o usuário de exemplo `scox` e dispositivo `MyDevice` estavam dentro de comentários XML. Nenhum `pamusb-agent` foi encontrado em execução. Não foi necessário desativar essas ações de exemplo.

Foi encontrada uma referência duplicada a `SanDisk` no cadastro de `henrique`. Abra:

```bash
nano /etc/security/pam_usb.conf
```

Mantenha apenas uma entrada, preservando o restante do XML:

```xml
<user id="henrique">
    <device>SanDisk</device>
</user>
```

No Nano: **Ctrl + O**, **Enter**, **Ctrl + X**. Em outra instalação, confira se há ações de desbloqueio realmente ativas antes de prosseguir.

## 4. Desativar somente o desbloqueio automático por udev

```bash
sed -i '/^ACTION=="add".*usb-lock\.sh unlock/s/^/# Desativado na Parte 02: /' \
  /etc/udev/rules.d/80-usb.rules
udevadm control --reload-rules
cat /etc/udev/rules.d/80-usb.rules
```

Resultado registrado:

```udev
# Desativado na Parte 02: ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", ENV{ID_BUS}=="usb", ENV{ID_VENDOR_ID}=="0781", ENV{ID_MODEL_ID}=="5567", ENV{ID_SERIAL_SHORT}=="4C530101421215115090", RUN+="/usr/local/bin/usb-lock.sh unlock"
ACTION=="remove", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", ENV{ID_BUS}=="usb", ENV{ID_VENDOR_ID}=="0781", ENV{ID_MODEL_ID}=="5567", ENV{ID_SERIAL_SHORT}=="4C530101421215115090", RUN+="/usr/local/bin/usb-lock.sh lock"
```

O script continua instalado e aceita `lock` e `unlock`, mas somente a remoção chama uma ação na configuração ativa. Não é necessário executar `udevadm trigger`: a recarga vale para os próximos eventos.

## 5. Retirar o USB da autenticação compartilhada

```bash
pam-auth-update --disable libpam-usb
cat /etc/pam.d/common-auth
```

Se a interface de seleção aparecer, mantenha **Unix authentication** habilitado e **USB Authentication** desabilitado. Não use `--force` para sobrescrever alterações locais sem conferir o que será substituído.

O bloco ativo registrado passou a ser:

```text
auth [success=1 default=ignore] pam_unix.so nullok
auth requisite pam_deny.so
auth required pam_permit.so
```

Não deve haver nenhuma linha ativa com `pam_usb.so` em `common-auth`. Não substitua o arquivo inteiro por esse trecho; os comentários e outros módulos presentes em outra instalação devem ser preservados.

A opção `nullok` permaneceu como gerada pelo Debian. A conta utilizada possui senha; esta etapa não revisou políticas de contas com senha vazia. `pam_permit.so` faz parte da sequência gerada, depois do controle de falha com `pam_deny.so`; não é uma autorização independente para qualquer senha.

## 6. Exigir o USB no GDM

```bash
nano /etc/pam.d/gdm-password
```

Adicione uma única linha imediatamente antes de `@include common-auth`:

```text
auth required pam_usb.so
```

O início confirmado ficou assim:

```text
#%PAM-1.0
auth requisite pam_nologin.so
auth required pam_succeed_if.so user != root quiet_success
auth required pam_usb.so
@include common-auth
auth optional pam_gnome_keyring.so
@include common-account
```

Preserve todas as linhas restantes, incluindo as de sessão e senha. Confira:

```bash
head -n 8 /etc/pam.d/gdm-password
```

### Por que os dois fatores são necessários

O `pam_usb.so` verifica o dispositivo e seus pads. Com `required`, sua falha impede o sucesso final, mas não interrompe imediatamente os módulos seguintes. Por isso pode haver solicitação de senha mesmo sem USB.

O `common-auth` verifica a senha com `pam_unix.so`. Com o bloco registrado, uma senha incorreta chega a `pam_deny.so` e a autenticação falha. O sucesso da senha não elimina uma falha anterior do USB.

Esta regra aplica-se ao serviço `gdm-password`; não é uma exigência global. O teste cobriu `henrique`. Antes de estender a configuração a outros usuários ou métodos de login, examine seus serviços e cadastros.

## 7. Testar a autenticação pelo terminal

```bash
apt update
apt install pamtester
pamtester gdm-password henrique authenticate
```

Saída positiva fornecida pelo usuário:

```text
* Authentication request for user "henrique" (gdm-password)
* Searching for "SanDisk" in the hardware database...
* Authentication device "SanDisk" is connected.
* Performing one time pad verification...
* Access granted.
Password:
pamtester: successfully authenticated
```

`Access granted` é a mensagem da etapa USB. Somente o resultado final do pamtester indica que toda a operação de autenticação passou. Em `Password:`, digite a senha de `henrique`, não a senha de root. Os caracteres não são exibidos.

Repita o comando para cada cenário:

| USB | Senha | Resultado esperado |
| --- | --- | --- |
| Conectado | Correta | Sucesso |
| Conectado | Incorreta | Falha |
| Desconectado | Correta | Falha |

As saídas enviadas do pamtester mostraram dois sucessos. Não foram fornecidos logs das recusas pelo terminal. A confirmação final das recusas veio dos testes físicos relatados pelo usuário; não se atribuem logs inexistentes ao pamtester.

Para testar a ausência do dispositivo, termine gravações e desmonte o volume antes de retirá-lo. A remoção pode bloquear a sessão gráfica e a tela pode apagar em seguida. Execute os testes pelo TTY para manter o terminal acessível. O fato de a tela bloquear comprova o evento udev; sozinho, não comprova a recusa de autenticação sem USB.

## 8. Validar na interface gráfica e após reiniciar

Retorne à interface gráfica sem fechar o terminal administrativo. Normalmente ela está no VT 2, mas pode estar no VT 1:

```bash
chvt 2
```

Trocar de terminal não desbloqueia a sessão. Conectar o USB também não deve desbloqueá-la automaticamente.

Resultados confirmados pelo usuário ao finalizar a etapa:

| Teste físico | Resultado |
| --- | --- |
| Sem USB, senha correta | Acesso gráfico recusado |
| USB conectado, senha incorreta | Acesso recusado |
| USB conectado, senha correta | Acesso permitido |
| Remover USB durante a sessão | Sessão bloqueada |
| Reconectar USB | Sessão continua bloqueada |
| Login após logout | Exigência dos dois fatores confirmada |
| Reinicialização e novo login | Comportamento esperado preservado |

Esses resultados são confirmação do usuário em 01/10/2026. Não foram disponibilizadas novas capturas da Parte 02. As imagens da Parte 01 documentam a política anterior e não devem ser apresentadas como prova de USB + senha.

Antes de reiniciar, salve o trabalho e encerre o shell root com `exit`; execute outro `exit` para encerrar a sessão de usuário no TTY. Não deixe uma sessão administrativa aberta após os testes.

## 9. Recuperação sem o pendrive

### Entrar pelo TTY

1. Pressione **Ctrl + Alt + F3**, ou **Ctrl + Alt + Fn + F3** no IdeaPad.
2. Em `debian login:`, digite `henrique`.
3. Digite a senha da conta em `Password:`.

Se o atalho não funcionar, teste F4. Com a interface já acessível, `sudo chvt 3` também solicita a troca para o TTY. Sem acesso gráfico, use o atalho do teclado.

O login pelo TTY é uma sessão separada e não desbloqueia a sessão gráfica. Na configuração registrada, ele não exige o pendrive. Acesso administrativo depende de a conta continuar autorizada a usar sudo.

### Recuperar o acesso gráfico

```bash
sudo nano /etc/pam.d/gdm-password
```

Comente somente a linha do USB:

```text
# auth required pam_usb.so
```

Salve e volte à interface:

```bash
sudo chvt 2
```

Se estiver em um shell root, use `chvt 2` sem sudo. Caso a interface esteja no VT 1, ajuste o número. Cancele qualquer tentativa de autenticação em andamento e comece outra: a nova tentativa deve aceitar a senha sem USB. Não é necessário reiniciar o GDM, o que encerraria a sessão gráfica.

Essa recuperação desativa temporariamente a exigência USB no GDM; não remove o bloqueio por udev. A senha e os privilégios de sudo são a válvula de escape deliberada do projeto.

### Reativar a proteção

Depois de corrigir ou substituir e cadastrar o dispositivo, remova o `#` da linha, mantendo-a antes de `@include common-auth`:

```text
auth required pam_usb.so
```

Repita os testes positivo e negativos antes de considerar a proteção restabelecida. Não habilite novamente o perfil USB global da Parte 01: a configuração final mantém esse perfil desabilitado.

### Restaurar o estado anterior inteiro

Para desfazer a Parte 02 e retornar a USB **ou** senha com desbloqueio automático, abra um shell root pelo TTY:

```bash
sudo -i
backup_usb=/root/usb-token-parte02.qz3aVC
```

Esse é o caminho do backup registrado. Em outra execução, use o caminho efetivamente criado e confirme seu conteúdo antes de restaurar:

```bash
ls -la "$backup_usb"
```

Então:

```bash
cp -a "$backup_usb/libpam-usb" /usr/share/pam-configs/libpam-usb
pam-auth-update --enable libpam-usb
cp -a "$backup_usb/pam.d/." /etc/pam.d/
cp -a "$backup_usb/pam_usb.conf" /etc/security/pam_usb.conf
cp -a "$backup_usb/80-usb.rules" /etc/udev/rules.d/80-usb.rules
cp -a "$backup_usb/usb-lock.sh" /usr/local/bin/usb-lock.sh
udevadm control --reload-rules
```

A restauração completa recoloca as configurações do momento do backup, incluindo os arquivos PAM compartilhados e a regra de desbloqueio. Se o backup for antigo, compare os arquivos antes: a cópia pode sobrescrever alterações legítimas posteriores. O backup do XML também recoloca o cadastro como estava, incluindo a referência duplicada que foi corrigida nesta etapa.

## 10. Diagnóstico e manutenção

| Sintoma | Verificação |
| --- | --- |
| USB autentica sem solicitar senha | Confira se o perfil global voltou a inserir `sufficient pam_usb.so` em `common-auth` |
| Senha correta funciona sem USB no GDM | Confira se a linha obrigatória foi comentada, se o serviço usado é `gdm-password` e se há outro método de login ativo |
| Reconectar desbloqueia automaticamente | Confira a regra de conexão e ações de agentes; a regra `unlock` deve permanecer comentada |
| `Pad checking failed!` | Confira dispositivo, UUID, montagem, integridade e acesso aos pads; consulte a Parte 01 |
| Remover não bloqueia | Confira a regra udev, o script e a identificação da sessão gráfica |
| TTY abre, mas interface continua bloqueada | Esperado: são sessões distintas; autentique normalmente ou use o procedimento de recuperação |
| GNOME Keyring pede outra senha | Confira se a senha do chaveiro corresponde à senha de login; o USB não descifra o chaveiro |

Consultar a configuração e mensagens recentes:

```bash
cat /etc/pam.d/common-auth
head -n 8 /etc/pam.d/gdm-password
sudo journalctl -b --no-pager -n 100
```

Atualizações de pacotes ou uma reinstalação do pam_usb podem alterar arquivos e perfis. Após mudanças relevantes, confira a configuração e repita os testes. Outros serviços PAM, outros usuários, login automático e impressão digital precisam de avaliação própria; não foram incluídos na validação desta etapa.

## 11. Segurança e limites

- Os pads são dados secretos comparados nos dois locais. Não publique `.pad` nem compartilhe seu conteúdo.
- A renovação é determinada pelo pam_usb; não é um código TOTP nem cifragem do disco. Veja a explicação na Parte 01.
- Pendrives comuns não protegem segredos como tokens criptográficos dedicados. Serial e UUID também não são, isoladamente, provas criptográficas de identidade.
- O FAT pode sofrer inconsistências após retirada durante gravações. Desmonte o volume antes de remover o USB.
- O bloqueio automático reage ao evento de remoção; não monitora continuamente a ausência do pendrive.
- A exigência cobre o fluxo GDM testado. O TTY e sudo permanecem disponíveis por senha para recuperação; administradores podem alterar a política.
- O projeto não aplica criptografia ao SSD nem altera autenticação de boot, SSH ou todos os serviços do computador.

## Referências

- [pam_usb 0.9.3](https://github.com/mcdope/pam_usb/tree/0.9.3)
- [Código de configuração](https://github.com/mcdope/pam_usb/blob/0.9.3/src/conf.h)
- [Código dos pads](https://github.com/mcdope/pam_usb/blob/0.9.3/src/pad.c)
- [PAM: required, sufficient e include](https://manpages.debian.org/trixie/libpam-runtime/pam.d.5.en.html)
- [pam-auth-update](https://manpages.debian.org/trixie/libpam-runtime/pam-auth-update.8.en.html)
- [pamtester](https://manpages.debian.org/trixie/pamtester/pamtester.1.en.html)
- [loginctl](https://manpages.debian.org/trixie/systemd/loginctl.1.en.html)
- [chvt](https://manpages.debian.org/trixie/kbd/chvt.1.en.html)
