# SOS Pet

## 1. Introdução

O SOS Pet é uma aplicação mobile desenvolvida em Flutter com o objetivo de facilitar a comunicação e a organização de ações voltadas ao cuidado, à adoção e à busca por animais desaparecidos. A solução foi concebida para conectar pessoas, protetores, ONGs e tutores em um ambiente digital que permite divulgar pets em situação de vulnerabilidade, encontrar animais perdidos e apoiar iniciativas de acolhimento comunitário.

No contexto de tecnologia aplicada à sociedade, o projeto busca reduzir a dificuldade de acesso a informações relevantes sobre animais em risco, promovendo uma interação mais direta entre interessados, responsáveis e instituições locais. A aplicação combina autenticação de usuários, publicação de anúncios, geolocalização, comunicação por mensagens e organização de informações em tempo real.

## 2. Problemática

A ausência de um canal centralizado e acessível para divulgação de pets perdidos ou disponíveis para adoção dificulta a mobilização de ajuda comunitária. Em muitos casos, a busca por um animal desaparecido ou a adoção responsável depende de ações fragmentadas, como grupos de redes sociais, comunicação direta e divulgação local, sem um mecanismo estruturado de organização e rastreio.

Dessa forma, o desenvolvimento do SOS Pet tem como objetivo criar uma solução prática, acessível e escalável que ofereça um ambiente unificado para apoiar a preservação do bem-estar animal e a colaboração comunitária.

## 3. Justificativa

A adoção responsável e a busca por animais perdidos exigem rapidez, organização e confiabilidade na troca de informações. O uso de uma aplicação móvel facilita o acesso ao conteúdo em qualquer momento e local, permitindo que usuários compartilhem dados relevantes de maneira mais eficiente.

Além disso, a utilização de tecnologias modernas, como Flutter, Firebase e serviços de geolocalização, torna o sistema viável para uso em ambientes reais, com atualização em tempo real, armazenamento seguro de dados e integração de recursos que aumentam a mobilidade e a eficiência da solução.

## 4. Objetivos

### 4.1 Objetivo Geral

Desenvolver uma aplicação mobile para facilitar a adoção, a busca por pets perdidos e a comunicação entre usuários interessados no cuidado animal.

### 4.2 Objetivos Específicos

- permitir o cadastro e autenticação de usuários;
- viabilizar a publicação de pets para adoção ou desaparecidos;
- oferecer mecanismos de busca e filtragem por status, local e características do pet;
- possibilitar a comunicação direta entre usuários por meio de conversas;
- disponibilizar informações georreferenciadas sobre locais próximos de acolhimento e adoção;
- estruturar uma solução funcional para uso acadêmico e potencial evolução para ambiente real.

## 5. Funcionalidades Implementadas

### 5.1 Autenticação e gerenciamento de usuários
- cadastro de usuários com nome, e-mail, telefone e senha;
- autenticação por e-mail e senha;
- armazenamento dos dados do perfil em Firebase Firestore;
- edição do perfil do usuário;
- contexto de sessão para recuperação do usuário autenticado.

### 5.2 Gestão de pets
- cadastro de pets com dados como nome, raça, localização, status e imagem;
- distinção entre animais perdidos e animais disponíveis para adoção;
- edição e exclusão de registros pelo responsável;
- listagem em tempo real dos anúncios cadastrados;
- detalhamento das informações do pet em tela específica.

### 5.3 Busca e filtragem
- pesquisa por nome, raça ou local;
- filtro por status da publicação;
- atualização dinâmica dos resultados com base nos dados armazenados no banco.

### 5.4 Comunicação
- criação de conversas entre usuários relacionadas a um pet específico;
- envio de mensagens em tempo real;
- controle de mensagens não lidas;
- alertas de respostas em conversas ativas.

### 5.5 Localização e suporte comunitário
- uso de geolocalização para identificar a posição do usuário;
- busca de locais próximos de adoção e acolhimento;
- mapeamento por meio de OpenStreetMap;
- classificação dos pontos por categoria de atuação.

## 6. Tecnologias Utilizadas

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Supabase Storage
- Geolocator
- flutter_map
- OpenStreetMap
- Google Sign-In (estrutura presente, porém temporariamente inativa em ambiente de testes)

## 7. Estrutura do Projeto

```text
lib/
  main.dart
  firebase_options.dart
  models/
    user_model.dart
  screens/
    auth_screen.dart
    splash_screen.dart
    home_screen.dart
    profile_screen.dart
    edit_profile_screen.dart
    my_pets_screen.dart
    pet_form_screen.dart
    pet_form_add.dart
    pet_detail_screen.dart
    search_screen.dart
    conversations_screen.dart
    chat_screen.dart
    notifications_screen.dart
    nearby_places_screen.dart
    settings_screen.dart
  services/
    user_service.dart
    chat_service.dart
    nearby_places_service.dart
```

## 8. Metodologia

O desenvolvimento da aplicação foi realizado com base em uma abordagem prática de engenharia de software, estruturando a solução em módulos funcionais e integrando tecnologias com foco em usabilidade, persistência e escalabilidade. A implementação foi organizada em telas e serviços independentes, com separação entre lógica de apresentação e regras de negócio.

A arquitetura adotada considera o uso de widgets em Flutter, a persistência em nuvem via Firebase e a integração com serviços externos para visão espacial e geolocalização. A navegação entre telas foi organizada para permitir fluxos intuitivos de cadastro, busca e interação do usuário.

## 9. Requisitos do Ambiente

- Flutter SDK 3.x
- Dart SDK compatível com a versão do projeto
- Firebase configurado e ativo
- Supabase configurado para armazenamento de imagens
- Ambiente de execução com suporte a Android, iOS ou Web

## 10. Procedimento de Execução

1. Clone o repositório:

```bash
git clone https://github.com/Vitu3301/sos_pet.git
cd sos_pet
```

2. Instale as dependências:

```bash
flutter pub get
```

3. Configure o Firebase:

- verifique as credenciais do projeto em `lib/firebase_options.dart`;
- confirme a configuração do Firebase Authentication e do Firestore;
- ajuste as regras de acesso conforme o ambiente de uso.

4. Configure o Supabase:

- ajuste a URL e a chave anônima em `lib/main.dart`;
- confirme a existência e a configuração do bucket de imagens para pets.

5. Execute a aplicação:

```bash
flutter run
```

## 11. Estado Atual do Desenvolvimento

O projeto encontra-se em fase funcional, com a base principal da aplicação já implementada. A solução apresenta fluxo de autenticação, gerenciamento de usuários, publicação e listagem de pets, comunicação por mensagens e suporte à localização. Esses elementos demonstram a viabilidade do sistema para uso prático em cenários de ajuda comunitária e proteção animal.

Ainda assim, o sistema pode ser aprimorado em áreas como:
- revisão de regras de segurança e permissões do Firebase/Supabase;
- refinamento de usabilidade e experiência do usuário;
- implementação de testes automatizados;
- aperfeiçoamento dos módulos de chat e notificações;
- expansão das funcionalidades de gestão da comunidade e manutenção dos registros.

## 12. Resultados Esperados

A aplicação tem potencial para contribuir na organização de ações de adoção, no apoio a pets perdidos e na promoção de uma rede de colaboração entre pessoas interessadas em animal welfare. O sistema pode ser utilizado como base para uma plataforma maior, com expansão para campanhas de resgate, organização por regiões geográficas e integração com entidades sociais.

## 13. Considerações Finais

O SOS Pet representa uma proposta de software com forte vínculo social e tecnológico. A combinação de desenvolvimento mobile, armazenamento em nuvem e geolocalização mostra-se adequada para aproximar comunidades e facilitar a atuação colaborativa em prol do bem-estar animal. O projeto já consolidou uma estrutura funcional e pode evoluir para uma solução mais robusta, escalável e alinhada a cenários reais de uso.

## 14. Licença

Este projeto foi desenvolvido como aplicação acadêmica e pode ser adaptado conforme as necessidades do curso, da instituição ou do grupo responsável pelo desenvolvimento.
