# Sistema de Gestão de Pedidos - PostgreSQL

Sistema completo de gestão de pedidos com controle de estoque, pagamentos e cancelamentos, implementado em PostgreSQL com procedures e triggers para automação de fluxos comerciais.

## 🚀 Funcionalidades

- **Criação de Pedidos**: Com validação de estoque em tempo real e interface JSON para itens
- **Controle de Pagamentos**: Processamento parcial e quitação com atualização automática de status
- **Cancelamento de Pedidos**: Reversão automática de estoque com lançamentos de entrada
- **Gestão de Estoque**: Movimentação precisa com origem documentada (VENDA, CANCELAMENTO, COMPRA)
- **Validações Automáticas**: Estoque, clientes, produtos e integridade de dados
- **Controle de Endereços**: Gerenciamento de endereços de entrega e cobrança
- **Categorias de Produtos**: Classificação e organização de produtos
- **Análise de Dados**: Views para análise de vendas, produtos mais vendidos e LTV de clientes

## 🛠️ Tecnologias

- PostgreSQL
- PL/pgSQL
- Procedures e Functions
- Triggers
- JSON para entrada de dados

## 📊 Estrutura de Tabelas

- `clientes` - Cadastro de clientes com informações completas
- `fornecedores` - Cadastro de fornecedores
- `produtos` - Cadastro de produtos com preços e categorias
- `categorias` - Classificação de produtos
- `enderecos` - Controle de endereços para entrega e cobrança
- `pedidos` - Cabeçalhos de pedidos com controle de endereços
- `pedido_itens` - Itens de cada pedido
- `estoque` - Movimentação de estoque com origem documentada
- `pagamentos` - Histórico de pagamentos
- `formas_pagamento` - Tipos de formas de pagamento
- `entradas` / `entrada_itens` - Controle de entradas de mercadorias

## 📥 Interface de Dados

### JSON para Itens do Pedido
```json
[
  {
    "produto_id": 1,
    "quantidade": 2,
    "preco_unit": 1899.99,
    "desconto": 0.00
  }
]
```

## 🚀 Como Executar

### 1. Configuração Inicial
Execute os scripts na seguinte ordem:
1. **tabelas.sql** - Criação das tabelas e índices
2. **triggers.sql** - Criação das triggers
3. **procedures.sql** - Criação das procedures e functions
4. **dados_iniciais.sql** - Inserção de dados básicos

### 2. Sequência de Execução
```sql
-- Criar pedido com endereço de entrega
CALL criar_pedido(1, '[{"produto_id": 1, "quantidade": 2, "preco_unit": 1899.99, "desconto": 0.00}]', 1);

-- Pagar pedido
CALL pagar_pedido(1, 3799.98, 'Cartão de Crédito');

-- Cancelar pedido
CALL cancelar_pedido(1);
```

## 🧪 Testes Implementados

- ✅ Criação de pedidos com múltiplos itens
- ✅ Validação de estoque em tempo real
- ✅ Controle de pagamentos parciais e totais
- ✅ Cancelamento com reversão de estoque
- ✅ Tratamento de erros e rollback automático
- ✅ Atualização automática de totais
- ✅ Controle de endereços de entrega
- ✅ Análise de dados com views

## 📋 Scripts de Teste

O repositório inclui script completo de testes validando todos os fluxos obrigatórios com saídas esperadas e verificação de resultados.

## 🏗️ Arquitetura

- Procedures encapsuladas para reutilização
- Triggers automatizadas para manutenção de integridade
- Mensagens de erro informativas
- Transações seguras com rollback automático
- Sem duplicação de lógica - reaproveitamento de funções
- Estrutura flexível para diferentes tipos de origem de estoque

## 📊 Views Disponíveis

- `vw_vendas_por_dia` - Análise de vendas por dia
- `vw_top_produtos` - Produtos mais vendidos
- `vw_ltv_clientes` - Valor de vida útil dos clientes

---

**Desenvolvido por Miguel Mantoan Castellani, Vitor Sauer e Kaique Geska**  
*Estudante de Inteligência Artificial e Data Science- Faculdade Donaduzzi*
