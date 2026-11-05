#!/usr/bin/env bash
# Emite uma NFS-e de teste no sandbox do emissaoja (Emissor Nacional simulado: nada vai ao fisco), só com curl e jq.
#
#   1. Entre em https://sandbox.emissaoja.com.br com o Google e crie uma chave em Conta → API (começa com ej_test_).
#   2. EMISSAOJA_KEY=ej_test_... ./emitir-nfse-sandbox.sh
set -euo pipefail
BASE="${EMISSAOJA_BASE:-https://sandbox.emissaoja.com.br}"
H=(-H "Authorization: Bearer ${EMISSAOJA_KEY:?defina EMISSAOJA_KEY}" -H "Content-Type: application/json")

# 1. Conectar a empresa (uma vez). No sandbox, 11111111000191 é um MEI pronto para emitir e qualquer senha serve.
estado=$(curl -fsS "${H[@]}" "$BASE/v1/empresa" | jq -r '.credencial.estado')
if [ "$estado" != "ativa" ]; then
  curl -fsS -X PUT "${H[@]}" "$BASE/v1/empresa/credencial" -d '{"cnpj":"11111111000191","senha":"senha-de-teste"}' >/dev/null
  until passo=$(curl -fsS "${H[@]}" "$BASE/v1/empresa/credencial" | jq -r '.tentativa.proximo_passo // "pronto"') && [ "$passo" != "aguardar" ]; do sleep 2; done
  echo "credencial: $passo"
fi

# 2. Tomador pelo CNPJ (nome e endereço vêm da Receita Federal)
tomador=$(curl -fsS -X POST "${H[@]}" "$BASE/v1/tomadores" -d '{"documento":"12345678000195"}' | jq -c '.tomador')

# 3. Emitir com Idempotency-Key (repetir a mesma chave nunca emite duas vezes)
corpo=$(jq -cn --argjson t "$tomador" '{tomador_tipo: $t.tipo, tomador_id: $t.id, valor: 150, descricao: "Consultoria em marketing digital"}')
pedido=$(curl -fsS -X POST "${H[@]}" -H "Idempotency-Key: exemplo-$(date +%s)" "$BASE/v1/notas" -d "$corpo" | jq -r '.pedido.id')

# 4. Acompanhar até autorizada | recusada | incerta, esperando proxima_consulta_ms
while :; do
  r=$(curl -fsS "${H[@]}" "$BASE/v1/emissoes/$pedido")
  estado=$(jq -r '.pedido.estado' <<<"$r")
  case "$estado" in autorizada|recusada|incerta) break ;; esac
  sleep "$(jq -r '((.pedido.proxima_consulta_ms // 3000) / 1000)' <<<"$r")"
done
jq '.pedido | {estado, numero, chave_acesso, motivo}' <<<"$r"

# 5. PDF (DANFSe) e XML
if [ "$estado" = "autorizada" ]; then
  origem=$(jq -r '.pedido.nota.origem' <<<"$r"); id=$(jq -r '.pedido.nota.id' <<<"$r")
  curl -fsS "${H[@]}" "$BASE/v1/notas/$origem/$id/pdf" -o nfse.pdf
  curl -fsS "${H[@]}" "$BASE/v1/notas/$origem/$id/xml" -o nfse.xml
  echo "nfse.pdf e nfse.xml salvos"
fi
