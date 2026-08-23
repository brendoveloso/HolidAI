# Plano técnico — reformulação da navegação e experiência do HolidAI

Status: aprovado para implementação futura  
Escopo deste documento: planejamento técnico; não implementar durante a criação ou revisão deste plano.

## 1. Objetivo

Reformular o HolidAI para oferecer uma experiência nativa e consistente com iOS 26, centrada em profissionais que podem manter um ou vários vínculos de trabalho. O aplicativo deve permitir:

- visualizar rapidamente o próximo feriado aplicável aos contratos ativos;
- consultar feriados de forma consolidada ou por contrato;
- cadastrar, consultar, editar, ativar, desativar e excluir contratos;
- pesquisar globalmente contratos e feriados em um único ponto;
- acessar um botão de perfil preparado para receber foto no futuro.

A implementação deve preservar a integração existente com a API de feriados, eliminar a dependência de um único contrato e estabelecer uma base testável para evolução do produto.

## 2. Contexto atual do repositório

O projeto Xcode está em `HolidAI.xcodeproj`, usa SwiftUI, SwiftData e tem deployment target iOS 26.1 para o aplicativo. O build estava bem-sucedido na última inspeção anterior a este plano.

Arquivos atuais mais relevantes:

- `HolidAI/HolidAI/Views/ContentView.swift`: usa `@Query` para buscar contratos, mas entrega apenas `contracts.first` ao restante do aplicativo. Quando não há contrato, exibe diretamente `RegisterView`.
- `HolidAI/HolidAI/Views/MainTabView.swift`: contém apenas as abas Feriados e Contrato; a segunda ainda é placeholder.
- `HolidAI/HolidAI/Views/DashboardView.swift`: implementa a lista atual de feriados, incluindo loading, erro, vazio, badge de data e tipo. Contém um `NavigationStack` próprio, embora `MainTabView` também envolva a tela em outro `NavigationStack`.
- `HolidAI/HolidAI/ViewModels/DashboardViewModel.swift`: carrega apenas o ano corrente e filtra feriados facultativos de acordo com um único contrato.
- `HolidAI/HolidAI/Models/Contract.swift`: persiste empresa, país, UF, cidade, tipo de vínculo e código bancário opcional.
- `HolidAI/HolidAI/Models/HolidayCache.swift`: está registrado no schema SwiftData, mas o fluxo atual apenas cria objetos em memória e não os insere no `ModelContext`.
- `HolidAI/HolidAI/Services/HolidayService.swift`: define a API de estados e feriados e os DTOs remotos.
- `HolidAI/HolidAI/Services/RealHolidayService.swift`: consulta `feriadosapi.com`, inclui facultativos e seleciona endpoint estadual ou municipal para capitais conhecidas.
- `HolidAI/HolidAI/Views/RegisterView.swift` e `ViewModels/RegisterViewModel.swift`: implementam o cadastro inicial de contrato.
- `HolidAI/HolidAI/HolidAIApp.swift`: registra `Contract` e `HolidayCache` no `ModelContainer` e encerra o app com `fatalError` se a criação do container falhar.

O plano de testes atual contém quatro testes habilitados, todos derivados do template (`example`, teste de UI básico, launch e launch performance). Eles não validam regras reais do produto.

## 3. Decisões de produto e interface já aprovadas

### 3.1 Navegação principal

Usar três abas normais e uma aba de busca especial:

1. **Início** — SF Symbol `house.fill`.
2. **Feriados** — SF Symbol `calendar`.
3. **Contratos** — SF Symbol `doc.text.fill`.
4. **Busca** — `Tab(role: .search)`, visualmente separada no trailing edge.

Cada aba deve possuir seu próprio `NavigationStack`, preservando posição de rolagem e estado de navegação. Não manter `NavigationStack` duplicado dentro de uma tela já hospedada pelo stack da aba.

A busca deve adotar o comportamento nativo de iOS 26 com `.searchable` e `.tabViewSearchActivation(.searchTabSelection)`: ao tocar a lupa, o campo recebe foco, o teclado aparece e a última aba de conteúdo permanece isolada no canto esquerdo. Ao cancelar, retornar à aba anterior.

Referências de design:

- [Apple HIG — Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars)
- [Apple HIG — Search fields](https://developer.apple.com/design/human-interface-guidelines/search-fields)
- [Apple HIG — Searching](https://developer.apple.com/design/human-interface-guidelines/searching)

### 3.2 Cabeçalho das telas principais

- Leading edge: somente o nome da aba atual (`Início`, `Feriados` ou `Contratos`).
- Trailing edge: botão circular de perfil.
- Placeholder inicial do perfil: `person.crop.circle.fill`.
- Futuramente, substituir o símbolo por uma foto circular sem alterar tamanho, posição ou semântica do botão.
- O botão deve ter hit target mínimo de 44 x 44 pt e accessibility label `Perfil`.
- Usar título grande nas raízes e título inline nas telas de detalhe.
- A tela de busca não deve exibir um título que concorra visualmente com o campo de pesquisa.

### 3.3 Comportamento das abas

**Início**

- Mostrar o próximo feriado aplicável entre todos os contratos ativos.
- Exibir data, dia da semana, nome, tipo, quantidade de dias restantes e contratos aos quais se aplica.
- Se o mesmo feriado se aplicar a vários contratos, consolidar o card e indicar a quantidade ou os nomes relevantes.
- Quando não restarem feriados no ano corrente, consultar o próximo ano.
- Se não houver contratos, mostrar estado vazio com ação `Adicionar contrato`.

**Feriados**

- Oferecer seletor entre `Todos` e um contrato específico.
- Agrupar feriados por mês e ordenar cronologicamente.
- Na primeira exibição, favorecer o posicionamento no próximo feriado.
- Datas passadas devem permanecer legíveis, mas visualmente secundárias.
- Na visão `Todos`, deduplicar um mesmo feriado e indicar os contratos aos quais ele se aplica.
- Cada linha deve incluir data, nome, tipo e contexto de localização/contrato quando necessário.

**Contratos**

- Mostrar cards com empresa, UF, cidade quando relevante e tipo de vínculo.
- Permitir criar, abrir detalhes, editar, ativar/desativar e excluir.
- Exigir confirmação antes da exclusão.
- Manter a ação principal `Adicionar contrato` no conteúdo ou no estado vazio, preservando o canto superior direito para perfil.

**Busca**

- Placeholder: `Buscar feriados ou contratos`.
- Pesquisar localmente enquanto a pessoa digita.
- Ignorar acentos, capitalização e espaços excedentes.
- Pesquisar nome e tipo de feriado; nome da empresa; UF; cidade; e tipo de vínculo.
- Agrupar resultados nas seções `Feriados` e `Contratos`.
- Ao selecionar um resultado, trocar para a aba correspondente e abrir o detalhe correto.
- Estado inicial: `Busque por feriado, empresa, UF ou vínculo`.
- Estado vazio: `Nenhum resultado para “<termo>”`.
- Buscas recentes e sugestões não pertencem ao MVP.

**Perfil**

- O botão deve abrir uma tela simples de perfil/configurações futuras.
- Persistência de perfil, autenticação e seleção de foto não pertencem ao MVP.

## 4. Decisões de arquitetura

### 4.1 SwiftData e ausência de migração

O aplicativo nunca foi lançado e não existem dados reais de usuários. Não implementar `VersionedSchema` nem `SchemaMigrationPlan` neste ciclo. O esquema publicado na primeira versão da App Store será considerado a versão inicial oficial.

Durante o desenvolvimento, quando uma alteração incompatível impedir a abertura do store local, usar uma instalação limpa do app ou um simulador limpo. Não criar lógica de migração apenas para preservar dados de teste.

Persistir no SwiftData somente dados criados pela pessoa usuária na versão inicial.

### 4.2 Modelo `Contract`

Evoluir `Contract` para conter, no mínimo:

- `id: UUID` único e estável;
- `companyName: String`;
- `country: String`, inicialmente `BR`;
- `state: String` com UF;
- `city: String`;
- representação persistida estável do tipo de vínculo;
- `isActive: Bool`;
- `createdAt: Date`;
- `bankCode: String?`, mantido para evolução futura, sem obrigatoriedade no MVP.

Criar um enum de domínio para os vínculos `CLT`, `PJ` e `Bancário`. Evitar comparações de negócio baseadas em variações de strings como `BANCÁRIO`, `Bancário` ou `banking`. A persistência pode usar raw value estável; a UI deve usar rótulo localizado.

### 4.3 Feriados como domínio não persistente no MVP

Remover `HolidayCache` do schema SwiftData inicial. Representar feriado com uma struct de domínio (`Holiday`) contendo, no mínimo:

- identidade estável para a sessão;
- data;
- nome;
- tipo;
- indicador de aplicação bancária recebido da API;
- ano;
- UF;
- cidade opcional;
- informação suficiente para diferenciar abrangência/localização.

Não implementar cache persistente ou suporte offline neste ciclo. A API é a fonte de verdade e os resultados ficam em memória durante a sessão.

### 4.4 Separação entre DTO, domínio e apresentação

- DTOs devem refletir exclusivamente o contrato remoto.
- O service deve buscar e decodificar dados.
- O repository deve converter DTOs em domínio, deduplicar requisições e manter cache de sessão.
- Regras de aplicabilidade e agregação devem ser funções de domínio testáveis.
- Views não devem interpretar strings da API nem conter regras de negócio.

### 4.5 `HolidayRepository`

Criar um repository com protocolo e implementações real/mock. Responsabilidades:

- buscar por uma chave composta de ano, UF e cidade aplicável;
- evitar chamadas duplicadas quando contratos compartilham localização;
- armazenar resultados em cache de memória durante a sessão;
- permitir retry seletivo de chaves que falharam;
- não acessar diretamente SwiftUI;
- não fazer chamadas reais de rede nos testes.

### 4.6 Regra de aplicabilidade

Preservar a intenção da regra existente, mas movê-la para o domínio:

- feriados retornados para a localização do contrato aplicam-se normalmente ao contrato;
- quando o tipo for `FACULTATIVO`, aplicar somente quando o contrato for Bancário e o DTO indicar aplicação bancária;
- normalizar tipo e vínculo antes da comparação;
- cobrir a regra com testes.

Se a regra de negócio mudar durante a execução, registrar a decisão no plano ou na entrega antes de alterar o comportamento.

### 4.7 Estado compartilhado e roteamento

Criar um estado observável compartilhado para feriados (`HolidayStore` ou nome equivalente), responsável por:

- carregar dados para contratos ativos;
- agrupar resultados por contrato e por chave de localização;
- produzir o próximo feriado consolidado;
- produzir a lista `Todos` e a lista de um contrato;
- expor loading inicial, refresh, erros por localização e resultado parcial;
- carregar o próximo ano quando necessário.

Criar um roteador observável (`AppRouter` ou equivalente), responsável por:

- aba selecionada;
- última aba de conteúdo selecionada antes da busca;
- rotas de detalhe de feriado e contrato;
- transição da busca para a aba/detalhe de destino.

O `@Query` de contratos deve continuar sendo a fonte reativa de contratos persistidos. Não copiar contratos para um segundo armazenamento que possa divergir do SwiftData.

### 4.8 Componentização de UI

Criar componentes reutilizáveis, com nomes equivalentes a:

- `ProfileButton`;
- `NextHolidayCard`;
- `HolidayRow`;
- `HolidayTypeBadge`;
- `ContractCard`;
- estados de loading, erro e vazio quando a abstração reduzir duplicação real.

Evitar criar abstrações genéricas antes de existir reutilização concreta.

## 5. Tarefas de implementação em ordem de dependência

### Fase 1 — domínio e esquema inicial

1. Definir o enum de vínculo e sua representação persistida/localizada.
2. Reformular `Contract` com identidade, atividade e data de criação.
3. Criar a struct de domínio `Holiday`.
4. Remover `HolidayCache` do schema do `ModelContainer` e, se não tiver outra utilidade, do target.
5. Atualizar fixtures e previews afetados pelos novos initializers.
6. Usar uma instalação limpa para validar o schema; não criar migração.

Resultado esperado: o projeto compila com o schema inicial definitivo e o cadastro continua salvando contratos.

### Fase 2 — service, repository e regras

1. Manter DTOs desacoplados do modelo de domínio.
2. Adaptar `HolidayService` para suportar a conversão necessária sem expor regras à UI.
3. Criar protocolo e implementação do repository com cache por chave.
4. Criar implementação mock determinística.
5. Extrair e testar aplicabilidade, deduplicação, normalização e cálculo do próximo feriado.
6. Tratar virada de ano sem misturar resultados incorretamente.

Resultado esperado: regras podem ser exercitadas sem SwiftUI e sem rede.

### Fase 3 — estado e navegação raiz

1. Criar o store compartilhado de feriados.
2. Criar o router e os destinos tipados.
3. Reestruturar `ContentView` para sempre hospedar a experiência principal e permitir estado vazio de contratos dentro dela; não bloquear todo o app em `RegisterView`.
4. Recriar `MainTabView` com as três abas normais e `Tab(role: .search)`.
5. Garantir um `NavigationStack` por aba e remover stacks duplicados.
6. Adicionar títulos corretos e botão de perfil compartilhado.

Resultado esperado: as quatro entradas aparecem e alternam corretamente mesmo antes de todas as telas estarem completas.

### Fase 4 — componentes e telas de conteúdo

1. Implementar os componentes visuais reutilizáveis.
2. Implementar Início com próximo feriado consolidado e estados vazio/loading/erro.
3. Evoluir ou substituir `DashboardView` pela tela Feriados agrupada, com seletor `Todos`/contrato.
4. Implementar Contratos com lista, estados, detalhes e formulário reutilizável para criar/editar.
5. Implementar ativação, desativação e exclusão confirmada.
6. Implementar a tela provisória de Perfil.

Resultado esperado: todos os fluxos de conteúdo funcionam sem depender da busca.

### Fase 5 — busca global

1. Criar normalização de texto testável e independente de SwiftUI.
2. Criar resultados tipados para feriado e contrato.
3. Implementar pesquisa incremental local e seções de resultados.
4. Implementar estados inicial e vazio.
5. Integrar seleção com o router para abrir a aba e o detalhe corretos.
6. Confirmar comportamento de foco, teclado, cancelamento e retorno à aba anterior.

Resultado esperado: uma única busca encontra todos os campos acordados e navega ao destino correto.

### Fase 6 — robustez, acessibilidade e acabamento

1. Suportar falhas parciais: preservar dados válidos, identificar localizações que falharam e permitir retry seletivo.
2. Usar cores semânticas e validar claro, escuro e contraste aumentado.
3. Garantir que tipo de feriado nunca seja comunicado apenas por cor.
4. Validar Dynamic Type, inclusive tamanhos de acessibilidade.
5. Adicionar accessibility labels, values e hints úteis.
6. Garantir hit targets mínimos de 44 x 44 pt.
7. Criar previews determinísticos para estados principais.
8. Verificar layout em iPhone e iPad.

## 6. Critérios de aceitação

### Navegação e cabeçalho

- Existem exatamente três abas normais: Início, Feriados e Contratos.
- Busca aparece como controle separado no trailing edge usando o papel nativo de search.
- Tocar Busca abre o campo, apresenta teclado no iPhone e mantém a aba anterior isolada à esquerda.
- Cancelar retorna à aba anterior sem corromper seu estado.
- Cada raiz mostra apenas o título no lado esquerdo e o botão de perfil no direito.
- Não existem `NavigationStack`s aninhados acidentalmente.

### Contratos

- É possível manter mais de um contrato.
- Criar, editar, ativar/desativar e excluir refletem imediatamente nas demais telas.
- Cards mostram empresa, UF e vínculo; cidade aparece quando útil.
- Exclusão exige confirmação.
- Contratos inativos não influenciam o próximo feriado da Home.

### Início e feriados

- Home mostra o próximo feriado aplicável entre contratos ativos.
- Um mesmo feriado aplicável a vários contratos aparece consolidado.
- Quando necessário, o próximo ano é consultado.
- Feriados podem ser vistos em `Todos` ou por contrato.
- A lista é cronológica, agrupada por mês e diferencia datas passadas sem perder legibilidade.
- Facultativos seguem a regra bancária definida neste plano.

### Busca

- Busca encontra contratos e feriados pelos campos definidos.
- `São Paulo`, `sao paulo` e `SAO PAULO` produzem resultados equivalentes.
- Resultados são agrupados por tipo.
- Selecionar resultado abre a aba e detalhe adequados.
- Estado inicial e ausência de resultados são compreensíveis e acessíveis.

### Qualidade e resiliência

- Falha de uma localização não descarta dados das demais.
- Nenhum teste depende da API real.
- Nenhum segredo é registrado em logs ou fixtures.
- Build e testes terminam com sucesso.
- Não há warning novo introduzido pelo trabalho; avaliar separadamente o warning preexistente `Update to recommended settings`.

## 7. Estratégia de testes

Adicionar testes unitários para:

- mapeamento do tipo de vínculo;
- normalização de busca sem acentos/case;
- regra de facultativo para CLT, PJ e Bancário;
- cálculo do próximo feriado;
- descarte de datas passadas nesse cálculo;
- fallback para o ano seguinte;
- deduplicação entre contratos;
- cache do repository por localização/ano;
- retry somente de chaves que falharam;
- agregação com erro parcial;
- busca em todos os campos acordados.

Adicionar testes de UI para:

- presença e troca das abas;
- botão de perfil;
- estado sem contratos e criação de contrato;
- exibição de vários cards;
- expansão e cancelamento da busca;
- resultado de contrato e de feriado levando ao destino correto.

Mocks devem usar datas fixas ou relógio injetável para evitar testes dependentes do dia em que executam.

## 8. Etapas de validação

Executar após cada fase:

1. Compilar o target `HolidAI` com o esquema e destino ativos no Xcode.
2. Inspecionar Build Log e Issue Navigator, não apenas o status final.
3. Executar os testes unitários relacionados à fase.
4. Executar toda a suíte antes de iniciar a fase seguinte quando houver mudança transversal.

Antes da entrega:

1. Executar todos os testes do plano ativo.
2. Fazer build limpo em instalação/simulador sem dados anteriores.
3. Exercitar manualmente os critérios de aceitação com pelo menos dois contratos em UFs ou vínculos diferentes.
4. Simular sucesso total, vazio, erro total e erro parcial.
5. Validar UI em claro/escuro, Dynamic Type e VoiceOver.
6. Validar em um iPhone e um iPad, respeitando a adaptação nativa da tab bar.
7. Comparar o diff final com este plano e com os critérios de aceitação.
8. Fazer revisão independente procurando regressões, regras duplicadas, acesso à rede em testes, problemas de concorrência, navegação inconsistente e violações de acessibilidade.

## 9. Restrições importantes

- Não implementar migração SwiftData neste ciclo; o app não foi lançado.
- Não preservar dados de teste às custas de complexidade de produção.
- Não adicionar dependências externas sem necessidade técnica demonstrada e aprovação.
- Não realizar chamadas reais de rede em testes ou previews.
- Não alterar a API remota nem expor a chave configurada em `Secrets.xcconfig`.
- Não persistir perfil, foto, histórico de busca ou feriados no MVP.
- Não criar uma tab bar customizada para imitar o comportamento que o iOS 26 já oferece nativamente.
- Não comunicar tipo/status apenas por cor.
- Não mover regras de negócio para views.
- Não considerar a tarefa concluída apenas porque o build passa; todos os critérios e estados devem ser validados.

## 10. Definição de pronto

A reformulação está pronta quando todas as fases foram implementadas na ordem de dependência, os critérios de aceitação estão demonstrados, a suíte relevante passa, o projeto compila sem novos problemas e uma revisão independente confirma que o comportamento entregue corresponde a este documento.
