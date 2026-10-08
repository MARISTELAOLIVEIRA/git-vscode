## 🔐 Passo 2 de 4: não envie segredos

Projetos de verdade têm senhas e chaves que **nunca** podem ir para o GitHub. Elas ficam num arquivo `.env`, e o `.gitignore` diz ao Git para ignorá-lo.

1. No VS Code, crie um arquivo chamado `.env` com uma senha **de mentira**:
   ```
   SENHA_DO_BANCO=123456
   ```
   Repare: ele aparece na aba **Controle do Código-Fonte** como arquivo novo (**U**). 👀
2. Agora crie um arquivo chamado `.gitignore` com uma linha só:
   ```
   .env
   ```
   Olhe de novo a aba **Controle do Código-Fonte**: o `.env` **sumiu** da lista! É o `.gitignore` funcionando. ✨
3. Faça o commit do `.gitignore` com a mensagem `Adiciona o .gitignore` e clique em **Sync Changes**

⏳ Fico de olho!
