# Relatório Individual de Contribuição — Sprint 1 — Vinicius Lavraldo de Brito (RA 2840482421023)

**Papel nesta sprint:** Responsável pela implementação dos perfis de aluno e professor, além do desenvolvimento de funcionalidades relacionadas à seção “Turmas” para esses perfis

## 1. O que fiz
| Item | PR/commit | Status |
|---|---|---|
|Implementação dos perfis de usuário (aluno e professor) na tela de cadastro|00914c7|Concluído|
|Adição dos campos semestre, curso e período no cadastro do aluno|00914c7|Concluído|
|Adição do campo disciplina no cadastro do professor|00914c7|Concluído|
|Atualização da tela Turmas para exibir disciplinas do semestre do aluno|00914c7|Concluído|
|Atualização da tela Turmas para exibir turmas do professor (manhã e noite)|00914c7|Concluído|
|Criação da tela Detalhes Turma|00914c7|Parcial|
|Criação da tela Atividades por turma|00914c7|Concluído|
|Criação da tela Todas as Atividades|00914c7|Concluído|
|Criação da tela Criar Atividade (exclusiva para professores)|00914c7|Parcial|
|Lógica de isolamento de atividades por turma|00914c7|Concluído| 

## 2. Rituais que participei
- [x] Dailies/weeklies
- [x] Sprint Review
- [x] Retrospectiva

## 3. PRs de colegas que revisei
| PR | Autor | Comentário resumido |
|---|---|---|
|Compromissos 397b856/cb70fcf|Gabriel Masson Rosa|Revisei a funcionalidade de áudio no chat|

## 4. Dificuldades e o que aprendi
Durante o sprint, enfrentei três dificuldades principais. A primeira foi a AppBar duplicada,
não previ que ter o componente tanto no AppShell quanto nas telas individuais causaria dois cabeçalhos simultâneos, 
o que me forçou a refatorar a propagação de dados do usuário pela aplicação. A segunda foi a lógica de permissões na tela Turmas, 
que foi mais complexa do que eu esperava, pois o filtro dependia do perfil do usuário e do formato em que a disciplina estava salva no Firestore, 
precisei criar mapas de conversão para cobrir os diferentes casos. Por fim, cometi um erro de versionamento ao esquecer de adicionar o app_bar.dart ao commit, o que ocasionou um erro quando meu parceiro atualizou o repositório. Precisei enviar o arquivo manualmente e aprendi a sempre verificar o git status antes de commitar.
