#!/bin/bash

# Exemplo de uso:
# de permissão: chmod +x release.sh
#   ./release.sh 1.2.3

# Verifica se a versão foi passada
if [ -z "$1" ]; then
  echo "❌ Você precisa informar a versão. Ex: ./release.sh 1.2.3"
  exit 1
fi

VERSION=$1
TAG="v$VERSION"
DATE=$(date +%F)
MESSAGE="release: $VERSION"

# Verifica se a versão está no formato correto x.y.z
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "❌ Versão inválida. Use o formato x.y.z. Ex: 1.2.3"
  exit 1
fi

# Verifica se a tag já existe
if git rev-parse "$TAG" >/dev/null 2>&1; then
  echo "❌ A tag $TAG já existe. Escolha outra versão."
  exit 1
fi

echo "🚀 Iniciando release $TAG..."

# Garante que está na branch master
git checkout master || exit 1
git pull origin master || exit 1

# Atualiza pubspec.yaml
echo "📝 Atualizando pubspec.yaml para versão $VERSION..."
sed -i "s/^version:.*/version: $VERSION/" pubspec.yaml

# Atualiza o CHANGELOG.md com a última mensagem de commit
COMMIT_MSG=$(git log -1 --pretty=format:"- %s")
echo -e "## [$VERSION] - $DATE\n\n$COMMIT_MSG\n\n$(cat CHANGELOG.md)" > CHANGELOG.md

# Comita as alterações
git add pubspec.yaml CHANGELOG.md
git commit -m "chore: release $TAG"
git push origin master

# Cria a tag anotada com a mesma mensagem
git tag -a "$TAG" -m "$MESSAGE"
git push origin "$TAG"

echo "✅ Release $TAG finalizada com sucesso!"