# Relatório de Testes Executados — FATECHUB

**Data da bateria final:** [13/11/2026]
**Escopo testado:** todas as histórias MUST + SHOULD do termo de aceite do projeto

## 1. Resumo executivo
| Métrica | Valor |
|---|---|
| Total de casos de teste | 16 + 4 (não planejados) |
| Passaram | 16 |
| Falharam | 4 |
| Cobertura automatizada (linhas/branches) | 0% |

## 2. Casos de teste — visão consolidada
| ID | Área | Tipo | Resultado | Observação |
|---|---|---|---|---|
| CT03-CT12 | Diferenciação de usuários (aluno, professor e coordenador) | Unitário/Integração | Passou | Herdados das Sprints 1 e 3 |
| CT01-CT02 | Envio de mensagens no messenger | Unitário | 1 Descartado | Herdados das Sprint 1 |
| CT10-CT16 | Mural de avisos com controle de coordenadores | Integração | 1 teste foi considerado valido, porém com bugs | Conferir Seção 3 |
| CT04-CT09 / T01-T04 (exclusivos da Sprint4) | Sistema de classroom com envio de atividades, avisos e material de aula | Unitário/Integração | 1 Falhou e 1 Descartado | Herdados das Sprints 3 e 4 |
| CT03-CT12 | Perfil de aluno específico por curso e período na faculdade | Unitário/Integração | Passou | Herdados das Sprints 1 e 3 |

## 3. Bugs encontrados nesta bateria
| # | Descrição | Severidade | Status |
|---|---|---|---|
| 1 | Enviar imagens nos chats de texto | baixa | Descartado |
| 2 | O Firebase Store está operando em uma porta diferente do Firebase Hosting, causando uma dessincronização ao puxar a imagem upada para um post no mural | baixa | Não Corrigida |
| 3 | Notificação das atividades publicadas | Média | Descartado |
| 4 | Tentar entregar atividade fora do prazo | Média | Corrigido |

## 4. Testes de aceitação com cliente/PO
Realizado em 13/11/2026 com um aluno do curso Análise e Desenvolvimento de Sistemas da FATEC (atuando como usuário Aluno dentro do sistema).
Roteiro: Cadastro no software como Aluno, checagem dos dados cadastrados ao logar, realização de uma atividade e envio da mesma, recepção de feedback (feito pela nossa equipe em uma conta de Professor criada para esse teste), download de documentos nos arquivos da sala de aula, troca de mensagens e áudios com nosso usuário Professor, interações com postagens no mural geral e no mural da turma (gerados por usuários Coordenador e Professor criado para testes), conferência dos botões de redirecionamento para os serviços da Fatec.
Resultado: aprovado com sugestões - de acordo com o usuário, seria ideal a correção de tamanhos que, por agora, são ajustados automaticamente para tela que está executando o software (fazendo com que os botões fiquem muito grandes nos computadores) e adicionar uma função que lembre da preferência pelo modo escuro do aplicativo.