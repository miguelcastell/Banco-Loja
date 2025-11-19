# Sistema de Gestão de Pedidos - PostgreSQL

Sistema completo de gestão de pedidos com controle de estoque, pagamentos e cancelamentos, implementado em PostgreSQL com procedures e triggers para automação de fluxos comerciais.

## 🚀 Funcionalidades

- **Criação de Pedidos**: Com validação de estoque em tempo real e interface JSON para itens
- **Controle de Pagamentos**: Processamento parcial e quitação com atualização automática de status
- **Cancelamento de Pedidos**: Reversão automática de estoque com lançamentos de entrada
- **Gestão de Estoque**: Movimentação precisa com origem documentada (VENDA, CANCELAMENTO, ENTRADA_FORNECEDOR)
- **Validações Automáticas**: Estoque, clientes, produtos e integridade de dados

## 🛠️ Tecnologias

- PostgreSQL
- PL/pgSQL
- Procedures e Functions
- Triggers
- JSON para entrada de dados

## 📊 Estrutura de Tabelas

- `clientes` - Cadastro de clientes
- `produtos` - Cadastro de produtos com preços
- `pedidos` - Cabeçalhos de pedidos
- `pedido_itens` - Itens de cada pedido
- `estoque` - Movimentação de estoque (entradas e saídas)
- `pagamentos` - Histórico de pagamentos
- `fornecedor`, `entrada`, `entrada_itens` - Controle de entradas

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
-- Criar pedido
CALL criar_pedido(1, '[{"produto_id": 1, "quantidade": 2, "preco_unit": 1899.99, "desconto": 0.00}]');

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

## 📋 Scripts de Teste

O repositório inclui script completo de testes validando todos os fluxos obrigatórios com saídas esperadas e verificação de resultados.

## 🏗️ Arquitetura

- Procedures encapsuladas para reutilização
- Triggers automatizadas para manutenção de integridade
- Mensagens de erro informativas
- Transações seguras com rollback automático
- Sem duplicação de lógica - reaproveitamento de funções

---

**Desenvolvido por Miguel Mantoan Castellani, Vitor Sauer e Kaique Geska**  
*Estudantes de Inteligência Artificial e Ciências de Dados - Faculdade Donaduzzi*
