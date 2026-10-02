# Revisão da documentação — 01/10/2026

Revisão dos três arquivos Markdown existentes e criação do guia do Método 02 — Parte 02, baseada na cópia atual do repositório e nos comandos e testes fornecidos pelo usuário.

## Alterações por arquivo

| Arquivo | Correções e complementos |
| --- | --- |
| `README.md` | Atualizado para o Debian instalado no IdeaPad; estrutura real de pastas; links entre guias; status concluído da Parte 02; tabela do comportamento final; escopo GDM e recuperação TTY; removidas descrições de pastas e arquivos que não existiam |
| `metodo-01/README_USB_Token.md` | Preservado o experimento original e suas capturas; aviso de que o desbloqueio automático está desativado no estado final; regras finais incluídas; distinguido o método isolado da composição com PAM; esclarecido que retirar regras udev não remove a exigência USB do GDM |
| `metodo-02/README_USB_Token_Metodo_02_Parte_01.md` | Identificada a política como histórica; caminho correto do XML; cadastro duplicado explicado; escopo de common-auth; `cmp -s` com código de saída; diagnóstico FAT com confirmação do dispositivo e desmontagem; explicação dos pads e distinção de TOTP; transição e link para a Parte 02 |
| `metodo-02/README_USB_Token_Metodo_02_Parte_02.md` | Novo guia com backup, correções, regras udev, desativação do perfil global, PAM do GDM, testes, resultados, TTY, recuperação, reativação e restauração completa |

## Precisão dos registros

- Os logs fornecidos confirmam as mudanças nas regras udev, em common-auth e no início de gdm-password, além de sucessos do pamtester.
- As recusas, o comportamento físico e a persistência após reinicialização foram confirmados pelo usuário; não foram inventadas saídas negativas do pamtester nem capturas da Parte 02.
- O erro de pads da Parte 01 foi preservado como registro histórico. A mensagem isolada não foi tratada como prova de corrupção causada pela remoção.
- Os testes do Método 1 foram mantidos como histórico, com aviso para não reativar o desbloqueio automático sobre a Parte 02.
- Outros usuários, serviços PAM, impressão digital, login automático e SSH não foram apresentados como validados.

## Entrega e aplicação

O pacote inclui a árvore atual do repositório com a documentação revisada, as imagens existentes, a licença e o arquivo de atributos, sem a pasta `.git`. Extraia em uma pasta separada e copie os cinco arquivos Markdown para os caminhos correspondentes da sua cópia local. As imagens e a licença não foram modificadas.

Não é necessário executar novamente os comandos dos guias no notebook que já foi configurado. Os guias registram a implementação e servem para reprodução e recuperação.

A revisão não executou comandos no notebook, não enviou commit e não publicou alterações no GitHub. Foram conferidos caminhos relativos, imagens, cercas de código, sintaxe dos blocos Bash e diferenças locais. A validação funcional do notebook é a fornecida pelo usuário.

Sugestão de commit:

```text
docs: documenta USB e senha no GDM e revisa os guias anteriores
```

## Complemento: scripts auxiliares

Foram adicionados os quatro scripts propostos, um menu, utilitários compartilhados, documentação de uso e testes em arquivos temporários. A recuperação não habilita o perfil global, não desbloqueia a tela diretamente e não executa restauração completa automaticamente. O novo pacote inclui toda a árvore atualizada; copie também `scripts/` e `tests/` para o repositório.
