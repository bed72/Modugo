# Modugo

**Modugo** é um gerenciador modular de dependências e rotas para Flutter/Dart que facilita a organização e o ciclo de vida de módulos, binds (dependências) e rotas. Inspirado em arquiteturas modulares, o Modugo traz controle automático de injeção, referência e descarte de dependências com suporte a composição de módulos.

---

## 📦 Recursos

- Registro e gerenciamento de binds (singleton, factory, etc) por módulo
- Controle automático do ciclo de vida de binds com base nas rotas ativas
- Suporte a módulos importados (modularização aninhada)
- Descarte automático das dependências que não estão mais em uso
- Logs detalhados para facilitar o diagnóstico e debugging
- Singleton global para gerenciamento centralizado
- Registro e remoção dinâmica de rotas e binds

---

## 🚀 Instalação

Como o Modugo ainda não está publicado no Pub.dev, utilize o pacote localmente ou faça fork e aponte para seu repositório:

```yaml
dependencies:
  modugo:
    path: ../modugo
```
