# Linux USB Security Token

Projeto educacional para utilizar um pendrive comum no controle de sessão e na autenticação do Linux.

**Estado atual:** Método 02 — Parte 02 validado no Debian 13 instalado no Lenovo IdeaPad 3i, incluindo teste após reinicialização. O GDM exige pendrive + senha; a remoção do pendrive bloqueia a sessão gráfica e a reconexão não a desbloqueia automaticamente.

## Documentação e ordem das etapas

| Etapa | Objetivo | Situação |
| --- | --- | --- |
| [Método 1](metodo-01/README_USB_Token.md) | Bloquear e solicitar desbloqueio com eventos USB via udev e loginctl | Validado como experimento; na configuração final, somente o bloqueio por remoção permanece ativo |
| [Método 02 — Parte 01](metodo-02/README_USB_Token_Metodo_02_Parte_01.md) | Autenticar por USB **ou** senha com pam_usb | Validado; política substituída pela Parte 02 |
| [Método 02 — Parte 02](metodo-02/README_USB_Token_Metodo_02_Parte_02.md) | Exigir USB **e** senha no GDM, preservando recuperação pelo TTY | Validado no notebook, incluindo testes físicos e reinicialização |

Os documentos anteriores preservam o histórico. Não reaplique as regras de desbloqueio do Método 1 nem o perfil USB global da Parte 01 sobre a configuração final.

## Ambiente

| Item | Ambiente registrado |
| --- | --- |
| Notebook | Lenovo IdeaPad 3i |
| Sistema principal | Debian GNU/Linux 13 (trixie), instalado diretamente no SSD |
| Interface / login | GNOME / GDM; sessão Wayland registrada no Método 1 |
| Usuário cadastrado | `henrique` |
| Pendrive | SanDisk Cruzer Blade de 4 GB nominais; 3,7 GB exibidos pelo sistema |
| Identificadores USB | `0781:5567`; serial `4C530101421215115090` |
| Volume do pendrive | FAT, UUID `9EE3-C03C` |
| Autenticação USB | pam_usb 0.9.3 |

O projeto começou em uma VM Debian no VirtualBox. Os guias disponíveis do Método 1 e da Parte 01 também registram testes posteriores; a Parte 02 foi aplicada ao sistema principal. O ambiente de cada registro deve ser respeitado ao reproduzir os passos. `/dev/sda1` foi o nome observado do pendrive, não um endereço permanente.

## Comportamento final

| Ação | Resultado validado/configurado |
| --- | --- |
| Login e desbloqueio gráfico pelo GDM | Exigem USB cadastrado + senha correta |
| Senha correta sem USB | Autenticação gráfica recusada |
| USB presente com senha incorreta | Autenticação gráfica recusada |
| Remover o USB durante a sessão | Regra udev solicita bloqueio ao GNOME |
| Reconectar o USB | Sessão continua bloqueada; é necessário autenticar |
| Login pelo terminal TTY | Usa senha, sem exigência do USB |
| Administração por sudo | Usa a política de senha do sistema; USB não é exigido por esta configuração |
| Reinicialização | Configuração persistiu nos testes confirmados pelo usuário |

A exigência do USB foi colocada em `/etc/pam.d/gdm-password`, antes de `@include common-auth`. O perfil `libpam-usb` foi desabilitado no `pam-auth-update`, retirando o USB da autenticação compartilhada. Não foram alterados os serviços PAM de TTY e sudo.

## O papel de cada mecanismo

- **udev + Bash + loginctl:** detecta a remoção e solicita o bloqueio de uma sessão existente. Não autentica o usuário.
- **PAM + pam_usb + pam_unix:** valida o pendrive e a senha no serviço `gdm-password`.
- **TTY + sudo:** permite recuperar o acesso administrativo e retirar temporariamente a exigência do USB no GDM.

O script do Método 1 ainda aceita `unlock`, mas nenhuma regra ativa de conexão o chama na configuração final. Não foi encontrado `pamusb-agent` em execução durante a inspeção.

## Escopo e limites

O pendrive é um fator de posse e a senha é um fator de conhecimento. Um dispositivo de armazenamento comum não oferece as mesmas garantias de proteção de chaves de um token FIDO2/U2F. Os pads são arquivos secretos verificáveis, e a identificação USB também depende de propriedades fornecidas pelo dispositivo.

Esta configuração protege o fluxo gráfico testado. Ela não cifra o SSD, não bloqueia o boot e não exige USB para todos os serviços do sistema. Quem possui a senha e autorização de sudo pode recuperar o acesso pelo TTY; isso é uma decisão explícita deste projeto.

Outros usuários, login automático, impressão digital, SSH e outros serviços PAM não foram validados nesta etapa. Alterar `gdm-password` pode afetar outros usuários que utilizem esse serviço; o guia cobre a conta cadastrada `henrique`.

Remova o USB somente após concluir gravações e desmontar o volume. O pam_usb pode renovar os pads durante a autenticação, portanto a integridade do sistema de arquivos é parte do funcionamento do projeto.

## Recuperação rápida

Acesse o TTY com **Ctrl + Alt + F3** (no IdeaPad, pode ser necessário **Ctrl + Alt + Fn + F3**), entre como `henrique` e execute:

```bash
sudo nano /etc/pam.d/gdm-password
```

Comente apenas esta linha:

```text
# auth required pam_usb.so
```

Salve, retorne à interface gráfica e inicie uma nova tentativa de autenticação. O GDM volta a aceitar a senha sem USB. Não é necessário reiniciar o GDM. O [guia da Parte 02](metodo-02/README_USB_Token_Metodo_02_Parte_02.md#9-recuperação-sem-o-pendrive) explica o procedimento completo, a reativação e a restauração do backup.

## Estrutura real

- `README.md`: visão geral e estado final.
- `metodo-01/README_USB_Token.md`: histórico do controle de sessão.
- `metodo-01/images/`: capturas existentes do Método 1.
- `metodo-02/README_USB_Token_Metodo_02_Parte_01.md`: histórico de USB ou senha.
- `metodo-02/README_USB_Token_Metodo_02_Parte_02.md`: implementação de USB + senha e recuperação.
- `metodo-02/images/`: capturas existentes da Parte 01.
- `REVISAO_DOCUMENTACAO.md`: registro das correções desta revisão.
- `LICENSE`: licença existente do repositório.

Os scripts e as regras são apresentados nos blocos dos guias; esta revisão não adiciona instaladores nem arquivos executáveis independentes.

## Referências técnicas

- [pam_usb, versão utilizada](https://github.com/mcdope/pam_usb/tree/0.9.3)
- [PAM: sintaxe e controles no Debian 13](https://manpages.debian.org/trixie/libpam-runtime/pam.d.5.en.html)
- [pam-auth-update](https://manpages.debian.org/trixie/libpam-runtime/pam-auth-update.8.en.html)
- [loginctl](https://manpages.debian.org/trixie/systemd/loginctl.1.en.html)
- [udev](https://manpages.debian.org/trixie/udev/udev.7.en.html)

Os testes de autenticação e de reinicialização foram realizados e confirmados pelo usuário no notebook. Esta revisão documental não executa alterações remotas no computador.
