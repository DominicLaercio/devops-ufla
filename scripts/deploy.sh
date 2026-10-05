#!/usr/bin/env bash
set -euo pipefail

echo "=== [1/6] Criando usuário de sistema ufla-shop ==="
if ! id ufla-shop &>/dev/null; then
    useradd --system --no-create-home --shell /bin/false ufla-shop
    echo "Usuário ufla-shop criado com sucesso."
else
    echo "Usuário ufla-shop já existe. Pulando."
fi

echo "=== [2/6] Sincronizando código e configurando ambiente virtual ==="
mkdir -p /opt/ufla-shop

# Copia arquivos do repositório para o diretório de produção
cp -r . /opt/ufla-shop/

# Garante a posse inicial para a criação do venv
chown -R ufla-shop:ufla-shop /opt/ufla-shop

# Cria o virtualenv se não existir
if [ ! -d "/opt/ufla-shop/.venv" ]; then
    python3 -m venv /opt/ufla-shop/.venv
fi

# Instala dependências usando o pip do ambiente virtual
/opt/ufla-shop/.venv/bin/pip install -q --upgrade pip
/opt/ufla-shop/.venv/bin/pip install -q -r /opt/ufla-shop/requirements.txt

# --- AJUSTE DE PERMISSÕES IDEMPOTENTE (Garante execução do uvicorn) ---
# Dá permissão de leitura/execução pública no diretório pai /opt e /opt/ufla-shop
chmod 755 /opt
chmod 755 /opt/ufla-shop

# Ajusta o proprietário de todos os arquivos para ufla-shop
chown -R ufla-shop:ufla-shop /opt/ufla-shop

# Garante permissão de execução explícita nos binários do venv
chmod -R 755 /opt/ufla-shop/.venv/bin/

echo "=== [3/6] Configurando arquivo de ambiente (/etc/ufla-shop.env) ==="
if [ ! -f /etc/ufla-shop.env ]; then
    echo "DATABASE_URL=postgresql://loja:loja@localhost:5432/loja" > /etc/ufla-shop.env
    echo "REDIS_URL=redis://localhost:6379/0" >> /etc/ufla-shop.env
    chown ufla-shop:ufla-shop /etc/ufla-shop.env
    chmod 600 /etc/ufla-shop.env
    echo "Arquivo /etc/ufla-shop.env criado."
else
    echo "Arquivo /etc/ufla-shop.env já existe. Pulando."
fi

echo "=== [4/6] Gerando certificado SSL autoassinado ==="
if [ ! -f /etc/ssl/certs/ufla-shop.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/ufla-shop.key \
        -out /etc/ssl/certs/ufla-shop.crt \
        -subj "/CN=localhost" 2>/dev/null
    chmod 600 /etc/ssl/private/ufla-shop.key
    echo "Certificado SSL gerado com sucesso."
else
    echo "Certificado SSL já existente. Pulando."
fi

echo "=== [5/6] Instalando unidades do Systemd e Nginx ==="
cp systemd/ufla-shop.service /etc/systemd/system/
cp systemd/ufla-shop-backup.service /etc/systemd/system/
cp systemd/ufla-shop-backup.timer /etc/systemd/system/

cp nginx/loja.conf /etc/nginx/sites-available/
ln -sf /etc/nginx/sites-available/loja.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

systemctl daemon-reload
systemctl enable ufla-shop.service
systemctl restart ufla-shop.service
systemctl enable --now ufla-shop-backup.timer
systemctl restart nginx

echo "=== [6/6] Executando Healthcheck final ==="
echo "Aguardando inicialização da aplicação em http://localhost:8000/ready..."

HEALTHCHECK_PASSED=0
for i in {1..10}; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/ready || true)
    if [ "$STATUS" -eq 200 ]; then
        echo "Sucesso: Aplicação pronta e respondendo HTTP 200!"
        HEALTHCHECK_PASSED=1
        break
    fi
    echo "Tentativa $i/10: Código HTTP $STATUS. Aguardando 1s..."
    sleep 1
done

if [ $HEALTHCHECK_PASSED -eq 1 ]; then
    exit 0
else
    echo "Erro: Healthcheck falhou após 10 tentativas."
    exit 1
fi
