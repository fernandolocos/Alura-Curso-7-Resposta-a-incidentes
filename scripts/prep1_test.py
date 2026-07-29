#!/usr/bin/env python3
# Script de Verificação do Ambiente - VM Linux
# Curso de SOC - Resposta a Incidentes
# Executar dentro da VM Linux

import subprocess
import os
import sys
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
        print(f"{GREEN}[✓]{RESET} {description} - {passed_msg}")
    else:
        print(f"{RED}[✗]{RESET} {description} - {failed_msg}")
        all_passed = False

def command_exists(cmd):
    return shutil.which(cmd) is not None

def run_command(cmd):
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=10)
        return result.stdout.strip() or result.stderr.strip()
    except:
        return None

print(f"{CYAN}{'='*50}{RESET}")
print(f"{CYAN}  VERIFICAÇÃO DO AMBIENTE - VM LINUX{RESET}")
print(f"{CYAN}{'='*50}{RESET}")
print()

# 1. Python
print(f"{YELLOW}--- Ferramentas de Desenvolvimento ---{RESET}")

python_output = run_command("python3 --version 2>&1")
test_check(
    "Python 3 instalado",
    python_output and "Python 3" in python_output,
    python_output,
    "Python não encontrado. Execute 'install_tools_linux.sh' novamente."
)

pip_output = run_command("pip3 --version 2>&1")
test_check(
    "pip3 instalado",
    pip_output and "pip" in pip_output,
    pip_output.split()[0] if pip_output else "",
    "pip3 não encontrado. Execute: sudo apt install -y python3-pip"
)

# 2. Git
print()
print(f"{YELLOW}--- Controle de Versão ---{RESET}")

git_output = run_command("git --version 2>&1")
test_check(
    "Git instalado",
    git_output and "git version" in git_output,
    git_output,
    "Git não encontrado. Execute 'install_tools_linux.sh' novamente."
)

# 3. Ferramentas de rede
print()
print(f"{YELLOW}--- Ferramentas de Rede ---{RESET}")

network_tools = [
    ("netstat", "netstat (conexões de rede)", "net-tools"),
    ("curl", "curl (transferência de dados)", "curl"),
    ("wget", "wget (download de arquivos)", "wget"),
    ("nc", "netcat (testes de conexão)", "netcat-openbsd"),
    ("tcpdump", "tcpdump (captura de pacotes)", "tcpdump"),
    ("nmap", "nmap (scan de rede)", "nmap"),
]

for cmd, desc, package in network_tools:
    exists = command_exists(cmd)
    test_check(
        desc,
        exists,
        "OK",
        f"Não encontrado. Execute: sudo apt install -y {package}"
    )

# 4. Comandos nativos do Linux
print()
print(f"{YELLOW}--- Comandos Nativos do Linux ---{RESET}")

native_commands = [
    ("ss", "ss (conexões de rede)"),
    ("ps", "ps (processos)"),
    ("iptables", "iptables (firewall)"),
    ("who", "who (usuários logados)"),
    ("systemctl", "systemctl (serviços)"),
    ("crontab", "crontab (tarefas agendadas)"),
    ("arp", "arp (tabela ARP)"),
]

for cmd, desc in native_commands:
    exists = command_exists(cmd)
    test_check(
        desc,
        exists,
        "Disponível",
        f"Não encontrado. Verifique a instalação do Ubuntu."
    )

# 5. Diretórios de trabalho
print()
print(f"{YELLOW}--- Diretórios de Trabalho ---{RESET}")

dirs = [
    ("~/scripts", "Scripts do curso"),
    ("~/temp", "Arquivos temporários"),
    ("~/evidencias", "Coleta de evidências"),
]

for path, desc in dirs:
    full_path = os.path.expanduser(path)
    exists = os.path.isdir(full_path)
    test_check(
        f"{desc} ({path})",
        exists,
        "Existe",
        f"Não encontrado. Execute 'install_tools_linux.sh' ou crie com: mkdir -p {path}"
    )

# 6. Repositório do curso
print()
print(f"{YELLOW}--- Repositório do Curso ---{RESET}")

repo_path = os.path.expanduser("~/6258-soc-resposta-incidentes")
repo_exists = os.path.exists(os.path.join(repo_path, "README.md"))
test_check(
    f"Repositório clonado em ~/6258-soc-resposta-incidentes",
    repo_exists,
    "Encontrado",
    "Repositório não encontrado. Execute: cd ~ && git clone https://github.com/alura-cursos/6258-soc-resposta-incidentes.git"
)

# 7. Conectividade de rede
print()
print(f"{YELLOW}--- Conectividade de Rede ---{RESET}")

ping_result = run_command("ping -c 1 -W 2 8.8.8.8 2>&1")
test_check(
    "Acesso à internet (NAT)",
    ping_result and "1 received" in ping_result,
    "Ping 8.8.8.8 OK",
    "Sem acesso à internet. Verifique o adaptador NAT no VirtualBox."
)

# 8. Espaço em disco
print()
print(f"{YELLOW}--- Recursos do Sistema ---{RESET}")

df_output = run_command("df -h / | tail -1")
if df_output:
    parts = df_output.split()
    if len(parts) >= 4:
        free_space = parts[3]
        test_check("Espaço livre em disco", True, f"{free_space} livres", "")

# Resultado final
print()
status_color = GREEN if all_passed else RED
status_text = "VM LINUX PRONTA PARA O CURSO" if all_passed else "PROBLEMAS ENCONTRADOS - VERIFIQUE OS ITENS ACIMA"
print(f"{status_color}{'='*50}{RESET}")
print(f"{status_color}  {status_text}{RESET}")
print(f"{status_color}{'='*50}{RESET}")
