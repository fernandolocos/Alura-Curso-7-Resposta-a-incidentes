# Script de Preparacao do Laboratorio - Aula 4.1
# Cria artefatos simulados de backdoor no Windows
# Executar como Administrador

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  PREPARACAO DO LABORATORIO - WINDOWS" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Criar diretorio e script de backdoor
Write-Host "[1/5] Criando backdoor..." -ForegroundColor Yellow
$backdoorDir = "C:\ProgramData\Microsoft"
New-Item -ItemType Directory -Path $backdoorDir -Force | Out-Null

@"
@echo off
REM Script de backdoor - mantem acesso remoto
echo Backdoor ativa em %date% %time% >> C:\ProgramData\Microsoft\backdoor.log
"@ | Out-File "$backdoorDir\winupdate.bat" -Encoding ASCII

Write-Host "  [OK] Script criado: $backdoorDir\winupdate.bat" -ForegroundColor Green

# 2. Criar tarefa agendada suspeita
Write-Host "[2/5] Criando tarefa agendada suspeita..." -ForegroundColor Yellow
schtasks /create /tn "WindowsUpdate" /tr "C:\ProgramData\Microsoft\winupdate.bat" /sc daily /st 02:00 /f 2>$null
Write-Host "  [OK] Tarefa 'WindowsUpdate' criada" -ForegroundColor Green

# 3. Adicionar persistencia no registro
Write-Host "[3/5] Adicionando persistencia no registro..." -ForegroundColor Yellow
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "Windows Service" /t REG_SZ /d "C:\ProgramData\Microsoft\winupdate.bat" /f 2>$null
Write-Host "  [OK] Entrada 'Windows Service' adicionada ao Run" -ForegroundColor Green

# 4. Criar regra de firewall suspeita
Write-Host "[4/5] Criando regra de firewall suspeita..." -ForegroundColor Yellow
netsh advfirewall firewall add rule name="Allow_SSH_Backdoor" dir=in localport=2222 protocol=tcp action=allow 2>$null
Write-Host "  [OK] Regra 'Allow_SSH_Backdoor' porta 2222 criada" -ForegroundColor Green

# 5. Simular listener em porta suspeita
Write-Host "[5/5] Simulando listener na porta 2222..." -ForegroundColor Yellow
$job = Start-Job -ScriptBlock {
    $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, 2222)
    $listener.Start()
    while ($true) { Start-Sleep -Seconds 3600 }
}
Write-Host "  [OK] Listener iniciado na porta 2222 (Job ID: $($job.Id))" -ForegroundColor Green

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  LABORATORIO PRONTO - WINDOWS" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Artefatos criados:" -ForegroundColor White
Write-Host "  - Backdoor: C:\ProgramData\Microsoft\winupdate.bat" -ForegroundColor Gray
Write-Host "  - Tarefa: WindowsUpdate (diaria as 02:00)" -ForegroundColor Gray
Write-Host "  - Registro: HKLM\...\Run\Windows Service" -ForegroundColor Gray
Write-Host "  - Firewall: Regra Allow_SSH_Backdoor porta 2222" -ForegroundColor Gray
Write-Host "  - Listener: Porta 2222" -ForegroundColor Gray
Write-Host ""
Write-Host "Agora investigue! Use netstat, schtasks, reg query, Get-NetFirewallRule." -ForegroundColor Yellow