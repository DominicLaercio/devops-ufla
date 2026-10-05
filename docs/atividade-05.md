# Atividade 05 — Orquestração Multicontainer com Docker Compose e GHCR

## 1. Saída do `docker compose ps`

```text
NAME                  IMAGE                                           COMMAND                  SERVICE   CREATED          STATUS                    PORTS
devops-ufla-api-1     ghcr.io/dominiclaercio/ufla-devops-shop:v1.0.0  "uvicorn app:api --h…"   api       16 minutes ago   Up 16 minutes (healthy)   8000/tcp
devops-ufla-banco-1   postgres:16-alpine                              "docker-entrypoint.s…"   banco     16 minutes ago   Up 16 minutes (healthy)   5432/tcp
devops-ufla-cache-1   redis:7-alpine                                  "docker-entrypoint.s…"   cache     16 minutes ago   Up 16 minutes (healthy)   6379/tcp
devops-ufla-nginx-1   nginx:1.27-alpine                               "/docker-entrypoint.…"   nginx     16 minutes ago   Up 16 minutes             0.0.0.0:80->80/tcp, [::]:80->80/tcp
```

## 2. Teste de Persistência de Dados

### POST (Cadastro de Produto)
```bash
$ curl -s -X POST http://localhost/api/produtos -H 'Content-Type: application/json' \
  -d '{"nome":"Prova de persistencia","preco":9.9,"estoque":1}'
{"id":14,"nome":"Prova de persistencia","descricao":"","preco":9.9,"estoque":1,"criado_em":"2026-10-05T07:32:20.604839+00:00"}
```

### Down e Up da Stack
```bash
$ docker compose down
[+] down 5/5
 ✔ Container devops-ufla-nginx-1 Removed                                                                                                                                              3.6s
 ✔ Container devops-ufla-api-1   Removed                                                                                                                                              3.7s
 ✔ Container devops-ufla-banco-1 Removed                                                                                                                                              9.5s
 ✔ Container devops-ufla-cache-1 Removed                                                                                                                                              7.4s
 ✔ Network devops-ufla_default   Removed                                                                                                                                              0.9s

$ docker compose up -d --wait
[+] up 5/5
 ✔ Network devops-ufla_default   Created                                                                                                                                              0.7s
 ✔ Container devops-ufla-banco-1 Healthy                                                                                                                                             21.8s
 ✔ Container devops-ufla-cache-1 Healthy                                                                                                                                             21.8s
 ✔ Container devops-ufla-api-1   Healthy                                                                                                                                             21.5s
 ✔ Container devops-ufla-nginx-1 Healthy                                                                                                                                             15.9s
```

### GET (Validação de Persistência)
```bash
$ curl -s 'http://localhost/api/busca?q=persistencia'
{"termo":"persistencia","total":2,"resultados":[{"id":13,"nome":"Prova de persistencia","descricao":"","preco":9.9,"estoque":1,"criado_em":"2026-10-05T07:14:16.122469+00:00"},{"id":14,"nome":"Prova de persistencia","descricao":"","preco":9.9,"estoque":1,"criado_em":"2026-10-05T07:32:20.604839+00:00"}]}
```

## 3. Endereço Público da Imagem no GHCR

* `ghcr.io/dominiclaercio/ufla-devops-shop:v1.0.0`

## 4. Pergunta Teórica: `depends_on` vs `service_healthy`

O `depends_on` isolado garante apenas a ordem de inicialização dos containers, disparando o container da API assim que os containers do banco de dados e cache iniciam a execução no sistema operacional. No entanto, o serviço de banco de dados leva alguns segundos adicionais para inicializar suas tabelas e aceitar conexões de rede, gerando falhas de *connection refused* caso a API tente conectar imediatamente. O uso do parâmetro `condition: service_healthy` resolve o problema pois condiciona o início da API à aprovação prévia das verificações de saúde (`healthcheck` com `pg_isready` e `redis-cli ping`), garantindo que a infraestrutura subjacente esteja pronta para receber conexões.
