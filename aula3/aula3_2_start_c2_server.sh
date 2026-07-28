#!/bin/bash
# Script do Servidor C2 Simulado - Aula 3.2
# Executar na VM Linux ANTES de iniciar a simulacao no Windows

C2_PORT=4444
LOG_FILE="/tmp/c2_server.log"

echo "=========================================="
echo "  SERVIDOR C2 SIMULADO - AULA 3.2"
echo "=========================================="
echo ""
echo "Este script simula um servidor C2 do atacante."
echo "A VM Windows ira se conectar a esta maquina."
echo ""
echo "Configuracao:"
echo "  Porta: $C2_PORT"
echo "  Log: $LOG_FILE"
echo ""
echo "Deixe este terminal aberto enquanto executa o laboratorio."
echo "Pressione Ctrl+C para encerrar."
echo ""

echo "[*] Aguardando conexoes na porta $C2_PORT..."
echo ""

while true; do
    echo "======================================" | tee -a "$LOG_FILE"
    echo " $(date) - Aguardando conexao..." | tee -a "$LOG_FILE"
    
    nc -l -p $C2_PORT -w 5 | while read line; do
        echo "[$(date)] DADOS RECEBIDOS: $line" | tee -a "$LOG_FILE"
    done
    
    sleep 1
done
