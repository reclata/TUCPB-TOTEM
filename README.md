
# Sistema de Fila para Terreiro (Terreiro Queue System)

Este projeto é um sistema completo de gestão de filas para Terreiros de Umbanda/Candomblé, focado na experiência do usuário e eficiência no atendimento.

## Funcionalidades

### 1. Kiosk / Totem (Android - Gertec SK210)
- Emissão de senhas por Entidade.
- Impressão térmica de ticket com QR Code PIX.
- Geração sequencial de senhas (Ex: SL0001).
- Modo Kiosk (tela cheia, bloqueado).

### 2. Painel Admin (Web/Mobile)
- Abertura e fechamento de Giras.
- Cadastro de Entidades e Médiuns.
- Gestão de Fila (Chamar próxima, Rechamar, Marcar ausente).
- Relatórios básicos.

### 3. Painel TV (Web)
- Visualização de chamadas em tempo real.
- Histórico das últimas chamadas.
- Design de alto contraste para leitura à distância.

### 4. Visão Usuário (Web Mobile)
- Consulta da própria posição na fila via QR Code (Ticket).

## Requisitos de Instalação

### Pré-requisitos
- Flutter SDK (3.x+)
- Conta no Firebase (Blaze plan recomendado para Functions se necessário, mas Spark funciona para base).
- Node.js (para Firebase Tools).

### Configuração do Firebase
1. Crie um projeto no Firebase Console.
2. Habilite **Authentication** (Email/Password).
3. Habilite **Firestore Database**.
4. Habilite **Hosting** (opcional, para Web).
5. Configure o projeto Flutter:
   ```bash
   flutterfire configure
   ```
   (Isso gerará o `firebase_options.dart` em `lib/`).
6. Implante as Regras de Segurança e Índices:
   - Copie o conteúdo de `firestore.rules` para o console.
   - Crie os índices compostos conforme solicitado pelo console ao rodar o app (links nos logs).

### Índices Firestore Necessários (Exemplo)
- `tickets`: `terreiroId` (ASC) + `status` (ASC) + `dataHoraChamada` (DESC)
- `tickets`: `terreiroId` (ASC) + `giraId` (ASC) + `entidadeId` (ASC) + `status` (ASC) + `ordemFila` (ASC)

## Como Rodar

### Web (Admin / TV)
```bash
flutter run -d chrome
# ou build
flutter build web --release
```
Para deploy:
```bash
firebase deploy --only hosting
```

### Android (Kiosk SK210)
Conecte o dispositivo via USB.
```bash
flutter run -d android
# ou gerar APK
flutter build apk --release
```
Instale o APK no dispositivo. Para produção, configure o modo "Kiosk" no Android (fixação de tela).

## Uso do Sistema

1. **Login**: Acesse `/login` (ou rota padrão). Crie usuários no Firebase Console.
2. **Setup Inicial (Admin)**:
   - Cadastre as Entidades.
   - Cadastre os Médiuns e vincule às Entidades.
3. **Dia de Gira**:
   - Vá em "Gira" no Admin.
   - Clique em "ABRIR NOVA GIRA" e defina o tema (ex: Caboclo).
   - Ative os Médiuns que estarão atendendo.
4. **Kiosk**:
   - Abra o app no Totem.
   - Ele detectará a Gira aberta e mostrará as Entidades disponíveis.
   - Usuário toca na Entidade e retira a senha impressa.
5. **Chamada (Fila)**:
   - No Admin, aba "Fila" (Visão Queue), chame a próxima senha.
   - O Painel TV atualizará instantaneamente.

## Regras de Negócio Importantes
- **Não Compareceu**: A senha é movida para o final da fila (mesmo código, nova ordem). Nunca excluída.
- **Impressão**: O ticket contém QR Code PIX (configurável via código no momento em `printer_service.dart`).
- **Senhas**: Formato [Iniciais do Médium] + [Sequencial 4 dígitos]. Reinicia a cada dia por médium.

## Estrutura do Código
- `lib/src/features/`: Módulos funcionais (admin, kiosk, tv, queue).
- `lib/src/shared/`: Modelos, Serviços e Providers globais.
- `lib/main.dart`: Rotas e inicialização.

## Troubleshooting
- **Impressora não imprime**: Verifique se o SK210 está com permissão de USB/Bluetooth para o app. No código `printer_service.dart`, a implementação é Genérica (ESC/POS). Para hardware específico, pode ser necessário ajustar o driver/plugin.
- **Erro de Permissão**: Verifique `firestore.rules`.
- **Tela preta no Kiosk**: Verifique se há uma Gira aberta no Admin.

---
Desenvolvido com Flutter & Firebase.
Axé!
