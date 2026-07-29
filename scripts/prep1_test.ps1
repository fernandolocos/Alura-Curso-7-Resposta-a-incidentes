# Script de Verificacao do Ambiente - VM Windows
# Curso de SOC - Resposta a Incidentes
# Executar dentro da VM Windows como Administrador

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  VERIFICACAO DO AMBIENTE - VM WINDOWS" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$allPassed = $true

function Test-Check {
    param(
        [string]$Description,
        [bool]$Condition,
        [string]$PassedMessage,
        [string]$FailedMessage
    )
    
    if ($Condition) {
        Write-Host "[OK] $Description - $PassedMessage" -ForegroundColor Green
    } else {
        Write-Host "[FALHA] $Description - $FailedMessage" -ForegroundColor Red
        $script:allPassed = $false
    }
}

# 1. Verificar Python
Write-Host "--- Ferramentas de Desenvolvimento ---" -ForegroundColor Yellow

$pythonVersion = $null
try { 
    $pythonVersion = python --version 2>&1 
} catch {}

Test-Check -Description "Python 3 instalado" `
    -Condition ($pythonVersion -match "Python 3") `
    -PassedMessage $pythonVersion.Trim() `
    -FailedMessage "Python nao encontrado. Execute install_tools_windows.ps1 novamente."

# 2. Verificar Git
$gitVersion = $null
try { 
    $gitVersion = git --version 2>&1 
} catch {}

Test-Check -Description "Git instalado" `
    -Condition ($gitVersion -match "git version") `
    -PassedMessage $gitVersion.Trim() `
    -FailedMessage "Git nao encontrado. Execute install_tools_windows.ps1 novamente."

# 3. Verificar Sysinternals
Write-Host ""
Write-Host "--- Sysinternals Suite ---" -ForegroundColor Yellow

$sysinternalsDir = "C:\Sysinternals"
$autorunsExists = Test-Path "$sysinternalsDir\autoruns.exe"
$procexpExists = Test-Path "$sysinternalsDir\procexp.exe"
$procmonExists = Test-Path "$sysinternalsDir\procmon.exe"

$sysinternalsOK = $autorunsExists -and $procexpExists -and $procmonExists

Test-Check -Description "Sysinternals Suite em C:\Sysinternals" `
    -Condition $sysinternalsOK `
    -PassedMessage "Encontrada (autoruns, procexp, procmon)" `
    -FailedMessage "Sysinternals nao encontrado. Execute install_tools_windows.ps1 novamente."

# 4. Verificar diretórios de trabalho
Write-Host ""
Write-Host "--- Diretorios de Trabalho ---" -ForegroundColor Yellow

$dirs = @(
    @{Path="C:\Temp"; Desc="Arquivos temporarios"},
    @{Path="C:\Scripts"; Desc="Scripts do curso"},
    @{Path="C:\Evidencias"; Desc="Coleta de evidencias"}
)

foreach ($dir in $dirs) {
    $exists = Test-Path $dir.Path
    Test-Check -Description "$($dir.Desc) ($($dir.Path))" `
        -Condition $exists `
        -PassedMessage "Existe" `
        -FailedMessage "Nao encontrado. Crie manualmente com: mkdir $($dir.Path)"
}

# 5. Verificar repositório do curso
Write-Host ""
Write-Host "--- Repositorio do Curso ---" -ForegroundColor Yellow

$repoPath = "C:\curso-soc-resposta-incidentes"
$repoExists = Test-Path "$repoPath\README.md"

Test-Check -Description "Repositorio clonado em $repoPath" `
    -Condition $repoExists `
    -PassedMessage "Encontrado" `
    -FailedMessage "Repositorio nao encontrado. Execute: cd C:\ && git clone https://github.com/alura-cursos/6258-soc-resposta-incidentes.git"

# 6. Verificar comandos nativos do Windows
Write-Host ""
Write-Host "--- Comandos Nativos do Windows ---" -ForegroundColor Yellow

$nativeCommands = @(
    @{Cmd="netstat.exe"; Desc="netstat (conexoes de rede)"},
    @{Cmd="tasklist.exe"; Desc="tasklist (processos)"},
    @{Cmd="netsh.exe"; Desc="netsh (firewall e rede)"},
    @{Cmd="schtasks.exe"; Desc="schtasks (tarefas agendadas)"},
    @{Cmd="reg.exe"; Desc="reg (registro do Windows)"},
    @{Cmd="net.exe"; Desc="net (usuarios e grupos)"}
)

foreach ($cmd in $nativeCommands) {
    $result = Get-Command $cmd.Cmd -ErrorAction SilentlyContinue
    Test-Check -Description $cmd.Desc `
        -Condition ($result -ne $null) `
        -PassedMessage "Disponivel" `
        -FailedMessage "Nao encontrado. Verifique a instalacao do Windows."
}

# 7. Verificar conectividade de rede
Write-Host ""
Write-Host "--- Conectividade de Rede ---" -ForegroundColor Yellow

$pingResult = Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet -ErrorAction SilentlyContinue
Test-Check -Description "Acesso a internet (NAT)" `
    -Condition $pingResult `
    -PassedMessage "Ping 8.8.8.8 OK" `
    -FailedMessage "Sem acesso a internet. Verifique o adaptador NAT no VirtualBox."

# 8. Verificar espaço em disco
Write-Host ""
Write-Host "--- Recursos do Sistema ---" -ForegroundColor Yellow

$disk = Get-PSDrive C
$freeGB = [math]::Round($disk.Free / 1GB, 1)
$totalGB = [math]::Round(($disk.Free + $disk.Used) / 1GB, 1)
$freeOK = $freeGB -ge 10

Test-Check -Description "Espaco livre em disco" `
    -Condition $freeOK `
    -PassedMessage "$freeGB GB livres de $totalGB GB" `
    -FailedMessage "Apenas $freeGB GB livres. Recomendado: 10 GB minimo."

# Resultado final
Write-Host ""
if ($allPassed) {
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "  VM WINDOWS PRONTA PARA O CURSO" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
} else {
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host "  PROBLEMAS ENCONTRADOS - VERIFIQUE OS ITENS ACIMA" -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Red
}
