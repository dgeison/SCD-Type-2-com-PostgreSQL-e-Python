"""
Gerador de dados sintéticos para testes de SCD Type 2
=======================================================

Este script gera dados fictícios de clientes para testar
o pipeline SCD Type 2 com diferentes cenários.
"""

import pandas as pd
import numpy as np
from faker import Faker
from datetime import datetime, timedelta
import random
import os
import sys

# Adicionar o diretório pai ao path para importar módulos
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Configurar Faker para português brasileiro
fake = Faker('pt_BR')
Faker.seed(42)  # Para resultados reproduzíveis

def gerar_clientes_iniciais(n_clientes=100):
    """
    Gera dados iniciais de clientes para a primeira carga
    """
    clientes = []
    
    for i in range(1, n_clientes + 1):
        cliente = {
            'id_cliente': i,
            'nm_cliente': fake.name(),
            'ds_email': fake.email(),
            'cidade': fake.city(),
            'uf': fake.state_abbr(),
            'telefone': fake.phone_number()[:20],  # Limitar tamanho
            'dt_nascimento': fake.date_of_birth(minimum_age=18, maximum_age=80),
            'dt_processamento': '2024-10-01'
        }
        clientes.append(cliente)
    
    return pd.DataFrame(clientes)

def gerar_mudancas_clientes(df_base, dt_processamento, pct_mudanca=0.3, pct_novos=0.1):
    """
    Gera mudanças nos clientes existentes + novos clientes
    
    Args:
        df_base: DataFrame com clientes base
        dt_processamento: Data do processamento
        pct_mudanca: Percentual de clientes que vão ter mudanças
        pct_novos: Percentual de novos clientes em relação à base
    """
    
    # 1. Selecionar clientes que terão mudanças
    n_mudancas = int(len(df_base) * pct_mudanca)
    clientes_mudanca = df_base.sample(n=n_mudancas, random_state=42).copy()
    
    # 2. Aplicar mudanças aleatórias
    for idx, row in clientes_mudanca.iterrows():
        tipo_mudanca = random.choice(['cidade', 'email', 'telefone', 'nome', 'multiplas'])
        
        if tipo_mudanca == 'cidade':
            clientes_mudanca.loc[idx, 'cidade'] = fake.city()
            clientes_mudanca.loc[idx, 'uf'] = fake.state_abbr()
        
        elif tipo_mudanca == 'email':
            # Manter mesmo domínio às vezes
            if random.random() < 0.5:
                nome_usuario = row['nm_cliente'].lower().replace(' ', '.')
                dominio = row['ds_email'].split('@')[1]
                clientes_mudanca.loc[idx, 'ds_email'] = f"{nome_usuario}@{dominio}"
            else:
                clientes_mudanca.loc[idx, 'ds_email'] = fake.email()
        
        elif tipo_mudanca == 'telefone':
            clientes_mudanca.loc[idx, 'telefone'] = fake.phone_number()[:20]
        
        elif tipo_mudanca == 'nome':
            # Simular mudança de nome (casamento, etc.)
            clientes_mudanca.loc[idx, 'nm_cliente'] = fake.name()
        
        elif tipo_mudanca == 'multiplas':
            # Mudanças múltiplas (mudança de estado, por exemplo)
            clientes_mudanca.loc[idx, 'cidade'] = fake.city()
            clientes_mudanca.loc[idx, 'uf'] = fake.state_abbr()
            clientes_mudanca.loc[idx, 'telefone'] = fake.phone_number()[:20]
            if random.random() < 0.3:  # 30% chance de mudar email também
                clientes_mudanca.loc[idx, 'ds_email'] = fake.email()
    
    # 3. Clientes sem mudança (amostra aleatória dos restantes)
    clientes_sem_mudanca = df_base[~df_base['id_cliente'].isin(clientes_mudanca['id_cliente'])].copy()
    
    # Selecionar apenas uma porção dos clientes sem mudança (simular clientes que "aparecem" nos dados)
    if len(clientes_sem_mudanca) > 0:
        n_sem_mudanca = min(len(clientes_sem_mudanca), int(len(df_base) * 0.7))
        clientes_sem_mudanca = clientes_sem_mudanca.sample(n=n_sem_mudanca, random_state=42)
    
    # 4. Gerar novos clientes
    n_novos = int(len(df_base) * pct_novos)
    max_id_existente = df_base['id_cliente'].max()
    
    novos_clientes = []
    for i in range(1, n_novos + 1):
        cliente = {
            'id_cliente': max_id_existente + i,
            'nm_cliente': fake.name(),
            'ds_email': fake.email(),
            'cidade': fake.city(),
            'uf': fake.state_abbr(),
            'telefone': fake.phone_number()[:20],
            'dt_nascimento': fake.date_of_birth(minimum_age=18, maximum_age=80),
            'dt_processamento': dt_processamento
        }
        novos_clientes.append(cliente)
    
    df_novos = pd.DataFrame(novos_clientes)
    
    # 5. Combinar tudo
    clientes_mudanca['dt_processamento'] = dt_processamento
    clientes_sem_mudanca['dt_processamento'] = dt_processamento
    
    df_final = pd.concat([clientes_mudanca, clientes_sem_mudanca, df_novos], ignore_index=True)
    
    print(f"📊 Dados gerados para {dt_processamento}:")
    print(f"   🔄 Clientes com mudança: {len(clientes_mudanca)}")
    print(f"   ➡️  Clientes sem mudança: {len(clientes_sem_mudanca)}")
    print(f"   🆕 Novos clientes: {len(df_novos)}")
    print(f"   📋 Total: {len(df_final)}")
    
    return df_final

def gerar_vendas_sinteticas(df_clientes, dt_ref, n_vendas_por_cliente=None):
    """
    Gera vendas sintéticas para os clientes
    
    Args:
        df_clientes: DataFrame com clientes
        dt_ref: Data de referência
        n_vendas_por_cliente: Número médio de vendas por cliente
    """
    
    if n_vendas_por_cliente is None:
        n_vendas_por_cliente = random.uniform(0.5, 2.0)  # Entre 0.5 e 2 vendas por cliente em média
    
    vendas = []
    produtos = [
        'Notebook Dell', 'Mouse Logitech', 'Teclado Mecânico', 'Monitor 24"',
        'Smartphone Samsung', 'Tablet iPad', 'Fone Bluetooth', 'Webcam HD',
        'Impressora HP', 'HD Externo', 'Pen Drive', 'Cabo HDMI'
    ]
    
    for _, cliente in df_clientes.iterrows():
        # Cada cliente tem uma chance de fazer compras
        n_compras = np.random.poisson(n_vendas_por_cliente)
        
        for _ in range(n_compras):
            # Data da venda entre dt_ref - 30 dias e dt_ref
            dt_ref_date = datetime.strptime(dt_ref, '%Y-%m-%d')
            dt_venda = fake.date_between(
                start_date=dt_ref_date - timedelta(days=30),
                end_date=dt_ref_date
            )
            
            produto = random.choice(produtos)
            valor_base = {
                'Notebook Dell': 2500,
                'Mouse Logitech': 150,
                'Teclado Mecânico': 300,
                'Monitor 24"': 800,
                'Smartphone Samsung': 1200,
                'Tablet iPad': 2000,
                'Fone Bluetooth': 250,
                'Webcam HD': 180,
                'Impressora HP': 400,
                'HD Externo': 350,
                'Pen Drive': 50,
                'Cabo HDMI': 30
            }
            
            # Adicionar variação no preço
            valor = valor_base[produto] * random.uniform(0.8, 1.2)
            
            venda = {
                'id_cliente': cliente['id_cliente'],
                'id_produto': hash(produto) % 10000,
                'nm_produto': produto,
                'dt_venda': dt_venda,
                'vl_venda': round(valor, 2),
                'qtd_vendida': random.choice([1, 1, 1, 2, 3]),  # Maioria compra 1 unidade
                'dt_ref': dt_ref
            }
            vendas.append(venda)
    
    df_vendas = pd.DataFrame(vendas)
    print(f"💰 Vendas geradas: {len(df_vendas)} transações")
    
    return df_vendas

def salvar_dados_csv(df, nome_arquivo, diretorio='../data'):
    """Salva DataFrame em CSV"""
    os.makedirs(diretorio, exist_ok=True)
    caminho = os.path.join(diretorio, nome_arquivo)
    df.to_csv(caminho, index=False, encoding='utf-8')
    print(f"💾 Arquivo salvo: {caminho}")

# Exemplo de uso
if __name__ == "__main__":
    print("🎲 GERADOR DE DADOS SINTÉTICOS PARA SCD TYPE 2")
    print("=" * 50)
    
    # 1. Gerar dados iniciais
    print("\n1️⃣ Gerando clientes iniciais...")
    df_inicial = gerar_clientes_iniciais(50)
    salvar_dados_csv(df_inicial, 'clientes_inicial_2024-10-01.csv')
    
    # 2. Simular várias datas de processamento
    datas_processamento = [
        '2024-10-15',
        '2024-10-30', 
        '2024-11-15',
        '2024-11-30'
    ]
    
    df_base = df_inicial.copy()
    
    for dt_proc in datas_processamento:
        print(f"\n📅 Processando {dt_proc}...")
        
        # Gerar mudanças
        df_mudancas = gerar_mudancas_clientes(
            df_base, 
            dt_proc, 
            pct_mudanca=0.25,  # 25% dos clientes mudam
            pct_novos=0.15     # 15% de novos clientes
        )
        
        # Salvar dados
        nome_arquivo = f'clientes_{dt_proc}.csv'
        salvar_dados_csv(df_mudancas, nome_arquivo)
        
        # Gerar vendas
        df_vendas = gerar_vendas_sinteticas(df_mudancas, dt_proc)
        nome_vendas = f'vendas_{dt_proc}.csv'
        salvar_dados_csv(df_vendas, nome_vendas)
        
        # Atualizar base para próxima iteração
        df_base = pd.concat([df_base, df_mudancas[df_mudancas['id_cliente'] > df_base['id_cliente'].max()]], ignore_index=True)
    
    print("\n✅ Geração de dados concluída!")
    print("   Os arquivos CSV estão na pasta 'data/'")
    print("   Use estes dados para testar diferentes cenários de SCD Type 2")