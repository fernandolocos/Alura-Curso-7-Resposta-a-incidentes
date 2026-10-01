<#
Script de Simulacao de Conexao C2 - Aula 3.2
Curso de SOC - Resposta a Incidentes

Este script simula uma conexao de malware com um servidor C2.
A VM Linux atua como servidor C2.
A conexao REAL entre as VMs eh derrubada pelo bloqueio.
#>

Write-Host "========================================" -ForegroundColor Red
Write-Host "  SIMULACAO DE CONEXAO C2 - AULA 3.2" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""

$c2IP = "192.168.56.20"
$c2Port = 4444

Write-Host "Este script simula um malware tentando se comunicar" -ForegroundColor Yellow
Write-Host "com um servidor C2 localizado na VM Linux." -ForegroundColor Yellow
Write-Host ""
Write-Host "Configuracao:" -ForegroundColor Cyan
Write-Host "  IP do C2: $c2IP" -ForegroundColor Gray
Write-Host "  Porta C2: $c2Port" -ForegroundColor Gray
Write-Host ""

Write-Host "[*] Verificando conectividade com o C2..." -ForegroundColor Yellow
$pingResult = Test-Connection -ComputerName $c2IP -Count 1 -Quiet

if (-not $pingResult) {
    Write-Host "[ERRO] VM Linux ($c2IP) nao esta respondendo." -ForegroundColor Red
    Write-Host "       Verifique se a VM Linux esta rodando." -ForegroundColor Red
    Write-Host "       Execute 'vagrant up linux' se necessario." -ForegroundColor Red
    pause
    exit 1
}

Write-Host "[OK] VM Linux acessivel em $c2IP" -ForegroundColor Green
Write-Host ""

Write-Host "[*] Iniciando beacon C2..." -ForegroundColor Yellow
Write-Host "    O malware esta tentando conectar ao C2 a cada 5 segundos." -ForegroundColor Gray
Write-Host "    Deixe este terminal aberto e execute a CONTENCAO em OUTRO terminal." -ForegroundColor Yellow
Write-Host ""
Write-Host "    Pressione Ctrl+C para encerrar a simulacao." -ForegroundColor Gray
Write-Host ""

$logFile = "C:\Evidencias\c2_beacon.log"
$beaconCount = 0

try {
    while ($true) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $timeout = 2000
            
            $result = $tcp.BeginConnect($c2IP, $c2Port, $null, $null)
            
            if ($result.AsyncWaitHandle.WaitOne($timeout, $false)) {
                $tcp.EndConnect($result)
                $beaconCount++
                
                $msg = "$timestamp - [BEACON $beaconCount] Conexao C2 estabelecida com $c2IP`:$c2Port"
                Write-Host $msg -ForegroundColor Green
                Add-Content -Path $logFile -Value $msg
                
                $stream = $tcp.GetStream()
                $data = [System.Text.Encoding]::ASCII.GetBytes("BEACON: sistema comprometido`n")
                $stream.Write($data, 0, $data.Length)
                $stream.Close()
            } else {
                $msg = "$timestamp - [BLOQUEADO] Conexao C2 bloqueada"
                Write-Host $msg -ForegroundColor Red
                Add-Content -Path $logFile -Value $msg
            }
            
            $tcp.Close()
        } catch {
            $msg = "$timestamp - [BLOQUEADO] Conexao C2 bloqueada"
            Write-Host $msg -ForegroundColor Red
            Add-Content -Path $logFile -Value $msg
        }
        
        Start-Sleep -Seconds 5
    }
} finally {
    Write-Host ""
    Write-Host "[*] Simulacao encerrada." -ForegroundColor Yellow
    Write-Host "    Total de beacons bem-sucedidos: $beaconCount" -ForegroundColor Cyan
    Write-Host "    Log salvo em: $logFile" -ForegroundColor Gray
}