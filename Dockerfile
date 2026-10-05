# --- Estágio 1: Builder ---
FROM python:3.12-slim AS builder

WORKDIR /app

# Cria um ambiente virtual para isolar as dependências
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# --- Estágio 2: Imagem Final ---
FROM python:3.12-slim

WORKDIR /app

# Copia o ambiente virtual com as dependências do estágio builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copia o código da aplicação
COPY . .

# Cria usuário não-root e concede permissão na pasta para escrita do SQLite (loja.db)
RUN adduser --disabled-password --gecos "" appuser && \
    chown -R appuser:appuser /app

USER appuser

EXPOSE 8000

# HEALTHCHECK usando o próprio Python (evita instalar curl)
HEALTHCHECK --interval=5s --timeout=3s --start-period=5s --retries=3 \
  CMD python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')" || exit 1

# CMD no formato exec (array) para sinalizar o SIGTERM corretamente ao Uvicorn
CMD ["uvicorn", "app:api", "--host", "0.0.0.0", "--port", "8000"]
