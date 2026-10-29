# Método 02 — Parte 01: Autenticação USB ou Senha com pam_usb

> **Registro histórico:** esta política foi validada e depois substituída pela [Parte 02 — USB + senha](README_USB_Token_Metodo_02_Parte_02.md). Não reative o perfil USB global sobre a configuração final do projeto.

## Ambiente e evidências

O projeto começou em uma VM Debian no VirtualBox e posteriormente passou ao Debian 13 instalado diretamente no SSD do Lenovo IdeaPad 3i. Esta Parte 01 preserva os comandos, capturas e resultados relativos à fase em que o pendrive era aceito como alternativa à senha.

As capturas existentes permanecem nos caminhos originais. Não foram criadas novas capturas nem executados novamente os testes desta etapa durante a revisão documental.

## Objetivo

Nesta etapa foi implementada uma autenticação em que o pendrive servia como fator de posse, mantendo a senha tradicional do usuário como alternativa.

Resultado esperado:

- Com USB conectado → login sem digitar senha.
- Sem USB conectado → login utilizando senha normalmente.

O USB ainda não era obrigatório nesta etapa.

