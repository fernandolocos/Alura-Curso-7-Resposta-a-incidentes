#!/usr/bin/env python3
# Script de Verificacao do Ambiente - Parte 2 (Linux)

import subprocess
import os
import shutil

GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
CYAN = "\033[96m"
RESET = "\033[0m"

all_passed = True

def test_check(description, condition, passed_msg, failed_msg):
    global all_passed
    if condition:
        print(f"{GREEN}[OK]{RESET} {description} - {passed_msg}")
    else:
        print(f"{RED}[FALHA]{RESET} {description} - {failed_msg}")
        all_passed = False

def run_command(cmd):
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=10)
        return result.stdout.strip()
    except:
        return None

print(f"{CYAN}{'='*50}{RESET}")
print(f"{CYAN}  VERIFICACAO DO AMBIENTE - PARTE 2 (LINUX){RESET}")
print(f"{CYAN}{'='*50}{RESET}")
print()

# 1. Usuários
print(f"{YELLOW}--- Usuarios Simulados ---{RESET}")
for user in ["svc_backup", "carlos.oliveira"]:
    result = run_command(f"id {user} 2>&1")
    test_check(f"Usuario {user}", result and "uid=" in result, "Criado", "Nao encontrado")

# 2. Diretórios
print(f"\n{YELLOW}--- Diretorios de Simulacao ---{RESET}")
for path, desc in [("/data/db", "Banco de dados"), ("/backup", "Backups"), ("/evidencias", "Evidencias"), ("/quarentena", "Quarentena")]:
    test_check(desc, os.path.isdir(path), path, "Nao encontrado")

# 3. Arquivos de dados
print(f"\n{YELLOW}--- Arquivos de Dados ---{RESET}")
data_files = ["clientes.mdf", "vendas.ldf", "produtos.mdf"]
data_count = sum(1 for f in data_files if os.path.exists(f"/data/db/{f}"))
test_check("Arquivos de dados", data_count == 3, f"{data_count} de 3", f"Apenas {data_count} de 3")

backup_count = sum(1 for f in data_files if os.path.exists(f"/backup/{f}"))
test_check("Arquivos de backup", backup_count == 3, f"{backup_count} de 3", f"Apenas {backup_count} de 3")

# 4. Conectividade
print(f"\n{YELLOW}--- Conectividade ---{RESET}")
ping_result = run_command("ping -c 1 -W 2 192.168.56.10 2>&1")
test_check("Conexao com VM Windows (192.168.56.10)", ping_result and "1 received" in ping_result, "Ping OK", "Sem resposta")

# 5. Verificar manifesto de integridade
print(f"\n{YELLOW}--- Manifesto de Integridade ---{RESET}")

manifesto_path = "/backup/manifesto_backup.sha256"
manifesto_exists = os.path.exists(manifesto_path)
test_check(
    "Manifesto de integridade do backup",
    manifesto_exists,
    manifesto_path,
    "Manifesto nao encontrado. Execute prep2_setup_linux.sh novamente."
)

if manifesto_exists:
    with open(manifesto_path, "r") as f:
        lines = [l.strip() for l in f.readlines() if l.strip() and not l.startswith("#")]
    test_check(
        "Hashes no manifesto",
        len(lines) == 3,
        f"{len(lines)} hashes (3 esperados)",
        f"Apenas {len(lines)} hashes. Esperado: 3"
    )

# Resultado
print()
if all_passed:
    print(f"{GREEN}{'='*50}{RESET}")
    print(f"{GREEN}  AMBIENTE APROVADO - PRONTO PARA AS AULAS{RESET}")
    print(f"{GREEN}{'='*50}{RESET}")
else:
    print(f"{RED}{'='*50}{RESET}")
    print(f"{RED}  PROBLEMAS ENCONTRADOS{RESET}")
    print(f"{RED}{'='*50}{RESET}")