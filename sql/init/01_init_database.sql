-- ==============================================
-- SCRIPT DE INICIALIZAÇÃO DO DATA WAREHOUSE
-- SCD Type 2 com PostgreSQL
-- ==============================================

-- Criar esquemas
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS dw;

-- ==============================================
-- 1. TABELA DE STAGING (dados de origem)
-- ==============================================

-- Tabela de staging para dados de clientes
CREATE TABLE staging.clientes_source (
    id_cliente INTEGER NOT NULL,
    nm_cliente VARCHAR(100) NOT NULL,
    ds_email VARCHAR(150),
    cidade VARCHAR(80),
    uf CHAR(2),
    telefone VARCHAR(20),
    dt_nascimento DATE,
    dt_processamento DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT pk_staging_clientes PRIMARY KEY (id_cliente, dt_processamento)
);

-- Índices para melhor performance
CREATE INDEX idx_staging_clientes_dt_proc ON staging.clientes_source(dt_processamento);

-- ==============================================
-- 2. DIMENSÃO SCD TYPE 2
-- ==============================================

-- Tabela de dimensão com SCD Type 2
CREATE TABLE dw.dim_cliente (
    sk_cliente SERIAL PRIMARY KEY,                -- Surrogate Key (Chave Surrogada)
    id_cliente INTEGER NOT NULL,                  -- Business Key (Chave de Negócio)
    nm_cliente VARCHAR(100) NOT NULL,
    ds_email VARCHAR(150),
    cidade VARCHAR(80),
    uf CHAR(2),
    telefone VARCHAR(20),
    dt_nascimento DATE,
    dt_inicio DATE NOT NULL,                      -- Data de início da validade
    dt_fim DATE NOT NULL DEFAULT '9999-12-31',   -- Data de fim da validade
    fl_corrente BOOLEAN NOT NULL DEFAULT TRUE,   -- Flag indicando se é o registro atual
    dt_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dt_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices importantes para SCD Type 2
CREATE INDEX idx_dim_cliente_id_negocio ON dw.dim_cliente(id_cliente);
CREATE INDEX idx_dim_cliente_corrente ON dw.dim_cliente(fl_corrente) WHERE fl_corrente = TRUE;
CREATE INDEX idx_dim_cliente_periodo ON dw.dim_cliente(dt_inicio, dt_fim);

-- Constraint para garantir que só existe um registro corrente por cliente
CREATE UNIQUE INDEX idx_dim_cliente_unico_corrente 
ON dw.dim_cliente(id_cliente) 
WHERE fl_corrente = TRUE;

-- ==============================================
-- 3. TABELA FATO (Vendas)
-- ==============================================

-- Tabela fato particionada por data
CREATE TABLE dw.fato_vendas (
    sk_venda SERIAL,
    sk_cliente INTEGER NOT NULL,                 -- FK para dim_cliente
    id_produto INTEGER NOT NULL,
    nm_produto VARCHAR(100),
    dt_venda DATE NOT NULL,
    vl_venda DECIMAL(15,2) NOT NULL,
    qtd_vendida INTEGER NOT NULL DEFAULT 1,
    dt_ref DATE NOT NULL,                        -- Data de referência (partição)
    dt_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_fato_vendas PRIMARY KEY (sk_venda, dt_ref),
    CONSTRAINT fk_fato_vendas_cliente FOREIGN KEY (sk_cliente) REFERENCES dw.dim_cliente(sk_cliente)
) PARTITION BY RANGE (dt_ref);

-- Criar partições para os próximos meses
CREATE TABLE dw.fato_vendas_2024_10 PARTITION OF dw.fato_vendas
    FOR VALUES FROM ('2024-10-01') TO ('2024-11-01');

CREATE TABLE dw.fato_vendas_2024_11 PARTITION OF dw.fato_vendas
    FOR VALUES FROM ('2024-11-01') TO ('2024-12-01');

CREATE TABLE dw.fato_vendas_2024_12 PARTITION OF dw.fato_vendas
    FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');

CREATE TABLE dw.fato_vendas_2025_01 PARTITION OF dw.fato_vendas
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

-- Índices na tabela fato
CREATE INDEX idx_fato_vendas_cliente ON dw.fato_vendas(sk_cliente);
CREATE INDEX idx_fato_vendas_dt_venda ON dw.fato_vendas(dt_venda);
CREATE INDEX idx_fato_vendas_dt_ref ON dw.fato_vendas(dt_ref);

-- ==============================================
-- 4. VIEWS ÚTEIS
-- ==============================================

-- View para clientes atuais (apenas registros correntes)
CREATE VIEW dw.v_clientes_atuais AS
SELECT 
    sk_cliente,
    id_cliente,
    nm_cliente,
    ds_email,
    cidade,
    uf,
    telefone,
    dt_nascimento,
    dt_inicio,
    dt_criacao,
    dt_atualizacao
FROM dw.dim_cliente 
WHERE fl_corrente = TRUE;

-- View para análise histórica de vendas com clientes
CREATE VIEW dw.v_vendas_historico AS
SELECT 
    f.sk_venda,
    f.dt_venda,
    f.vl_venda,
    f.qtd_vendida,
    f.id_produto,
    f.nm_produto,
    d.id_cliente,
    d.nm_cliente,
    d.ds_email,
    d.cidade AS cidade_na_epoca_da_venda,
    d.uf,
    d.dt_inicio AS cliente_valido_desde,
    d.dt_fim AS cliente_valido_ate,
    f.dt_ref
FROM dw.fato_vendas f
INNER JOIN dw.dim_cliente d ON f.sk_cliente = d.sk_cliente
    AND f.dt_venda BETWEEN d.dt_inicio AND d.dt_fim;

-- ==============================================
-- 5. FUNÇÕES AUXILIARES
-- ==============================================

-- Função para obter o próximo SK disponível
CREATE OR REPLACE FUNCTION dw.get_next_sk_cliente()
RETURNS INTEGER AS $$
BEGIN
    RETURN COALESCE(MAX(sk_cliente), 0) + 1 FROM dw.dim_cliente;
END;
$$ LANGUAGE plpgsql;

-- ==============================================
-- 6. COMENTÁRIOS NAS TABELAS
-- ==============================================

COMMENT ON SCHEMA staging IS 'Schema para dados de staging/origem';
COMMENT ON SCHEMA dw IS 'Schema do Data Warehouse';

COMMENT ON TABLE staging.clientes_source IS 'Tabela de staging para dados de clientes vindos do sistema origem';
COMMENT ON TABLE dw.dim_cliente IS 'Dimensão de clientes com SCD Type 2 - mantém histórico completo';
COMMENT ON TABLE dw.fato_vendas IS 'Tabela fato de vendas particionada por dt_ref';

COMMENT ON COLUMN dw.dim_cliente.sk_cliente IS 'Surrogate Key - Chave primária única para cada versão do cliente';
COMMENT ON COLUMN dw.dim_cliente.id_cliente IS 'Business Key - ID do cliente no sistema origem (pode repetir para histórico)';
COMMENT ON COLUMN dw.dim_cliente.dt_inicio IS 'Data de início da validade desta versão do cliente';
COMMENT ON COLUMN dw.dim_cliente.dt_fim IS 'Data de fim da validade desta versão do cliente (9999-12-31 = atual)';
COMMENT ON COLUMN dw.dim_cliente.fl_corrente IS 'Flag indicando se é a versão atual do cliente (TRUE = atual)';

COMMENT ON VIEW dw.v_clientes_atuais IS 'View com apenas os registros atuais dos clientes (fl_corrente = TRUE)';
COMMENT ON VIEW dw.v_vendas_historico IS 'View para análise histórica - join entre vendas e clientes válidos na época';

-- ==============================================
-- 7. DADOS INICIAIS PARA TESTE
-- ==============================================

-- Inserir alguns clientes iniciais na staging
INSERT INTO staging.clientes_source (id_cliente, nm_cliente, ds_email, cidade, uf, telefone, dt_nascimento, dt_processamento)
VALUES 
    (1, 'João Silva', 'joao.silva@email.com', 'São Paulo', 'SP', '11999999999', '1985-03-15', '2024-10-01'),
    (2, 'Maria Santos', 'maria.santos@email.com', 'Rio de Janeiro', 'RJ', '21888888888', '1990-07-22', '2024-10-01'),
    (3, 'Carlos Oliveira', 'carlos.oliveira@email.com', 'Belo Horizonte', 'MG', '31777777777', '1987-12-10', '2024-10-01'),
    (4, 'Ana Costa', 'ana.costa@email.com', 'Porto Alegre', 'RS', '51666666666', '1992-05-18', '2024-10-01');

-- Processar dados iniciais para a dimensão (primeira carga)
INSERT INTO dw.dim_cliente (id_cliente, nm_cliente, ds_email, cidade, uf, telefone, dt_nascimento, dt_inicio, dt_fim, fl_corrente)
SELECT 
    id_cliente,
    nm_cliente,
    ds_email,
    cidade,
    uf,
    telefone,
    dt_nascimento,
    dt_processamento as dt_inicio,
    '9999-12-31' as dt_fim,
    TRUE as fl_corrente
FROM staging.clientes_source
WHERE dt_processamento = '2024-10-01';

-- Inserir algumas vendas de exemplo
INSERT INTO dw.fato_vendas (sk_cliente, id_produto, nm_produto, dt_venda, vl_venda, qtd_vendida, dt_ref)
SELECT 
    d.sk_cliente,
    100 + (d.id_cliente * 10) as id_produto,
    'Produto ' || (100 + (d.id_cliente * 10)) as nm_produto,
    '2024-10-15' as dt_venda,
    500.00 + (d.id_cliente * 50) as vl_venda,
    1 as qtd_vendida,
    '2024-10-15' as dt_ref
FROM dw.dim_cliente d
WHERE d.fl_corrente = TRUE;

-- ==============================================
-- FIM DO SCRIPT DE INICIALIZAÇÃO
-- ==============================================

SELECT 'Database inicializado com sucesso!' as status;