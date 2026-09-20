# Relatório Individual de Contribuição — Sprint 1 — Gabriel Masson Rosa (RA 2840482421002)

**Papel nesta sprint:** Responsável pela funcionalidade do áudio no chat, prototipagem das telas e o serviço de notificações

## 1. O que fiz
| Item | PR/commit | Status |
|---|---|---|
| Prototipagem das telas |  | Projetadas |
| Funcionalidade dos áudios no chat | Commit 397b856 / cb70fcf | Mergeado |
| Função de notificações |  | Removido por questões de incompatibilidade com o projeto |

## 2. Rituais que participei
- [X] 2/2 Reuniões
- [x] Sprint Review
- [x] Retrospectiva

## 3. PRs de colegas que revisei
| PR | Autor | Comentário resumido |
|---|---|---|
| Commit 00914c7 | Vinicius Lavraldo de Brito | Sugeri a adição de váriaveis de identificação das turmas no banco de dados |

## 4. Dificuldades e o que aprendi
Subestimei a complexidade de fazer um sistema de notificações utilizando a Cloud Firebase. Além de ter tido diversos
problemas de consulta com tokens através das funções (passei dias tentando fazer a função ler o token para enviar as notificações)
também descobri que não iria compensar manter isso no projeto, mesmo que para testes, por conta de rapidamente exceder a cota
mensal gratuita do Plano Blaze do Firebase. Por tanto, foi removido essa funcionalidade do nosso aplicativo.