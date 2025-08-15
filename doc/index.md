![logo](assets/logo.png){ width="720" .center }

# Modugo — Modularize, injete e navegue 🚀

🎯 **Modugo** é um sistema modular para Flutter, inspirado no **Flutter Modular** e no **GoRouter Modular**. Ele oferece uma forma **limpa e organizada** de estruturar módulos, rotas e injeção de dependências, mantendo a simplicidade e clareza.

---

## Por que Modugo? 🤔

O Modugo nasceu para resolver problemas comuns em apps grandes:

- 🧩 **Modularidade**: Divida sua aplicação em módulos isolados e reutilizáveis.
- 🔍 **Clareza**: Cada módulo define suas rotas e dependências de forma explícita.
- ⚡ **Injeção de dependências simples**: Baseado em **GetIt**, as dependências são registradas **uma vez** na inicialização.
- 🛣️ **Navegação robusta**: Com integração ao **GoRouter**, gerencie rotas de forma eficiente.

> 💡 **Nota importante:** Diferente de outros frameworks modulares, **Modugo não faz o dispose automático das dependências**. Todas as instâncias vivem até o encerramento do app.

---

## Slogan do Modugo ✨

> **Modugo — Modularize, injete e navegue.**

Modugo é ideal para quem quer **organização, modularidade e injeção de dependências simples**, sem comprometer a flexibilidade do Flutter.

---

## Base tecnológica 🛠️

| Área                   | Tecnologias usadas              |
| ---------------------- | ------------------------------- |
| Navegação              | GoRouter                        |
| Injeção de Dependência | GetIt                           |
| Modularização          | Módulos isolados e desacoplados |

---

## Limitações ⚠️

- ❌ **Sem dispose automático**: Evita inconsistência quando múltiplas rotas compartilham o mesmo módulo.
- ✅ **Foco na estrutura e clareza**, não no gerenciamento automático de memória.
- 🔄 **Versão 3.x é breaking**: Mudança no sistema de DI.
  > Ao migrar de versões <3, será necessário **gerenciar manualmente o dispose** das dependências.

---

## Principais pontos ✅

- [x] Dependências registradas **uma vez** na inicialização.
- [x] Arquitetura **desacoplada** e modular.
- [x] Navegação simplificada com **GoRouter**.
- [ ] ❌ Cleanup automático **não disponível**.
- [ ] ⚠️ Atenção ao migrar para **v3+**, mudanças de DI.

---

> ⚠️ **Atenção**: Diferente de alguns frameworks modulares, **Modugo não faz o dispose automático das dependências**. Todas as instâncias vivem até o encerramento do aplicativo.

---
