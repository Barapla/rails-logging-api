# Rails API Codespace Template

Template base para proyectos Rails API con PostgreSQL y Redis configurado para GitHub Codespaces.

## 🚀 Quick Start

### 1. Usar Este Template

1. Click en **"Use this template"** en GitHub
2. Crea tu nuevo repositorio (ej: `mi-proyecto-api`)
3. Abre un **Codespace** (botón verde "Code" → "Codespaces" → "Create codespace")
4. Espera ~2-3 minutos mientras se instala todo automáticamente ✨

### 2. Crear Tu Proyecto Rails
```bash
# Crear proyecto Rails API
rails new . --api --database=postgresql --force --skip-git

# Instalar dependencias
bundle install

# IMPORTANTE: Configurar database.yml
cat > config/database.yml << 'EOF'
default: &default
  adapter: postgresql
  encoding: unicode
  host: <%= ENV.fetch("DB_HOST") { "db" } %>
  username: <%= ENV.fetch("DB_USERNAME") { "postgres" } %>
  password: <%= ENV.fetch("DB_PASSWORD") { "postgres" } %>
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: mi_proyecto_development

test:
  <<: *default
  database: mi_proyecto_test

production:
  <<: *default
  database: mi_proyecto_production
EOF

# Crear la base de datos
rails db:create

# Verificar que todo funciona
rails console
```

### 3. Iniciar el Servidor
```bash
rails server -b 0.0.0.0
```

Tu API estará disponible en el puerto 3000 (GitHub Codespaces lo detecta automáticamente).

---

## 📦 ¿Qué Incluye Este Template?

### Stack Pre-instalado
- ✅ **Ruby 3.2.8**
- ✅ **Rails** (última versión estable)
- ✅ **PostgreSQL 15** (contenedor separado, hostname: `db`)
- ✅ **Redis 7** (contenedor separado, hostname: `redis`)
- ✅ **Bundler**
- ✅ **PostgreSQL Client & Redis CLI**

### VS Code Extensions
- Ruby & RuboCop
- Solargraph (IntelliSense)
- GitHub Copilot
- GitLens
- Code Spell Checker

### Archivo `.env` Pre-configurado
```bash
DB_HOST=db
DB_USERNAME=postgres
DB_PASSWORD=postgres
REDIS_URL=redis://redis:6379/0
RAILS_ENV=development
```

---

## ⚙️ Configuración Importante

### Database Configuration

**CRÍTICO**: Rails por defecto busca PostgreSQL en `localhost`, pero en este template PostgreSQL corre en un contenedor con hostname `db`.

Tu `config/database.yml` **DEBE** usar las variables de entorno:
```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  host: <%= ENV.fetch("DB_HOST") { "db" } %>        # ← IMPORTANTE
  username: <%= ENV.fetch("DB_USERNAME") { "postgres" } %>
  password: <%= ENV.fetch("DB_PASSWORD") { "postgres" } %>
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
```

### Redis Configuration

Si usas Redis para cache o Sidekiq, configúralo así:
```ruby
# config/initializers/redis.rb
Redis.current = Redis.new(url: ENV.fetch("REDIS_URL", "redis://redis:6379/0"))

# config/environments/development.rb
config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'] }
```

---

## 🛠️ Comandos Útiles

### Verificar Servicios
```bash
# PostgreSQL
pg_isready -h db -U postgres
PGPASSWORD=postgres psql -h db -U postgres -c "SELECT version();"

# Redis  
redis-cli -h redis ping
redis-cli -h redis SET test "hello"
redis-cli -h redis GET test
```

### Rails
```bash
rails db:create          # Crear base de datos
rails db:migrate         # Correr migraciones
rails db:seed            # Poblar con datos
rails console            # Consola interactiva
rails server -b 0.0.0.0  # Iniciar servidor
rails routes             # Ver todas las rutas
```

### Testing (cuando lo configures)
```bash
bundle exec rspec
bundle exec rubocop
```

---

## 📁 Estructura del Template
```
rails-api-codespace-template/
├── .devcontainer/
│   ├── devcontainer.json      # Configuración del Codespace
│   ├── docker-compose.yml     # PostgreSQL y Redis
│   └── setup.sh               # Script de instalación automática
├── .env                       # Variables de entorno (auto-generado)
├── .gitignore
└── README.md
```

---

## 🎯 Próximos Pasos Después del `rails new`

### 1. Configurar dotenv-rails (Recomendado)

Para cargar automáticamente el `.env`:
```bash
# Agregar al Gemfile
echo "gem 'dotenv-rails', groups: [:development, :test]" >> Gemfile
bundle install
```

### 2. Configurar RuboCop Standard
```bash
bundle add standard --group development
echo "require: standard" > .rubocop.yml
```

### 3. Configurar RSpec
```bash
bundle add rspec-rails --group development,test
rails generate rspec:install
```

### 4. Gemas Comunes para APIs
```ruby
# Gemfile
gem 'rack-cors'           # CORS para frontend
gem 'bcrypt'              # Autenticación
gem 'jwt'                 # Tokens JWT
gem 'redis'               # Cliente Redis
gem 'sidekiq'             # Background jobs
gem 'pagy'                # Paginación
gem 'blueprinter'         # JSON serialization
```

---

## 🐛 Troubleshooting

### "Could not connect to server" al crear la BD

**Problema**: Rails está buscando PostgreSQL en `localhost` en lugar de `db`.

**Solución**: Verifica que tu `config/database.yml` use `host: <%= ENV.fetch("DB_HOST") { "db" } %>`

### "Connection refused" con Redis

**Problema**: Estás intentando conectar a `localhost` en lugar de `redis`.

**Solución**: Usa `redis-cli -h redis ping` en lugar de `redis-cli ping`

### El setup no se ejecutó automáticamente
```bash
# Ejecutar manualmente
bash .devcontainer/setup.sh
```

### Ver logs del setup
```bash
cat /tmp/setup.log
```

---

## 💡 Tips de GitHub Codespaces

- **Costos**: 120 horas gratis/mes (máquina de 2 cores) - más que suficiente
- **Pausa automática**: Se pausa después de 30 min de inactividad
- **Persistencia**: Los datos de PostgreSQL y Redis persisten entre sesiones
- **Secrets**: Para variables sensibles, usa GitHub Codespaces Secrets en repo settings
- **Puertos**: Los puertos 3000, 5432, 6379 se exponen automáticamente

---

## 📖 Recursos

- [GitHub Codespaces Docs](https://docs.github.com/en/codespaces)
- [Rails Guides](https://guides.rubyonrails.org/)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [Redis Docs](https://redis.io/docs/)

---

## 🤝 Contribuir

Si encuentras mejoras para este template:

1. Fork el repositorio
2. Crea tu feature branch
3. Commit tus cambios
4. Push al branch
5. Abre un Pull Request

---