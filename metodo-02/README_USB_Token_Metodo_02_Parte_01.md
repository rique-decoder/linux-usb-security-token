# Método 02 — Parte 01: Autenticação USB ou Senha com pam_usb

> **Registro histórico:** esta política foi validada e depois substituída pela [Parte 02 — USB + senha](README_USB_Token_Metodo_02_Parte_02.md). Não reative o perfil USB global sobre a configuração final.

## Ambiente e evidências

O projeto começou em uma VM Debian no VirtualBox e posteriormente passou ao Debian 13 instalado diretamente no SSD do Lenovo IdeaPad 3i. Esta Parte 01 preserva os comandos, capturas e resultados registrados da autenticação por USB ou senha. Na inspeção anterior à Parte 02, o notebook já tinha o pam_usb instalado e a política abaixo ativa.

As capturas existentes permanecem nos caminhos originais. Não foram criadas novas capturas nem executados novamente os testes desta etapa durante a revisão documental.

## Objetivo

Nesta etapa foi implementada uma autenticação utilizando o pendrive como dispositivo de segurança, mantendo a senha tradicional do usuário como alternativa.

Resultado esperado:

- Com USB conectado → login sem digitar senha.
- Sem USB conectado → login utilizando senha normalmente.

O USB ainda não é obrigatório nesta etapa.

---

## 1. Instalação do pam_usb

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

## 2. Cadastro do dispositivo USB

O pendrive utilizado foi:

- SanDisk Cruzer Blade
- Serial: `4C530101421215115090`

Cadastro (execute uma vez; se já existir, confira a configuração antes de repetir):

```bash
sudo pamusb-conf --add-device SanDisk
```

![config usb drive](./images/Captura%20de%20tela%20de%202026-10-01%2017-11-12.png)

Depois:

```bash
sudo pamusb-conf --add-user henrique
```


![config user](./images/Captura%20de%20tela%20de%202026-10-01%2017-11-25.png)


A configuração desta versão fica em `/etc/security/pam_usb.conf`, não em `/etc/pamusb.conf`. O cadastro esperado é:

```xml
<user id="henrique">
    <device>SanDisk</device>
</user>
```

Na Parte 02 foi encontrada e removida uma referência duplicada a `SanDisk` nesse bloco. As ações de `pamusb-agent` com `scox` e `MyDevice` eram exemplos dentro de comentários XML; não estavam ativas. Não publique os arquivos `.pad` nem seu conteúdo.

Teste com USB conectado e depois desconectado:

```bash
pamusb-check henrique
```

![checagem login](./images/Captura%20de%20tela%20de%202026-10-01%2017-12-05.png)


---

## 3. Configuração do PAM

A autenticação USB foi ativada usando:

```bash
sudo pam-auth-update
```

Mantendo:

- USB Authentication
- Unix authentication

Trecho inicial de `/etc/pam.d/common-auth` gerado nessa etapa (não é o arquivo completo):

```text
auth sufficient pam_usb.so
auth [success=1 default=ignore] pam_unix.so nullok try_first_pass
```

![config. pam](./images/Captura%20de%20tela%20de%202026-10-01%2017-12-20.png)

O controle `sufficient` permite que o sucesso do USB encerre a autenticação sem solicitar senha, desde que não haja uma falha obrigatória anterior. A falha do USB deixa a sequência seguir para a autenticação Unix.

Por estar em `common-auth`, a política pode atingir outros serviços que o incluem, e não apenas o GDM. O perfil identificado no notebook foi `/usr/share/pam-configs/libpam-usb`, com `sufficient pam_usb.so` em `Auth` e `Auth-Initial`.

Funcionamento:

```
USB OU senha
```


---

## 4. Testes de autenticação

### Login utilizando USB

Com o pendrive conectado:

- Logout realizado.
- Usuário selecionado no GDM.
- Entrada realizada sem digitar senha.


---

### Login utilizando senha

Com o pendrive removido:

- Login tradicional realizado.
- Senha aceita normalmente.


---

## 5. Validação após reinicialização

O computador foi reiniciado com o pendrive conectado.

Resultado:

O login utilizando apenas o USB continuou funcionando.


---

## 6. Problema encontrado: One Time Pads

Durante os testes ocorreu:

```text
Pad checking failed!
```

Foi identificado que os pads do sistema e do pendrive estavam diferentes.

O registro associa a ocorrência a inconsistências no FAT e à remoção sem desmontagem. A mensagem `Pad checking failed!`, isoladamente, não demonstra a causa: arquivo ausente, acesso negado, volume incorreto ou divergência entre os pads também podem impedir a verificação.

O reparo registrado usou `fsck.fat`. Para reproduzir o diagnóstico, confirme primeiro que a partição é a do pendrive, feche os arquivos e desmonte o volume. No ambiente registrado, o volume correto tinha UUID `9EE3-C03C`:

```bash
lsblk -o NAME,SIZE,FSTYPE,UUID,MOUNTPOINTS,MODEL
sudo apt install dosfstools
udisksctl unmount -b /dev/disk/by-uuid/9EE3-C03C
findmnt -S /dev/disk/by-uuid/9EE3-C03C
```

Prossiga somente se a desmontagem tiver sido bem-sucedida e `findmnt` não indicar uma montagem. Faça primeiro uma inspeção sem gravar alterações:

```bash
sudo fsck.fat -n -v /dev/disk/by-uuid/9EE3-C03C
```

Se o diagnóstico justificar reparo, preserve os dados importantes do pendrive e execute o reparo interativo:

```bash
sudo fsck.fat -r -v /dev/disk/by-uuid/9EE3-C03C
udisksctl mount -b /dev/disk/by-uuid/9EE3-C03C
```

O comando histórico foi `sudo fsck.fat -a -v /dev/sda1`; ele não deve ser copiado sem confirmar o dispositivo e a desmontagem. Nunca repare a partição EFI do SSD por engano. O comando de montagem exibirá o caminho efetivo do volume.

Após o reparo, o registro original relata:

- Sistema FAT corrigido.
- Volume voltou para modo leitura/escrita.
- Pads foram regenerados.

Comparação:

```bash
cmp -s /home/henrique/.pamusb/SanDisk.pad /media/henrique/9EE3-C03C/.pamusb/henrique.debian.pad
echo $?
```

O `cmp -s` não imprime o resultado. `echo $?`, executado imediatamente depois, mostra o código de saída: `0` para arquivos iguais, `1` para diferentes e `2` para erro. No registro, a comparação confirmou igualdade:

```text
0
```

Os caminhos dependem do usuário, hostname, nome do dispositivo e ponto de montagem; confira antes de comparar. A igualdade dos pads não valida toda a política PAM. O reparo do FAT também não garante, por si só, que pads divergentes voltem a coincidir; reavalie a autenticação depois. Não apague ou substitua pads como correção automática.

![corrigindo one-time-pad](./images/Captura%20de%20tela%20de%202026-10-01%2017-13-08.png)


---

### Como os pads funcionam

No código da versão 0.9.3, o pam_usb compara dados secretos do arquivo no sistema com os do arquivo no pendrive. A renovação depende da configuração `pad_expiration`; não significa necessariamente um novo pad a cada login.

Apesar do nome *one-time pads* usado pelo projeto, este mecanismo não é um código TOTP de aplicativo autenticador nem uma operação de cifragem de mensagens com a cifra One-Time Pad. Aqui, os arquivos participam da verificação do fator USB. Manter os pads em segredo e garantir gravações corretas nos dois locais são requisitos do funcionamento.

## 7. GNOME Keyring e Google Online Accounts

O login utilizando USB funciona, porém o GNOME Keyring continua protegido.

Motivo:

- O login via USB autentica o usuário.
- A senha não foi digitada durante o login.
- O GNOME Keyring não recebe automaticamente essa senha.

O registro original também relata validação da conta Google do GNOME após reiniciar `goa-daemon`. Esse resultado é independente da política PAM e não é necessário para autenticar pelo USB. Na Parte 02 a senha volta a ser digitada; o chaveiro pode ser desbloqueado automaticamente se sua senha corresponder à senha de login e a integração estiver funcionando.


---

## Estado ao concluir a Parte 01

| Função | Resultado |
|-|-|
| Login via USB | Funcionando |
| Login via senha | Funcionando |
| One Time Pads | Funcionando |
| Reinicialização validada | Funcionando |
| Método 1 reativado | Funcionando |
| GNOME Keyring protegido | Mantido |

---

## Evolução para a Parte 02

A [Parte 02](README_USB_Token_Metodo_02_Parte_02.md) foi concluída e validada no notebook, inclusive após reinicialização. Ela documenta a transição:

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

## Referências

- [pam_usb 0.9.3](https://github.com/mcdope/pam_usb/tree/0.9.3)
- [Implementação dos pads](https://github.com/mcdope/pam_usb/blob/0.9.3/src/pad.c)
- [Caminho da configuração no código](https://github.com/mcdope/pam_usb/blob/0.9.3/src/conf.h)
- [Controles PAM no Debian 13](https://manpages.debian.org/trixie/libpam-runtime/pam.d.5.en.html)
- [fsck.fat](https://manpages.debian.org/trixie/dosfstools/fsck.fat.8.en.html)
