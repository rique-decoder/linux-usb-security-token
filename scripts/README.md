# Ferramentas interativas do projeto

Scripts auxiliares para a configuração do [Método 02 — Parte 02](../metodo-02/README_USB_Token_Metodo_02_Parte_02.md). Eles não instalam automaticamente o pam_usb nem aplicam a Parte 02 inteira.

## Começar pelo menu

Na pasta do repositório:

```bash
bash scripts/menu.sh
```

Execute o menu como usuário comum. As opções administrativas solicitam sudo individualmente. Se estiver usando um shell root no TTY, informe `henrique` ao selecionar os testes; não teste autenticação do GDM com root.

| Opção | Script | Efeito |
| --- | --- | --- |
| Diagnóstico | `diagnostico.sh` | Consulta sistema, volumes, ferramentas, PAM, regras e sessões |
| Backup | `backup.sh` | Copia configurações para um novo diretório privado em `/root` |
| Testes | `testar-autenticacao.sh` | Executa três operações reais de autenticação com pamtester |
| Recuperação | `recuperar-acesso.sh` | Após confirmação e backup, comenta a regra USB obrigatória do GDM |

Também é possível usar cada ferramenta diretamente, de qualquer pasta, informando seu caminho. Exemplos a partir da raiz do repositório:

```bash
bash scripts/diagnostico.sh
sudo bash scripts/backup.sh
sudo bash scripts/testar-autenticacao.sh henrique
sudo bash scripts/recuperar-acesso.sh
```

Todos os scripts principais aceitam `--help`. Não é necessário chmod para executar os exemplos com `bash`.

## Dependências

Debian 13, Bash, ferramentas básicas do sistema e Python 3. Para os testes de autenticação:

```bash
sudo apt update
sudo apt install pamtester
```

A conta e o dispositivo precisam estar cadastrados no pam_usb e a Parte 02 precisa estar configurada. Os scripts não instalam dependências automaticamente.

## Diagnóstico

Não solicita autenticação USB, não renova pads e não altera arquivos. Mostra as regras de autenticação e udev, mas não lê o conteúdo do XML nem dos pads. Identificadores e nomes de usuário podem aparecer; revise a saída antes de compartilhar.

O diagnóstico não declara a configuração segura só porque encontra uma linha. Confira a interpretação e execute os testes reais.

## Backup

O diretório `/root/usb-token-backup.XXXXXX` tem permissão `700`. Guarde o caminho exibido. São copiados:

- `/etc/pam.d/`;
- `/usr/share/pam-configs/libpam-usb`, se existir;
- `/etc/udev/rules.d/80-usb.rules`, se existir;
- `/usr/local/bin/usb-lock.sh`, se existir;
- `/etc/security/pam_usb.conf`, se existir.

Um registro lista o que foi copiado ou estava ausente. Pads, senhas de `/etc/shadow` e arquivos pessoais não são copiados. Isso é um backup de configuração, não do sistema inteiro. Não publique o diretório.

## Testes guiados

Use preferencialmente um TTY: **Ctrl + Alt + F3**, ou **Ctrl + Alt + Fn + F3** no IdeaPad. A retirada do USB pode bloquear a sessão gráfica.

O script pede que você prepare cada condição e usa `pamtester gdm-password USUARIO authenticate`:

1. USB presente e senha correta: deve ter sucesso.
2. USB presente e senha incorreta: deve falhar.
3. USB ausente e senha correta: deve falhar.

A senha é solicitada pelo pamtester, sem captura ou armazenamento pelo script. Antes de retirar o pendrive, termine gravações e desmonte o volume. Os testes podem renovar pads porque executam autenticação de verdade.

O script interrompe se o teste positivo falhar ou se um teste negativo tiver sucesso. Uma saída de falha também pode significar erro do serviço: leia as mensagens, não apenas o código de retorno. A ferramenta não consegue confirmar qual senha você digitou nem se preparou corretamente cada condição física.

Os testes do GDM gráfico, bloqueio na remoção, reconexão, logout e reinicialização permanecem manuais, conforme a Parte 02.

## Recuperação

No TTY, faça login com sua senha e execute a ferramenta com sudo. Ela:

1. Confere se há exatamente uma regra `auth required pam_usb.so` ativa no GDM.
2. Recusa outras regras USB ativas no GDM e a presença de USB ativo em `common-auth`, pois esses casos exigem revisão própria.
3. Exibe a mudança proposta e pede a palavra `CONFIRMAR`.
4. Cria um backup das configurações atuais.
5. Comenta apenas a regra obrigatória USB em `gdm-password`, preservando as demais linhas, proprietário e permissões do arquivo.

A gravação usa um arquivo temporário no mesmo diretório e substituição atômica. O arquivo original precisa ser regular; links simbólicos são recusados. Se a regra já estiver comentada, o script não altera nada. Configurações ausentes ou ambíguas também são recusadas.

Após recuperar, volte à interface, cancele uma autenticação antiga e tente novamente com sua senha. O script não executa `loginctl unlock-session`, não reinicia o GDM e não muda a regra de bloqueio udev. Outros fatores PAM existentes continuam sujeitos à própria política.

Para reativar o USB, retire manualmente o comentário da regra, mantendo-a antes de `@include common-auth`, e repita os testes. Não reative o perfil global da Parte 01. A [documentação de recuperação](../metodo-02/README_USB_Token_Metodo_02_Parte_02.md#9-recuperação-sem-o-pendrive) explica também a restauração completa; ela não é automática neste script.

## Verificações de desenvolvimento

```bash
python3 -m unittest discover -s tests -v
```

Os testes usam arquivos temporários, verificam a edição e recusa de casos ambíguos, a preservação de linhas e permissões, a execução repetida, a sintaxe Bash e a ajuda. Não testam a integração PAM do notebook nem alteram o PAM real.

A camada de edição é `lib/editar-gdm.py`, chamada pelo recuperador. `lib/comum.sh` contém utilitários de backup e interação; esses arquivos não são opções independentes do menu.
