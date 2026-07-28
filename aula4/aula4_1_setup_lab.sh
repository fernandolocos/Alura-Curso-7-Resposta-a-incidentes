#!/bin/bash
# Script de Preparacao do Laboratorio - Aula 4.1
# Cria artefatos simulados de backdoor no Linux
# Executar como root (sudo su -)

echo "=========================================="
echo "  PREPARACAO DO LABORATORIO - LINUX"
echo "=========================================="
echo ""

# 1. Criar processo falso em local atipico
echo "[1/4] Criando backdoor em /tmp..."

cat > /tmp/.nginx-backdoor << 'EOF'
#!/bin/bash
BACKDOOR_LOG="/tmp/.backdoor.log"
while true; do
    echo "$(date) - nginx: master process running" >> "$BACKDOOR_LOG"
    sleep 60
done
EOF

chmod +x /tmp/.nginx-backdoor
nohup /tmp/.nginx-backdoor > /dev/null 2>&1 &
BACKDOOR_PID=$!
echo "  [OK] Processo falso 'nginx-backdoor' rodando de /tmp/ (PID: $BACKDOOR_PID)"

# 2. Criar cron job suspeito (usuario)
echo "[2/4] Criando cron jobs suspeitos..."
(crontab -l 2>/dev/null; echo "@reboot /tmp/.nginx-backdoor &") | crontab -
echo "  [OK] Cron job @reboot adicionado ao crontab do root"

# 3. Criar cron job no sistema (/etc/cron.d)
echo "@reboot root /tmp/.nginx-backdoor" > /etc/cron.d/nginx-backdoor
echo "  [OK] Arquivo /etc/cron.d/nginx-backdoor criado"

# 4. Criar servico systemd falso
echo "[3/4] Criando servico systemd falso..."
cat > /etc/systemd/system/nginx-backup.service << EOF
[Unit]
Description=Nginx Backup Service

[Service]
Type=simple
ExecStart=/tmp/.nginx-backdoor
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
echo "  [OK] Servico nginx-backup criado"

# 5. Abrir porta suspeita
echo "[4/4] Abrindo porta suspeita..."
nc -l -p 4444 -k > /dev/null 2>&1 &
NC_PID=$!
echo "  [OK] Netcat ouvindo na porta 4444 (PID: $NC_PID)"

echo ""
echo "=========================================="
echo "  LABORATORIO PRONTO - LINUX"
echo "=========================================="
echo ""
echo "Artefatos criados:"
echo "  - Processo falso: /tmp/.nginx-backdoor (PID: $BACKDOOR_PID)"
echo "  - Log da backdoor: /tmp/.backdoor.log"
echo "  - Cron job: @reboot no crontab do root"
echo "  - Cron job: /etc/cron.d/nginx-backdoor"
echo "  - Servico: nginx-backup.service"
echo "  - Listener: porta 4444 (PID: $NC_PID)"
echo ""
echo "Agora investigue! Use ps, ss, crontab, systemctl."