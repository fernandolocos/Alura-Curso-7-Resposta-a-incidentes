# Script de Preparacao do Laboratorio Final - Aula 4.4
# Operacao BlackVault - Cenario de ransomware com persistencia via login
# Executar como Administrador

# ============================================================
# Verificacao inicial: precisa ser Administrador
# ============================================================

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host "  ERRO: Este script precisa ser executado como Administrador" -ForegroundColor Red
    Write-Host "  Abra o PowerShell como Administrador e execute novamente" -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Red
    exit 1
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  LABORATORIO FINAL - WINDOWS" -ForegroundColor Cyan
Write-Host "  Operacao BlackVault - Aula 4.4" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$allSuccess = $true

# ============================================================
# Detectar nome do grupo de administradores
# ============================================================

$adminGroupName = $null
try {
    $adminGroup = Get-LocalGroup -SID "S-1-5-32-544" -ErrorAction Stop
    $adminGroupName = $adminGroup.Name
} catch {
    $adminGroupName = "Administrators"
}
Write-Host "[i] Grupo de administradores detectado: $adminGroupName" -ForegroundColor Gray
Write-Host ""

# ============================================================
# Funcao: ofuscar conteudo de um arquivo (simula criptografia)
# ============================================================

function Get-ObfuscatedContent {
    param([string]$FilePath)
    
    $originalContent = Get-Content $FilePath -Raw -ErrorAction SilentlyContinue
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($originalContent)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $obfuscated = "BLACKVAULT-ENCRYPTED-AES256`n" + $base64
    
    return $obfuscated
}

# ============================================================
# 1. Criptografar arquivos em C:\DB_Data
# ============================================================

Write-Host "[1/4] Criptografando arquivos de C:\DB_Data..." -ForegroundColor Yellow

$dataDir = "C:\DB_Data"
$files = @("clientes.mdf", "vendas.ldf", "produtos.mdf", "financeiro.ldf", "rh_dados.mdf")

foreach ($file in $files) {
    $filePath = Join-Path $dataDir $file
    $encryptedPath = Join-Path $dataDir "$file.blackvault"
    
    if (Test-Path $filePath) {
        # Se o arquivo .blackvault ja existe, remover antes de renomear
        if (Test-Path $encryptedPath) {
            Remove-Item -Path $encryptedPath -Force -ErrorAction SilentlyContinue
        }
        
        # Ofuscar o conteudo
        $obfuscatedContent = Get-ObfuscatedContent -FilePath $filePath
        $obfuscatedContent | Out-File -FilePath $filePath -Encoding UTF8 -Force
        
        # Renomear para .blackvault
        Rename-Item -Path $filePath -NewName "$file.blackvault" -ErrorAction SilentlyContinue
        Write-Host "  [OK] Criptografado: $file -> $file.blackvault" -ForegroundColor Gray
    } elseif (Test-Path $encryptedPath) {
        Write-Host "  [OK] Ja criptografado: $file.blackvault" -ForegroundColor Gray
    } else {
        Write-Host "  [!] Arquivo nao encontrado: $filePath" -ForegroundColor Yellow
    }
}

# Criar nota de resgate
$ransomNote = @"
==========================================
        OPERACAO BLACKVAULT
==========================================

Todos os seus arquivos de banco de dados
foram criptografados.

Para recuperar seus dados, pague 15 BTC para:
  1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa

Contato: blackvault@protonmail.com
ID da vitima: BV-2026-0619-042

PRAZO: 48 horas.

NAO TENTE recuperar sozinho.
NAO CONTATE a policia.

==========================================
"@

$ransomNote | Out-File "$dataDir\README_BLACKVAULT.txt" -Encoding UTF8
Write-Host "  [OK] Nota de resgate criada: README_BLACKVAULT.txt" -ForegroundColor Green

# ============================================================
# 2. Criar conta backdoor svc_monitor
# ============================================================

Write-Host "[2/4] Criando conta backdoor svc_monitor..." -ForegroundColor Yellow

$existingUser = $null
try { $existingUser = Get-LocalUser -Name "svc_monitor" -ErrorAction Stop } catch {}

if ($existingUser) {
    Write-Host "  [OK] Usuario svc_monitor ja existe" -ForegroundColor Green
} else {
    try {
        $password = ConvertTo-SecureString "Backup@2026" -AsPlainText -Force
        New-LocalUser -Name "svc_monitor" -Password $password -FullName "Service Monitor Account" -PasswordNeverExpires -ErrorAction Stop | Out-Null
        Write-Host "  [OK] Usuario svc_monitor criado" -ForegroundColor Green
    } catch {
        Write-Host "  [ERRO] Falha ao criar usuario svc_monitor: $_" -ForegroundColor Red
        $allSuccess = $false
    }
}

# Verificar se ja esta no grupo
$isInGroup = $false
try {
    $members = Get-LocalGroupMember -Group $adminGroupName -ErrorAction Stop
    if ($members.Name -match "svc_monitor") {
        $isInGroup = $true
    }
} catch {}

if ($isInGroup) {
    Write-Host "  [OK] svc_monitor ja esta em $adminGroupName" -ForegroundColor Green
} else {
    try {
        Add-LocalGroupMember -Group $adminGroupName -Member "svc_monitor" -ErrorAction Stop
        
        $members = Get-LocalGroupMember -Group $adminGroupName -ErrorAction SilentlyContinue
        if ($members.Name -match "svc_monitor") {
            Write-Host "  [OK] svc_monitor adicionado a $adminGroupName" -ForegroundColor Green
        } else {
            Write-Host "  [ERRO] Falha ao adicionar svc_monitor a $adminGroupName" -ForegroundColor Red
            $allSuccess = $false
        }
    } catch {
        Write-Host "  [ERRO] Falha ao adicionar svc_monitor a $adminGroupName" -ForegroundColor Red
        $allSuccess = $false
    }
}

# ============================================================
# 3. Criar binario do backdoor
# ============================================================

Write-Host "[3/4] Criando binario do backdoor..." -ForegroundColor Yellow

$backdoorDir = "C:\ProgramData\Microsoft"
New-Item -ItemType Directory -Path $backdoorDir -Force | Out-Null

$backdoorContent = @"
@echo off
REM monitor_agent.exe - simula um agente de monitoramento malicioso
echo [%date% %time%] monitor_agent executado >> C:\ProgramData\Microsoft\monitor_agent.log
"@

$backdoorContent | Out-File "$backdoorDir\monitor_agent.exe" -Encoding ASCII

if (Test-Path "$backdoorDir\monitor_agent.exe") {
    Write-Host "  [OK] Binario criado: $backdoorDir\monitor_agent.exe" -ForegroundColor Green
} else {
    Write-Host "  [ERRO] Falha ao criar binario" -ForegroundColor Red
    $allSuccess = $false
}

# ============================================================
# 4. Criar tarefa agendada com trigger de logon
# ============================================================

Write-Host "[4/4] Criando tarefa agendada com trigger de logon..." -ForegroundColor Yellow

$taskName = "MicrosoftEdgeUpdateTask"

try {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop
    Write-Host "  [i] Tarefa anterior removida" -ForegroundColor Gray
} catch {}

$action = New-ScheduledTaskAction -Execute "$backdoorDir\monitor_agent.exe"
$logonTrigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

try {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $logonTrigger -Settings $settings -Description "Microsoft Edge Update Task" -Force -ErrorAction Stop | Out-Null
    
    $taskCheck = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($taskCheck) {
        Write-Host "  [OK] Tarefa '$taskName' criada com trigger de logon" -ForegroundColor Green
    } else {
        Write-Host "  [ERRO] Tarefa nao foi criada" -ForegroundColor Red
        $allSuccess = $false
    }
} catch {
    Write-Host "  [ERRO] Falha ao criar tarefa: $_" -ForegroundColor Red
    $allSuccess = $false
}

# ============================================================
# Verificacao final
# ============================================================

Write-Host ""
Write-Host "==========================================" -ForegroundColor $(if ($allSuccess) { "Green" } else { "Red" })
if ($allSuccess) {
    Write-Host "  LABORATORIO PRONTO - WINDOWS" -ForegroundColor Green
} else {
    Write-Host "  LABORATORIO COM ERROS - VERIFIQUE ACIMA" -ForegroundColor Red
}
Write-Host "==========================================" -ForegroundColor $(if ($allSuccess) { "Green" } else { "Red" })
Write-Host ""
Write-Host "Verificacao de artefatos:" -ForegroundColor White
Write-Host ""

if (Test-Path "C:\DB_Data\README_BLACKVAULT.txt") {
    Write-Host "  [OK] Nota de resgate" -ForegroundColor Green
} else {
    Write-Host "  [ ] Nota de resgate NAO CRIADA" -ForegroundColor Red
}

$encryptedCount = (Get-ChildItem "C:\DB_Data\*.blackvault" -ErrorAction SilentlyContinue).Count
if ($encryptedCount -gt 0) {
    Write-Host "  [OK] Arquivos criptografados: $encryptedCount arquivos" -ForegroundColor Green
} else {
    Write-Host "  [ ] Arquivos .blackvault NAO CRIADOS" -ForegroundColor Red
}

$userFinal = Get-LocalUser -Name "svc_monitor" -ErrorAction SilentlyContinue
if ($userFinal) {
    Write-Host "  [OK] Conta backdoor: svc_monitor" -ForegroundColor Green
} else {
    Write-Host "  [ ] Conta svc_monitor NAO CRIADA" -ForegroundColor Red
}

$groupFinal = Get-LocalGroupMember -Group $adminGroupName -ErrorAction SilentlyContinue
if ($groupFinal.Name -match "svc_monitor") {
    Write-Host "  [OK] svc_monitor em $adminGroupName" -ForegroundColor Green
} else {
    Write-Host "  [ ] svc_monitor NAO esta em $adminGroupName" -ForegroundColor Red
}

if (Test-Path "C:\ProgramData\Microsoft\monitor_agent.exe") {
    Write-Host "  [OK] Binario: monitor_agent.exe" -ForegroundColor Green
} else {
    Write-Host "  [ ] Binario NAO CRIADO" -ForegroundColor Red
}

$taskFinal = Get-ScheduledTask -TaskName "MicrosoftEdgeUpdateTask" -ErrorAction SilentlyContinue
if ($taskFinal) {
    Write-Host "  [OK] Tarefa agendada: MicrosoftEdgeUpdateTask" -ForegroundColor Green
} else {
    Write-Host "  [ ] Tarefa NAO CRIADA" -ForegroundColor Red
}

Write-Host ""
Write-Host "Agora investigue! Use os comandos da Aula 4.4." -ForegroundColor Yellow
