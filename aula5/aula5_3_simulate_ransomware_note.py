#!/usr/bin/env python3
"""
Simulacao de Nota de Resgate - Aula 5.3
Curso de SOC - Resposta a Incidentes

Cria arquivos simulando um ataque de ransomware
para treinamento de primeiras acoes.
Executar na VM Windows.
"""

import os
import random
import string
import shutil
from datetime import datetime

def create_simulation():
    """Cria os artefatos simulados de ransomware."""
    
    # Forcar C:\Temp como diretorio de simulacao
    sim_dir = "C:\\Temp\\Ransomware_Sim"
    
    # Limpar diretorio anterior se existir
    if os.path.exists(sim_dir):
        shutil.rmtree(sim_dir)
    
    os.makedirs(sim_dir, exist_ok=True)
    
    print("=" * 60)
    print("  SIMULACAO DE RANSOMWARE - AULA 5.3")
    print("=" * 60)
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Diretorio criado: {sim_dir}")
    
    # Arquivos simulados
    files = [
        "relatorio_financeiro.xlsx",
        "dados_clientes.csv",
        "apresentacao.pptx",
        "contratos_2026.pdf",
        "folha_pagamento.xlsx"
    ]
    
    # ID da vitima simulado
    victim_id = ''.join(random.choices(string.ascii_uppercase + string.digits, k=12))
    
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Criando arquivos simulados...")
    
    for file in files:
        filepath = os.path.join(sim_dir, file)
        # Criar arquivo original
        with open(filepath, "w") as f:
            f.write(f"DADOS SIMULADOS - {file}\n")
        
        # Simular criptografia (renomear)
        encrypted_path = filepath + ".locked"
        os.rename(filepath, encrypted_path)
        print(f"[{datetime.now().strftime('%H:%M:%S')}] Criptografando: {file} -> {file}.locked")
    
    # Criar nota de resgate
    ransom_note = f"""==========================================
  SEUS ARQUIVOS FORAM CRIPTOGRAFADOS
==========================================

Todos os seus arquivos importantes foram criptografados
com criptografia AES-256 + RSA-2048.

Para recuperar seus dados, voce precisa pagar um resgate
de 5 BTC (aproximadamente R$ 1.500.000,00) para o endereco:

  1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa

Apos o pagamento, envie o ID da vitima para:
  recover@ransom-group-xz.onion

SEU ID DE VITIMA: {victim_id}

PRAZO: 72 horas. Apos isso, o valor dobra.
Apos 7 dias, a chave de decriptacao sera destruida.

NAO TENTE recuperar os arquivos sozinho.
NAO CONTATE a policia.
NAO USE ferramentas de terceiros.

==========================================
"""
    
    note_path = os.path.join(sim_dir, "README_RECOVER.txt")
    with open(note_path, "w") as f:
        f.write(ransom_note)
    
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Nota de resgate criada: README_RECOVER.txt")
    print()
    print("=" * 60)
    print("  SIMULACAO CONCLUIDA")
    print(f"  Diretorio: {sim_dir}")
    print(f"  Extensao: .locked")
    print(f"  Nota: README_RECOVER.txt")
    print(f"  ID da Vitima: {victim_id}")
    print("=" * 60)
    print()
    print("AGORA: Preencha o formulario de primeiro respondedor.")
    print("Arquivo: aula5_3_formulario_ransomware.xlsx")

if __name__ == "__main__":
    create_simulation()