#!/usr/bin/env bash
# ==========================================================
#  Robô do curso "Git no VS Code"
# ==========================================================
#  Roda a cada push na main e a cada comentário na issue do curso
#  (ver .github/workflows/curso.yml).
#
#  Igual ao curso "Minha primeira entrega":
#    - a etiqueta da issue (passo-1 ... passo-4, concluido) guarda o passo atual;
#    - cumpriu: parabéns + próximo passo; adiantou: avança vários de uma vez;
#    - errou de um jeito que dá para explicar: comenta uma dica.
#
#  O QUE ESTE CURSO TEM DE DIFERENTE
#    O robô não enxerga o computador do aluno, só o histórico do Git. Por isso:
#    - commit feito pelo site do GitHub tem como "committer" o e-mail
#      noreply@github.com. Os feitos no VS Code têm o e-mail do aluno.
#      É assim que o robô sabe se a tarefa foi feita no computador.
#    - se o e-mail do "git config" não for o da conta, o GitHub não liga o
#      commit ao aluno (fica "sem dono"). O robô avisa como corrigir.
#
#  Os textos de cada passo ficam em .github/passos/*.md
# ==========================================================
set -euo pipefail

REPO="$GITHUB_REPOSITORY"
USUARIO="${REPO%%/*}"
NOME_REPO="${REPO#*/}"
PASSOS=".github/passos"
TITULO="💻 Git no VS Code"
ULTIMO_PASSO=4
EMAIL_SITE="noreply@github.com"   # "committer" dos commits feitos pelo site do GitHub

# PARA EDITAR: o visual dos comentários do robô. A Stela fala num balão colorido ao lado do memoji
# (tipo: TIP = verde, WARNING = laranja, NOTE = azul), e cada passo certo vem com confete e placar.
CABECALHO=""
ASSETS="https://maristelaoliveira.github.io/curso-github/assets"

# fala <memoji> <tipo> <texto>
fala() {
  local texto="${3//$'\n'/$'\n> '}"
  printf '<table><tr><td width="96" align="center"><img src="%s/memoji/%s.webp" width="80" alt="Stela"></td><td>\n\n> [!%s]\n> %s\n\n</td></tr></table>\n' "$ASSETS" "$1" "$2" "$texto"
}

# 🟩🟩⬜⬜⬜ 2 de 5
placar() {
  local barra="" i
  for ((i = 1; i <= ULTIMO_PASSO; i++)); do
    if [ "$i" -le "$PASSO" ]; then barra+="🟩"; else barra+="⬜"; fi
  done
  printf '<p align="center">%s &nbsp; <b>%s de %s</b></p>\n' "$barra" "$PASSO" "$ULTIMO_PASSO"
}

# confete + parabéns do passo + placar (no último passo, o confete é o grande)
sucesso() {
  local gif=confete memojis=(festa joinha olhos-de-estrela punho piscando)
  [ "$PASSO" -ge "$ULTIMO_PASSO" ] && gif=confete-grande
  printf '<p align="center"><img src="%s/confete/%s.gif" width="600" alt=""></p>\n\n' "$ASSETS" "$gif"
  fala "${memojis[$((PASSO % 5))]}" TIP "${FEITO[$PASSO]}"
  echo
  placar
}

# PARA EDITAR: a frase de parabéns de cada passo concluído
FEITO[1]="✅ **Passo 1 concluído!** Seu primeiro commit saiu do VS Code direto para o GitHub. 🚀"
FEITO[2]="✅ **Passo 2 concluído!** O \`.gitignore\` está protegendo o seu \`.env\`. A senha ficou só no seu computador. 🔐"
FEITO[3]="✅ **Passo 3 concluído!** Commits pequenos, com mensagens que contam a história do projeto. 📸"
FEITO[4]="✅ **Passo 4 concluído!** Você puxou a mudança do \"colega\" antes de enviar a sua. Trabalho em equipe sem conflito! 🤝"

# PARA EDITAR: mensagens de commit que não explicam nada
MENSAGEM_RUIM='^(update|updates|teste|test|asdf|agora vai|commit|ajuste|ajustes|mudança|mudanças|mudanca|mudancas|alterações|alteracoes|wip|\.|ok|fix|arrumando)$'

# ---------- funções auxiliares ----------
renderizar() { sed -e "s|{{usuario}}|${USUARIO}|g" -e "s|{{repo}}|${NOME_REPO}|g" "$1"; }
arquivo_do_passo() { ls "$PASSOS"/"$1"-*.md | head -1; }
comentar() { gh issue comment "$ISSUE" --repo "$REPO" --body "${CABECALHO}$1" >/dev/null; }

# commits feitos NO COMPUTADOR (não pelo site) que mexeram num arquivo, do mais novo ao mais antigo
commits_locais() { git log --format='%H %ce' -- "$1" | awk -v site="$EMAIL_SITE" '$2 != site {print $1}'; }

# o commit está ligado a uma conta do GitHub? (vazio = e-mail do git config não é o da conta)
dono_do_commit() { gh api "repos/${REPO}/commits/$1" --jq '.author.login // empty' 2>/dev/null || true; }

# ---------- as conferências de cada passo ----------
# Devolvem 0 (passou) ou 1 (ainda não). DICA = explicação do erro.
# AVISO = um alerta que vai junto com o parabéns (não impede de avançar).

conferir_1() {   # sobre-mim.md criado por um commit feito no computador
  if [ ! -f sobre-mim.md ]; then
    local achado
    achado="$(find . -iname '*sobre*mim*' -not -path './.git/*' | head -1)"
    if [ -n "$achado" ]; then DICA="Encontrei \`${achado#./}\`, mas o arquivo precisa se chamar exatamente \`sobre-mim.md\` e ficar na raiz do projeto."; fi
    return 1
  fi
  local locais
  locais="$(commits_locais sobre-mim.md)"
  if [ -z "$locais" ]; then
    DICA="Recebi o \`sobre-mim.md\`, mas ele foi criado **pelo site** do GitHub 😉. A ideia aqui é fazer pelo VS Code: clone o repositório, acrescente uma linha no \`sobre-mim.md\`, faça o commit e clique em **Sync Changes**."
    return 1
  fi
  if [ -z "$(dono_do_commit "$(echo "$locais" | tail -1)")" ]; then
    AVISO="

> ⚠️ **Atenção:** seu commit chegou **sem dono**: o e-mail configurado no seu Git não é o da sua conta do GitHub, então o commit não aparece no seu perfil.
> Para corrigir, no terminal do VS Code (troque pelo e-mail da sua conta, que aparece em **Settings → Emails**):
> \`\`\`
> git config --global user.email \"email-da-sua-conta@exemplo.com\"
> \`\`\`
> Os próximos commits já vão aparecer com a sua foto."
  fi
}

conferir_2() {   # .gitignore com .env, e o .env NÃO foi enviado
  if git ls-files --error-unmatch .env >/dev/null 2>&1; then
    DICA="Ops! O \`.env\` foi para o GitHub 😱 Num projeto de verdade, a senha agora estaria pública. Para tirar, no terminal do VS Code:
\`\`\`
git rm --cached .env
\`\`\`
Depois confira se o \`.gitignore\` tem a linha \`.env\`, faça o commit e clique em **Sync Changes**. (Num projeto real, troque também a senha!)"
    return 1
  fi
  if [ ! -f .gitignore ]; then
    if [ -n "$(find . -maxdepth 1 -iname '*gitignore*' -not -name '.gitignore' | head -1)" ]; then
      DICA="Achei um arquivo parecido, mas o nome precisa ser exatamente \`.gitignore\`: começando com **ponto** e sem extensão (nada de \`.txt\`)."
    fi
    return 1
  fi
  if ! grep -qE '^[[:space:]]*/?\.env[[:space:]]*$' .gitignore; then
    DICA="O \`.gitignore\` está lá, mas não achei a linha \`.env\` dentro dele."
    return 1
  fi
}

conferir_3() {   # duas seções novas, em commits separados, com mensagem clara
  local tem_tec=0 tem_obj=0
  grep -qiE '^##[[:space:]]*tecnologias' sobre-mim.md && tem_tec=1
  grep -qiE '^##[[:space:]]*meu objetivo' sobre-mim.md && tem_obj=1
  if [ $((tem_tec + tem_obj)) -lt 2 ]; then
    [ $((tem_tec + tem_obj)) -eq 1 ] && DICA="Uma das seções já chegou! 👏 Agora faça a outra num **novo commit**."
    return 1
  fi
  if [ "$(commits_locais sobre-mim.md | wc -l)" -lt 3 ]; then
    DICA="As duas seções estão lá, mas chegaram juntas, num commit só. Faça mais uma mudança pequena (por exemplo, acrescente um item na lista de tecnologias), faça um **novo commit** e clique em **Sync Changes**."
    return 1
  fi
  local ultima
  ultima="$(git log -1 --format=%s "$(commits_locais sobre-mim.md | head -1)")"
  if echo "$ultima" | grep -qiE "$MENSAGEM_RUIM" || [ "${#ultima}" -lt 10 ]; then
    DICA="Recebi os commits! Só que a mensagem do último, \"**${ultima}**\", não explica o que mudou. Faça mais uma pequena mudança e um commit com uma mensagem que conte o que você fez, como \`Adiciona JavaScript à lista de tecnologias\`."
    return 1
  fi
}

conferir_4() {   # README editado pelo site + nova seção enviada do computador depois do pull
  local tem_site=0 tem_aprendi=0
  grep -qi 'editado no site' README.md && tem_site=1
  grep -qiE '^##[[:space:]]*o que eu aprendi' sobre-mim.md && tem_aprendi=1
  if [ "$tem_site" = 0 ]; then
    [ "$tem_aprendi" = 1 ] && DICA="A seção \"O que eu aprendi\" chegou! Mas falta a parte do \"colega\": edite o \`README.md\` **pelo site** do GitHub e acrescente \`Editado no site ✔\`. Depois puxe no VS Code (**Sync Changes**)."
    return 1
  fi
  [ "$tem_aprendi" = 1 ] || return 1
  # a seção "O que eu aprendi" tem que ter sido escrita no computador
  local sha_aprendi
  sha_aprendi="$(git log -1 --format=%H -S 'O que eu aprendi' -- sobre-mim.md)"
  if [ "$(git log -1 --format=%ce "$sha_aprendi")" = "$EMAIL_SITE" ]; then
    DICA="A seção \"O que eu aprendi\" foi escrita **pelo site**. Escreva no VS Code: faça **Sync Changes** para puxar, edite o \`sobre-mim.md\` no seu computador, faça o commit e envie."
    return 1
  fi
  # o último commit enviado (HEAD) tem que ter saído do computador do aluno.
  # Como o "colega" mudou o GitHub, o aluno só consegue enviar algo depois de puxar
  # (Sync Changes): seja escrevendo depois do pull, seja juntando as mudanças (merge).
  if [ "$(git log -1 --format=%ce HEAD)" = "$EMAIL_SITE" ]; then
    DICA="Você escreveu \"O que eu aprendi\" **antes** de o \"colega\" editar o README, então ainda não treinou o *pull*. No VS Code, clique em **Sync Changes** para puxar a mudança do colega, acrescente mais uma frase em \"O que eu aprendi\", faça o commit e envie de novo."
    return 1
  fi
}

# ---------- 1. a issue do curso existe? ----------
ISSUE="$(gh issue list --repo "$REPO" --label curso --state all --json number --jq '.[0].number // empty')"
if [ -z "$ISSUE" ]; then
  gh label create curso     --repo "$REPO" --color 3fb950 --description "Curso prático" --force >/dev/null
  gh label create concluido --repo "$REPO" --color 7ee2b8 --force >/dev/null
  for n in $(seq 1 "$ULTIMO_PASSO"); do gh label create "passo-$n" --repo "$REPO" --color e3c26b --force >/dev/null; done
  corpo="$(fala acenando NOTE "$(renderizar "$PASSOS/0-boas-vindas.md")")

---

$(renderizar "$(arquivo_do_passo 1)")"
  url="$(gh issue create --repo "$REPO" --title "$TITULO" --label curso --label passo-1 --body "$corpo")"
  echo "Issue do curso criada: $url"
  exit 0
fi

# ---------- 2. em que passo o aluno está? ----------
ETIQUETAS="$(gh issue view "$ISSUE" --repo "$REPO" --json labels --jq '[.labels[].name] | join(" ")')"
if [[ " $ETIQUETAS " == *" concluido "* ]]; then echo "Curso já concluído."; exit 0; fi
PASSO="$(echo "$ETIQUETAS" | grep -o 'passo-[0-9]*' | head -1 | cut -d- -f2)"
PASSO="${PASSO:-1}"
echo "Issue #$ISSUE · passo atual: $PASSO · evento: ${EVENTO:-?}"

# no fim do curso, o certificado entra no topo do README do aluno: a issue fecha e some da vista, o README fica
readme_final() {
  git config user.name "Robô do curso"
  git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
  git fetch -q origin main
  git checkout -q -B main origin/main
  bash .github/scripts/readme-final.sh "$USUARIO" vscode "Git no VS Code"
  git add README.md
  git commit -q -m "Põe o certificado do curso no README" || return 0
  git push -q origin main
}

# ---------- 3. confere e avança enquanto as tarefas estiverem cumpridas ----------
AVANCOU=0
while [ "$PASSO" -le "$ULTIMO_PASSO" ]; do
  DICA=""; AVISO=""
  if "conferir_$PASSO"; then
    if [ "$PASSO" -lt "$ULTIMO_PASSO" ]; then
      comentar "$(sucesso)${AVISO}

---

$(renderizar "$(arquivo_do_passo $((PASSO + 1)))")"
      gh issue edit "$ISSUE" --repo "$REPO" --remove-label "passo-$PASSO" --add-label "passo-$((PASSO + 1))" >/dev/null
    else
      comentar "$(sucesso)${AVISO}

---

$(renderizar "$PASSOS/5-fim.md")"
      gh issue edit "$ISSUE" --repo "$REPO" --remove-label "passo-$PASSO" --add-label concluido >/dev/null
      gh issue close "$ISSUE" --repo "$REPO" --reason completed >/dev/null
      readme_final || echo "Não consegui atualizar o README (o curso já está concluído)."
      gh api -X POST "repos/${REPO}/issues/${ISSUE}/reactions" -f content=hooray >/dev/null || true   # 🎉 na issue
    fi
    PASSO=$((PASSO + 1))
    AVANCOU=1
  else
    if [ "$AVANCOU" = 0 ] && [ -n "$DICA" ]; then comentar "$(fala ideia WARNING "**Quase!** $DICA")"; fi
    break
  fi
done
