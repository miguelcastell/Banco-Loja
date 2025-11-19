CREATE OR REPLACE FUNCTION recalcular_totais_pedido(p_pedido_id BIGINT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_bruto NUMERIC(14,2);
    v_total_desconto NUMERIC(14,2);
    v_total_liq NUMERIC(14,2);
BEGIN
    SELECT
        COALESCE(SUM(quantidade * preco_unit), 0),
        COALESCE(SUM(desconto), 0)
    INTO
        v_total_bruto,
        v_total_desconto
    FROM
        pedido_itens
    WHERE
        pedido_id = p_pedido_id;

    v_total_liq := v_total_bruto - v_total_desconto;

    UPDATE pedidos
    SET
        total_bruto = v_total_bruto,
        desconto = v_total_desconto,
        total_liq = v_total_liq,
        atualizado_em = NOW()
    WHERE
        pedido_id = p_pedido_id;

END;
$$;

CREATE OR REPLACE PROCEDURE criar_pedido(
    p_cliente_id BIGINT,
    p_itens JSON
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_pedido_id BIGINT;
    v_item RECORD;
    v_estoque_atual INT;
    v_produto_id BIGINT;
    v_quantidade_saida INT;
    v_preco_unit NUMERIC(14,2);
    v_desconto NUMERIC(14,2);
BEGIN
    IF NOT EXISTS (SELECT 1 FROM clientes WHERE cliente_id = p_cliente_id) THEN
        RAISE EXCEPTION 'ERRO: Cliente com ID % não encontrado.', p_cliente_id;
    END IF;

    INSERT INTO pedidos (cliente_id, status, data_pedido, criado_em, atualizado_em)
    VALUES (p_cliente_id, 'ABERTO', CURRENT_DATE, NOW(), NOW())
    RETURNING pedido_id INTO v_pedido_id;

    FOR v_item IN
        SELECT
            (js.value->>'produto_id')::BIGINT AS produto_id,
            (js.value->>'quantidade')::INT AS quantidade,
            (js.value->>'preco_unit')::NUMERIC(14,2) AS preco_unit,
            (js.value->>'desconto')::NUMERIC(14,2) AS desconto
        FROM json_array_elements(p_itens) AS js(value)
    LOOP
        v_produto_id := v_item.produto_id;
        v_quantidade_saida := v_item.quantidade;
        v_preco_unit := v_item.preco_unit;
        v_desconto := v_item.desconto;

        IF NOT EXISTS (SELECT 1 FROM produtos WHERE produto_id = v_produto_id) THEN
            RAISE EXCEPTION 'ERRO: Produto com ID % não encontrado.', v_produto_id;
        END IF;

        SELECT
            COALESCE(SUM(CASE WHEN tipo = 'ENTRADA' THEN quantidade ELSE -quantidade END), 0)
        INTO
            v_estoque_atual
        FROM
            estoque
        WHERE
            produto_id = v_produto_id;

        IF v_estoque_atual < v_quantidade_saida THEN
            RAISE EXCEPTION 'ERRO: Estoque insuficiente para o Produto ID %. Necessário: %, Disponível: %',
                v_produto_id, v_quantidade_saida, v_estoque_atual;
        END IF;

        INSERT INTO pedido_itens (
            pedido_id,
            produto_id,
            quantidade,
            preco_unit,
            desconto,
            criado_em,
            atualizado_em
        )
        VALUES (
            v_pedido_id,
            v_produto_id,
            v_quantidade_saida,
            v_preco_unit,
            v_desconto,
            NOW(),
            NOW()
        );

        INSERT INTO estoque (
            pedido_id,
            tipo,
            quantidade,
            origem_tipo,
            data_movimentacao,
            criado_em,
            atualizado_em,
            produto_id
        )
        VALUES (
            v_pedido_id,
            'SAIDA',
            v_quantidade_saida,
            'VENDA',
            NOW(),
            NOW(),
            NOW(),
            v_produto_id
        );

    END LOOP;

    PERFORM recalcular_totais_pedido(v_pedido_id);
    RAISE NOTICE 'SUCESSO: Pedido ID % criado com sucesso.', v_pedido_id;

END;
$$;

CREATE OR REPLACE PROCEDURE pagar_pedido(
    p_pedido_id BIGINT,
    p_valor_pago NUMERIC(10,2),
    p_forma_pagamento VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_liquido NUMERIC(14,2);
    v_total_pago NUMERIC(14,2);
    v_cliente_id BIGINT;
BEGIN
    SELECT total_liq, cliente_id INTO v_total_liquido, v_cliente_id
    FROM pedidos
    WHERE pedido_id = p_pedido_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'ERRO: Pedido com ID % não encontrado.', p_pedido_id;
    END IF;

    IF v_total_liquido IS NULL OR v_total_liquido <= 0 THEN
        RAISE EXCEPTION 'ERRO: Pedido ID % não possui valor líquido para pagamento.', p_pedido_id;
    END IF;

    INSERT INTO pagamentos (
        pedido_id,
        cliente_id,
        valor_pago,
        data_pagamento,
        forma_pagamento,
        status_pagamento,
        criado_em,
        atualizado_em
    )
    VALUES (
        p_pedido_id,
        v_cliente_id,
        p_valor_pago,
        CURRENT_DATE,
        p_forma_pagamento,
        'APROVADO',
        NOW(),
        NOW()
    );

    SELECT COALESCE(SUM(valor_pago), 0) INTO v_total_pago
    FROM pagamentos
    WHERE pedido_id = p_pedido_id;

    IF v_total_pago >= v_total_liquido THEN
        UPDATE pedidos
        SET status = 'PAGO', atualizado_em = NOW()
        WHERE pedido_id = p_pedido_id AND status <> 'PAGO';
        RAISE NOTICE 'SUCESSO: Pedido ID % quitado. Status atualizado para PAGO.', p_pedido_id;
    ELSE
        RAISE NOTICE 'SUCESSO: Pagamento registrado. Total pago: %. Total líquido: %.', v_total_pago, v_total_liquido;
    END IF;

END;
$$;

CREATE OR REPLACE PROCEDURE cancelar_pedido(
    p_pedido_id BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status_atual VARCHAR(20);
    v_item RECORD;
BEGIN
    SELECT status INTO v_status_atual
    FROM pedidos
    WHERE pedido_id = p_pedido_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'ERRO: Pedido com ID % não encontrado.', p_pedido_id;
    END IF;

    IF v_status_atual = 'CANCELADO' THEN
        RAISE EXCEPTION 'ERRO: Pedido ID % já está CANCELADO.', p_pedido_id;
    END IF;

    IF v_status_atual = 'PAGO' THEN
        RAISE NOTICE 'AVISO: Pedido ID % já está PAGO. O cancelamento será efetuado, mas o estorno financeiro deve ser tratado externamente.', p_pedido_id;
    END IF;

    FOR v_item IN
        SELECT produto_id, quantidade
        FROM pedido_itens
        WHERE pedido_id = p_pedido_id
    LOOP
        INSERT INTO estoque (
            pedido_id,
            tipo,
            quantidade,
            origem_tipo,
            data_movimentacao,
            criado_em,
            atualizado_em
        )
        VALUES (
            p_pedido_id,
            'ENTRADA',
            v_item.quantidade,
            'CANCELAMENTO',
            NOW(),
            NOW(),
            NOW()
        );
    END LOOP;

    UPDATE pedidos
    SET status = 'CANCELADO', atualizado_em = NOW()
    WHERE pedido_id = p_pedido_id;

    RAISE NOTICE 'SUCESSO: Pedido ID % cancelado e estoque revertido.', p_pedido_id;

END;
$$;