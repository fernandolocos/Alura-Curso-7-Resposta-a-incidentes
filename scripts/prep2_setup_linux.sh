#!/bin/bash
# Script de Configuracao do Laboratorio - Linux
# Curso de SOC - Resposta a Incidentes

echo "=========================================="
echo "  CONFIGURACAO DO LABORATORIO - LINUX"
echo "=========================================="
echo ""

ALL_SUCCESS=true

# ============================================================
# 1. Criar usuários simulados
# ============================================================

echo "[1/5] Criando usuarios simulados..."

declare -A USUARIOS
USUARIOS[svc_backup]="Conta de servico"
USUARIOS[carlos.oliveira]="Gerente financeiro"

for USER in "${!USUARIOS[@]}"; do
    if id "$USER" &>/dev/null; then
        echo "  [OK] Usuario $USER ja existe"
    else
        sudo useradd -m "$USER" -c "${USUARIOS[$USER]}" -s /bin/bash
        echo "$USER:Senha123!" | sudo chpasswd
        echo "  [OK] Usuario $USER criado"
    fi
done

# ============================================================
# 2. Configurar SSH para o laboratorio
# ============================================================

echo "[2/5] Configurando SSH para o laboratorio..."

# Habilitar autenticacao por senha
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication no/' /etc/ssh/sshd_config
sudo rm /etc/ssh/sshd_config.d/60-cloudimg-settings.conf

# Reiniciar o servico SSH
sudo systemctl restart ssh

# Verificar status
if sudo systemctl is-active --quiet ssh; then
    echo "  [OK] SSH configurado e rodando"
else
    echo "  [ERRO] Falha ao reiniciar o SSH"
    ALL_SUCCESS=false
fi

# ============================================================
# 3. Criar diretórios de simulação
# ============================================================

echo "[3/5] Criando diretorios de simulacao..."

DIRS=(
    "/data/db"
    "/backup"
    "/evidencias"
    "/quarentena"
    "/tmp/sessions"
)

for DIR in "${DIRS[@]}"; do
    sudo mkdir -p "$DIR"
    if [ -d "$DIR" ]; then
        echo "  [OK] $DIR"
    else
        echo "  [ERRO] Falha ao criar $DIR"
        ALL_SUCCESS=false
    fi
done

# ============================================================
# 4. Criar arquivos de dados simulados E MANIFESTOS
# ============================================================

echo "[4/5] Criando arquivos de dados simulados..."

declare -A DATA_FILES
DATA_FILES[clientes.mdf]="DADOS SIMULADOS - CLIENTES - Registro de clientes ativos e inativos com dados de contato."
DATA_FILES[vendas.ldf]="DADOS SIMULADOS - VENDAS - Log de transacoes de vendas dos ultimos 12 meses."
DATA_FILES[produtos.mdf]="DADOS SIMULADOS - PRODUTOS - Catalogo completo de produtos com precos e estoque."

# Criar arquivos de dados
for FILE in "${!DATA_FILES[@]}"; do
    echo "${DATA_FILES[$FILE]}" | sudo tee "/data/db/$FILE" > /dev/null
    echo "  [OK] $FILE"
done

# Criar backups identicos e gerar MANIFESTO
echo "  [*] Criando backups e gerando manifesto..."
MANIFESTO="/backup/manifesto_backup.sha256"
sudo sh -c "echo '# Manifesto de Integridade - Backup' > $MANIFESTO"
sudo sh -c "echo '# Gerado em: $(date)' >> $MANIFESTO"
sudo sh -c "echo '#' >> $MANIFESTO"

for FILE in "${!DATA_FILES[@]}"; do
    echo "${DATA_FILES[$FILE]}" | sudo tee "/backup/$FILE" > /dev/null
    
    # Calcular hash para o manifesto (com caminho completo)
    HASH=$(sudo sha256sum "/backup/$FILE" | cut -d' ' -f1)
    sudo sh -c "echo '$HASH  /data/db/$FILE' >> $MANIFESTO"
done

echo "  [OK] Backups criados em /backup/"
echo "  [OK] Manifesto de integridade gerado: $MANIFESTO"

# ============================================================
# 5. Configurar permissões
# ============================================================

echo "[5/5] Configurando permissoes..."

sudo chown -R svc_backup:svc_backup /data/db /backup 2>/dev/null
sudo chmod 755 /data/db /backup /evidencias /quarentena 2>/dev/null
echo "  [OK] Permissoes configuradas"

# ============================================================
# Resumo
# ============================================================

echo ""
echo "=========================================="
if [ "$ALL_SUCCESS" = true ]; then
    echo "  CONFIGURACAO CONCLUIDA COM SUCESSO!"
else
    echo "  CONFIGURACAO CONCLUIDA COM AVISOS"
fi
echo "=========================================="
echo ""
echo "Resumo do que foi configurado:"
echo "  [OK] Usuarios: svc_backup, carlos.oliveira"
echo "  [OK] SSH configurado (senha habilitada, chave desabilitada)"
echo "  [OK] Diretorios: /data/db, /backup, /evidencias, /quarentena"
echo "  [OK] Arquivos de dados criados (3 arquivos)"
echo "  [OK] Backups criados (3 arquivos)"
echo "  [OK] Manifesto de integridade gerado"
echo ""
echo "Execute o script de verificacao:"
echo "  python3 prep2_test.py"
