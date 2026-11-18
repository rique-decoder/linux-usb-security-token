
# Linux USB Security Token

Educational project demonstrating how to use a standard USB flash drive for session control and authentication on Linux.

<<<<<<< Updated upstream
**Estado atual:** Método 02 — Parte 02 validado no Debian 13 instalado no Lenovo IdeaPad 3i, incluindo teste após reinicialização. O GDM exige pendrive + senha; a remoção do pendrive bloqueia a sessão; o login pelo TTY continua usando senha.
=======
**Current status:** Method 02 — Part 02 validated on Debian 13 installed on a Lenovo IdeaPad 3i, including post-reboot testing. GDM requires USB flash drive + password; removing the USB drive locks the graphical session, and reconnecting it does not automatically unlock it.
>>>>>>> Stashed changes

## Documentation and Stage Order

| Stage | Objective | Status |
| --- | --- | --- |
| [Method 1](metodo-01/README_USB_Token.md) | Lock and request unlock with USB events via udev and loginctl | Validated as an experiment; in the final setup, only lock-on-removal remains active |
| [Method 02 — Part 01](metodo-02/README_USB_Token_Metodo_02_Parte_01.md) | Authenticate via USB **or** password with pam_usb | Validated; policy replaced by Part 02 |
| [Method 02 — Part 02](metodo-02/README_USB_Token_Metodo_02_Parte_02.md) | Require USB **and** password in GDM while preserving TTY recovery | Validated on the laptop, including physical tests and reboot |

Previous documents preserve project history. Do not reapply the unlock rules from Method 1 or the global USB profile from Part 01 over the final configuration.

<<<<<<< Updated upstream
> Para desabilitar temporariamente a proteção sem remover os arquivos de configuração, use [DESABILITAR_TOKEN.md](DESABILITAR_TOKEN.md). Esse procedimento é reversível e cobre os métodos 01 e 02 separadamente.

## Ambiente
=======
## Environment
>>>>>>> Stashed changes

| Item | Recorded Environment |
| --- | --- |
| Laptop | Lenovo IdeaPad 3i |
| Primary OS | Debian GNU/Linux 13 (trixie), installed directly on the SSD |
| Desktop / login | GNOME / GDM; Wayland session recorded in Method 1 |
| Registered user | `henrique` |
| USB flash drive | SanDisk Cruzer Blade 4 GB nominal; 3.7 GB reported by the system |
| USB identifiers | `0781:5567`; serial `4C530101421215115090` |
| USB volume | FAT, UUID `9EE3-C03C` |
| USB authentication | pam_usb 0.9.3 |

<<<<<<< Updated upstream
O projeto começou em uma VM Debian no VirtualBox. Os guias disponíveis do Método 1 e da Parte 01 também registram testes posteriores; a Parte 02 foi aplicada ao sistema principal. O ambiente documentado é o do notebook usado para a validação final.
=======
The project started in a Debian VM on VirtualBox. The available guides for Method 1 and Part 01 also record later tests; Part 02 was applied to the primary system. Each recorded environment should be respected when reproducing the steps. `/dev/sda1` was the observed device node for the flash drive, not a permanent address.
>>>>>>> Stashed changes

## Final Behavior

| Action | Validated / Configured Result |
| --- | --- |
| Graphical login and unlock via GDM | Requires registered USB + correct password |
| Correct password without USB | Graphical authentication rejected |
| USB present with incorrect password | Graphical authentication rejected |
| Removing USB during session | udev rule requests session lock from GNOME |
| Reconnecting USB | Session remains locked; manual authentication is required |
| TTY terminal login | Uses password only, without requiring USB |
| Administration via sudo | Uses system password policy; USB is not required by this configuration |
| System reboot | Configuration persisted across tests confirmed by the user |

<<<<<<< Updated upstream
A exigência do USB foi colocada em `/etc/pam.d/gdm-password`, antes de `@include common-auth`. O perfil `libpam-usb` foi desabilitado no `pam-auth-update`, retirando o USB da autenticação compartilhada, e a regra final foi mantida somente no serviço `gdm-password`.
=======
The USB requirement was placed in `/etc/pam.d/gdm-password`, right before `@include common-auth`. The `libpam-usb` profile was disabled in `pam-auth-update`, removing USB from shared authentication. TTY and sudo PAM services were not modified.
>>>>>>> Stashed changes

## Role of Each Mechanism

- **udev + Bash + loginctl:** detects removal and requests locking an existing session. It does not authenticate the user.
- **PAM + pam_usb + pam_unix:** validates the USB flash drive and password within the `gdm-password` service.
- **TTY + sudo:** allows recovering administrative access and temporarily disabling the USB requirement in GDM.

The Method 1 script still accepts `unlock`, though no active connection rule invokes it in the final setup. No running `pamusb-agent` instance was found during inspection.

## Scope and Limitations

<<<<<<< Updated upstream
O pendrive é um fator de posse e a senha é um fator de conhecimento. Um dispositivo de armazenamento comum não oferece as mesmas garantias de proteção de chaves de um token FIDO2/U2F. Os pads e a serial do dispositivo ajudam a identificar o token, mas não substituem autenticação criptográfica forte.

Esta configuração protege o fluxo gráfico testado. Ela não cifra o SSD, não bloqueia o boot e não exige USB para todos os serviços do sistema. Quem possui a senha e autorização de sudo pode administrar a máquina; o pendrive não é um requisito global para todos os serviços PAM.

Outros usuários, login automático, impressão digital, SSH e outros serviços PAM não foram validados nesta etapa. Alterar `gdm-password` pode afetar outros usuários que utilizem esse serviço na mesma máquina.

Remova o USB somente após concluir gravações e desmontar o volume. O pam_usb pode renovar os pads durante a autenticação, portanto a integridade do sistema de arquivos é parte do funcionamento seguro do pendrive.
=======
The USB flash drive acts as a possession factor and the password acts as a knowledge factor. A standard storage device does not provide the same key-protection guarantees as a FIDO2/U2F hardware token. Pads are verifiable secret files, and USB identification also relies on device-reported properties.

This configuration protects the tested graphical login flow. It does not encrypt the SSD, lock the boot process, or require USB for all system services. Anyone with the password and sudo privileges can recover access via TTY; this is an explicit design decision of the project.

Other users, automatic login, fingerprint authentication, SSH, and other PAM services were not validated at this stage. Modifying `gdm-password` may affect other users relying on that service; this guide covers the registered account `henrique`.

Remove the USB drive only after writes finish and the volume is unmounted. `pam_usb` may renew pads during authentication, so filesystem integrity is part of the project's proper operation.
>>>>>>> Stashed changes

## Quick Recovery

Switch to a TTY using **Ctrl + Alt + F3** (on the IdeaPad, **Ctrl + Alt + Fn + F3** may be required), log in as `henrique`, and run:

```bash
sudo nano /etc/pam.d/gdm-password
```

Comment out only this line:

```text
# auth required pam_usb.so
```

<<<<<<< Updated upstream
Salve, retorne à interface gráfica e inicie uma nova tentativa de autenticação. O GDM volta a aceitar a senha sem USB. Não é necessário reiniciar o GDM. O guia da Parte 02 documenta a recuperação completa e a restauração do estado anterior.

Para uma desativação reversível sem apagar a configuração, consulte [DESABILITAR_TOKEN.md](DESABILITAR_TOKEN.md).
=======
Save the file, return to the graphical interface, and start a new authentication attempt. GDM will accept the password without the USB drive again. Restarting GDM is not required. The [Part 02 guide](https://www.google.com/search?q=metodo-02/README_USB_Token_Metodo_02_Parte_02.md%239-recupera%C3%A7%C3%A3o-sem-o-pendrive) covers the full procedure, re-enabling, and backup restoration.
>>>>>>> Stashed changes

## Actual Structure

<<<<<<< Updated upstream
- `README.md`: visão geral e estado final.
- `metodo-01/README_USB_Token.md`: histórico do controle de sessão.
- `metodo-01/images/`: capturas existentes do Método 1.
- `metodo-02/README_USB_Token_Metodo_02_Parte_01.md`: histórico de USB ou senha.
- `metodo-02/README_USB_Token_Metodo_02_Parte_02.md`: implementação de USB + senha e recuperação.
- `metodo-02/images/`: capturas existentes da Parte 01.
- `DESABILITAR_TOKEN.md`: procedimento reversível para desativar os métodos sem apagar as configurações.
- `REVISAO_DOCUMENTACAO.md`: registro das correções desta revisão.
- `LICENSE`: licença existente do repositório.
=======
* `README.md`: overview and final state.
* `metodo-01/README_USB_Token.md`: session control history.
* `metodo-01/images/`: existing screenshots from Method 1.
* `metodo-02/README_USB_Token_Metodo_02_Parte_01.md`: USB-or-password history.
* `metodo-02/README_USB_Token_Metodo_02_Parte_02.md`: USB + password implementation and recovery.
* `metodo-02/images/`: existing screenshots from Part 01.
* `REVISAO_DOCUMENTACAO.md`: log of corrections made in this documentation review.
* `LICENSE`: existing repository license.
>>>>>>> Stashed changes

## Interactive Tools

The [helper scripts](https://www.google.com/search?q=scripts/README.md) provide diagnostics, backup, guided tests, and recovery. To open the menu from the repository root:

```bash
bash scripts/menu.sh
```

<<<<<<< Updated upstream
O menu solicita sudo nas opções administrativas. A recuperação exige confirmação e cria um backup antes de comentar a regra USB do GDM. Os scripts não são um instalador automático; as regras e arquivos PAM continuam sendo responsabilidade do administrador.
=======
The menu prompts for `sudo` on administrative options. Recovery requires confirmation and creates a backup before commenting out the GDM USB rule. The scripts are not an automated installer; the udev rules and lock script remain documented in the guides.
>>>>>>> Stashed changes

The `scripts/` directory contains the tools, and `tests/` contains checks executed on temporary files without altering the live PAM configuration.

## Technical References

* [pam_usb, version used](https://github.com/mcdope/pam_usb/tree/0.9.3)
* [PAM: syntax and controls on Debian 13](https://manpages.debian.org/trixie/libpam-runtime/pam.d.5.en.html)
* [pam-auth-update](https://manpages.debian.org/trixie/libpam-runtime/pam-auth-update.8.en.html)
* [loginctl](https://manpages.debian.org/trixie/systemd/loginctl.1.en.html)
* [udev](https://manpages.debian.org/trixie/udev/udev.7.en.html)

Authentication and reboot tests were performed and confirmed by the user on the laptop. This documentation revision does not perform remote changes on the machine.
