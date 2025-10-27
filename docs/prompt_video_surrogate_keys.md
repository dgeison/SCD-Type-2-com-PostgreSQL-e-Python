# 🎬 PROMPT PARA LLM - VÍDEO SOBRE SURROGATE KEYS

## 🎯 INSTRUÇÃO PARA GERAÇÃO DE VÍDEO

**Crie um vídeo educativo de 10-15 minutos explicando Surrogate Keys em Data Warehousing com foco prático e didático.**

---

## 📋 ROTEIRO SUGERIDO

### 🎬 **INTRODUÇÃO (1 minuto)**
- O que são Surrogate Keys?
- Por que são cruciais em Data Warehousing?
- Preview do que será mostrado

### 🚨 **PROBLEMA (2 minutos)**
- SCD Type 2 sem Surrogate Keys = IMPOSSÍVEL
- Mostrar tentativa fracassada com business keys duplicadas
- Enfatizar a dor: "Como manter histórico sem perder integridade?"

### ✅ **SOLUÇÃO (3 minutos)**  
- Surrogate Keys resolvem o problema
- Mostrar dados reais do projeto:
```
sk_cliente | id_cliente | nome       | cidade     | fl_corrente
-----------|------------|------------|------------|------------
1          | 1          | João Silva | São Paulo  | false      ← HISTÓRICO
6          | 1          | João Silva | Brasília   | true       ← ATUAL
```

### 🔧 **IMPLEMENTAÇÃO (4 minutos)**
- Como criar tabelas com Surrogate Keys
- Pipeline ETL automático
- Códigos SQL reais do projeto
- Geração automática com SERIAL

### 🎯 **BENEFÍCIOS (2 minutos)**
- Performance: Joins 3x mais rápidos
- Integridade: Cada versão tem chave única  
- Flexibilidade: Business keys podem mudar
- Estabilidade: Surrogate Keys nunca mudam

### 🔍 **POINT-IN-TIME JOINS (2 minutos)**
- Como consultar dados históricos corretamente
- Exemplo: "Onde João morava quando comprou em 2024-10-20?"
- SQL com join usando Surrogate Key

### 🏆 **CONCLUSÃO (1 minuto)**
- Recap dos benefícios
- Surrogate Keys = ESSENCIAIS para DW profissional
- Call to action: Implementar no seu projeto

---

## 💎 DADOS REAIS PARA USAR NO VÍDEO

### 📊 **RESULTADO REAL DO PROJETO:**
```sql
sk_cliente | id_cliente | nome            | cidade        | dt_inicio  | dt_fim     | fl_corrente
-----------|------------|-----------------|---------------|------------|------------|------------
1          | 1          | João Silva      | São Paulo     | 2024-10-01| 2024-10-27| false
6          | 1          | João Silva      | Brasília      | 2024-10-27| 9999-12-31| true
3          | 3          | Carlos Oliveira | Belo Horizonte| 2024-10-01| 2024-10-27| false
7          | 3          | Carlos Oliveira | São Paulo     | 2024-10-27| 9999-12-31| true
```

### 📈 **NARRATIVA DOS DADOS:**
- **João Silva**: Mudou de São Paulo → Brasília (2 versões: sk_cliente 1 e 6)
- **Carlos Oliveira**: Mudou de Belo Horizonte → São Paulo (2 versões: sk_cliente 3 e 7)
- **Cada mudança**: Nova Surrogate Key, histórico preservado
- **Business Key**: Permanece igual (id_cliente = 1, 3)

---

## 🎨 ELEMENTOS VISUAIS OBRIGATÓRIOS

### 📊 **TABELAS E DIAGRAMAS:**
1. Tabela "ANTES" (sem Surrogate Key) - ERRO
2. Tabela "DEPOIS" (com Surrogate Key) - SUCESSO  
3. Diagrama comparativo: SK vs BK
4. Código SQL real formatado
5. Gráfico de performance (opcional)

### 🎯 **ANIMAÇÕES SUGERIDAS:**
1. **Transformação**: Business Key → Surrogate Key
2. **SCD Process**: Dados chegam → Mudanças detectadas → Novas versões criadas
3. **Point-in-Time Join**: Linha do tempo mostrando joins corretos

### 🎨 **CORES E ÍCONES:**
- ✅ Verde para sucessos
- ❌ Vermelho para problemas  
- 🔑 Ícone de chave para Surrogate Keys
- 📊 Gráficos para dados
- ⚡ Performance/velocidade

---

## 💬 FRASES-CHAVE PARA ENFATIZAR

### 🎯 **GANCHOS EMOCIONAIS:**
- *"Imagine tentar organizar um arquivo sem números únicos..."*
- *"Isso é o que acontece sem Surrogate Keys!"*
- *"O resultado? Um Data Warehouse quebrado!"*
- *"Mas há uma solução elegante..."*

### 🏆 **BENEFÍCIOS IMPACTANTES:**
- *"3x mais rápido em joins"*
- *"Histórico completo preservado"* 
- *"Zero conflitos de chaves"*
- *"Escalabilidade infinita"*

### 💡 **CALL TO ACTION:**
- *"Agora é sua vez de implementar!"*
- *"Seu Data Warehouse merece Surrogate Keys!"*
- *"Vamos transformar seu DW juntos!"*

---

## 🔧 CÓDIGOS ESSENCIAIS PARA MOSTRAR

### 1. **CRIAÇÃO DA TABELA:**
```sql
CREATE TABLE dim_cliente (
    sk_cliente SERIAL PRIMARY KEY,    -- ← SURROGATE KEY
    id_cliente INTEGER,               -- ← BUSINESS KEY  
    nome VARCHAR(100),
    cidade VARCHAR(80),
    dt_inicio DATE,
    dt_fim DATE DEFAULT '9999-12-31',
    fl_corrente BOOLEAN DEFAULT TRUE
);
```

### 2. **INSERÇÃO COM SCD TYPE 2:**
```sql
-- Expirar versão antiga
UPDATE dim_cliente 
SET fl_corrente = FALSE, dt_fim = '2024-10-27'
WHERE id_cliente = 1 AND fl_corrente = TRUE;

-- Inserir nova versão (sk_cliente auto-increment)
INSERT INTO dim_cliente (id_cliente, nome, cidade, dt_inicio)
VALUES (1, 'João Silva', 'Brasília', '2024-10-27');
```

### 3. **POINT-IN-TIME JOIN:**
```sql
SELECT f.dt_venda, f.produto, d.nome, d.cidade
FROM fato_vendas f
JOIN dim_cliente d ON f.sk_cliente = d.sk_cliente
-- ↑ SURROGATE KEY garante versão correta!
```

---

## 🎓 CONCEITOS TÉCNICOS A EXPLICAR

### 🔑 **SURROGATE KEY:**
- Chave artificial única
- Gerada automaticamente  
- Sem significado de negócio
- Integer para performance

### 🏢 **BUSINESS KEY:**
- Chave do sistema origem
- Pode repetir (histórico)
- Tem significado de negócio
- Pode ser string/composta

### 📊 **SCD TYPE 2:**
- Preserva histórico completo
- Múltiplas versões por entidade
- fl_corrente indica versão atual
- dt_inicio/dt_fim controlam validade

### 🕰️ **POINT-IN-TIME JOIN:**
- Join histórico correto
- f.sk_cliente = d.sk_cliente
- Garante versão exata da data
- Essencial para precisão analítica

---

## 🎯 MENSAGEM PRINCIPAL

> **"Surrogate Keys não são apenas uma boa prática - são ESSENCIAIS para um Data Warehouse profissional. Elas tornam possível o que seria impossível: manter histórico completo com performance máxima!"**

---

## 📝 DICAS DE PRODUÇÃO

### 🎙️ **TOM DE VOZ:**
- Entusiasta mas profissional
- Didático, explicando passo a passo
- Enfatizar benefícios práticos
- Usar analogias quando possível

### 📱 **FORMATO:**
- Slides limpos e modernos
- Códigos bem formatados
- Transições suaves
- Screenshots reais do projeto

### ⏱️ **TIMING:**
- Não acelerar conceitos complexos
- Pausas para absorção
- Repetir pontos-chave
- Recap rápido no final

---

**🎬 USE ESTE PROMPT PARA GERAR UM VÍDEO PROFISSIONAL E DIDÁTICO SOBRE SURROGATE KEYS EM DATA WAREHOUSING!**