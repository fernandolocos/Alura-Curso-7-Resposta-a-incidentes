#!/usr/bin/env python3
"""
Script de Priorização de Alertas - Aula 2.1
Curso de SOC - Resposta a Incidentes
"""

import json
from datetime import datetime

# ============================================================
# CONFIGURAÇÃO DE PESOS - EDITÁVEL PELO ALUNO
# ============================================================

# Pesos de criticidade por tipo de ativo (identificado por palavra-chave no nome)
ASSET_WEIGHTS = {
    "banco de dados": 10,
    "database": 10,
    "controlador de domínio": 10,
    "domain controller": 10,
    "cfo": 10,
    "diretor": 8,
    "payment": 10,
    "produção": 10,
    "production": 10,
    "aplicação": 7,
    "application": 7,
    "arquivos": 7,
    "file server": 7,
    "vendas": 4,
    "vendedor": 4,
    "homologação": 4,
    "staging": 4,
    "desenvolvimento": 3,
    "development": 3,
    "estação": 2,
    "workstation": 2,
    "estagiário": 2,
    "intern": 2,
    "firewall": 7,
    "visitante": 1,
    "guest": 1
}

# Thresholds de prioridade
P1_THRESHOLD = 500
P2_THRESHOLD = 200
P3_THRESHOLD = 50

# ============================================================
# FUNÇÕES - NÃO EDITAR
# ============================================================

def get_asset_weight(asset_name):
    """Retorna o peso da criticidade do ativo baseado em palavras-chave."""
    asset_lower = asset_name.lower()
    for keyword, weight in ASSET_WEIGHTS.items():
        if keyword in asset_lower:
            return weight
    return 4  # Peso padrão se não encontrar correspondência

def calculate_score(alert):
    """Calcula a pontuação de prioridade do alerta."""
    asset_weight = alert.get("asset_criticality", get_asset_weight(alert.get("asset", "")))
    impact = alert.get("estimated_impact", 4)
    confidence = alert.get("alert_confidence", 4)
    return asset_weight * impact * confidence

def classify_priority(score):
    """Classifica a prioridade baseada na pontuação."""
    if score >= P1_THRESHOLD:
        return "P1 - Crítico"
    elif score >= P2_THRESHOLD:
        return "P2 - Alta"
    elif score >= P3_THRESHOLD:
        return "P3 - Média"
    else:
        return "P4 - Baixa"

def print_table(alerts):
    """Exibe a tabela formatada no terminal."""
    print("\n" + "=" * 90)
    print("  FILA DE ALERTAS PRIORIZADA - RESPOSTA A INCIDENTES")
    print("=" * 90)
    print(f"  {'Prioridade':<15} {'Pontuação':<10} {'Alerta':<12} {'Ativo':<40}")
    print("-" * 90)
    
    for alert in alerts:
        priority = alert["priority"]
        score = alert["score"]
        alert_id = alert["id"]
        asset = alert["asset"][:38]
        
        # Indicador visual de prioridade
        if "P1" in priority:
            indicator = "🔴 " + priority
        elif "P2" in priority:
            indicator = "🟠 " + priority
        elif "P3" in priority:
            indicator = "🟡 " + priority
        else:
            indicator = "🟢 " + priority
        
        print(f"  {indicator:<15} {score:<10} {alert_id:<12} {asset:<40}")
    
    print("=" * 90)
    print(f"  Total de alertas processados: {len(alerts)}")
    print(f"  Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 90 + "\n")

def main():
    """Função principal."""
    try:
        with open("aula2_1_alerts.json", "r", encoding="utf-8") as f:
            alerts = json.load(f)
    except FileNotFoundError:
        print("ERRO: Arquivo 'aula2_1_alerts.json' não encontrado.")
        print("Certifique-se de que ele está no mesmo diretório deste script.")
        return
    
    # Calcular pontuação para cada alerta
    for alert in alerts:
        alert["score"] = calculate_score(alert)
        alert["priority"] = classify_priority(alert["score"])
    
    # Ordenar por pontuação (maior primeiro)
    alerts_sorted = sorted(alerts, key=lambda x: x["score"], reverse=True)
    
    # Exibir tabela
    print_table(alerts_sorted)
    
    # Resumo por prioridade
    print("  RESUMO POR PRIORIDADE:")
    for priority_level in ["P1 - Crítico", "P2 - Alta", "P3 - Média", "P4 - Baixa"]:
        count = sum(1 for a in alerts_sorted if a["priority"] == priority_level)
        bar = "█" * count
        print(f"  {priority_level:<15}: {count} alerta(s) {bar}")

if __name__ == "__main__":
    main()