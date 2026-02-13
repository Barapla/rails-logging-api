#!/bin/bash

set -e

echo "============================================"
echo "🚀 SETUP AUTOMÁTICO - RAILS API TEMPLATE"
echo "============================================"
echo ""

# Remover repositorio problemático de Yarn
echo "🔧 Limpiando repositorios problemáticos..."
sudo rm -f /etc/apt/sources.list.d/yarn.list 2>/dev/null || true

# Actualizar sistema SIN prompts interactivos
echo "📦 Actualizando sistema..."
export DEBIAN_FRONTEND=noninteractive
sudo -E apt-get update -qq

# Instalar clientes SIN prompts
echo "📦 Instalando clientes PostgreSQL y Redis..."
sudo -E apt-get install -y -qq \
  postgresql-client \
  redis-tools \
  libpq-dev \
  build-essential \
  git \
  curl

# Configurar Ruby y Rails
echo "💎 Instalando Bundler y Rails..."
gem install bundler --no-document
gem install rails --no-document

# Configurar Git
echo "🔧 Configurando Git..."
git config --global init.defaultBranch main
git config --global pull.rebase false

# Crear archivo .env
echo "📝 Creando archivo .env..."
cat > /workspace/.env << 'EOF'
DB_HOST=db
DB_USERNAME=postgres
DB_PASSWORD=postgres
REDIS_URL=redis://redis:6379/0
RAILS_ENV=development
EOF

# Configurar password de PostgreSQL para comandos CLI
echo "🔐 Configurando autenticación PostgreSQL..."
export PGPASSWORD=postgres

# Esperar PostgreSQL (10 intentos = 20 segundos)
echo "⏳ Esperando a que PostgreSQL esté listo..."
for i in {1..10}; do
  if pg_isready -h db -U postgres > /dev/null 2>&1; then
    echo "✅ PostgreSQL está listo"
    break
  fi
  if [ $i -eq 10 ]; then
    echo "⚠️ PostgreSQL tardó más de lo esperado (continuando...)"
  fi
  sleep 2
done

# Esperar Redis (10 intentos = 20 segundos)
echo "⏳ Esperando a que Redis esté listo..."
for i in {1..10}; do
  if redis-cli -h redis ping > /dev/null 2>&1; then
    echo "✅ Redis está listo"
    break
  fi
  if [ $i -eq 10 ]; then
    echo "⚠️ Redis tardó más de lo esperado (continuando...)"
  fi
  sleep 2
done

# Si existe Gemfile, instalar dependencias
if [ -f "/workspace/Gemfile" ]; then
  echo "📦 Gemfile detectado, instalando gems..."
  cd /workspace
  bundle install
  
  # Si existe Rails, configurar BD
  if bundle show rails > /dev/null 2>&1; then
    echo "🗄️ Configurando base de datos Rails..."
    PGPASSWORD=postgres bundle exec rails db:create 2>/dev/null || echo "⚠️ No se pudo crear BD"
    bundle exec rails db:migrate 2>/dev/null || echo "⚠️ No hay migraciones aún"
  fi
fi

# Verificación final
echo ""
echo "============================================"
echo "✅ VERIFICACIÓN DE INSTALACIÓN"
echo "============================================"
echo "Ruby: $(ruby -v)"
echo "Bundler: $(bundle -v)"
echo "Rails: $(rails -v)"
echo "PostgreSQL Client: $(psql --version)"
echo "Redis Client: $(redis-cli --version)"
echo ""

# Verificar servicios (SIN pedir password)
if pg_isready -h db -U postgres > /dev/null 2>&1; then
  echo "✅ PostgreSQL conectado (hostname: db)"
  # Usar PGPASSWORD para no pedir password
  PGPASSWORD=postgres psql -h db -U postgres -tc "SELECT version();" 2>/dev/null | head -1 | xargs || true
else
  echo "⚠️ PostgreSQL no respondió"
fi

if redis-cli -h redis ping > /dev/null 2>&1; then
  echo "✅ Redis conectado (hostname: redis) - $(redis-cli -h redis ping)"
else
  echo "⚠️ Redis no respondió"
fi

echo ""
echo "============================================"
echo "✨ SETUP COMPLETADO"
echo "============================================"
echo ""
if [ ! -f "/workspace/Gemfile" ] || [ ! -f "/workspace/config/application.rb" ]; then
  echo "👉 Para crear un nuevo proyecto Rails API:"
  echo "   rails new . --api --database=postgresql --force --skip-git"
  echo "   bundle install"
  echo "   PGPASSWORD=postgres rails db:create"
else
  echo "✅ Proyecto Rails ya inicializado"
  echo "👉 Comandos útiles:"
  echo "   rails db:migrate    # Correr migraciones"
  echo "   rails console       # Consola interactiva"
  echo "   rails server        # Iniciar servidor"
fi
echo ""

# Marcar como completado
echo "✅ Setup marcado como completado"