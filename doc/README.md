# 📚 Configurando Ambiente Virtual e Instalando o MkDocs (Linux e macOS)

Este guia explica como criar um ambiente virtual Python, instalar o MkDocs e rodar o servidor local.

---

## 1️⃣ Criar e Ativar Ambiente Virtual

No terminal, navegue até a pasta do seu projeto e execute:

```bash
python3 -m venv .venv
```

Ativar o ambiente virtual:

**Linux/macOS (bash/zsh):**

```bash
source .venv/bin/activate
```

Você verá algo como:

```
(.venv) user@machine project %
```

---

## 2️⃣ Instalar o MkDocs

Com o ambiente virtual ativo, instale o MkDocs:

```bash
pip install mkdocs
```

Se quiser instalar com tema Material:

```bash
pip install mkdocs-material
```

---

## 3️⃣ Criar um Novo Projeto MkDocs

```bash
mkdocs new .
```

Isso criará a estrutura básica:

```
mkdocs.yml
/docs/index.md
```

---

## 4️⃣ Rodar o Servidor Local

```bash
mkdocs serve -a 127.0.0.1:8080
```

O terminal mostrará algo como:

```
INFO    -  Serving on http://127.0.0.1:8000/
```

Abra o link no navegador para visualizar.

---

## 5️⃣ Desativar Ambiente Virtual

Para sair do ambiente virtual:

```bash
deactivate
```
