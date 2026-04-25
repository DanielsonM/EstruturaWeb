# setup.ps1 - Script de configuração do projeto GestorMais com TypeScript

# 1. Instala o PostgreSQL
Write-Host "Instalando PostgreSQL..." -ForegroundColor Cyan
try {
    winget install -e --id PostgreSQL.PostgreSQL.16 -ErrorAction Stop
} catch {
    Write-Error "Falha ao instalar PostgreSQL: $_"
    exit 1
}

# 2. Aguarda o serviço iniciar
Write-Host "Aguardando PostgreSQL iniciar..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

# 2.1 Adiciona PostgreSQL ao PATH
$pgBinPath = "C:\Program Files\PostgreSQL\16\bin"
if (-Not ($env:Path -like "*$pgBinPath*")) {
    Write-Host "Adicionando PostgreSQL ao PATH..." -ForegroundColor Cyan
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$pgBinPath", "Machine")
    $env:Path += ";$pgBinPath"
}

# 3. Carrega variáveis do .env
try {
    if (-Not (Test-Path ".env")) {
        throw "Arquivo .env não encontrado na raiz do projeto."
    }
    Get-Content .env | ForEach-Object {
        if ($_ -match "^(.*?)=(.*)$") {
            $name = $matches[1]
            $value = $matches[2]
            [System.Environment]::SetEnvironmentVariable($name, $value)
        }
    }
} catch {
    Write-Error "Erro ao carregar variáveis do .env: $_"
    exit 1
}

# 4. Configura o banco de dados usando variáveis
Write-Host "Configurando banco de dados..." -ForegroundColor Cyan
try {
    if (-Not (Get-Command psql -ErrorAction SilentlyContinue)) {
        throw "psql não encontrado no PATH. Verifique a instalação do PostgreSQL."
    }
    $env:PGPASSWORD = $env:PGPASSWORD
    psql -U $env:POSTGRES_USER -h localhost -c "CREATE USER $env:GESTOR_USER WITH PASSWORD '$env:GESTOR_PASSWORD';" -ErrorAction Stop
    psql -U $env:POSTGRES_USER -h localhost -c "CREATE DATABASE $env:GESTOR_DB OWNER $env:GESTOR_USER;" -ErrorAction Stop
} catch {
    Write-Error "Erro ao configurar banco de dados: $_"
    exit 1
}

# 5. Cria o backend com TypeScript
Write-Host "Criando backend com TypeScript..." -ForegroundColor Cyan
try {
    Set-Location backend
    npm init -y
    npm install express pg cors dotenv
    npm install --save-dev typescript ts-node nodemon @types/node @types/express @types/pg @types/cors @types/dotenv

    # Cria tsconfig.json
    if (-Not (Test-Path "tsconfig.json")) {
@"
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "rootDir": "./src",
    "outDir": "./dist",
    "strict": true,
    "esModuleInterop": true
  }
}
"@ | Out-File -Encoding utf8 tsconfig.json
    }

    # Cria pasta src e index.ts
    if (-Not (Test-Path "src")) {
        New-Item -ItemType Directory -Path "src"
    }
    if (-Not (Test-Path "src/index.ts")) {
@"
import dotenv from 'dotenv';
import express, { Request, Response } from 'express';
import { Pool } from 'pg';
import cors from 'cors';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const pool = new Pool({
  user: process.env.GESTOR_USER,
  host: 'localhost',
  database: process.env.GESTOR_DB,
  password: process.env.GESTOR_PASSWORD,
  port: 5432,
});

app.get('/', (req: Request, res: Response) => {
  res.send('Backend funcionando com TypeScript!');
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Servidor backend rodando em http://localhost:${PORT}`);
});
"@ | Out-File -Encoding utf8 src/index.ts
    }

    # Adiciona script de inicialização no package.json
    npm set-script dev "nodemon --exec ts-node src/index.ts"

    Set-Location ..
} catch {
    Write-Error "Erro ao configurar backend: $_"
    exit 1
}

# 6. Cria o frontend (último passo)
Write-Host "Criando frontend..." -ForegroundColor Cyan
try {
    Set-Location frontend
    npm create vite@latest . -- --template vue --yes -ErrorAction Stop
    npm install -ErrorAction Stop
    npm install --save-dev typescript -ErrorAction Stop
    Set-Location ..
} catch {
    Write-Error "Erro ao configurar frontend: $_"
    exit 1
}

Write-Host "Projeto GestorMais configurado com sucesso em TypeScript!" -ForegroundColor Green
