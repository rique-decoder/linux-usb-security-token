# Método 1 — Controle de sessão com pendrive USB

Guia para configurar o bloqueio e o desbloqueio automático de uma sessão gráfica no Debian 13 usando `udev`, Bash e `loginctl`.

**Status histórico:** a implementação foi validada no Debian instalado diretamente no SSD, incluindo teste após reinicialização.

> **Estado atual após o Método 02 — Parte 02:** a regra de conexão que solicitava desbloqueio foi comentada. Somente o bloqueio na remoção permanece ativo. Os testes de desbloqueio automático não são mais a configuração final do projeto.

Quando usado isoladamente, este método controla uma sessão já iniciada. Ele não autentica o primeiro login e não torna o pendrive obrigatório: a senha continua permitindo entrar e desbloquear a sessão.

## 1. Ambiente e comportamento esperado

| Item | Ambiente validado |
| --- | --- |
| Sistema | Debian GNU/Linux 13 (trixie) |
| Instalação | Diretamente no SSD, sem máquina virtual |
| Interface gráfica | GNOME |
| Tipo de sessão | Wayland |
| Gerenciador de login | GDM |
| Usuário | `henrique` |
| Pendrive | SanDisk Cruzer Blade |
| Vendor ID / Product ID | `0781:5567` |
| Número de série | `4C530101421215115090` |

| Evento | Resultado esperado |
| --- | --- |
| Remover o pendrive cadastrado | Bloquear a sessão gráfica de `henrique` |
| Reconectar o pendrive cadastrado | Solicitar o desbloqueio da sessão gráfica |
| Inicializar sem o pendrive | Login convencional continua disponível |

O `udev` identifica o evento e executa o script como root. O script encontra a sessão gráfica do usuário e chama `loginctl`. O ambiente gráfico precisa atender às solicitações de bloqueio e desbloqueio. A implementação foi validada neste ambiente específico.

As capturas estão organizadas cronologicamente e distribuídas junto aos passos correspondentes. A pasta `./images/` deve permanecer ao lado deste README para os caminhos relativos funcionarem no repositório.

