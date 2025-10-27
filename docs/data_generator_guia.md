# 📊 Como Usar o Data Generator - Guia Completo

## 🎯 **O que é o data_generator.py?**

O `data_generator.py` é um script Python que **gera dados sintéticos** para testar o pipeline SCD Type 2. Ele cria:

- **Clientes fictícios** com nomes, emails, cidades em português brasileiro
- **Mudanças realistas** nos dados dos clientes ao longo do tempo
- **Vendas sintéticas** vinculadas aos clientes
- **Cenários diversos** para testar SCD Type 2 completo

---

## 🚀 **Como Usar**

### **Método 1: Execução Direta (Dados Padrão)**

```bash
# 1. Navegar para a pasta src
cd src

# 2. Executar o gerador
python data_generator.py
```

**Resultado:** Cria automaticamente arquivos CSV na pasta `data/` com:
- 50 clientes iniciais (2024-10-01)
- 4 lotes de mudanças em datas diferentes
- Vendas para cada período

### **Método 2: Importar e Personalizar**

```python
# Importar as funções
from data_generator import gerar_clientes_iniciais, gerar_mudancas_clientes, gerar_vendas_sinteticas

# Gerar 100 clientes iniciais
df_clientes = gerar_clientes_iniciais(n_clientes=100)

# Simular mudanças (30% dos clientes mudam, 20% novos clientes)
df_mudancas = gerar_mudancas_clientes(
    df_base=df_clientes,
    dt_processamento='2024-12-01',
    pct_mudanca=0.30,      # 30% dos clientes com mudanças
    pct_novos=0.20         # 20% de novos clientes
)

# Gerar vendas (média de 1.5 vendas por cliente)
df_vendas = gerar_vendas_sinteticas(
    df_clientes=df_mudancas,
    dt_ref='2024-12-01',
    n_vendas_por_cliente=1.5
)
```

---

## 📋 **Arquivos Gerados**

### **Estrutura dos Arquivos de Clientes:**
```csv
id_cliente,nm_cliente,ds_email,cidade,uf,telefone,dt_nascimento,dt_processamento
1,Ana Sophia Araújo,luigi32@example.net,Viana,AP,0900 600 1338,1985-10-15,2024-10-01
2,Matheus da Paz,cdas-neves@example.net,Almeida da Serra,RR,(011) 5423-5116,1951-05-27,2024-10-01
```

### **Estrutura dos Arquivos de Vendas:**
```csv
id_cliente,id_produto,nm_produto,dt_venda,vl_venda,qtd_vendida,dt_ref
49,8890,Pen Drive,2024-09-26,41.35,3,2024-10-15
26,8890,Pen Drive,2024-10-13,50.68,3,2024-10-15
```

---

## 🔧 **Parâmetros Personalizáveis**

### **gerar_clientes_iniciais()**
```python
gerar_clientes_iniciais(
    n_clientes=100  # Número de clientes iniciais
)
```

### **gerar_mudancas_clientes()**
```python
gerar_mudancas_clientes(
    df_base=df_clientes,           # DataFrame base
    dt_processamento='2024-12-01', # Data do processamento
    pct_mudanca=0.30,              # % clientes que mudam (0.0 a 1.0)
    pct_novos=0.15                 # % novos clientes (0.0 a 1.0)
)
```

### **gerar_vendas_sinteticas()**
```python
gerar_vendas_sinteticas(
    df_clientes=df_clientes,        # DataFrame de clientes
    dt_ref='2024-12-01',           # Data de referência
    n_vendas_por_cliente=1.5       # Média de vendas por cliente
)
```

---

## 🎲 **Tipos de Mudanças Geradas**

O gerador simula **5 tipos de mudanças** realistas:

### 1. **Mudança de Cidade**
```python
# Exemplo: João mudou de São Paulo para Rio de Janeiro
'cidade': 'São Paulo' → 'Rio de Janeiro'
'uf': 'SP' → 'RJ'
```

### 2. **Mudança de Email**
```python
# Exemplo: Troca de provedor ou atualização
'ds_email': 'joao@gmail.com' → 'joao.silva@empresa.com'
```

### 3. **Mudança de Telefone**
```python
# Exemplo: Novo número
'telefone': '(11) 9999-9999' → '(11) 8888-8888'
```

### 4. **Mudança de Nome**
```python
# Exemplo: Casamento, divórcio
'nm_cliente': 'Maria Silva' → 'Maria Santos'
```

### 5. **Mudanças Múltiplas**
```python
# Exemplo: Mudança de estado (cidade + telefone + às vezes email)
'cidade': 'São Paulo' → 'Brasília'
'uf': 'SP' → 'DF'  
'telefone': '(11) 9999-9999' → '(61) 8888-8888'
```

---

## 📊 **Exemplo de Uso Completo**

### **Cenário: Teste de SCD Type 2 Personalizado**

```python
import pandas as pd
from data_generator import *

# 1. Gerar dados iniciais (janeiro)
print("🎯 Gerando dados iniciais...")
df_jan = gerar_clientes_iniciais(n_clientes=200)
salvar_dados_csv(df_jan, 'clientes_2024-01-01.csv')

# 2. Simular mudanças trimestrais
trimestres = [
    ('2024-04-01', 0.20, 0.10),  # Q1: 20% mudanças, 10% novos
    ('2024-07-01', 0.25, 0.15),  # Q2: 25% mudanças, 15% novos  
    ('2024-10-01', 0.30, 0.20),  # Q3: 30% mudanças, 20% novos
]

df_base = df_jan.copy()

for dt_ref, pct_mudanca, pct_novos in trimestres:
    print(f"\n📅 Processando {dt_ref}...")
    
    # Gerar mudanças
    df_mudancas = gerar_mudancas_clientes(
        df_base, dt_ref, pct_mudanca, pct_novos
    )
    
    # Salvar clientes
    nome_clientes = f'clientes_{dt_ref}.csv'
    salvar_dados_csv(df_mudancas, nome_clientes)
    
    # Gerar e salvar vendas
    df_vendas = gerar_vendas_sinteticas(df_mudancas, dt_ref, 2.0)
    nome_vendas = f'vendas_{dt_ref}.csv'
    salvar_dados_csv(df_vendas, nome_vendas)
    
    # Atualizar base para próximo trimestre
    novos_ids = df_mudancas[df_mudancas['id_cliente'] > df_base['id_cliente'].max()]
    df_base = pd.concat([df_base, novos_ids], ignore_index=True)

print("\n✅ Dados trimestrais gerados com sucesso!")
```

---

## 🎯 **Integrando com o Pipeline SCD Type 2**

### **Fluxo Completo de Teste:**

```bash
# 1. Gerar dados sintéticos
cd src
python data_generator.py

# 2. Iniciar PostgreSQL
docker-compose up -d

# 3. Executar notebook SCD Type 2
jupyter lab notebooks/scd_type2_tutorial.ipynb

# 4. Carregar dados gerados no staging
# (usar funções do notebook para inserir CSVs)

# 5. Processar SCD Type 2 para cada data
# (executar pipeline para cada dt_processamento)
```

### **Carregar Dados no PostgreSQL:**

```python
# No notebook Jupyter
import pandas as pd

# Carregar CSV gerado
df_clientes = pd.read_csv('../data/clientes_2024-10-15.csv')

# Inserir no staging
for _, row in df_clientes.iterrows():
    params = {
        'id_cliente': row['id_cliente'],
        'nm_cliente': row['nm_cliente'],
        'ds_email': row['ds_email'],
        'cidade': row['cidade'],
        'uf': row['uf'],
        'telefone': row['telefone'],
        'dt_nascimento': row['dt_nascimento'],
        'dt_processamento': row['dt_processamento']
    }
    
    execute_query("""
        INSERT INTO staging.clientes_source 
        (id_cliente, nm_cliente, ds_email, cidade, uf, telefone, dt_nascimento, dt_processamento)
        VALUES (:id_cliente, :nm_cliente, :ds_email, :cidade, :uf, :telefone, :dt_nascimento, :dt_processamento)
    """, params)

# Processar SCD Type 2
relatorio = processar_scd2_completo('2024-10-15')
```

---

## ✅ **Validação do Data Generator**

### **Status: ✅ FUNCIONANDO PERFEITAMENTE**

**Teste Executado:**
```bash
cd src
python data_generator.py
```

**Resultado:**
- ✅ 50 clientes iniciais gerados
- ✅ 4 lotes de mudanças processados
- ✅ Vendas sintéticas criadas
- ✅ 9 arquivos CSV salvos em `data/`

**Arquivos Gerados:**
```
data/
├── clientes_inicial_2024-10-01.csv    # 50 clientes base
├── clientes_2024-10-15.csv            # 54 clientes (12 mudanças + 35 sem mudança + 7 novos)
├── clientes_2024-10-30.csv            # 61 clientes
├── clientes_2024-11-15.csv            # 70 clientes  
├── clientes_2024-11-30.csv            # 80 clientes
├── vendas_2024-10-15.csv              # 37 transações
├── vendas_2024-10-30.csv              # 82 transações
├── vendas_2024-11-15.csv              # 65 transações
└── vendas_2024-11-30.csv              # 120 transações
```

**Qualidade dos Dados:**
- ✅ Nomes brasileiros realistas (Faker pt_BR)
- ✅ Emails válidos
- ✅ Cidades e UFs brasileiras
- ✅ Telefones formatados
- ✅ Datas de nascimento consistentes
- ✅ Mudanças graduais e realistas

---

## 🛠️ **Troubleshooting**

### **Erro: ModuleNotFoundError: No module named 'faker'**
```bash
# Solução: Instalar Faker
pip install faker

# Ou usar requirements.txt atualizado
pip install -r requirements.txt
```

### **Erro: Pasta data/ não existe**
```bash
# Solução: O script cria automaticamente
# Ou criar manualmente:
mkdir data
```

### **Customizar dados:**
```python
# Editar configurações no script:
fake = Faker('en_US')  # Para dados em inglês
fake.seed(123)         # Para resultados diferentes
```

---

## 🎉 **Conclusão**

O `data_generator.py` é uma **ferramenta poderosa** para:

- ✅ **Testar SCD Type 2** com dados realistas
- ✅ **Simular cenários** diversos de mudanças
- ✅ **Validar pipeline ETL** antes da produção
- ✅ **Demonstrar conceitos** para aprendizado
- ✅ **Gerar volume** para testes de performance

**🚀 Use este gerador para explorar todos os aspectos do SCD Type 2 com dados seguros e realistas!**