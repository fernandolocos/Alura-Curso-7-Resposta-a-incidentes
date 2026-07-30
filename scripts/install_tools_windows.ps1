# Script de Instalacao de Ferramentas - Windows
# Curso de SOC - Resposta a Incidentes
# Executar como Administrador

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  INSTALACAO DE FERRAMENTAS - WINDOWS" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$allSuccess = $true

# ============================================================
# 1. Criar diretorios de trabalho
# ============================================================

Write-Host "[1/3] Criando diretorios de trabalho..." -ForegroundColor Yellow
$dirs = @("C:\Temp", "C:\Scripts", "C:\Evidencias", "C:\Installers")
foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}
Write-Host "  [OK] Diretorios criados: C:\Temp, C:\Scripts, C:\Evidencias" -ForegroundColor Green

# ============================================================
# 2. Instalar Sysinternals Suite (DOWNLOAD MANUAL)
# ============================================================

Write-Host "[2/3] Sysinternals Suite - Download Manual Necessario" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Devido ao tamanho do arquivo, o download nao pode ser automatizado." -ForegroundColor White
Write-Host "  Siga os passos abaixo:" -ForegroundColor White
Write-Host ""
Write-Host "  1. Acesse: https://download.sysinternals.com/files/SysinternalsSuite.zip" -ForegroundColor Gray
Write-Host "  2. O download será feito automaticamente" -ForegroundColor Gray
Write-Host "  3. Extraia o conteudo para C:\\Sysinternals\\" -ForegroundColor Gray
Write-Host "  4. Pressione ENTER apos concluir..." -ForegroundColor Yellow
Write-Host ""

# Aguardar confirmacao do usuario
do {
    $confirm = Read-Host "Ja baixou e extraiu o Sysinternals? (S/N)"
} while ($confirm -notmatch "^[SN]$")

if ($confirm -eq "S") {
    $sysinternalsDir = "C:\Sysinternals"
    if (Test-Path "$sysinternalsDir\autoruns.exe") {
        [Environment]::SetEnvironmentVariable("PATH", [Environment]::GetEnvironmentVariable("PATH", "Machine") + ";$sysinternalsDir", "Machine")
        $env:PATH = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        Write-Host "  [OK] Sysinternals instalado em $sysinternalsDir" -ForegroundColor Green
    } else {
        Write-Host "  [ERRO] Sysinternals nao encontrado em $sysinternalsDir" -ForegroundColor Red
        Write-Host "  Certifique-se de extrair o ZIP para C:\\Sysinternals\\" -ForegroundColor Yellow
        $allSuccess = $false
    }
} else {
    Write-Host "  [AVISO] Sysinternals nao foi instalado. Sera necessario para as aulas 4 em diante." -ForegroundColor Yellow
}

# ============================================================
# 3. Instalar Python 3 (DOWNLOAD AUTOMATICO)
# ============================================================

Write-Host ""
Write-Host "[3/3] Instalando Python 3..." -ForegroundColor Yellow

$pythonUrl = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe"
$pythonInstaller = "C:\Installers\python_installer.exe"

try {
    Write-Host "  Baixando Python 3.11.9..." -ForegroundColor Gray
    
    # Criar pasta de instaladores se nao existir
    New-Item -ItemType Directory -Path "C:\Installers" -Force | Out-Null
    
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($pythonUrl, $pythonInstaller)
    $webClient.Dispose()
    
    if (Test-Path $pythonInstaller) {
        $fileSize = (Get-Item $pythonInstaller).Length
        if ($fileSize -gt 1MB) {
            Write-Host "  Download concluido ($([math]::Round($fileSize/1MB, 1)) MB)" -ForegroundColor Gray
            Write-Host "  Executando instalador (modo silencioso)..." -ForegroundColor Gray
            
            $process = Start-Process -FilePath $pythonInstaller -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0" -Wait -PassThru
            
            if ($process.ExitCode -eq 0) {
                Remove-Item $pythonInstaller
                $env:PATH = [Environment]::GetEnvironmentVariable("PATH", "Machine")
                Write-Host "  [OK] Python 3 instalado com sucesso" -ForegroundColor Green
            } else {
                Write-Host "  [AVISO] Instalador retornou codigo $($process.ExitCode)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  [ERRO] Download do Python falhou (arquivo muito pequeno)" -ForegroundColor Red
            $allSuccess = $false
        }
    }
} catch {
    Write-Host "  [ERRO] Falha ao baixar Python: $_" -ForegroundColor Red
    Write-Host "  Solucao: Baixe manualmente de https://www.python.org/downloads/" -ForegroundColor Yellow
    Write-Host "  IMPORTANTE: Marque 'Add Python to PATH' durante a instalacao" -ForegroundColor Yellow
    $allSuccess = $false
}


# ============================================================
# Verificacao final
# ============================================================

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  VERIFICACAO RAPIDA" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Python
$pythonVersion = $null
try { $pythonVersion = python --version 2>&1 } catch {}
if ($pythonVersion -match "Python") {
    Write-Host "  [OK] Python 3 - $pythonVersion" -ForegroundColor Green
} else {
    Write-Host "  [AVISO] Python 3 - Nao detectado. Feche e reabra o terminal como Admin." -ForegroundColor Yellow
}

# Sysinternals
if (Test-Path "C:\Sysinternals\autoruns.exe") {
    Write-Host "  [OK] Sysinternals Suite - C:\\Sysinternals\\" -ForegroundColor Green
} else {
    Write-Host "  [AVISO] Sysinternals Suite - Nao encontrado" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor $(if ($allSuccess) { "Green" } else { "Yellow" })
if ($allSuccess) {
    Write-Host "  INSTALACAO CONCLUIDA COM SUCESSO!" -ForegroundColor Green
} else {
    Write-Host "  INSTALACAO CONCLUIDA COM AVISOS" -ForegroundColor Yellow
}
Write-Host "==========================================" -ForegroundColor $(if ($allSuccess) { "Green" } else { "Yellow" })
Write-Host ""
Write-Host "PROXIMO PASSO: Feche e reabra o terminal como Administrador." -ForegroundColor Yellow
Write-Host "Depois execute o script de verificacao:" -ForegroundColor White
Write-Host "  cd C:\\curso-soc-resposta-incidentes\\scripts" -ForegroundColor Gray
Write-Host "  .\\prep1_test.ps1" -ForegroundColor Gray
