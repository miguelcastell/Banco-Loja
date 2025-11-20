-- T1
CREATE OR REPLACE FUNCTION validar_estoque_saida()
RETURNS TRIGGER AS $$
DECLARE
    estoque_atual INT;
BEGIN
    IF NEW.tipo = 'SAIDA' THEN
        SELECT COALESCE(SUM(
            CASE 
                WHEN tipo = 'ENTRADA' THEN quantidade
                WHEN tipo = 'SAIDA' THEN -quantidade
            END
        ), 0)
        INTO estoque_atual
        FROM estoque
        WHERE produto_id = NEW.produto_id;

        IF estoque_atual < NEW.quantidade THEN
            RAISE EXCEPTION 
                'Estoque insuficiente para o produto %: disponível %, solicitado %',
                NEW.produto_id, estoque_atual, NEW.quantidade;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_estoque_saida
BEFORE INSERT OR UPDATE ON estoque
FOR EACH ROW
WHEN (NEW.tipo = 'SAIDA')
EXECUTE FUNCTION validar_estoque_saida();

-- T2
CREATE OR REPLACE FUNCTION preencher_preco_e_subtotal()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.preco_unit IS NULL THEN
        SELECT preco_unitario
        INTO NEW.preco_unit
        FROM produtos
        WHERE produto_id = NEW.produto_id;
    END IF;
    NEW.total_liq := NEW.quantidade * NEW.preco_unit;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_preencher_preco_e_subtotal
BEFORE INSERT OR UPDATE
ON pedido_itens
FOR EACH ROW
EXECUTE FUNCTION preencher_preco_e_subtotal();

-- T3
CREATE OR REPLACE FUNCTION recalcular_totais_pedido()
RETURNS TRIGGER AS $$
DECLARE
    v_pedido_id BIGINT;
BEGIN
    v_pedido_id := COALESCE(NEW.pedido_id, OLD.pedido_id);

    UPDATE pedidos
    SET 
        total_bruto = COALESCE((
            SELECT SUM(quantidade * preco_unit)
            FROM pedido_itens
            WHERE pedido_id = v_pedido_id
        ), 0),
        total_liq = COALESCE((
            SELECT SUM(total_liq)
            FROM pedido_itens
            WHERE pedido_id = v_pedido_id
        ), 0),
        atualizado_em = NOW()
    WHERE pedido_id = v_pedido_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_recalcular_totais_pedido
AFTER INSERT OR UPDATE OR DELETE
ON pedido_itens
FOR EACH ROW
EXECUTE FUNCTION recalcular_totais_pedido();

CREATE OR REPLACE FUNCTION baixa_estoque_pedido()
RETURNS TRIGGER AS $$
DECLARE
    estoque_atual INT;
BEGIN
    
    SELECT COALESCE(SUM(
        CASE 
            WHEN tipo = 'ENTRADA' THEN quantidade
            WHEN tipo = 'SAIDA' THEN -quantidade
        END
    ), 0)
    INTO estoque_atual
    FROM estoque
    WHERE produto_id = NEW.produto_id;

    IF estoque_atual < NEW.quantidade THEN
        RAISE EXCEPTION 
            'Estoque insuficiente para o produto %: disponível %, solicitado %',
            NEW.produto_id, estoque_atual, NEW.quantidade;
    END IF;

    INSERT INTO estoque (
        produto_id,
        tipo,
        quantidade,
        origem_tipo,
        origem_id,
        observacoes,
        criado_em,
        atualizado_em
    )
    VALUES (
        NEW.produto_id,
        'SAIDA',
        NEW.quantidade,
        'VENDA',
        NEW.pedido_id,
        'Saída por venda - Pedido ' || NEW.pedido_id,
        NOW(),
        NOW()
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_baixa_estoque_pedido
AFTER INSERT ON pedido_itens
FOR EACH ROW
EXECUTE FUNCTION baixa_estoque_pedido();

CREATE OR REPLACE FUNCTION registrar_entrada_estoque()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO estoque (
        produto_id,
        tipo,
        quantidade,
        origem_tipo,
        origem_id,
        observacoes,
        criado_em,
        atualizado_em
    ) VALUES (
        NEW.produto_id,
        'ENTRADA',
        NEW.quantidade,
        'COMPRA',
        NEW.entrada_id,
        'Entrada de compra - Entrada ' || NEW.entrada_id,
        NOW(),
        NOW()
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_registrar_entrada_estoque
AFTER INSERT ON entrada_itens
FOR EACH ROW
EXECUTE FUNCTION registrar_entrada_estoque();

CREATE OR REPLACE VIEW vw_vendas_por_dia AS
SELECT 
    data_pedido AS dia,
    COUNT(pedido_id) AS numero_pedidos,
    SUM(total_liq) AS total_vendido
FROM pedidos
WHERE status = 'PAGO'
GROUP BY data_pedido
ORDER BY data_pedido;

CREATE OR REPLACE VIEW vw_top_produtos AS
SELECT 
    p.nome AS produto,
    SUM(pi.quantidade) AS quantidade_vendida,
    SUM(pi.total_liq) AS faturamento
FROM pedido_itens pi
JOIN produtos p ON pi.produto_id = p.produto_id
JOIN pedidos pe ON pi.pedido_id = pe.pedido_id
WHERE pe.status = 'PAGO'
GROUP BY p.produto_id, p.nome
ORDER BY faturamento DESC;

CREATE OR REPLACE VIEW vw_ltv_clientes AS
SELECT 
    c.nome AS cliente,
    c.email,
    COALESCE(SUM(p.total_liq), 0) AS ltv_total
FROM clientes c
LEFT JOIN pedidos p ON c.cliente_id = p.cliente_id
WHERE p.status != 'CANCELADO' OR p.status IS NULL
GROUP BY c.cliente_id, c.nome, c.email
ORDER BY ltv_total DESC;