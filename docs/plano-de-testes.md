# Plano de Testes — FatecHub

## 1. Estratégia
| Tipo de teste | O que cobre | Ferramenta | Quando roda |
|---|---|---|---|
| Unitário | Regras de negócio isoladas (bloqueio de conversa duplicada, contador de mensagens não lidas, validação de perfil) | Flutter Test | A cada PR (CI) |
| Integração | Fluxos com Firebase (autenticação, envio de mensagem, criação de conversa, publicação de postagem)  | Flutter Test + Firebase Emulator  | A cada PR (CI), a partir da Sprint 2 |
| Manual/aceitação | Fluxos completos de ponta a ponta antes de cada Sprint Review | Roteiro manual documentado | Ao fim de cada sprint |

## 2. Critério de bloqueio de merge
Nenhum PR é aceito na main se: (a) algum teste automatizado existente quebrar; (b) uma nova regra de negócio (ex.: bloqueio de conversa duplicada, controle de permissões por perfil) for adicionada sem teste unitário correspondente; (c) o build do Flutter falhar com erros de compilação.

## 3. Casos de teste planejados (cresce a cada sprint)
| ID | História (E2) | Cenário | Entrada | Resultado esperado | Prioridade |
|---|---|---|---|---|---|
| CT01 | #1 | Usuário envia arquivo de imagem no chat | Arquivo de imagem selecionado da galeria | Arquivo aparece como mensagem do tipo 'imagem' na conversa | Alta |
| CT02 | #1 | Usuário envia áudio no chat | Arquivo de áudio gravado ou selecionado | Áudio aparece como mensagem do tipo 'áudio' na conversa | Alta |
| CT03 | #2| Professor preenche formulário de atividade e publica | Título, descrição, data limite e arquivo anexado | Atividade aparece na tela dos alunos da turma | Alta |
| CT04 | #2| Professor tenta publicar atividade sem título | Campo título vazio | Sistema exibe mensagem de erro e bloqueia envio | Alta |
| CT05 | #3| Professor publica nova atividade | Atividade criada com sucesso | Todos os alunos da turma recebem notificação | Alta |
| CT06 | #4| Aluno envia resposta em texto para atividade | Texto digitado no campo de resposta | Resposta aparece na atividade e professor é notificado | Alta |
| CT07 | #4| Aluno tenta entregar a mesma atividade duas vezes | Segunda submissão do mesmo aluno | Sistema bloqueia com mensagem "atividade já entregue" | Alta |
| CT08 | #4| Aluno tenta entregar atividade fora do prazo | Submissão após data_limite | Sistema exibe aviso de prazo encerrado | Média |
| CT09 | #5 | Professor abre entrega de aluno e devolve comentário | Texto de correção preenchido | Comentário aparece na entrega do aluno | Média |
| CT10 | #6 | Coordenador faz upload de novo documento de calendário | Arquivo PDF enviado | Documento antigo é substituído pelo novo | Alta |
| CT11 | #6 | Aluno acessa opção de calendário | Toque na opção "Calendário" na tela home | Sistema redireciona para o documento mais recente | Média |
| CT12 | #7 | Coordenador preenche formulário e pública postagem | Título, descrição e imagem anexada | Postagem aparece no mural para todos os usuários | Alta |
| CT13 | #8| Usuário comenta em postagem do mural | Texto digitado no campo de comentário | Comentário aparece abaixo da postagem | Média |
| CT14 | #9| Professor envia mensagem de texto na sala da turma | Texto digitado e enviado | Mensagem aparece no chat da turma para todos os alunos | Alta |
| CT15 | #10| Usuário acessa opção de calendário acadêmico | Toque na opção na tela home | Sistema redireciona para o documento do calendário | Média |
| CT16 | #11| Usuário acessa opção de horários das aulas | Toque na opção na tela home | Sistema redireciona para o site de horários da Fatec | Média |
