# Atividade 03 - Deploy, Backup, Systemd e Nginx

## 1. Como rodar o deploy.sh numa máquina limpa

Para realizar o deploy automatizado da aplicação em um ambiente Linux recém-configurado:

1. Garanta que as dependências do sistema estejam instaladas (Python 3, PostgreSQL, Redis, Nginx e OpenSSL).
2. Clone o repositório e acesse a raiz do projeto:
   ```bash
   git clone <URL_DO_SEU_FORK>
   cd ufla-devops-shop
   ```
3. Garanta permissão de execução no script de deploy e execute-o com privilégios de superusuário:
   ```bash
   chmod +x scripts/deploy.sh
   sudo ./scripts/deploy.sh
   ```

---

## 2. Evidência do Restart Automático do Systemd (Kill -9)

Executado o encerramento forçado do processo uvicorn via `sudo pkill -9 -f uvicorn`. O Systemd detectou a falha e reiniciou a unidade automaticamente com a diretiva `Restart=on-failure`.

Saída do `systemctl status ufla-shop`:

```text
● ufla-shop.service - UFLA DevOps Shop API
     Loaded: loaded (/etc/systemd/system/ufla-shop.service; enabled; preset: enabled)
     Active: active (running) since Sun 2026-10-04 20:55:15 -03; 1s ago
 Invocation: 7e42fb4053cd42c19d03c5d28e153256
   Main PID: 6217 (uvicorn)
      Tasks: 1 (limit: 9486)
     Memory: 33.4M (peak: 33.4M)
        CPU: 380ms
     CGroup: /system.slice/ufla-shop.service
             └─6217 /home/dominic/devops/devops-ufla/.venv/bin/python3 /opt/ufla-shop/.venv/bin/uvicorn app:api --host 127.0.0.1 --port 8000

Oct 04 20:55:11 Dominic-Desktop systemd[1]: ufla-shop.service: Failed with result 'signal'.
Oct 04 20:55:11 Dominic-Desktop systemd[1]: ufla-shop.service: Consumed 2.272s CPU time over 11min 10.343s wall clock time, 53.7M memory peak
Oct 04 20:55:15 Dominic-Desktop systemd[1]: ufla-shop.service: Scheduled restart job, restart counter is at 1.
Oct 04 20:55:15 Dominic-Desktop systemd[1]: Started ufla-shop.service - UFLA DevOps Shop API.
```

---

## 3. Evidência do Proxy Reverso Nginx (HTTP e HTTPS)

### Redirecionamento HTTP -> HTTPS (Porta 80)
Saída do comando `curl -I http://localhost`:

```http
HTTP/1.1 301 Moved Permanently
Server: nginx/1.28.3 (Ubuntu)
Date: Sun, 04 Oct 2026 23:57:31 GMT
Content-Type: text/html
Content-Length: 178
Connection: keep-alive
Location: https://localhost/
```

### Requisição com TLS Ativo (Porta 443)
Saída do comando `curl -ki https://localhost/ready`:

```http
HTTP/1.1 200 OK
Server: nginx/1.28.3 (Ubuntu)
Date: Sun, 04 Oct 2026 23:59:45 GMT
Content-Type: application/json
Content-Length: 42
Connection: keep-alive

{"status":"ok","banco":"ok","cache":"ok"}
```

---

## 4. Evidência dos Backups e Rotação em /var/backups/ufla-shop

Saída do comando `ls -la /var/backups/ufla-shop` após a execução do `backup.sh`:

```text
total 16
drwxrwxrwx 2 dominic  dominic  4096 Oct  4 21:12 .
drwxr-xr-x 3 root     root     4096 Oct  4 19:34 ..
-rw-r--r-- 1 postgres postgres 1622 Oct  4 19:51 loja-2026-10-04-1951.sql.gz
-rw-r--r-- 1 root     root     1624 Oct  4 21:12 loja-2026-10-04-2112.sql.gz
```

---

## 5. Prova de Idempotência do deploy.sh

Últimas linhas da segunda execução consecutiva do script `./scripts/deploy.sh`:

```text
=== [5/6] Instalando unidades do Systemd e Nginx ===
=== [6/6] Executando Healthcheck final ===
Aguardando inicialização da aplicação em http://localhost:8000/ready...
Sucesso: Aplicação pronta e respondendo HTTP 200!
```
