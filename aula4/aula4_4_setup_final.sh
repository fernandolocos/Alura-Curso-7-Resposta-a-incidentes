#!/bin/bash
# Script de Preparacao do Laboratorio Final - Aula 4.4
# Operacao BlackVault - Cenario de ransomware com persistencia via login
# Executar como root (sudo su -)

echo "=========================================="
echo "  LABORATORIO FINAL - LINUX"
echo "  Operacao BlackVault - Aula 4.4"
echo "=========================================="
echo ""

ALL_SUCCESS=true

# ============================================================
# 1. Criptografar arquivos em /data/db (ransomware .blackvault)
# ============================================================

echo "[1/4] Criptografando arquivos de /data/db..."

for FILE in clientes.mdf vendas.ldf produtos.mdf; do
    FILEPATH="/data/db/$FILE"
    if [ -f "$FILEPATH" ]; then
        mv "$FILEPATH" "$FILEPATH.blackvault"
        echo "  [OK] Criptografado: $FILE -> $FILE.blackvault"
    fi
done

# Criar nota de resgate
cat > /data/db/README_BLACKVAULT.txt << 'EOF'
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
EOF

echo "  [OK] Nota de resgate criada: README_BLACKVAULT.txt"

# ============================================================
# 2. Criar conta backdoor monitor
# ============================================================

echo "[2/4] Criando conta backdoor monitor..."

if id "monitor" &>/dev/null; then
    echo "  [OK] Usuario monitor ja existe"
else
    useradd -m -s /bin/bash -c "Monitor Service Account" monitor
    echo "monitor:Backup@2026" | chpasswd
    usermod -aG sudo monitor
    echo "  [OK] Usuario monitor criado e adicionado ao sudo"
fi

# ============================================================
# 3. Criar binario do backdoor
# ============================================================

echo "[3/4] Criando binario do backdoor..."

cat > /tmp/.monitor-agent << 'EOF'
#!/bin/bash
# monitor-agent - simula um agente de monitoramento malicioso
LOG_FILE="/tmp/.monitor-agent.log"
while true; do
    echo "$(date) - monitor-agent executado (PID: $$)" >> "$LOG_FILE"
    sleep 60
done
EOF

chmod +x /tmp/.monitor-agent
echo "  [OK] Binario criado: /tmp/.monitor-agent"

# ============================================================
# 4. Criar script em /etc/profile.d/ (persistencia via login)
# ============================================================

echo "[4/4] Criando script em /etc/profile.d/..."

cat > /etc/profile.d/01-lsb-check.sh << 'EOF'
#!/bin/bash
# LSB check - verifica conformidade do sistema
# (na verdade, executa o backdoor em todo login)

if [ -x /tmp/.monitor-agent ]; then
    nohup /tmp/.monitor-agent > /dev/null 2>&1 &
fi
EOF

chmod +x /etc/profile.d/01-lsb-check.sh
echo "  [OK] Script /etc/profile.d/01-lsb-check.sh criado"

# ============================================================
# Verificacao
# ============================================================

echo ""
echo "=========================================="
echo "  LABORATORIO PRONTO - LINUX"
echo "=========================================="
echo ""
echo "Artefatos criados:"
echo "  - Arquivos criptografados: /data/db/*.blackvault"
echo "  - Nota de resgate: /data/db/README_BLACKVAULT.txt"
echo "  - Conta backdoor: monitor (senha: Backup@2026, grupo: sudo)"
echo "  - Script de login: /etc/profile.d/01-lsb-check.sh"
echo "  - Binario: /tmp/.monitor-agent"
echo ""
echo "Agora investigue! Use os comandos da Aula 4.4."