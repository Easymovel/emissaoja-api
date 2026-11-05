// Ajusta a coleção gerada pelo openapi-to-postmanv2: nome, descrição, variáveis baseUrl/apiKey, auth Bearer {{apiKey}},
// sem os exemplos de resposta gerados (aleatórios) e com ids estáveis, para o diff semanal só mostrar mudança real.
const fs = require('fs');
const crypto = require('crypto');
const p = 'postman/emissaoja.postman_collection.json';
const c = JSON.parse(fs.readFileSync(p, 'utf8'));
c.info.name = 'emissaoja API (NFS-e nacional)';
c.info.description = 'Coleção oficial da API do emissaoja: emita NFS-e no Emissor Nacional sem certificado digital, para MEI e Simples Nacional. Defina a variável apiKey com uma chave ej_test_ (sandbox) ou ej_live_ (produção), criada em Conta → API. A variável baseUrl começa no sandbox (https://sandbox.emissaoja.com.br); em produção, use https://emissaoja.com.br. Documentação: https://emissaoja.com.br/docs/';
c.info._postman_id = 'b6f1c0de-5e1a-4c0a-9a0e-3e15a0ca0001';
c.variable = [
  { key: 'baseUrl', value: 'https://sandbox.emissaoja.com.br', type: 'string' },
  { key: 'apiKey', value: '', type: 'string' },
];
c.auth = { type: 'bearer', bearer: [{ key: 'token', value: '{{apiKey}}', type: 'string' }] };
const uuid = (s) => { const h = crypto.createHash('sha1').update(s).digest('hex'); return `${h.slice(0, 8)}-${h.slice(8, 12)}-5${h.slice(13, 16)}-a${h.slice(17, 20)}-${h.slice(20, 32)}`; };
const ajustar = (itens, caminho) => {
  for (const it of itens || []) {
    const chave = `${caminho}/${it.name}/${it.request ? it.request.method : 'pasta'}`;
    it.id = uuid(chave);
    if (it.request) {
      delete it.request.auth;
      it.response = [];
    }
    ajustar(it.item, chave);
  }
};
ajustar(c.item, '');
fs.writeFileSync(p, JSON.stringify(c, null, 2) + '\n');
