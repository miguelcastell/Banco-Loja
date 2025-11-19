# Sistema de Gestão de Pedidos - Banco de Dados

## 🎯 Objetivo
Encapsular o fluxo de pedidos em rotinas reusáveis e seguras, com validações de estoque, controle de pagamentos e cancelamentos com reversão de estoque.

## 🛠️ Estrutura

### Tabelas Principais
- `clientes` - Cadastro de clientes
- `produtos` - Cadastro de produtos com preços
- `pedidos` - Cabeçalhos de pedidos
- `pedido_itens` - Itens de cada pedido
- `estoque` - Movimentação de estoque (entradas e saídas)
- `pagamentos` - Histórico de pagamentos
- `fornecedor` - Cadastro de fornecedores
- `entrada` / `entrada_itens` - Entrada de mercadorias

### Procedures/Functions Implementadas
- `criar_pedido(cliente_id, itens)` - Criação de pedidos com validação de estoque
- `pagar_pedido(pedido_id, valor, metodo)` - Processamento de pagamentos
- `cancelar_pedido(pedido_id)` - Cancelamento com reversão de estoque
- `recalcular_totais_pedido(pedido_id)` - Recálculo de totais do pedido

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
Execute na seguinte ordem:
1. Script de criação das tabelas
2. Script de triggers
3. Script de procedures/functions
4. Script de dados iniciais (clientes, produtos, entradas)

### 2. Testes Recomendados
Execute os scripts de teste sequencialmente para verificar todas as funcionalidades.

### 3. Sequência de Execução
```sql
-- Criar pedido
CALL criar_pedido(1, '[{"produto_id": 1, "quantidade": 2, "preco_unit": 1899.99, "desconto": 0.00}]');

-- Pagar pedido
CALL pagar_pedido(1, 3799.98, 'Cartão de Crédito');

-- Cancelar pedido
CALL cancelar_pedido(1);
```

## ✅ Funcionalidades Testadas
- ✅ Criação de pedidos com múltiplos itens
- ✅ Validação de estoque em tempo real
- ✅ Controle de pagamentos parciais e totais
- ✅ Cancelamento com reversão de estoque
- ✅ Tratamento de erros e rollback automático
- ✅ Atualização automática de totais
