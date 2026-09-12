# FATECHUB

Um aplicativo desenvolvido para solucionar a descentralização dos serviços da Fatec de Ribeirão Preto, trazendo comunicação e troca de dados de maneira mais eficiente.

**Deploy:** https://fatechub-621ee.web.app/
**Equipe:** Vinicius Lavraldo de Brito (2840482421023) | Gabriel Masson Rosa (2840482421002) · Laboratório de Engenharia de Software · ADS Fatec Ribeirão Preto

## Stack
- Frontend: Flutter 3.47.2
- Backend: Flutter 3.47.2
- Banco de dados: Cloud Firestore ^6.3.0, Firebase Auth ^6.4.0, Firebase Core ^4.7.0

## Como rodar localmente
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

## Estrutura do repositório
```
/lib     —  /controllers/cadastrar_controller.dart
                       /conta_controller.dart
                       /login_controller.dart
                       /navigation_controller.dart
                       /theme_controller.dart
            /services/chat_services.dart
            /view/app_shell.dart
                 /nova_conversa.dart
                 /view_acessibilidade.dart
                 /view_cadastrar.dart
                 /view_chat.dart
                 /view_conta.dart
                 /view_esqueciSenha.dart
                 /view_home.dart
                 /view_login.dart
                 /view_menu.dart
                 /view_messenger.dart
                 /view_turma.dart
            /widgets/app_bar.dart
   /firebase_options.dart <- Esse arquivo faz a comunicação com o banco de dadps, por isso ele é sensível
   /main.dart
```

## Convenções da equipe
- Branches: `[main]`
- Commits: `[padrão, ex: Descrição simples da implementação]`
- Toda PR exige revisão de ao menos 1 integrante antes do merge.

## Licença / Uso acadêmico
Projeto desenvolvido para a disciplina de Laboratório de Engenharia de Software e para TCC — ADS, Fatec
Ribeirão Preto, 2026.