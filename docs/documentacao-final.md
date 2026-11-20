# Documentação Final — FATECHUB

**Deploy definitivo:** [https://fatechub-621ee.firebaseapp.com/]
**Repositório:** [https://github.com/gabrielbr4000/fatechub]

## 1. Índice de artefatos do semestre
| Entrega | Documento | Link |
|---|---|---|
| E1 | Documento de Visão | ´docs/documento-de-visao.pdf´ |
| E2 | Backlog + Termo de Aceite do Projeto | [Backlog](https://docs.google.com/spreadsheets/d/11nLn_qqkQxTMVogq8icIFG1rmNITaizkWkvHX0nSWG8/edit?hl=pt-br&gid=0#gid=0), `docs/Termo_de_Aceite_do_Projeto.docx` |
| E3 | UML + DER + DDL | `docs/FATECHUB_UC.png`, `docs/FATECHUB_CD.png` |
| E4 | README + Protótipo + Plano de Testes | `README.md`, [Protótipo](https://www.figma.com/design/1YFCvPVJcDTPJgm2zZUh2M/Telas-FatecHub?node-id=0-1&t=9asuOmz5dEopRh8z-1), `docs/plano-de-teste.md` |
| E5–E8 | Relatórios de sprint | `docs/Sprint{1,2,3,4}/Relatorio_de_entrega.md` |
| E9 | Relatório de testes + Termo de Aceite do Cliente | `docs/relatorio-de-testes-executados.md`, `docs/termo-aceite-cliente.md` |

## 2. Desvios do escopo original (vs. E2b)
| Item | Mudou? | Justificativa |
|---|---|---|
| Notificações de novas mensagens | Foi removido | Devido à custeamento do Firebase |

## 3. Arquitetura final (resumo)
[Diagrama ou descrição textual das camadas/serviços, se mudou desde a E4]

## 4. Como contribuir/rodar
### Pré-requisitos
- Flutter SDK ^3.47.2
- Visual Studio Code ^1.137.0
- [Firebase CLI](https://firebase.google.com/docs/cli#install-cli-windows)
- Conta no banco de dados da FireBase

### Passo a passo
1. Clone o repositório: `git clone https://github.com/gabrielbr4000/fatechub1.git`
2. Rode `flutter pub get`, depois `flutter pub outdated` e depois `flutter pub upgrade`
3. Instale o Firebase CLI negando o Gemini e a opção de dados e faça login com a conta do seu banco de dados firebase `firebase login`
4. Instale a CLI do Flutterfire usando `dart pub global activate flutterfire_cli`
5. Configure o firebase usando `flutterfire configure`
6. Depois de fazer as devidas configurações e gerar o firebase_options.dart, execute o main.dart, escolha seu navegador (dê preferência para o Google Chrome) e seja feliz.
7. Todas as configurações de banco de dados devem ser feitas pelo serviço do firebase utilizando o console firebase.
