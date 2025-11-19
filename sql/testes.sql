-- Teste 1: Criar pedido com 2–3 itens. Ver estoque cair corretamente.
SELECT setval('estoque_estoque_id_seq', (SELECT COALESCE(MAX(estoque_id), 0) FROM estoque), true);
SELECT 
    p.produto_id,
    p.nome,
    COALESCE(SUM(CASE 
        WHEN e.tipo = 'ENTRADA' THEN e.quantidade 
        WHEN e.tipo = 'SAIDA' THEN -e.quantidade 
    END), 0) AS estoque_antes
FROM produtos p
LEFT JOIN estoque e ON p.produto_id = e.produto_id
WHERE p.produto_id = 4
GROUP BY p.produto_id, p.nome;

DO $$
DECLARE
    itens_pedido JSON := '[{"produto_id": 4, "quantidade": 3, "preco_unit": 89.90, "desconto": 0.00}]';
BEGIN
    CALL criar_pedido(1, itens_pedido);
END $$;

SELECT 
    p.produto_id,
    p.nome,
    COALESCE(SUM(CASE 
        WHEN e.tipo = 'ENTRADA' THEN e.quantidade 
        WHEN e.tipo = 'SAIDA' THEN -e.quantidade 
    END), 0) AS estoque_depois
FROM produtos p
LEFT JOIN estoque e ON p.produto_id = e.produto_id
WHERE p.produto_id = 4
GROUP BY p.produto_id, p.nome;

-- Teste 2: Pagar parcial e depois quitar. Ver status mudar para PAGO.
SELECT setval('pagamentos_pagamentos_id_seq', (SELECT COALESCE(MAX(pagamentos_id), 0) FROM pagamentos), true);
DO $$
DECLARE
    v_pedido_id BIGINT := (SELECT MAX(pedido_id) FROM pedidos WHERE cliente_id = 1);
BEGIN
    CALL pagar_pedido(v_pedido_id, 100.00, 'Cartão de Crédito');
    
    RAISE NOTICE 'Status após pagamento parcial: %', (SELECT status FROM pedidos WHERE pedido_id = v_pedido_id);
    RAISE NOTICE 'Total pago: %', (SELECT COALESCE(SUM(valor_pago), 0) FROM pagamentos WHERE pedido_id = v_pedido_id);
END $$;

DO $$
DECLARE
    v_pedido_id BIGINT := (SELECT MAX(pedido_id) FROM pedidos WHERE cliente_id = 1);
    v_total_pago NUMERIC(14,2);
    v_total_pedido NUMERIC(14,2);
BEGIN
    SELECT total_liq INTO v_total_pedido FROM pedidos WHERE pedido_id = v_pedido_id;
    SELECT COALESCE(SUM(valor_pago), 0) INTO v_total_pago FROM pagamentos WHERE pedido_id = v_pedido_id;
    
    RAISE NOTICE 'Total do pedido: %', v_total_pedido;
    RAISE NOTICE 'Total pago até agora: %', v_total_pago;
    RAISE NOTICE 'Faltam pagar: %', (v_total_pedido - v_total_pago);
    
    CALL pagar_pedido(v_pedido_id, (v_total_pedido - v_total_pago), 'PIX');
    
    RAISE NOTICE 'Status após quitação: %', (SELECT status FROM pedidos WHERE pedido_id = v_pedido_id);
    RAISE NOTICE 'Total pago final: %', (SELECT COALESCE(SUM(valor_pago), 0) FROM pagamentos WHERE pedido_id = v_pedido_id);
END $$;

SELECT 
    p.pedido_id,
    p.cliente_id,
    c.nome as cliente_nome,
    p.status,
    p.total_bruto,
    p.desconto,
    p.total_liq,
    p.data_pedido
FROM pedidos p
JOIN clientes c ON p.cliente_id = c.cliente_id
WHERE p.pedido_id = 7;

-- Teste 3: Cancelar outro pedido. Ver estoque voltar e status = CANCELADO.
DO $$
DECLARE
    itens_pedido3 JSON := '[{"produto_id": 4, "quantidade": 2, "preco_unit": 89.90, "desconto": 0.00}]';  -- Mouse Gamer RGB
BEGIN
    CALL criar_pedido(3, itens_pedido3);
END $$;

DO $$
DECLARE
    v_pedido_id BIGINT := (SELECT MAX(pedido_id) FROM pedidos WHERE cliente_id = 3);
    v_estoque_antes INT;
BEGIN
    RAISE NOTICE 'Pedido a ser cancelado: %', v_pedido_id;
    RAISE NOTICE 'Status antes do cancelamento: %', (SELECT status FROM pedidos WHERE pedido_id = v_pedido_id);
    
    SELECT COALESCE(SUM(CASE WHEN tipo='ENTRADA' THEN quantidade ELSE -quantidade END), 0)
    INTO v_estoque_antes
    FROM estoque WHERE produto_id = 4;
    
    RAISE NOTICE 'Estoque do produto 4 antes do cancelamento: %', v_estoque_antes;
    
    CALL cancelar_pedido(v_pedido_id);
    
    RAISE NOTICE 'Status após cancelamento: %', (SELECT status FROM pedidos WHERE pedido_id = v_pedido_id);
    RAISE NOTICE 'Estoque do produto 4 após cancelamento: %', 
        (SELECT COALESCE(SUM(CASE WHEN tipo='ENTRADA' THEN quantidade ELSE -quantidade END), 0) FROM estoque WHERE produto_id = 4);
    
    RAISE NOTICE 'Lançamentos de entrada por cancelamento: %',
        (SELECT COUNT(*) FROM estoque WHERE pedido_id = v_pedido_id AND tipo = 'ENTRADA' AND origem_tipo = 'CANCELAMENTO');
END $$;

SELECT 
    e.estoque_id,
    e.produto_id,
    pr.nome as produto_nome,
    e.tipo,
    e.quantidade,
    e.origem_tipo,
    e.pedido_id,
    e.data_movimentacao
FROM estoque e
JOIN produtos pr ON e.produto_id = pr.produto_id
WHERE e.pedido_id = 10
ORDER BY e.data_movimentacao;

-- Teste 4: Caso de erro: tentar vender sem estoque; verificar rollback e mensagem.
DO $$
DECLARE
    itens_pedido4 JSON := '[{"produto_id": 4, "quantidade": 100, "preco_unit": 89.90, "desconto": 0.00}]';
BEGIN
    CALL criar_pedido(4, itens_pedido4);
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Erro capturado conforme esperado: %', SQLERRM;
END $$;