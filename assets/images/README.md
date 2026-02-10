# Instruções para adicionar a imagem de fundo

## Passo 1: Salvar a imagem
Salve a imagem de fundo de madeira que você enviou com o nome:
`wood_background.jpg`

## Passo 2: Colocar no diretório correto
Coloque o arquivo na pasta:
`D:\THABATA\TUCPB\TOTEM\assets\images\wood_background.jpg`

## Passo 3: Reiniciar o aplicativo
Após adicionar a imagem:
1. Pare o Flutter (pressione 'q' no terminal ou Ctrl+C)
2. Execute novamente: `flutter run -d chrome`

A imagem será exibida como fundo nas seguintes telas:
- Tela de Login
- Tela Inicial do Kiosk/Totem

## Observações
- O formato deve ser JPG
- Recomenda-se uma imagem de alta qualidade (mínimo 1920x1080)
- A imagem será exibida com fit: BoxFit.cover (preenche toda a tela mantendo proporção)
