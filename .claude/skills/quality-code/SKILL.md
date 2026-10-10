---
name: quality-code
description: Padrão de qualidade de código Flutter/Dart deste projeto. Use sempre que for criar, alterar, refatorar ou revisar código Flutter (telas, widgets, estado, serviços, temas, formulários, testes), mesmo que o pedido não cite estas regras. Cobre arquitetura Feature-First, componentes modularizados, nomes em inglês, comentários em português, segurança (nunca confiar no cliente, nada exposto, sem segredos no app), nada hardcoded, regras de negócio, filtros e paginação no backend, form compartilhado entre create e edit, e tema central com contexto.
---

# quality-code

Siga estas regras em todo código Flutter deste projeto. Quando uma regra não puder ser cumprida (por exemplo, a feature ainda não tem backend), diga isso explicitamente ao usuário e explique a alternativa adotada. Não ignore a regra em silêncio.

Prioridade em caso de conflito: **segurança > correção > desempenho > legibilidade > conveniência**.

## 1. Arquitetura Feature-First

Organize as pastas por funcionalidade, não por tipo de arquivo.

```
lib/
  main.dart
  app/                      # MaterialApp, rotas, injeção de dependências
  core/                     # código compartilhado entre features
    theme/                  # tema central (ver seção 9)
    config/                 # env, constantes de ambiente, flavors
    network/                # cliente HTTP, interceptors, tratamento de erro
    security/               # armazenamento seguro, sessão
    widgets/                # componentes reutilizáveis entre features
    utils/
  features/
    <feature>/
      data/                 # datasources (API), DTOs, repositories (implementação)
      domain/               # entities, contratos de repository, use cases
      presentation/
        pages/              # telas
        widgets/            # componentes exclusivos da feature
        controllers/        # estado (ChangeNotifier/Cubit/Notifier etc.)
        forms/              # formulários compartilhados (ver seção 7)
```

- Uma feature não importa arquivos internos de outra. O que precisar ser compartilhado vai para `core/`.
- A camada `presentation` não fala com HTTP nem com storage diretamente: passa por repository/use case.
- Testes espelham a estrutura: `test/features/<feature>/...`.

## 2. Componentes modularizados

- Um widget por responsabilidade. Se um `build` passa de ~80–100 linhas ou repete um bloco, extraia um widget.
- Prefira **classes de widget** (`class PriceTag extends StatelessWidget`) a métodos `_buildX()`: elas permitem `const`, rebuild isolado e teste.
- Componentes recebem dados e callbacks por parâmetro. Não leem estado global escondido.
- Componente usado em mais de uma feature vai para `core/widgets/`. Componente de uma feature só fica em `features/<feature>/presentation/widgets/`.
- Use `const` sempre que possível.

## 3. Nomes e comentários

- **Código em inglês**: classes, funções, métodos, variáveis, parâmetros, arquivos, pastas, enums e chaves de JSON internas.
  - Arquivos e pastas em `snake_case`, classes em `PascalCase`, membros em `camelCase`.
  - Nomes descritivos: `fetchInvoices`, `isLoading`, `selectedUserId`. Nunca `data2`, `aux`, `tmp`.
- **Comentários em português**, só quando agregam: breves e objetivos, explicando o **porquê**, não o óbvio.
  - Bom: `// O backend devolve o total já com desconto; não recalcular aqui.`
  - Ruim: `// incrementa o contador`
- Texto exibido ao usuário pode estar em português, mas sempre vindo de arquivos de tradução/strings (ver seção 5), não solto no widget.

## 4. Nunca confiar no cliente

O app pode ser modificado, inspecionado e ter as requisições alteradas. Portanto:

- **Regras de negócio, cálculos com efeito real (preço, saldo, permissão, limite) e validação definitiva ficam no backend.**
- A validação no app serve só para **UX** (feedback rápido). O backend sempre revalida tudo.
- Nunca decidir permissão/autorização no app (por exemplo, `if (user.isAdmin)` liberando ação sensível). O app pode esconder botões, mas quem autoriza é o servidor.
- Nunca enviar ao backend valores que ele deveria calcular (total, preço, papel do usuário, `ownerId`).
- Trate toda resposta do backend como possivelmente incompleta: faça parse defensivo (DTO com `fromJson` tipado e tratamento de nulos).

## 5. Nada hardcoded

- **URLs, chaves públicas, flags, timeouts e ambientes**: em `core/config/` via `--dart-define`/`--dart-define-from-file` ou flavors. Nunca literais espalhados pelo código.
- **Cores, tamanhos de fonte, espaçamentos e raios**: só pelo tema central (seção 9). Nada de `Color(0xFF...)` ou `fontSize: 14` dentro de telas.
- **Textos de UI**: em arquivos de localização (`flutter_localizations` + `.arb`) ou num arquivo central de strings.
- **Números mágicos**: viram constantes nomeadas.
- **Dados de exemplo/seed**: nunca no código de produção. Ficam em fixtures de teste ou mocks de desenvolvimento.

## 6. Filtros, busca e paginação no backend

- Listas que podem crescer sempre usam **paginação do servidor** (cursor ou `page`/`limit`). Não baixe tudo para filtrar no app.
- Filtros, ordenação e busca são **parâmetros da requisição**. O app só envia os critérios e renderiza o resultado.
- Use scroll infinito ou paginação com estados claros: carregando, vazio, erro e "fim da lista".
- Na busca por texto, aplique debounce (~300–500 ms) e cancele requisições anteriores.
- Filtrar no cliente só é aceitável em listas pequenas e fixas (por exemplo, opções de um select), e isso deve ser intencional.

## 7. Form único para create e edit

Toda entidade editável tem **um arquivo de form** reutilizado pelas telas de criação e de edição:

```
features/<feature>/presentation/
  forms/<entity>_form.dart          # campos, validação de UX, layout
  pages/<entity>_create_page.dart   # importa <Entity>Form, sem valor inicial, chama create
  pages/<entity>_edit_page.dart     # importa <Entity>Form com valor inicial, chama update
```

- O form recebe `initialValue` (nulo na criação) e um callback `onSubmit(<Entity>Input)`. Ele não sabe se é create ou edit.
- As pages decidem título, texto do botão e qual use case chamar.
- Nunca duplicar campos ou validação entre create e edit.

## 8. Segurança

- **Nunca guardar tokens sensíveis no cliente** (refresh tokens de longa duração, chaves de API privadas, segredos de terceiros, credenciais).
  - Segredos de terceiros ficam no backend. O app chama o backend, nunca o serviço direto com a chave.
  - Sessão: prefira tokens de acesso de vida curta. Se algo precisar persistir no aparelho, use `flutter_secure_storage` (Keychain/Keystore), **nunca** `SharedPreferences`, arquivos ou banco local em texto puro.
  - Limpe tudo de sessão no logout e em erros 401 irrecuperáveis.
- **Nunca deixar nada exposto**:
  - Sem segredos em código, `.env` versionado, assets ou `--dart-define` (tudo isso vai no binário e pode ser extraído).
  - Sem `print`/`debugPrint` de dados pessoais, tokens ou respostas completas. Use logger que é desligado em release.
  - Mensagens de erro ao usuário são genéricas; detalhes técnicos só no log de desenvolvimento.
  - Builds de release com `--obfuscate --split-debug-info`.
  - Só HTTPS. Nada de `badCertificateCallback` liberando tudo.
  - Telas com dado sensível: considere bloquear screenshots (`FLAG_SECURE`) e ocultar o conteúdo no app switcher.
- Permissões do Android/iOS: peça só as necessárias.
- Valide e sanitize entradas antes de enviar (tamanho, formato), lembrando que o backend revalida.
- Dependências: prefira pacotes mantidos e verificados no pub.dev, e mantenha as versões atualizadas.

## 9. Tema central com contexto

- Um único ponto de tema em `core/theme/`:
  - `app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, `app_radius.dart` (tokens)
  - `app_theme.dart`: monta `ThemeData` claro/escuro a partir dos tokens
  - Tokens próprios expostos como `ThemeExtension` (preferido) ou `InheritedWidget`, acessados por contexto: `context.appColors`, `context.spacing`
- Widgets **nunca** usam cor, fonte ou espaçamento literal. Sempre `Theme.of(context)` ou a extensão de contexto.
- Troca de tema (claro/escuro/sistema) acontece em um só lugar (`MaterialApp.themeMode`).

## 10. Desempenho

- `const` em widgets e construtores sempre que possível.
- Rebuild mínimo: estado o mais perto possível de onde é usado. Use `ValueListenableBuilder`, `Selector`/`select` ou equivalentes para ouvir só o necessário.
- Listas com `ListView.builder`/`SliverList` (nunca `Column` com centenas de itens).
- Nada pesado no `build` (parse, ordenação, formatação de listas grandes). Calcule no controller ou faça memoização.
- Trabalho pesado (JSON grande, criptografia) em `Isolate.run`/`compute`.
- Imagens com tamanho adequado (`cacheWidth`/`cacheHeight`) e cache de rede.
- Sempre fazer `dispose` de controllers, streams, timers e animations.
- Verificar `mounted` antes de usar `context` depois de um `await`.

## 11. Clean code em Flutter (boas práticas gerais)

- Siga `flutter_lints` (ou `very_good_analysis`) e mantenha `flutter analyze` sem avisos.
- Formate com `dart format`.
- Funções pequenas, com uma responsabilidade e poucos parâmetros (agrupe em objeto quando passar de ~4).
- Imutabilidade: entities e estados `final`, com `copyWith`. Evite mutação compartilhada.
- Tipagem explícita em APIs públicas. Evite `dynamic`. Use `sealed class` para estados (`Loading`, `Success`, `Failure`).
- Erros tratados em camadas: o datasource converte exceções em falhas de domínio, e a UI mostra estado de erro (nunca um `catch` vazio).
- Injeção de dependências (construtor, `get_it`, Riverpod etc.) para tudo que acessa rede ou storage, o que permite testar com fakes.
- Sem código morto, sem `TODO` sem responsável e sem imports não usados.
- Acessibilidade: `Semantics`/`tooltip` em botões só com ícone, contraste adequado e alvos de toque com ≥ 48 dp.
- Testes: unitários para use cases/controllers, de widget para componentes e telas principais. Todo bug corrigido ganha um teste.

## Checklist antes de entregar

- [ ] Arquivos na estrutura Feature-First correta
- [ ] Componentes extraídos e reutilizáveis, com `const` onde der
- [ ] Nomes em inglês e comentários (se houver) em português, breves
- [ ] Nenhuma cor, texto, URL ou número mágico hardcoded
- [ ] Regras de negócio e validação definitiva no backend (a do app é só UX)
- [ ] Filtros, busca e paginação feitos pelo backend
- [ ] Create e edit usam o mesmo `<entity>_form.dart`
- [ ] Nenhum segredo ou token sensível no app, nada logado ou exposto
- [ ] Estilos vindos do tema central via contexto
- [ ] `flutter analyze` limpo, `dart format` aplicado e testes passando
