# Relatório de Entrega — Sprint 2 — FatecHub

**Período:** 25/09/2026 (Sprint 2 comprimida em 1 semana só)
**Sprint Review:** 25/09/2026, com o professor Lucas B. F.

## 1. Planejado vs. entregue
| História (E2) | Planejada para esta sprint? | Entregue? | Observação |
|               |                             |           |            |
| #1 Enviar audio (correções) | Não | Sim | Funcionando perfeitamente
| #2 Acesso e resposta do Aluno nas atividades | Sim | Sim (parcial) | Ainda precisa de um refino e alguns consertos, mas funcional |
| #3 Professor corrigir atividades | Sim | Sim (parcial) | Funcionando, mas ainda precisa passar por testes |
| #4 Coordenador e a manipulação do calendário academico | Sim | Sim (parcial) | Funcionando, mas ainda precisa passar por testes |

## 2. Incremento funcional demonstrável
Correções dos bugs anteriores.
Implementado a tela das atividades a possibilidade do aluno pode entrar na tela de uma atividade e responder com o envio de um arquivo.
O professor também pode anexar arquivos nas atividades para os alunos acessarem (ainda precisa ser feito a possibilidade do aluno acessar).
O professor pode verificar cada envio das atividades dos alunos e corrigi-las postando uma nota em resposta.
O coordenador pode enviar o PDF do calendário acadêmico semestral na aba do calendário no menu principal.

### IMPORTANTE
Não foi possível as verificações das implementações e nem mesmo a possibilidade da gravação do video por conta de um problema com o banco de dados:
Por conta da tentativa da implementação do sistema de notificações, o banco de dados bloqueou o acesso deste mês por questões de orçamento,
ele irá ser liberado apenas mês que vem quando as taxas voltarem a 0 reais.

## 3. Backlog atualizado
Board: https://docs.google.com/spreadsheets/d/11nLn_qqkQxTMVogq8icIFG1rmNITaizkWkvHX0nSWG8/edit?usp=sharing — ao fim da sprint,
3 itens foram parcialmente finalizados.

## 4. Evidências de teste
2 testes unitários nesta sprint. Detalhe
completo: `docs/sprint2/evidencias-teste.md`.

## 5. Retrospectiva e contribuição individual
- Ata de retrospectiva: `docs/sprint2/retrospectiva.md`
- Relatórios individuais (com nome + RA de cada um): `docs/sprint2/contribuicao-{gabriel,vinicius}.md`

## 6. Riscos/impedimentos para a próxima sprint
O banco de dados foi bloqueado, verificar possibilidade de ser bloqueado no próximo mês após a liberação para não ocorrer imprevistos como este na sprint 4.