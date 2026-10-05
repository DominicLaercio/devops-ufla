# Relatório da Atividade 4 - DevOps na Prática

## 1. Comparativo de Tamanho da Imagem

| Versão | Tamanho Descompactado |
| :--- | :--- |
| Primeira Versão (Slim Monestágio) | 69 MB |
| Versão Final (Multi-Stage + Non-Root) | 76 MB |

*(Ambas as versões ficaram consideravelmente abaixo do limite máximo de 150 MB).*

## 2. Mudanças Aplicadas, Análise de Camadas e Otimizações

A primeira versão da aplicação gerou uma imagem de apenas **69 MB**, um valor abaixo do limite máximo de 150 MB exigido. O principal motivo para a imagem inicial ter ficado tão pequena foi a criação antecipada do arquivo `.dockerignore`, que impediu a inclusão de pastas pesadas no contexto de build (como `.venv` local e o diretório `.git`).

### O que mudou e o impacto de cada alteração:

1. **Uso do `.dockerignore` (Maior Economia):**
   - **Economia estimada:** ~100 MB a 300 MB.
   - **Explicação:** Evitou o vazamento da pasta `.venv` local e de caches de desenvolvimento para o contexto da imagem.

2. **Adoção do Multi-Stage Build:**
   - **Diferença de tamanho:** +7 MB (de 69 MB para 76 MB na versão final).
   - **Explicação:** O primeiro estágio (`builder`) isolou a instalação de dependências no diretório `/opt/venv`. O segundo estágio apenas copiou os binários finais. O pequeno acréscimo se deve ao isolamento do ambiente virtual completo e permissões do diretório `/app`.

3. **Criação do Usuário Não-Root (`appuser`) e Permissões:**
   - **Impacto no tamanho:** Negligenciável (~0 MB em camadas de metadados/chown).
   - **Explicação:** Adicionou a camada de segurança para rodar a aplicação sem privilégios de `root`, alterando o dono da pasta `/app` com `chown` para permitir a escrita do banco SQLite (`loja.db`).

4. **Healthcheck nativo com Python (`urllib.request`):**
   - **Economia estimada:** ~10 MB a 15 MB.
   - **Explicação:** Evitou a instalação de pacotes adicionais como o `curl` no sistema base `python:3.12-slim`.

### Inspeção de Camadas (`docker history ufla-shop:1.0`)
A verificação camada por camada via `docker history` confirma a distribuição de espaço da imagem final:
- **Base `python:3.12-slim`:** ~68 MB
- **Cópia do `/opt/venv` (dependências):** ~7.3 MB
- **Código-fonte da aplicação:** < 1 MB

## 3. Saída dos Comandos de Verificação

### Usuário Não-Root (`id -u`)
```bash
$ docker run --rm ufla-shop:1.0 id -u
1000
```

### Status do Healthcheck
```bash
$ sleep 10 && docker inspect --format '{{.State.Health.Status}}' loja
healthy
```

### Tempo de Desligamento (`time docker stop`)
```bash
$ time docker stop loja
loja

real    0m1.948s
user    0m0.007s
sys     0m0.043s
```

## 4. Por que o HEALTHCHECK consulta `/health` e não `/ready`?
O /health verifica apenas se o processo da aplicação está vivo e respondendo internamente, servindo para o Docker saber se o container precisa ser reiniciado. Já o /ready avalia a prontidão para receber tráfego externo (como conexão com banco ou cache), cuja indisponibilidade temporária não deve causar a reinicialização do container.
