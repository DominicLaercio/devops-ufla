#!/usr/bin/env bash
set -euo pipefail

# 1. Carrega as variáveis de ambiente do serviço (onde está o DATABASE_URL)
if [ -f /etc/ufla-shop.env ]; then
    # Exporta DATABASE_URL mantendo compatibilidade
    export $(grep -v '^#' /etc/ufla-shop.env | xargs)
fi

BACKUP_DIR="/var/backups/ufla-shop"
TIMESTAMP=$(date +"%Y-%m-%d-%H%M")
BACKUP_FILE="${BACKUP_DIR}/loja-${TIMESTAMP}.sql.gz"

# Garante que o diretório de destino existe
mkdir -p "${BACKUP_DIR}"

# 2. Executa o pg_dump usando a variável DATABASE_URL (sem expor senha em texto no script)
# O pipefail no topo garante que se o pg_dump falhar, o script também falha
pg_dump "${DATABASE_URL}" | gzip > "${BACKUP_FILE}"

# 3. Rotação: Mantém apenas os 7 backups mais recentes e remove os antigos
ls -1t "${BACKUP_DIR}"/loja-*.sql.gz 2>/dev/null | tail -n +8 | xargs -r rm -f

# 4. Registra log no systemd journal
FILE_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
logger -t backup "Backup gerado com sucesso: ${BACKUP_FILE} (Tamanho: ${FILE_SIZE})"

echo "Backup concluído: ${BACKUP_FILE}"
