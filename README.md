<p align="center"><img src="https://emissaoja.com.br/icone-192.png" width="72" alt="emissaoja"></p>

# API de NFS-e nacional sem certificado digital (emissaoja)

A **API do [emissaoja](https://emissaoja.com.br)** emite **NFS-e (Nota Fiscal de Serviço eletrônica) no Emissor Nacional** (nfse.gov.br) a partir do seu sistema, com o CNPJ e a senha do portal da empresa, **sem certificado digital**, para **MEI e empresas do Simples Nacional**. Você cadastra a empresa uma vez, cria tomadores pelo CNPJ, emite com uma chave de idempotência, acompanha a autorização e baixa o **PDF (DANFSe) e o XML**.

Este repositório reúne o que é público da API: a especificação **[OpenAPI 3.1](openapi/openapi.json)** (sincronizada toda semana com a produção), a **[coleção do Postman](postman/emissaoja.postman_collection.json)**, exemplos em [curl](exemplos/emitir-nfse-sandbox.sh) e em [arquivo .http](exemplos/emissaoja.http), e os links para as bibliotecas oficiais.

| | |
| --- | --- |
| Documentação | [emissaoja.com.br/docs](https://emissaoja.com.br/docs/) · [Markdown](https://emissaoja.com.br/docs.md) · [llms.txt](https://emissaoja.com.br/llms.txt) |
| OpenAPI | [`https://emissaoja.com.br/v1/openapi.json`](https://emissaoja.com.br/v1/openapi.json) |
| Produção | `https://emissaoja.com.br` (chaves `ej_live_`) |
| Sandbox | `https://sandbox.emissaoja.com.br` (Emissor Nacional simulado, chaves `ej_test_`, grátis) |
| Autenticação | `Authorization: Bearer <chave>` (crie em Conta → API) |
| MCP | `https://emissaoja.com.br/mcp` ([emissaoja-mcp](https://github.com/Easymovel/emissaoja-mcp)) |
| Status | [`/v1/status`](https://emissaoja.com.br/v1/status) |

## Bibliotecas oficiais

| Linguagem | Instalação | Repositório |
| --- | --- | --- |
| Node.js / TypeScript | `npm install emissaoja` | [emissaoja-js](https://github.com/Easymovel/emissaoja-js) |
| Python | `pip install emissaoja` | [emissaoja-py](https://github.com/Easymovel/emissaoja-py) |
| PHP / Laravel | `composer require emissaoja/emissaoja` | [emissaoja-php](https://github.com/Easymovel/emissaoja-php) |
| .NET (C#) | `dotnet add package Emissaoja` | [emissaoja-dotnet](https://github.com/Easymovel/emissaoja-dotnet) |
| Go | `go get emissaoja.com.br/go` | [emissaoja-go](https://github.com/Easymovel/emissaoja-go) |
| Ruby / Rails | `gem install emissaoja` | [emissaoja-ruby](https://github.com/Easymovel/emissaoja-ruby) |
| n8n | Community node `n8n-nodes-emissaoja` | [n8n-nodes-emissaoja](https://github.com/Easymovel/n8n-nodes-emissaoja) |
| WordPress / WooCommerce | Plugin `emissaoja-nfse` | [emissaoja-woocommerce](https://github.com/Easymovel/emissaoja-woocommerce) |
| Assistentes de IA | MCP `https://emissaoja.com.br/mcp` | [emissaoja-mcp](https://github.com/Easymovel/emissaoja-mcp) · [Cursor](https://github.com/Easymovel/emissaoja-cursor-plugin) |

## Em 5 minutos, no sandbox

1. Entre em [sandbox.emissaoja.com.br](https://sandbox.emissaoja.com.br) com o Google e crie uma chave em **Conta → API** (começa com `ej_test_`).
2. Conecte a empresa de exemplo e emita:

```bash
export EMISSAOJA_KEY=ej_test_...
BASE=https://sandbox.emissaoja.com.br

# Conectar a empresa (MEI de exemplo; no sandbox qualquer senha serve)
curl -X PUT $BASE/v1/empresa/credencial -H "Authorization: Bearer $EMISSAOJA_KEY" \
  -H "Content-Type: application/json" -d '{"cnpj":"11111111000191","senha":"senha-de-teste"}'

# Tomador pelo CNPJ (nome e endereço vêm da Receita Federal)
curl -X POST $BASE/v1/tomadores -H "Authorization: Bearer $EMISSAOJA_KEY" \
  -H "Content-Type: application/json" -d '{"documento":"12345678000195"}'

# Emitir: a Idempotency-Key é o seu id da nota (repetir nunca emite duas vezes)
curl -X POST $BASE/v1/notas -H "Authorization: Bearer $EMISSAOJA_KEY" \
  -H "Idempotency-Key: pedido-2026-11-0001" -H "Content-Type: application/json" \
  -d '{"tomador_tipo":"pj","tomador_id":"<id do tomador>","valor":150,"descricao":"Consultoria"}'

# Acompanhar até autorizada | recusada | incerta (respeite proxima_consulta_ms)
curl $BASE/v1/emissoes/<id do pedido> -H "Authorization: Bearer $EMISSAOJA_KEY"
```

O roteiro inteiro, com espera e download do PDF e do XML, está em [`exemplos/emitir-nfse-sandbox.sh`](exemplos/emitir-nfse-sandbox.sh). Valores com significado no sandbox: `13.13` → nota incerta (resolva com `POST /v1/emissoes/{id}/conferir`), `77.77` → incerta que não saiu, `99.99` → recusada.

## Postman

Importe [`postman/emissaoja.postman_collection.json`](postman/emissaoja.postman_collection.json) (35 requisições, por pasta: Empresa, Tomadores, Serviços, Notas, Emissões, CNPJ). Preencha a variável `apiKey`; `baseUrl` começa no sandbox. Insomnia, Bruno e Hoppscotch importam o [OpenAPI](openapi/openapi.json) direto.

## Como a API funciona

- **Empresa:** `PUT /v1/empresa/credencial` com CNPJ e senha do Emissor Nacional. O emissaoja confere a senha no portal, lê o cadastro fiscal e traz as notas dos últimos 90 dias. O que o cadastro não responde (como a alíquota do Simples de uma ME) aparece em `GET /v1/empresa/onboarding`.
- **Emissão assíncrona:** `POST /v1/notas` devolve `202` com o `pedido`; o estado anda `na_fila → emitindo → confirmando → autorizada | recusada | incerta`. A resposta traz `proxima_consulta_ms`.
- **Idempotência:** `Idempotency-Key` obrigatório. Repetir devolve o mesmo pedido; nota igual no mesmo dia volta `409 possivel_duplicada`.
- **Erros:** sempre `{ "status": "ERROR", "code": "...", "message": "..." }`; decida pelo `code`. `422 nota_bloqueada` traz `bloqueios[]` com a ação de cada um.
- **Limites:** 60 chamadas por minuto por chave, 10 emissões por minuto. O plano Grátis emite 1 nota por mês; planos em [emissaoja.com.br/#precos](https://emissaoja.com.br/#precos).
- **Público:** MEI, ME e EPP optantes pelo Simples Nacional, em município que emite pelo Emissor Nacional.

## Perguntas frequentes

**Precisa de certificado digital?** Não. O emissaoja usa o acesso por CNPJ e senha que o Emissor Nacional oferece a MEI e empresas do Simples Nacional.

**O que é a NFS-e nacional?** É o padrão único de Nota Fiscal de Serviço eletrônica, emitido pelo Emissor Nacional e guardado no Ambiente de Dados Nacional (ADN), que substitui os sistemas próprios das prefeituras aderentes. Mais em [emissaoja.com.br/api-nfse-nacional](https://emissaoja.com.br/api-nfse-nacional).

**Tem webhook?** Ainda não; acompanhe o pedido em `GET /v1/emissoes/{id}`.

**Dá para emitir pelo ChatGPT ou pelo Claude?** Sim, pelo servidor MCP: [emissaoja.com.br/emitir-nota-fiscal-por-ia](https://emissaoja.com.br/emitir-nota-fiscal-por-ia).

## In English

Public resources for the [emissaoja API](https://emissaoja.com.br/docs/), which issues Brazilian **NFS-e** (electronic service invoices) through the national **Emissor Nacional** without a digital certificate, for MEI and Simples Nacional companies: OpenAPI 3.1 spec (synced weekly), Postman collection, curl and `.http` examples, official SDKs (Node.js, Python, PHP, .NET, Go, Ruby), an n8n node, a WooCommerce plugin and a remote MCP server. Free sandbox with a simulated tax authority.

---

Suporte: [suporte@emissaoja.com.br](mailto:suporte@emissaoja.com.br) · [Termos](https://emissaoja.com.br/termos/) · [Privacidade](https://emissaoja.com.br/privacidade/) · Licença MIT (exemplos e coleção), © 2026 BINOBO LTDA.

O emissaoja é um serviço privado e não tem vínculo com a Receita Federal nem com o Emissor Nacional.
