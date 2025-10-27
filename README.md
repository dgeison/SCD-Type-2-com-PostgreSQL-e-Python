# SCD Type 2 com PostgreSQL e Python

## 🎯 Objetivo

Este projeto demonstra como implementar **Slowly Changing Dimensions (SCD) Type 2** usando PostgreSQL e Python. Você aprenderá a manter o histórico completo de mudanças em dimensões do Data Warehouse.

## 📚 O que é SCD Type 2?

SCD Type 2 é uma técnica de Data Warehousing que **preserva o histórico completo** das mudanças em uma dimensão, criando novos registros para cada alteração em vez de sobrescrever os dados antigos.

### Exemplo Real de Execução:

Este é o resultado real de uma execução do pipeline SCD Type 2:

```
sk_cliente | id_cliente | nome            | email                    | cidade        | uf | telefone    | dt_nascimento | dt_inicio  | dt_fim     | fl_corrente
-----------|------------|-----------------|--------------------------|---------------|----|-----------  |---------------|------------|------------|------------
1          | 1          | João Silva      | joao.silva@email.com     | São Paulo     | SP | 11999999999 | 1985-03-15    | 2024-10-01 | 2024-10-27 | false
6          | 1          | João Silva      | joao.silva@email.com     | Brasília      | DF | 11888888888 | 1985-03-15    | 2024-10-27 | 9999-12-31 | true
3          | 3          | Carlos Oliveira | carlos.oliveira@email.com| Belo Horizonte| MG | 31777777777 | 1987-12-10    | 2024-10-01 | 2024-10-27 | false
7          | 3          | Carlos Oliveira | carlos.oliveira@email.com| São Paulo     | SP | 31777777777 | 1987-12-10    | 2024-10-27 | 9999-12-31 | true
```

**O que aconteceu:**
- **João Silva**: Mudou de São Paulo/SP para Brasília/DF e trocou telefone
- **Carlos Oliveira**: Mudou de Belo Horizonte/MG para São Paulo/SP
- **Histórico preservado**: Versões antigas marcadas com `fl_corrente = false`
- **Versões atuais**: Novas versões com `fl_corrente = true` e `dt_fim = 9999-12-31`

## 🏗️ Estrutura do Projeto

```
scd_type2_com_spark/
├── 📁 notebooks/           # Jupyter Notebooks com tutorial
│   └── scd_type2_tutorial.ipynb
├── 📁 sql/                 # Scripts SQL
│   └── init/
│       └── 01_init_database.sql
├── 📁 src/                 # Código Python
│   └── data_generator.py
├── 📁 data/                # Dados gerados
├── docker-compose.yml      # Configuração Docker
├── requirements.txt        # Dependências Python
├── .env                   # Variáveis de ambiente
└── README.md              # Este arquivo
```

## 🚀 Configuração do Ambiente

### 1. Pré-requisitos

- **Docker** e **Docker Compose**
- **Python 3.8+**
- **VS Code** (recomendado)

### 2. Configurar o ambiente

1. **Clone o projeto** (ou certifique-se de estar no diretório correto):
   ```bash
   cd d:\OneDrive\Documents\_projetos\scd_type2_com_spark
   ```

2. **Instalar dependências Python**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Iniciar o PostgreSQL com Docker**:
   ```bash
   docker-compose up -d
   ```

4. **Verificar se os containers estão rodando**:
   ```bash
   docker-compose ps
   ```

### 3. Acessar os serviços

- **PostgreSQL**: `localhost:5432`
  - Database: `datawarehouse`
  - User: `dw_user` 
  - Password: `dw_password`

- **PgAdmin** (Interface web): http://localhost:8080
  - Email: `admin@datawarehouse.com`
  - Password: `admin123`

## ✨ Funcionalidades Implementadas

### 🎯 Pipeline ETL Completo para SCD Type 2

- **Detecção automática de mudanças** em atributos de clientes
- **Expiração inteligente** de registros históricos
- **Inserção de novas versões** mantendo integridade referencial
- **Point-in-Time Joins** para consultas históricas precisas
- **Relatórios detalhados** de processamento

### 🔧 Recursos Técnicos

- **SQLAlchemy** para ORM e conexões robustas
- **Pandas** para manipulação eficiente de dados
- **PostgreSQL** com schemas dedicados (staging + dw)
- **Docker Compose** para ambiente containerizado
- **Arquivo .env** para configurações centralizadas

### 📊 Estruturas de Dados

- **Staging**: `staging.clientes_source` - dados de origem
- **Dimensão**: `dw.dim_cliente` - SCD Type 2 com histórico completo
- **Fato**: `dw.fato_vendas` - vendas com chaves históricas corretas

## 🎯 Resultado Prático - Como Interpretar

### Exemplo de Mudanças Detectadas:

O sistema identifica automaticamente quando um cliente muda dados e cria o histórico:

```sql
-- João Silva (id_cliente = 1):
-- ANTES: São Paulo/SP, telefone 11999999999 (válido até 2024-10-27)
-- DEPOIS: Brasília/DF, telefone 11888888888 (válido a partir de 2024-10-27)

-- Carlos Oliveira (id_cliente = 3):  
-- ANTES: Belo Horizonte/MG (válido até 2024-10-27)
-- DEPOIS: São Paulo/SP (válido a partir de 2024-10-27)
```

### Como o SCD Type 2 funciona:

1. **Preservação**: Dados antigos ficam com `fl_corrente = false` e `dt_fim = 2024-10-27`
2. **Evolução**: Novos dados com `fl_corrente = true` e `dt_fim = 9999-12-31`
3. **Rastreabilidade**: Todos os `sk_cliente` únicos permitem joins históricos corretos
4. **Auditoria**: `dt_criacao` e `dt_atualizacao` registram timestamps precisos

### Consultas Essenciais:

```sql
-- Ver apenas dados atuais
SELECT * FROM dw.dim_cliente WHERE fl_corrente = true;

-- Ver histórico completo de um cliente
SELECT * FROM dw.dim_cliente WHERE id_cliente = 1 ORDER BY sk_cliente;

-- Point-in-Time Join para vendas históricas
SELECT f.dt_venda, f.nm_produto, d.nm_cliente, d.cidade AS cidade_na_epoca
FROM dw.fato_vendas f
INNER JOIN dw.dim_cliente d ON f.sk_cliente = d.sk_cliente
    AND f.dt_venda BETWEEN d.dt_inicio AND d.dt_fim;
```

## 📖 Tutorial Completo

### Abrir o Jupyter Notebook

1. **Iniciar Jupyter Lab**:
   ```bash
   jupyter lab
   ```

2. **Abrir o tutorial**:
   - Navegue até `notebooks/scd_type2_tutorial.ipynb`
   - Execute as células sequencialmente

### O que você vai aprender:

1. **Setup e Conexão** - Conectar Python com PostgreSQL
2. **Estrutura SCD2** - Tabelas staging, dimensão e fato
3. **Identificar Mudanças** - Comparar dados novos vs atuais
4. **Expirar Registros** - Marcar versões antigas como históricas
5. **Inserir Novas Versões** - Criar registros atualizados
6. **Point-in-Time Joins** - Consultas históricas corretas
7. **Pipeline ETL Completo** - Automatizar todo o processo

## 🧪 Gerar Dados de Teste

Para testar com dados sintéticos:

```bash
cd src
python data_generator.py
```

Isso criará arquivos CSV na pasta `data/` com:
- Clientes iniciais
- Mudanças simuladas em datas diferentes
- Vendas sintéticas para demonstrar Point-in-Time Joins

## 🔍 Comandos Úteis

### Docker

```bash
# Iniciar ambiente
docker-compose up -d

# Parar ambiente
docker-compose down

# Ver logs do PostgreSQL
docker-compose logs postgres

# Reiniciar apenas o PostgreSQL
docker-compose restart postgres
```

### PostgreSQL Direto

```bash
# Conectar via psql (se instalado)
psql -h localhost -p 5432 -U dw_user -d datawarehouse

# Backup do banco
docker exec scd_postgres pg_dump -U dw_user datawarehouse > backup.sql

# Restaurar backup
docker exec -i scd_postgres psql -U dw_user datawarehouse < backup.sql
```

## 📊 Consultas de Exemplo

### Clientes Atuais
```sql
SELECT * FROM dw.dim_cliente WHERE fl_corrente = TRUE;
```

### Histórico Completo
```sql
SELECT 
    id_cliente,
    nm_cliente,
    cidade,
    dt_inicio,
    dt_fim,
    fl_corrente
FROM dw.dim_cliente 
ORDER BY id_cliente, sk_cliente;
```

### Point-in-Time Join (Vendas com contexto histórico)
```sql
SELECT 
    f.dt_venda,
    f.nm_produto,
    f.vl_venda,
    d.nm_cliente,
    d.cidade AS cidade_na_epoca_da_venda
FROM dw.fato_vendas f
INNER JOIN dw.dim_cliente d 
    ON f.sk_cliente = d.sk_cliente
ORDER BY f.dt_venda, d.id_cliente;
```

## 🛠️ Troubleshooting

### Problema: Docker não inicia
```bash
# Verificar se as portas estão livres
netstat -an | find "5432"
netstat -an | find "8080"

# Limpar containers antigos
docker system prune -f
```

### Problema: Erro de conexão Python
```bash
# Verificar se o PostgreSQL está rodando
docker-compose ps

# Testar conexão
python -c "import psycopg2; print('psycopg2 OK')"
```

### Problema: Jupyter não encontra módulos
```bash
# Instalar kernel do projeto
python -m ipykernel install --user --name scd_env --display-name "SCD Type 2"
```

## 🎓 Conceitos Chave

### SCD Type 2 vs Type 1

| **SCD Type 1** | **SCD Type 2** |
|----------------|----------------|
| ❌ Sobrescreve dados antigos | ✅ Preserva histórico completo |
| ❌ Perde contexto histórico | ✅ Point-in-Time Joins precisos |
| ✅ Mais simples | ✅ Mais robusto para analytics |
| ✅ Menos espaço | ✅ Melhor para auditoria |

### Colunas Essenciais SCD2

- `sk_cliente` - **Surrogate Key** (chave primária única)
- `id_cliente` - **Business Key** (ID do sistema origem)
- `dt_inicio` - Data de início da validade
- `dt_fim` - Data de fim da validade (`9999-12-31` = atual)
- `fl_corrente` - Flag booleano (TRUE = registro atual)

### Pipeline ETL SCD2

1. **Extract** - Carregar novos dados da origem
2. **Compare** - Identificar novos, alterados, inalterados
3. **Expire** - Marcar registros antigos como históricos
4. **Insert** - Criar novas versões + novos registros
5. **Validate** - Verificar integridade dos dados

## 📈 Próximos Passos

1. **PySpark**: Implementar para grandes volumes
2. **Delta Lake**: Usar `MERGE INTO` para otimização
3. **Airflow**: Orquestrar pipeline em produção
4. **DBT**: Transformações declarativas
5. **Monitoramento**: Logs e alertas

## 🤝 Contribuição

Este é um projeto educacional. Sugestões e melhorias são bem-vindas!

## 📄 Licença

MIT License - Use livremente para aprender e ensinar SCD Type 2.

## 🏆 Resultados Alcançados

### ✅ Pipeline ETL Funcional
- **SCD Type 2 completo** implementado e testado
- **Detecção automática** de mudanças em tempo real
- **Histórico preservado** com integridade total
- **Point-in-Time Joins** funcionando corretamente

### ✅ Ambiente Completo
- **Docker containerizado** para fácil setup
- **PostgreSQL** configurado com schemas otimizados
- **Jupyter Notebook** com tutorial passo a passo
- **Python + SQLAlchemy** para ETL robusto

### ✅ Dados Reais Testados
- **Clientes com mudanças** processados com sucesso
- **Histórico temporal** mantido corretamente
- **Vendas históricas** vinculadas às versões corretas
- **Consultas analíticas** validadas

---

**🎉 Agora você está pronto para dominar SCD Type 2!**

Comece executando o notebook `scd_type2_tutorial.ipynb` e acompanhe o tutorial passo a passo.