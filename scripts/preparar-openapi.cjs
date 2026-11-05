// Cópia do OpenAPI só para gerar a coleção do Postman: todo enum sem example/default ganha example = o primeiro valor,
// para o conversor não sortear valores (e o diff semanal só mostrar mudança real da API).
const fs = require('fs');
const [entrada, saida] = process.argv.slice(2);
const spec = JSON.parse(fs.readFileSync(entrada, 'utf8'));
const visitar = (o) => {
  if (Array.isArray(o)) { o.forEach(visitar); return; }
  if (!o || typeof o !== 'object') return;
  if (Array.isArray(o.enum) && o.enum.length && o.example === undefined && o.default === undefined) o.example = o.enum[0];
  Object.values(o).forEach(visitar);
};
visitar(spec);
fs.writeFileSync(saida, JSON.stringify(spec));
