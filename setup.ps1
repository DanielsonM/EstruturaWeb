# setup.ps1 - Script de configuração do projeto GestorMais

# 1. Instala o PostgreSQL
Write-Host "Instalando PostgreSQL..." -ForegroundColor Cyan
winget install -e --id PostgreSQL.PostgreSQL.16

# 2. Aguarda o serviço iniciar
Write-Host "Aguardando PostgreSQL iniciar..." -ForegroundColor Cyan
Start-Sleep -Seconds 15

# 3. Carrega variáveis do .env
Get-Content .env | ForEach-Object {
    if ($_ -match "^(.*?)=(.*)$") {
        $name = $matches[1]
        $value = $matches[2]
        [System.Environment]::SetEnvironmentVariable($name, $value)
    }
}

# 4. Configura o banco de dados usando variáveis
Write-Host "Configurando banco de dados..." -ForegroundColor Cyan
$env:PGPASSWORD = $env:PGPASSWORD

psql -U $env:POSTGRES_USER -h localhost -c "CREATE USER $env:GESTOR_USER WITH PASSWORD '$env:GESTOR_PASSWORD';"
psql -U $env:POSTGRES_USER -h localhost -c "CREATE DATABASE $env:GESTOR_DB OWNER $env:GESTOR_USER;"

# 5. Cria o frontend
Write-Host "Criando frontend..." -ForegroundColor Cyan
Set-Location frontend
npm create vite@latest . -- --template vue
Set-Location ..

# 6. Cria o backend
Write-Host "Criando backend..." -ForegroundColor Cyan
Set-Location backend
npm init -y
npm install express pg cors dotenv
Set-Location ..

Write-Host "Pronto!" -ForegroundColor Green
