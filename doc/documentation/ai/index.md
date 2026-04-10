# 🤖 Suporte a IA

O Modugo disponibiliza arquivos de configuração para que ferramentas de IA (Claude, Cursor, Copilot, etc.) entendam a biblioteca corretamente e gerem código preciso — sem alucinações de API.

---

## Context7

O [Context7](https://context7.com) é um MCP (_Model Context Protocol_) que injeta documentação atualizada e versionada diretamente no contexto das ferramentas de IA. Com o Modugo indexado no Context7, qualquer assistente que use o MCP recebe os exemplos e a API correta da versão instalada.

### Configurar o Context7 MCP

=== "Claude Code"

    Adicione ao `~/.claude/settings.json` (ou `settings.local.json`):

    ```json
    {
      "mcpServers": {
        "context7": {
          "command": "npx",
          "args": ["-y", "@upstash/context7-mcp"]
        }
      }
    }
    ```

=== "VS Code (Copilot)"

    Adicione ao `settings.json` do VS Code:

    ```json
    {
      "github.copilot.chat.mcp.enabled": true,
      "mcp": {
        "servers": {
          "context7": {
            "command": "npx",
            "args": ["-y", "@upstash/context7-mcp"]
          }
        }
      }
    }
    ```

=== "Cursor"

    Adicione ao `~/.cursor/mcp.json`:

    ```json
    {
      "mcpServers": {
        "context7": {
          "command": "npx",
          "args": ["-y", "@upstash/context7-mcp"]
        }
      }
    }
    ```

### Usar o Modugo com Context7

Com o MCP ativo, inclua `use context7` no seu prompt:

```
Como criar um módulo com guard de autenticação? use context7
```

O assistente buscará automaticamente a documentação correta do Modugo antes de responder.

---

## llms.txt

O Modugo inclui um arquivo [`llms.txt`](https://github.com/bed72/Modugo/blob/master/llms.txt) na raiz do repositório — padrão criado por [Jeremy Howard](https://llmstxt.org) para expor documentação de forma estruturada a LLMs.

Ferramentas que consomem `llms.txt` automaticamente encontram os links para todas as seções da documentação:

```
https://raw.githubusercontent.com/bed72/Modugo/master/llms.txt
```

---

## context7.json

O arquivo [`context7.json`](https://github.com/bed72/Modugo/blob/master/context7.json) na raiz do repositório controla como o Context7 indexa o projeto:

- **Pastas indexadas:** `doc/` e `lib/`
- **Pastas excluídas:** `test/`, `build/`, `coverage/`, `example/`
- **Regras de uso** que guiam o AI sobre padrões corretos da lib

```json
{
  "$schema": "https://context7.com/schema/context7.json",
  "projectTitle": "Modugo",
  "folders": ["doc", "lib"],
  "rules": [
    "Define modules implementing IModule with imports(), binds(), and routes()",
    "Prefer the declarative DSL: child(), module(), alias(), shell(), statefulShell()",
    "Protect routes with guards implementing IGuard",
    "Access DI via Modugo.i.get<T>(), i.get<T>(), or context.read<T>()"
  ]
}
```

---

## Skills

Skills são instruções estruturadas que ensinam o assistente a executar tarefas específicas com o Modugo — como criar um módulo, registrar uma dependência ou adicionar um guard.

O Modugo disponibiliza 4 skills prontas na pasta [`skills/`](https://github.com/bed72/Modugo/tree/master/skills) do repositório:

| Skill | Descrição |
|---|---|
| `create-module` | Criar um módulo com `binds()`, `routes()` e `imports()` |
| `create-route` | Usar os 5 tipos de rota com a DSL declarativa |
| `add-guard` | Criar e aplicar guards com propagação automática |
| `register-dependency` | Registrar e acessar dependências via GetIt |

### Instalar as skills

=== "ctx7 CLI"

    ```bash
    # Instalar todas as skills do Modugo interativamente
    ctx7 skills install /bed72/Modugo

    # Instalar uma skill específica
    ctx7 skills install /bed72/Modugo create-module
    ```

=== "Manual"

    Copie o diretório da skill desejada para a pasta de skills do seu projeto:

    ```
    skills/
    └── create-module/
        └── SKILL.md
    ```

### Como funciona uma skill

Cada skill é um diretório com um arquivo `SKILL.md` que contém instruções para o assistente:

```
skills/
├── create-module/
│   └── SKILL.md
├── create-route/
│   └── SKILL.md
├── add-guard/
│   └── SKILL.md
└── register-dependency/
    └── SKILL.md
```

O formato segue o [Agent Skills open standard](https://context7.com/docs/skills), compatível com Claude Code, Cursor e Copilot.

### Usar uma skill

Após instalar, invoque a skill pelo nome no prompt:

```
use create-module skill to scaffold a ProfileModule with AuthGuard
```

```
use add-guard skill to protect all routes in AdminModule
```

---

## Boas práticas ao usar IA com Modugo

| Faça | Evite |
|------|-------|
| Referencie tipos concretos: `ChildRoute`, `IGuard`, `IModule` | Pedir "crie uma rota" sem especificar o tipo |
| Use `use context7` para garantir a API da versão correta | Confiar em respostas sem contexto — a API muda entre versões |
| Peça exemplos de um padrão específico (ex: `ShellModuleRoute` com guard) | Pedir código genérico sem mencionar Modugo |
| Verifique se o assistente usou `Modugo.configure()` e `modugoRouter` | Aceitar código que configure GoRouter diretamente sem o Modugo |
