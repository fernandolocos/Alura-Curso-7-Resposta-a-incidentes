# Script de Verificacao do Ambiente - Parte 2 (Windows)
# Curso de SOC - Resposta a Incidentes

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  VERIFICACAO DO AMBIENTE - PARTE 2" -ForegroundColor Cyan
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

# 1. Verificar usuários
Write-Host "--- Usuarios Simulados ---" -ForegroundColor Yellow

$usuarios = @("svc_backup", "carlos.oliveira", "maria.santos")
foreach ($user in $usuarios) {
    $result = $null
    try { 
        $result = net user $user 2>&1 | Out-String
    } catch {}
    
    $exists = $result -match "Nome completo|Nome de usu.rio|User name"
    
    Test-Check -Description "Usuario $user" `
        -Condition $exists `
        -PassedMessage "Criado" `
        -FailedMessage "Nao encontrado. Execute prep2_setup_windows.ps1"
}

# 2. Verificar svc_backup no grupo Administradores
Write-Host ""
Write-Host "--- Permissoes ---" -ForegroundColor Yellow

$isAdmin = $false

# Metodo via PowerShell (mais confiavel)
try {
    $adminGroup = Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop
    $isAdmin = ($adminGroup.Name | Where-Object { $_ -match "svc_backup" }) -ne $null
} catch {
    # Fallback: net localgroup
    $grupoResult = net localgroup "Administrators" 2>&1 | Out-String
    $isAdmin = $grupoResult -match "svc_backup"
}

# Se nao encontrou, tentar adicionar
if (-not $isAdmin) {
    Write-Host "  [!] svc_backup nao esta no grupo. Tentando adicionar..." -ForegroundColor Yellow
    try {
        net localgroup "Administrators" svc_backup /add 2>&1 | Out-Null
        # Verificar novamente
        try {
            $adminGroup = Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop
            $isAdmin = ($adminGroup.Name | Where-Object { $_ -match "svc_backup" }) -ne $null
        } catch {
            $grupoResult = net localgroup "Administrators" 2>&1 | Out-String
            $isAdmin = $grupoResult -match "svc_backup"
        }
    } catch {}
}

Test-Check -Description "svc_backup no grupo Administrators" `
    -Condition $isAdmin `
    -PassedMessage "Confirmado" `
    -FailedMessage "Nao foi possivel adicionar. Execute manualmente: net localgroup Administrators svc_backup /add"

# 3. Verificar diretórios
Write-Host ""
Write-Host "--- Diretorios de Simulacao ---" -ForegroundColor Yellow

$dirs = @(
    @{Path="C:\DB_Data"; Desc="Banco de dados"},
    @{Path="C:\Backup"; Desc="Backups"},
    @{Path="C:\Evidencias"; Desc="Evidencias"},
    @{Path="C:\Quarentena"; Desc="Quarentena"}
)

foreach ($dir in $dirs) {
    $exists = Test-Path $dir.Path
    Test-Check -Description $dir.Desc `
        -Condition $exists `
        -PassedMessage $dir.Path `
        -FailedMessage "Nao encontrado. Execute prep2_setup_windows.ps1"
}

# 4. Verificar arquivos de dados
Write-Host ""
Write-Host "--- Arquivos de Dados ---" -ForegroundColor Yellow

$dataFiles = @("clientes.mdf", "vendas.ldf", "produtos.mdf", "financeiro.ldf", "rh_dados.mdf")
$dataCount = 0
foreach ($file in $dataFiles) {
    $path = Join-Path "C:\DB_Data" $file
    if (Test-Path $path) { $dataCount++ }
}

Test-Check -Description "Arquivos de banco de dados" `
    -Condition ($dataCount -eq 5) `
    -PassedMessage "$dataCount de 5 arquivos" `
    -FailedMessage "Apenas $dataCount de 5 encontrados"

$backupCount = 0
foreach ($file in $dataFiles) {
    $path = Join-Path "C:\Backup" $file
    if (Test-Path $path) { $backupCount++ }
}

Test-Check -Description "Arquivos de backup" `
    -Condition ($backupCount -eq 5) `
    -PassedMessage "$backupCount de 5 arquivos" `
    -FailedMessage "Apenas $backupCount de 5 encontrados"

# 5. Verificar conectividade com VM Linux
Write-Host ""
Write-Host "--- Conectividade ---" -ForegroundColor Yellow

$pingResult = Test-Connection -ComputerName 192.168.56.20 -Count 1 -Quiet -ErrorAction SilentlyContinue
Test-Check -Description "Conexao com VM Linux (192.168.56.20)" `
    -Condition $pingResult `
    -PassedMessage "Ping OK" `
    -FailedMessage "Sem resposta. Verifique se a VM Linux esta rodando."
	
# 6. Verificar manifesto de integridade
Write-Host ""
Write-Host "--- Manifesto de Integridade ---" -ForegroundColor Yellow

$manifestoExists = Test-Path "C:\Backup\manifesto_backup.sha256"
Test-Check -Description "Manifesto de integridade do backup" `
    -Condition $manifestoExists `
    -PassedMessage "C:\Backup\manifesto_backup.sha256" `
    -FailedMessage "Manifesto nao encontrado. Execute prep2_setup_windows.ps1 novamente."

if ($manifestoExists) {
    $manifestoContent = Get-Content "C:\Backup\manifesto_backup.sha256"
    $manifestoCount = ($manifestoContent | Where-Object { $_ -notmatch "^#" -and $_ -ne "" }).Count
    Test-Check -Description "Hashes no manifesto" `
        -Condition ($manifestoCount -eq 5) `
        -PassedMessage "$manifestoCount hashes (5 esperados)" `
        -FailedMessage "Apenas $manifestoCount hashes. Esperado: 5"
}

# Resultado final
Write-Host ""
if ($allPassed) {
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "  AMBIENTE APROVADO - PRONTO PARA AS AULAS" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
} else {
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host "  PROBLEMAS ENCONTRADOS - VEJA ACIMA" -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Red
}