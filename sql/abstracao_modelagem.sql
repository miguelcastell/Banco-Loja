-- Entrega 01 - Abstração e Modelagem do Banco de Dados

-- CREATE SCHEMA public;

CREATE TABLE clientes (
    cliente_id BIGSERIAL PRIMARY KEY,
    cpf CHAR(20) UNIQUE,
    nome VARCHAR(45) NOT NULL,
    email VARCHAR(45) UNIQUE NOT NULL,
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW()
);
CREATE TABLE fornecedor (
    fornecedor_id BIGSERIAL PRIMARY KEY,
    nome_fornecedor VARCHAR(45) NOT NULL,
    cnpj VARCHAR(18) UNIQUE,
    telefone VARCHAR(45),
    email VARCHAR(45),
    ie VARCHAR(18),
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW()
);
CREATE TABLE produtos (
    produto_id BIGSERIAL PRIMARY KEY,
    nome VARCHAR(45) NOT NULL,
    sku VARCHAR(45) UNIQUE NOT NULL,
    preco_unitario NUMERIC(12,2) NOT NULL CHECK (preco_unitario >= 0),
    ativo BOOLEAN DEFAULT TRUE,
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW()
);
CREATE TABLE pedidos (
    pedido_id BIGSERIAL PRIMARY KEY,
    cliente_id BIGINT NOT NULL REFERENCES clientes(cliente_id) ON DELETE RESTRICT,
    data_pedido DATE DEFAULT CURRENT_DATE,
    numero INT,
    status VARCHAR(20) NOT NULL DEFAULT 'ABERTO'
        CHECK (status IN ('ABERTO', 'PAGO', 'CANCELADO')),
    total_bruto NUMERIC(14,2) DEFAULT 0 CHECK (total_bruto >= 0),
    desconto NUMERIC(14,2) DEFAULT 0 CHECK (desconto >= 0),
    total_liq NUMERIC(14,2) DEFAULT 0 CHECK (total_liq >= 0),
    pedidocol VARCHAR(45),
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW()
);
CREATE TABLE pedido_itens (
    pedido_item_id BIGSERIAL PRIMARY KEY,
    pedido_id BIGINT NOT NULL REFERENCES pedidos(pedido_id) ON DELETE CASCADE,
    produto_id BIGINT NOT NULL REFERENCES produtos(produto_id) ON DELETE RESTRICT,
    pedido_has_produtocol VARCHAR(45),
    quantidade NUMERIC(12,2) NOT NULL CHECK (quantidade > 0),
    preco_unit NUMERIC(14,2) NOT NULL CHECK (preco_unit >= 0),
    desconto NUMERIC(14,2) DEFAULT 0 CHECK (desconto >= 0),
    total_liq NUMERIC(14,2) DEFAULT 0 CHECK (total_liq >= 0),
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW()
);
CREATE TABLE entrada (
    entrada_id BIGSERIAL PRIMARY KEY,
    fornecedor_id BIGINT NOT NULL REFERENCES fornecedor(fornecedor_id) ON DELETE RESTRICT,
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW()
);
CREATE TABLE entrada_itens (
    entrada_item_id BIGSERIAL PRIMARY KEY,
    entrada_id BIGINT NOT NULL REFERENCES entrada(entrada_id) ON DELETE CASCADE,
    produto_id BIGINT NOT NULL REFERENCES produtos(produto_id) ON DELETE RESTRICT,
    data DATE DEFAULT CURRENT_DATE,
    lote VARCHAR(45),
    quantidade VARCHAR(45),
    status_entrada VARCHAR(45),
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW()
);
CREATE TABLE estoque (
    estoque_id BIGSERIAL PRIMARY KEY,
    produto_id BIGINT REFERENCES produtos(produto_id) ON DELETE RESTRICT,
    tipo VARCHAR(255),
    quantidade INT NOT NULL CHECK (quantidade > 0),
    origem_tipo VARCHAR(255),
    data_movimentacao TIMESTAMP DEFAULT NOW(),
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW(),
    entrada_id BIGINT REFERENCES entrada(entrada_id) ON DELETE RESTRICT,
    pedido_id BIGINT REFERENCES pedidos(pedido_id) ON DELETE RESTRICT
);
CREATE TABLE pagamentos (
    pagamentos_id BIGSERIAL PRIMARY KEY,
    pedido_id BIGINT NOT NULL REFERENCES pedidos(pedido_id) ON DELETE CASCADE,
    cliente_id BIGINT NOT NULL REFERENCES clientes(cliente_id) ON DELETE RESTRICT,
    valor_pago NUMERIC(10,2) NOT NULL CHECK (valor_pago >= 0),
    data_pagamento DATE DEFAULT CURRENT_DATE,
    forma_pagamento VARCHAR(45),
    status_pagamento VARCHAR(45) DEFAULT 'PENDENTE',
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_pedidos_cliente ON pedidos (cliente_id);
CREATE INDEX idx_itens_pedido ON pedido_itens (pedido_id);
CREATE INDEX idx_itens_produto ON pedido_itens (produto_id);
CREATE INDEX idx_estoque_entrada ON estoque (entrada_id);
CREATE INDEX idx_estoque_pedido ON estoque (pedido_id);
CREATE INDEX idx_pagamentos_pedido ON pagamentos (pedido_id);
CREATE INDEX idx_pagamentos_cliente ON pagamentos (cliente_id);
CREATE INDEX idx_entrada_fornecedor ON entrada (fornecedor_id);
CREATE INDEX idx_entrada_itens_entrada ON entrada_itens (entrada_id);
CREATE INDEX idx_entrada_itens_produto ON entrada_itens (produto_id);

INSERT INTO clientes (cliente_id, cpf, nome, email, criado_em, atualizado_em) VALUES
(1, '11122233344', 'João Silva', 'joao.silva@email.com', NOW(), NOW()),
(2, '22233344455', 'Maria Santos', 'maria.santos@email.com', NOW(), NOW()),
(3, '33344455566', 'Pedro Oliveira', 'pedro.oliveira@email.com', NOW(), NOW()),
(4, '44455566677', 'Ana Costa', 'ana.costa@email.com', NOW(), NOW()),
(5, '55566677788', 'Carlos Pereira', 'carlos.pereira@email.com', NOW(), NOW()),
(6, '66677788899', 'Fernanda Lima', 'fernanda.lima@email.com', NOW(), NOW());

INSERT INTO fornecedor (fornecedor_id, nome_fornecedor, cnpj, telefone, email, ie, criado_em, atualizado_em) VALUES
(1, 'Fornecedor Alpha', '11.111.111/0001-11', '11987654321', 'contato@alpha.com', '123456789', NOW(), NOW()),
(2, 'Fornecedor Beta', '22.222.222/0002-22', '21998765432', 'contato@beta.com', '987654321', NOW(), NOW());

INSERT INTO produtos (produto_id, nome, sku, preco_unitario, ativo, criado_em, atualizado_em) VALUES
(1, 'Smartphone X', 'SMARTX001', 1899.99, TRUE, NOW(), NOW()),
(2, 'Notebook Pro 15', 'NOTEPRO15', 4500.00, TRUE, NOW(), NOW()),
(3, 'Fone Bluetooth', 'FONEBT005', 129.50, TRUE, NOW(), NOW()),
(4, 'Mouse Gamer RGB', 'MOUSEGRGB', 89.90, TRUE, NOW(), NOW()),
(5, 'Teclado Mecânico', 'TECLADOMEC', 250.00, TRUE, NOW(), NOW()),
(6, 'Monitor 27 Polegadas', 'MONITOR27', 1199.00, TRUE, NOW(), NOW()),
(7, 'Webcam Full HD', 'WEBCAMFHD', 150.00, TRUE, NOW(), NOW()),
(8, 'SSD 500GB', 'SSD500GB', 350.00, TRUE, NOW(), NOW()),
(9, 'Cabo HDMI 2m', 'CABOHDMI02', 45.00, TRUE, NOW(), NOW());

INSERT INTO entrada (entrada_id, fornecedor_id, criado_em, atualizado_em) VALUES
(1, 1, NOW(), NOW()),
(2, 2, NOW(), NOW());

INSERT INTO entrada_itens (entrada_item_id, entrada_id, produto_id, data, lote, quantidade, status_entrada, criado_em, atualizado_em) VALUES
(1, 1, 1, CURRENT_DATE, 'LOTE001', '50', 'RECEBIDO', NOW(), NOW()),
(2, 1, 3, CURRENT_DATE, 'LOTE002', '100', 'RECEBIDO', NOW(), NOW()),
(3, 2, 2, CURRENT_DATE, 'LOTE003', '20', 'RECEBIDO', NOW(), NOW()),
(4, 2, 4, CURRENT_DATE, 'LOTE004', '75', 'RECEBIDO', NOW(), NOW());

INSERT INTO pedidos (
    pedido_id, cliente_id, data_pedido, numero, status,
    total_bruto, desconto, total_liq, pedidocol, criado_em, atualizado_em
) VALUES
(1, 1, CURRENT_DATE, 1, 'ABERTO', 0.00, 0.00, 0.00, NULL, NOW(), NOW()),
(2, 2, CURRENT_DATE, 2, 'PAGO', 0.00, 0.00, 0.00, NULL, NOW(), NOW()),
(3, 3, CURRENT_DATE, 3, 'CANCELADO', 0.00, 0.00, 0.00, NULL, NOW(), NOW()),
(4, 4, CURRENT_DATE, 4, 'PAGO', 0.00, 0.00, 0.00, NULL, NOW(), NOW());


INSERT INTO pedido_itens (
    pedido_item_id, pedido_id, produto_id, pedido_has_produtocol,
    quantidade, preco_unit, desconto, total_liq, criado_em, atualizado_em
) VALUES
(1, 1, 1, NULL, 1, 1899.99, 0.00, 1899.99, NOW(), NOW()),
(2, 1, 3, NULL, 2, 129.50, 0.00, 259.00, NOW(), NOW()),
(3, 2, 2, NULL, 1, 4500.00, 0.00, 4500.00, NOW(), NOW()),
(4, 2, 4, NULL, 1, 89.90, 0.00, 89.90, NOW(), NOW()),
(5, 3, 5, NULL, 1, 250.00, 0.00, 250.00, NOW(), NOW()),
(6, 3, 6, NULL, 1, 1199.00, 0.00, 1199.00, NOW(), NOW()),
(7, 4, 8, NULL, 1, 350.00, 0.00, 350.00, NOW(), NOW()),
(8, 4, 7, NULL, 2, 150.00, 0.00, 300.00, NOW(), NOW());

INSERT INTO estoque (
    estoque_id, produto_id, tipo, quantidade, origem_tipo,
    data_movimentacao, criado_em, atualizado_em, entrada_id, pedido_id
) VALUES
(1, 1, 'ENTRADA', 50, 'Compra Inicial Fornecedor Alpha', NOW(), NOW(), NOW(), 1, NULL),
(2, 2, 'ENTRADA', 20, 'Compra Inicial Fornecedor Beta', NOW(), NOW(), NOW(), 2, NULL),
(3, 3, 'ENTRADA', 100, 'Compra Inicial Fornecedor Alpha', NOW(), NOW(), NOW(), 1, NULL),
(4, 4, 'ENTRADA', 75, 'Compra Inicial Fornecedor Beta', NOW(), NOW(), NOW(), 2, NULL);

INSERT INTO pagamentos (
    pagamentos_id, pedido_id, cliente_id,
    valor_pago, data_pagamento, forma_pagamento, status_pagamento,
    criado_em, atualizado_em
) VALUES
(1, 2, 2, 4589.90, CURRENT_DATE, 'Cartão de Crédito', 'APROVADO', NOW(), NOW()),
(2, 4, 4, 350.00, CURRENT_DATE, 'PIX', 'APROVADO', NOW(), NOW()),
(3, 4, 4, 300.00, CURRENT_DATE, 'Boleto', 'APROVADO', NOW(), NOW());