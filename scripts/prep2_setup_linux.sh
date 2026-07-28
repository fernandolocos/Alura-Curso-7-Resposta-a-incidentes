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

echo "[1/4] Criando usuarios simulados..."

declare -A USUARIOS
USUARIOS[svc_backup]="Conta de servico"
USUARIOS[carlos.oliveira]="Gerente financeiro"

for USER in "${!USUARIOS[@]}"; do
    if id "$USER" &>/dev/null; then
        echo "  [OK] Usuario $USER ja existe"
    else
        sudo useradd -m "$USER" -c "${USUARIOS[$USER]}"
        echo "$USER:Senha123!" | sudo chpasswd
        echo "  [OK] Usuario $USER criado"
    fi
done

# ============================================================
# 2. Criar diretórios de simulação
# ============================================================

echo "[2/4] Criando diretorios de simulacao..."

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
# 3. Criar arquivos de dados simulados E MANIFESTOS
# ============================================================

echo "[3/4] Criando arquivos de dados simulados..."

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
# 4. Configurar permissões
# ============================================================

echo "[4/4] Configurando permissoes..."

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
echo "  [OK] Diretorios: /data/db, /backup, /evidencias, /quarentena"
echo "  [OK] Arquivos de dados criados (3 arquivos)"
echo "  [OK] Backups criados (3 arquivos)"
echo "  [OK] Manifesto de integridade gerado"
echo ""
echo "Execute o script de verificacao:"
echo "  python3 prep2_test.py"