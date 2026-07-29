#!/bin/bash
# Script de Instalação de Ferramentas - Linux
# Curso de SOC - Resposta a Incidentes

echo "=========================================="
echo "  INSTALAÇÃO DE FERRAMENTAS - LINUX"
echo "=========================================="
echo ""

# Atualizar repositórios
echo "[1/3] Atualizando repositórios..."
sudo apt update -y && sudo apt upgrade -y
echo "  [✓] Repositórios atualizados"

# Python e pip
echo "[2/3] Instalando Python 3 e pip..."
sudo apt install -y python3 python3-pip
echo "  [✓] Python 3 e pip instalados"

# Ferramentas de rede
echo "[3/3] Instalando ferramentas de rede..."
sudo apt install -y net-tools curl wget netcat-openbsd tcpdump nmap
echo "  [✓] net-tools, curl, wget, netcat, tcpdump, nmap instalados"

# Criar diretórios de trabalho
echo ""
echo "Criando diretórios de trabalho..."
mkdir -p ~/scripts ~/temp ~/evidencias
echo "  [✓] ~/scripts, ~/temp, ~/evidencias criados"

echo ""
echo "=========================================="
echo "  INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
echo "=========================================="
echo ""
echo "Ferramentas instaladas:"
echo "  - Python 3 e pip"
echo "  - Git"
echo "  - netcat, tcpdump, nmap"
echo ""
echo "Diretórios criados:"
echo "  - ~/scripts"
echo "  - ~/temp"
echo "  - ~/evidencias"
