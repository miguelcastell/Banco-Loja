-- Entrega 01 - Abstração e Modelagem do Banco de Dados - Versão Expandida

CREATE SCHEMA public;

CREATE TABLE clientes (
    cliente_id BIGSERIAL PRIMARY KEY,
    cpf CHAR(20) UNIQUE,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefone VARCHAR(20),
    data_nascimento DATE,
    sexo CHAR(1) CHECK (sexo IN ('M', 'F')),
    status_cliente VARCHAR(20) DEFAULT 'ATIVO' CHECK (status_cliente IN ('ATIVO', 'INATIVO', 'BLOQUEADO')),
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW()
);

CREATE TABLE fornecedores (
    fornecedor_id BIGSERIAL PRIMARY KEY,
    cnpj VARCHAR(20) UNIQUE,
    razao_social VARCHAR(100) NOT NULL,
    nome_fantasia VARCHAR(100),
    email VARCHAR(100),
    telefone VARCHAR(20),
    ie VARCHAR(20),
    status_fornecedor VARCHAR(20) DEFAULT 'ATIVO' CHECK (status_fornecedor IN ('ATIVO', 'INATIVO')),
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW()
);

CREATE TABLE categorias (
    categoria_id BIGSERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN DEFAULT TRUE,
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW()
);

CREATE TABLE produtos (
    produto_id BIGSERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    sku VARCHAR(50) UNIQUE NOT NULL,
    categoria_id BIGINT REFERENCES categorias(categoria_id) ON DELETE SET NULL,
    preco_unitario NUMERIC(12,2) NOT NULL CHECK (preco_unitario >= 0),
    preco_custo NUMERIC(12,2) CHECK (preco_custo >= 0),
    peso DECIMAL(8,3),
    dimensoes VARCHAR(50), -- Ex: "10x5x3 cm"
    ativo BOOLEAN DEFAULT TRUE,
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW()
);

CREATE TABLE enderecos (
    endereco_id BIGSERIAL PRIMARY KEY,
    logradouro VARCHAR(255) NOT NULL,
    numero VARCHAR(10),
    complemento VARCHAR(100),
    bairro VARCHAR(100),
    cidade VARCHAR(100),
    estado CHAR(2),
    cep VARCHAR(10),
    tipo_endereco VARCHAR(20) DEFAULT 'ENTREGA' CHECK (tipo_endereco IN ('ENTREGA', 'COBRANCA', 'RESIDENCIAL', 'COMERCIAL')),
    cliente_id BIGINT REFERENCES clientes(cliente_id) ON DELETE CASCADE,
    fornecedor_id BIGINT REFERENCES fornecedores(fornecedor_id) ON DELETE CASCADE,
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW(),
    CHECK (cliente_id IS NOT NULL OR fornecedor_id IS NOT NULL)
);

CREATE TABLE pedidos (
    pedido_id BIGSERIAL PRIMARY KEY,
    cliente_id BIGINT NOT NULL REFERENCES clientes(cliente_id) ON DELETE RESTRICT,
    endereco_entrega_id BIGINT REFERENCES enderecos(endereco_id) ON DELETE SET NULL,
    endereco_cobranca_id BIGINT REFERENCES enderecos(endereco_id) ON DELETE SET NULL,
    data_pedido DATE DEFAULT CURRENT_DATE,
    data_entrega_prevista DATE,
    data_entrega DATE,
    numero VARCHAR(20) UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'ABERTO'
        CHECK (status IN ('ABERTO', 'CONFIRMADO', 'EM_PREPARACAO', 'ENVIADO', 'ENTREGUE', 'PAGO', 'CANCELADO')),
    total_bruto NUMERIC(14,2) DEFAULT 0 CHECK (total_bruto >= 0),
    desconto NUMERIC(14,2) DEFAULT 0 CHECK (desconto >= 0),
    frete NUMERIC(14,2) DEFAULT 0 CHECK (frete >= 0),
    total_liq NUMERIC(14,2) DEFAULT 0 CHECK (total_liq >= 0),
    observacoes TEXT,
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW()
);

CREATE TABLE pedido_itens (
    pedido_item_id BIGSERIAL PRIMARY KEY,
    pedido_id BIGINT NOT NULL REFERENCES pedidos(pedido_id) ON DELETE CASCADE,
    produto_id BIGINT NOT NULL REFERENCES produtos(produto_id) ON DELETE RESTRICT,
    quantidade NUMERIC(12,2) NOT NULL CHECK (quantidade > 0),
    preco_unit NUMERIC(14,2) NOT NULL CHECK (preco_unit >= 0),
    desconto NUMERIC(14,2) DEFAULT 0 CHECK (desconto >= 0),
    total_liq NUMERIC(14,2) DEFAULT 0 CHECK (total_liq >= 0),
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW()
);

CREATE TABLE entradas (
    entrada_id BIGSERIAL PRIMARY KEY,
    fornecedor_id BIGINT NOT NULL REFERENCES fornecedores(fornecedor_id) ON DELETE RESTRICT,
    nota_fiscal VARCHAR(20),
    data_entrada DATE DEFAULT CURRENT_DATE,
    total_entrada NUMERIC(14,2) DEFAULT 0,
    status_entrada VARCHAR(20) DEFAULT 'PENDENTE' CHECK (status_entrada IN ('PENDENTE', 'RECEBIDO', 'CONFERIDO', 'FINALIZADO')),
    observacoes TEXT,
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW()
);

CREATE TABLE entrada_itens (
    entrada_item_id BIGSERIAL PRIMARY KEY,
    entrada_id BIGINT NOT NULL REFERENCES entradas(entrada_id) ON DELETE CASCADE,
    produto_id BIGINT NOT NULL REFERENCES produtos(produto_id) ON DELETE RESTRICT,
    quantidade INT NOT NULL CHECK (quantidade > 0),
    preco_unitario NUMERIC(14,2) NOT NULL CHECK (preco_unitario >= 0),
    lote VARCHAR(50),
    data_validade DATE,
    status_item VARCHAR(20) DEFAULT 'PENDENTE' CHECK (status_item IN ('PENDENTE', 'RECEBIDO', 'CONFERIDO')),
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW()
);

CREATE TABLE estoque (
    estoque_id BIGSERIAL PRIMARY KEY,
    produto_id BIGINT REFERENCES produtos(produto_id) ON DELETE RESTRICT,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('ENTRADA', 'SAIDA', 'AJUSTE', 'TRANSFERENCIA')),
    quantidade INT NOT NULL CHECK (quantidade >= 0),
    origem_tipo VARCHAR(50),
    origem_id BIGINT,
    data_movimentacao TIMESTAMP DEFAULT NOW(),
    observacoes TEXT,
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW()
);

CREATE TABLE pagamentos (
    pagamento_id BIGSERIAL PRIMARY KEY,
    pedido_id BIGINT NOT NULL REFERENCES pedidos(pedido_id) ON DELETE CASCADE,
    cliente_id BIGINT NOT NULL REFERENCES clientes(cliente_id) ON DELETE RESTRICT,
    valor_pago NUMERIC(14,2) NOT NULL CHECK (valor_pago >= 0),
    data_pagamento DATE DEFAULT CURRENT_DATE,
    forma_pagamento VARCHAR(50) NOT NULL,
    meio_pagamento VARCHAR(50),
    status_pagamento VARCHAR(20) DEFAULT 'PENDENTE' CHECK (status_pagamento IN ('PENDENTE', 'PROCESSANDO', 'APROVADO', 'REPROVADO', 'ESTORNADO')),
    numero_parcelas INT DEFAULT 1,
    observacoes TEXT,
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW()
);

CREATE TABLE formas_pagamento (
    forma_pagamento_id BIGSERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('A_VISTA', 'PARCELADO', 'PIX', 'BOLETO', 'CARTAO')),
    ativo BOOLEAN DEFAULT TRUE,
    criado_em TIMESTAMP DEFAULT NOW(),
    atualizado_em TIMESTAMP DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_clientes_cpf ON clientes (cpf);
CREATE INDEX idx_clientes_email ON clientes (email);
CREATE INDEX idx_fornecedores_cnpj ON fornecedores (cnpj);
CREATE INDEX idx_produtos_sku ON produtos (sku);
CREATE INDEX idx_produtos_categoria ON produtos (categoria_id);
CREATE INDEX idx_pedidos_cliente ON pedidos (cliente_id);
CREATE INDEX idx_pedidos_numero ON pedidos (numero);
CREATE INDEX idx_pedidos_status ON pedidos (status);
CREATE INDEX idx_pedido_itens_pedido ON pedido_itens (pedido_id);
CREATE INDEX idx_pedido_itens_produto ON pedido_itens (produto_id);
CREATE INDEX idx_estoque_produto ON estoque (produto_id);
CREATE INDEX idx_estoque_tipo ON estoque (tipo);
CREATE INDEX idx_pagamentos_pedido ON pagamentos (pedido_id);
CREATE INDEX idx_pagamentos_cliente ON pagamentos (cliente_id);
CREATE INDEX idx_entradas_fornecedor ON entradas (fornecedor_id);
CREATE INDEX idx_entrada_itens_entrada ON entrada_itens (entrada_id);
CREATE INDEX idx_entrada_itens_produto ON entrada_itens (produto_id);

INSERT INTO categorias (nome, descricao) VALUES
('Eletrônicos', 'Produtos eletrônicos e gadgets'),
('Informática', 'Computadores, periféricos e acessórios'),
('Áudio e Vídeo', 'Sistemas de áudio e equipamentos de vídeo');

INSERT INTO clientes (cliente_id, cpf, nome, email, telefone, data_nascimento, sexo) VALUES
(1, '11122233344', 'João Silva', 'joao.silva@email.com', '11987654321', '1990-05-15', 'M'),
(2, '22233344455', 'Maria Santos', 'maria.santos@email.com', '21998765432', '1985-08-22', 'F'),
(3, '33344455566', 'Pedro Oliveira', 'pedro.oliveira@email.com', '31976543210', '1992-12-10', 'M'),
(4, '44455566677', 'Ana Costa', 'ana.costa@email.com', '41965432109', '1988-03-07', 'F'),
(5, '55566677788', 'Carlos Pereira', 'carlos.pereira@email.com', '51954321098', '1995-11-18', 'M'),
(6, '66677788899', 'Fernanda Lima', 'fernanda.lima@email.com', '61943210987', '1991-07-25', 'F');

INSERT INTO fornecedores (fornecedor_id, cnpj, razao_social, nome_fantasia, email, telefone, ie) VALUES
(1, '11111111000111', 'Fornecedor Alpha Ltda', 'Fornecedor Alpha', 'contato@alpha.com', '11987654321', '123456789'),
(2, '22222222000222', 'Fornecedor Beta S/A', 'Fornecedor Beta', 'contato@beta.com', '21998765432', '987654321');

INSERT INTO produtos (produto_id, nome, descricao, sku, categoria_id, preco_unitario, preco_custo, peso, dimensoes) VALUES
(1, 'Smartphone X', 'Smartphone de última geração', 'SMARTX001', 1, 1899.99, 1500.00, 0.200, '15x7x0.8 cm'),
(2, 'Notebook Pro 15', 'Notebook para profissionais', 'NOTEPRO15', 2, 4500.00, 3800.00, 2.100, '35x25x2 cm'),
(3, 'Fone Bluetooth', 'Fone sem fio com cancelamento de ruído', 'FONEBT005', 1, 129.50, 80.00, 0.150, '18x15x8 cm'),
(4, 'Mouse Gamer RGB', 'Mouse gamer com iluminação RGB', 'MOUSEGRGB', 2, 89.90, 45.00, 0.100, '12x8x4 cm'),
(5, 'Teclado Mecânico', 'Teclado mecânico com switches blue', 'TECLADOMEC', 2, 250.00, 120.00, 0.800, '45x15x3 cm'),
(6, 'Monitor 27 Polegadas', 'Monitor Full HD 27 polegadas', 'MONITOR27', 2, 1199.00, 900.00, 5.500, '60x40x20 cm'),
(7, 'Webcam Full HD', 'Webcam 1080p com microfone', 'WEBCAMFHD', 2, 150.00, 85.00, 0.300, '10x10x8 cm'),
(8, 'SSD 500GB', 'SSD NVMe PCIe M.2 500GB', 'SSD500GB', 2, 350.00, 220.00, 0.050, '8x3x0.5 cm'),
(9, 'Cabo HDMI 2m', 'Cabo HDMI 2.0 de 2 metros', 'CABOHDMI02', 2, 45.00, 15.00, 0.080, '200x2x1 cm');

INSERT INTO enderecos (endereco_id, logradouro, numero, bairro, cidade, estado, cep, tipo_endereco, cliente_id) VALUES
(1, 'Rua das Flores', '123', 'Centro', 'São Paulo', 'SP', '01001000', 'ENTREGA', 1),
(2, 'Av. Paulista', '1000', 'Bela Vista', 'São Paulo', 'SP', '01310940', 'ENTREGA', 2),
(3, 'Rua Oscar Freire', '500', 'Cerqueira César', 'São Paulo', 'SP', '01426000', 'ENTREGA', 3),
(4, 'Rua Augusta', '2000', 'Consolação', 'São Paulo', 'SP', '01305000', 'ENTREGA', 4);

INSERT INTO entradas (entrada_id, fornecedor_id, nota_fiscal, data_entrada, status_entrada) VALUES
(1, 1, 'NF12345', CURRENT_DATE, 'RECEBIDO'),
(2, 2, 'NF67890', CURRENT_DATE, 'RECEBIDO');

INSERT INTO entrada_itens (entrada_item_id, entrada_id, produto_id, quantidade, preco_unitario, lote, status_item) VALUES
(1, 1, 1, 50, 1500.00, 'LOTE001', 'CONFERIDO'),
(2, 1, 3, 100, 80.00, 'LOTE002', 'CONFERIDO'),
(3, 2, 2, 20, 3800.00, 'LOTE003', 'CONFERIDO'),
(4, 2, 4, 75, 45.00, 'LOTE004', 'CONFERIDO');

INSERT INTO estoque (estoque_id, produto_id, tipo, quantidade, origem_tipo, origem_id, observacoes) VALUES
(1, 1, 'ENTRADA', 50, 'COMPRA', 1, 'Entrada inicial fornecedor Alpha'),
(2, 3, 'ENTRADA', 100, 'COMPRA', 1, 'Entrada inicial fornecedor Alpha'),
(3, 2, 'ENTRADA', 20, 'COMPRA', 2, 'Entrada inicial fornecedor Beta'),
(4, 4, 'ENTRADA', 75, 'COMPRA', 2, 'Entrada inicial fornecedor Beta');
