# Relatório de Desenvolvimento

Este documento descreve o desenvolvimento do projeto "Order Processing", uma aplicação em OCaml para processar pedidos, calcular receitas e impostos, e gerar relatórios a partir de arquivos CSV. O objetivo é fornecer um roteiro claro para reconstrução futura, detalhando as etapas, decisões de design e ferramentas utilizadas.

## 1. Introdução
- **Objetivo do Projeto**: Criar uma aplicação que lê dados de pedidos e itens de CSV, calcula resumos de receita e impostos, e gera relatórios parametrizáveis por status e origem, com uma saída adicional de médias por mês/ano.
- **Requisitos Iniciais**:
  - Processamento de pedidos com filtragem por status (`Pending`, `Complete`, `Cancelled`) e origem (`Paraphysical`, `Online`).
  - Cálculo de receita (`quantidade * preço`) e impostos (`receita * percentual de imposto`).
  - Saída em CSV e uma análise adicional de médias mensais.
- **Uso de IA Generativa**: Este projeto foi desenvolvido com auxílio da IA generativa Grok, para suporte na escrita de código, depuração e sugestões de design.

## 2. Estrutura do Projeto
- **Diretórios e Arquivos**:
  - `lib/order_processing.ml`: Contém a lógica pura (tipos e funções de processamento).
  - `bin/main.ml`: Contém a lógica impura (leitura/escrita de arquivos e execução principal).
  - `data/order.csv`: Dados de pedidos (exemplo: `id,client_id,order_date,status,origin`).
  - `data/order_item.csv`: Dados de itens (exemplo: `order_id,product_id,quantity,price,tax`).
  - `dune-project`, `bin/dune`, `lib/dune`: Configurações do Dune para compilação.
- **Dependências**:
  - OCaml (linguagem principal).
  - Dune (ferramenta de build).
  - Biblioteca `csv` (leitura/escrita de arquivos CSV).

## 3. Etapas de Construção

### 3.1 Configuração do Ambiente
- **Instalação de Ferramentas**:
  - Iniciar OPAM: `opam init`.
  - Instalar Dune: `opam install dune`.
  - Instalar biblioteca `csv`: `opam install csv`.
- **Estrutura Inicial**:
  - Criar `dune-project` com `(lang dune 3.17)` e dependências (`ocaml`, `dune`, `csv`).
  - Configurar `lib/dune` como `(library (name order_processing))`.
  - Configurar `bin/dune` como `(executable (public_name order_processing) (name main) (libraries order_processing csv))`.

### 3.2 Desenvolvimento da Lógica Principal
- **Definição dos Tipos** (`lib/order_processing.ml`):
  - `order_status` e `order_origin` como tipos variantes.
  - Records `order`, `order_item`, e `order_summary` para representar os dados.
- **Funções de Conversão**:
  - `status_of_string` e `origin_of_string`: Conversão de strings para tipos variantes.
  - `order_of_list` e `order_item_of_list`: Parsing de listas de strings para records.
- **Cálculos**:
  - `calculate_item_revenue`: Multiplica quantidade por preço.
  - `calculate_item_tax`: Multiplica receita por percentual de imposto.
- **Processamento**:
  - `group_items_by_order`: Agrupa itens por pedido.
  - `summarize_order`: Calcula total de receita e impostos por pedido.
  - `process_orders`: Filtra pedidos por status e origem e gera resumos.

### 3.3 Leitura e Escrita de Dados
- **Leitura de CSV** (`bin/main.ml`):
  - Função `read_csv`: Usa `Csv.load` e ignora o cabeçalho com pattern matching.
- **Escrita de CSV** (`bin/main.ml`):
  - Função `write_csv`: Gera `output2.csv` com resumos de pedidos.

### 3.4 Parametrização
- **Argumentos de Linha de Comando** (`bin/main.ml`):
  - Uso do módulo `Arg` para aceitar `--status` e `--origin`.
  - Valores padrão: `Complete` e `O` (Online).
  - Conversão para tipos com `status_of_string` e `origin_of_string`.
- **Execução**:
  - Comando: `dune exec ./bin/main.exe -- --status Complete --origin O`.

### 3.5 Saída Adicional: Média por Mês/Ano
- **Lógica Pura** (`lib/order_processing.ml`):
  - `extract_year_month`: Extrai ano e mês de `order_date`.
  - `calculate_monthly_avg`: Calcula médias de receita e impostos por mês/ano, retornando uma lista de tuplas.
- **Escrita Impura** (`bin/main.ml`):
  - `write_monthly_avg_csv`: Gera `monthly_avg.csv` com as médias.
- **Integração**:
  - Chamada em `main` para processar os resumos e gravar o novo CSV.

## 4. Depuração e Ajustes
- **Erros Encontrados**:
  - Tipos incompatíveis no início (ex.: `order_summary` vs `order_item`), resolvidos com anotações explícitas.
  - Cabeçalhos de CSV processados como dados, corrigidos com `match _ :: data`.
  - Argumentos de linha de comando não reconhecidos pelo Dune, resolvidos com `--`.
- **Ajustes**:
  - Separação rigorosa entre funções puras (`lib/`) e impuras (`bin/`).

## 5. Uso de IA Generativa
- **Ferramenta Utilizada**: Grok, criado pela xAI.
- **Contribuições da IA**:
  - Geração inicial de código para tipos, funções e estrutura do projeto.
  - Sugestões de correções para erros de compilação e lógica.
  - Criação de docstrings para documentação.
  - Propostas de design, como parametrização via argumentos de linha de comando e cálculo de médias.
  - Documentação e ajustes de escrita.
- **Interação**: O desenvolvimento foi iterativo, com perguntas específicas ao Grok para cada etapa, refinando o código com base nas respostas.

## 6. Como Executar
- **Compilação**:
  ```bash
  dune build

    ```

- **Execução**:
    ```bash
    dune exec ./bin/main.exe -- --status Complete --origin O
    ```

- **Saídas**:
    - `output2.csv`: Resumo de pedidos filtrados.
    - `monthly_avg.csv`: Médias mensais de receita e impostos.

## 7. Conclusão
Este projeto demonstrou a eficácia do uso de OCaml para processamento de dados e a utilidade da IA generativa na aceleração do desenvolvimento. A estrutura modular e a separação entre lógica pura e impura facilitaram a manutenção e a extensão futura do código.
