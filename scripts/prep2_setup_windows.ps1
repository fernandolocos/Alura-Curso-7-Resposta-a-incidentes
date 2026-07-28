# Script de Configuracao do Laboratorio - Windows
# Curso de SOC - Resposta a Incidentes
# Executar como Administrador

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  CONFIGURACAO DO LABORATORIO - WINDOWS" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$allSuccess = $true

# ============================================================
# 1. Criar usuários simulados
# ============================================================

Write-Host "[1/6] Criando usuarios simulados..." -ForegroundColor Yellow

$usuarios = @(
    @{Nome="svc_backup"; Senha="Senha123!"; Desc="Conta de servico"},
    @{Nome="carlos.oliveira"; Senha="Senha123!"; Desc="Gerente financeiro"},
    @{Nome="maria.santos"; Senha="Senha123!"; Desc="Gerente financeira"},
    @{Nome="backup_admin"; Senha="Senha123!"; Desc="Conta backdoor simulada"}
)

foreach ($user in $usuarios) {
    $exists = $null
    try { $exists = net user $user.Nome 2>&1 } catch {}
    
    if ($exists -match "Comando concluido") {
        Write-Host "  [OK] Usuario $($user.Nome) ja existe" -ForegroundColor Green
    } else {
        net user $user.Nome $user.Senha /add /fullname:"$($user.Desc)" 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Usuario $($user.Nome) criado" -ForegroundColor Green
        } else {
            Write-Host "  [ERRO] Falha ao criar $($user.Nome)" -ForegroundColor Red
            $allSuccess = $false
        }
    }
}

# ============================================================
# 2. Configurar permissões
# ============================================================

Write-Host "[2/6] Configurando permissoes..." -ForegroundColor Yellow

try {
    net localgroup Administradores svc_backup /add 2>&1 | Out-Null
    Write-Host "  [OK] svc_backup adicionado ao grupo Administradores" -ForegroundColor Green
} catch {
    Write-Host "  [!] svc_backup ja esta no grupo ou nao foi possivel adicionar" -ForegroundColor Yellow
}

# ============================================================
# 3. Criar diretórios de simulação
# ============================================================

Write-Host "[3/6] Criando diretorios de simulacao..." -ForegroundColor Yellow

$dirs = @(
    "C:\DB_Data",
    "C:\Backup",
    "C:\Evidencias",
    "C:\Quarentena",
    "C:\Users\svc_backup\AppData\Local\Temp",
    "C:\Users\svc_backup\Downloads",
    "C:\ProgramData\Google",
    "C:\Temp\sessions"
)

foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    if (Test-Path $dir) {
        Write-Host "  [OK] $dir" -ForegroundColor Green
    } else {
        Write-Host "  [ERRO] Falha ao criar $dir" -ForegroundColor Red
        $allSuccess = $false
    }
}

# ============================================================
# 4. Configurar firewall para laboratório
# ============================================================

Write-Host "[4/6] Configurando firewall para o laboratorio..." -ForegroundColor Yellow

# Habilitar ping (ICMP) da rede do laboratorio
try {
    netsh advfirewall firewall add rule name="LabSOC_ICMP" dir=in action=allow protocol=icmpv4 remoteip=192.168.56.0/24 2>&1 | Out-Null
    Write-Host "  [OK] Ping liberado para rede 192.168.56.0/24" -ForegroundColor Green
} catch {
    Write-Host "  [!] Regra de ping ja existe ou nao foi possivel criar" -ForegroundColor Yellow
}

# Para laboratorio, desabilitar firewall completamente
try {
    netsh advfirewall set allprofiles state off 2>&1 | Out-Null
    Write-Host "  [OK] Firewall desabilitado (apenas para laboratorio isolado)" -ForegroundColor Green
} catch {
    Write-Host "  [!] Nao foi possivel desabilitar firewall" -ForegroundColor Yellow
}

Write-Host "  [AVISO] Firewall desabilitado apenas para ambiente de laboratorio!" -ForegroundColor Yellow

# ============================================================
# 5. Criar arquivos de dados simulados
# ============================================================

Write-Host "[5/6] Criando arquivos de dados simulados..." -ForegroundColor Yellow

$dataFiles = @(
    @{Name="clientes.mdf"; Content="DADOS SIMULADOS - CLIENTES - TechVarejo S.A. - Registro de clientes ativos e inativos com dados de contato."},
    @{Name="vendas.ldf"; Content="DADOS SIMULADOS - VENDAS - TechVarejo S.A. - Log de transacoes de vendas dos ultimos 12 meses."},
    @{Name="produtos.mdf"; Content="DADOS SIMULADOS - PRODUTOS - TechVarejo S.A. - Catalogo completo de produtos com precos e estoque."},
    @{Name="financeiro.ldf"; Content="DADOS SIMULADOS - FINANCEIRO - TechVarejo S.A. - Registros financeiros, contas a pagar e receber."},
    @{Name="rh_dados.mdf"; Content="DADOS SIMULADOS - RH - TechVarejo S.A. - Dados de funcionarios, folha de pagamento e beneficios."}
)

# Criar arquivos de dados em DB_Data
foreach ($file in $dataFiles) {
    $path = Join-Path "C:\DB_Data" $file.Name
    $file.Content | Out-File -FilePath $path -Encoding UTF8
    if (Test-Path $path) {
        Write-Host "  [OK] $($file.Name)" -ForegroundColor Green
    }
}

# Criar backups identicos e gerar MANIFESTO
Write-Host "  [*] Criando backups e gerando manifesto..." -ForegroundColor Gray
$manifestoBackup = @()
$manifestoBackup += "# Manifesto de Integridade - Backup SRV-DB-01"
$manifestoBackup += "# Gerado em: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$manifestoBackup += "#"

foreach ($file in $dataFiles) {
    $path = Join-Path "C:\Backup" $file.Name
    $file.Content | Out-File -FilePath $path -Encoding UTF8
    
    # Calcular hash para o manifesto
    $hash = (Get-FileHash -Path $path -Algorithm SHA256).Hash
    $manifestoBackup += "$hash  $($file.Name)"
}

# Salvar manifesto
$manifestoBackup | Out-File "C:\Backup\manifesto_backup.sha256" -Encoding UTF8
Write-Host "  [OK] Backups criados em C:\Backup\" -ForegroundColor Green
Write-Host "  [OK] Manifesto de integridade gerado: C:\Backup\manifesto_backup.sha256" -ForegroundColor Green

# ============================================================
# 6. Configurar permissões nos diretórios
# ============================================================

Write-Host "[6/6] Configurando permissoes nos diretorios..." -ForegroundColor Yellow

try {
    icacls "C:\DB_Data" /grant "svc_backup:(OI)(CI)F" 2>&1 | Out-Null
    icacls "C:\Backup" /grant "svc_backup:(OI)(CI)F" 2>&1 | Out-Null
    Write-Host "  [OK] Permissoes configuradas" -ForegroundColor Green
} catch {
    Write-Host "  [!] Nao foi possivel configurar permissoes (pode nao ser necessario)" -ForegroundColor Yellow
}

# ============================================================
# Resumo
# ============================================================

Write-Host ""
Write-Host "==========================================" -ForegroundColor $(if ($allSuccess) { "Green" } else { "Yellow" })
if ($allSuccess) {
    Write-Host "  CONFIGURACAO CONCLUIDA COM SUCESSO!" -ForegroundColor Green
} else {
    Write-Host "  CONFIGURACAO CONCLUIDA COM AVISOS" -ForegroundColor Yellow
}
Write-Host "==========================================" -ForegroundColor $(if ($allSuccess) { "Green" } else { "Yellow" })
Write-Host ""
Write-Host "Resumo do que foi configurado:" -ForegroundColor White
Write-Host "  [OK] Usuarios: svc_backup, carlos.oliveira, maria.santos" -ForegroundColor Green
Write-Host "  [OK] Diretorios: DB_Data, Backup, Evidencias, Quarentena" -ForegroundColor Green
Write-Host "  [OK] Arquivos de dados criados (5 arquivos)" -ForegroundColor Green
Write-Host "  [OK] Backups criados (5 arquivos)" -ForegroundColor Green
Write-Host "  [OK] Manifesto de integridade gerado" -ForegroundColor Green
Write-Host "  [OK] Firewall desabilitado para laboratorio" -ForegroundColor Green
Write-Host "  [OK] Ping liberado entre VMs" -ForegroundColor Green
Write-Host ""
Write-Host "Execute o script de verificacao:" -ForegroundColor Yellow
Write-Host "  .\prep2_test.ps1" -ForegroundColor Gray