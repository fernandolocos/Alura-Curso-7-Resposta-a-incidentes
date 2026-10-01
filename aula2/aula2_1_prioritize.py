#!/usr/bin/env python3
"""
Script de Priorização de Alertas - Aula 2.1
Curso de SOC - Resposta a Incidentes

Le o arquivo JSON com alertas simulados, calcula a pontuacao
de prioridade e exibe a fila ordenada.

Uso:
    python aula2_1_prioritize.py
"""

import json
from datetime import datetime

# ============================================================
# CONFIGURAÇÃO DE PESOS - EDITÁVEL PELO ALUNO
# ============================================================

# Pesos de criticidade por tipo de ativo (identificado por palavra-chave no nome)
ASSET_WEIGHTS = {
    "controlador": 14,
    "cfo": 7,
    "banco de dados": 10,
    "database": 10,
    "firewall": 7,
    "estação": 2,
    "workstation": 2,
    "estagiário": 2,
    "intern": 2,
    "vendas": 4,
    "vendedor": 4,
    "homologação": 4,
    "staging": 4,
    "desenvolvimento": 3,
    "development": 3,
    "produção": 10,
    "production": 10,
    "aplicação": 7,
    "application": 7,
    "diretor": 8
}

# Thresholds de prioridade
P1_THRESHOLD = 500
P2_THRESHOLD = 200
P3_THRESHOLD = 50

# ============================================================
# FUNCOES - NAO EDITAR
# ============================================================

def get_asset_weight(alert):
    """
    Retorna o peso da criticidade do ativo usando SOMENTE a tabela ASSET_WEIGHTS.
    A primeira palavra-chave encontrada no nome do ativo vence.
    """
    asset_name = alert.get("asset", "").lower()
    
    for keyword, weight in ASSET_WEIGHTS.items():
        if keyword in asset_name:
            return weight
    
    # Se nenhuma palavra-chave for encontrada, usa peso padrao
    return 4


def get_impact(alert):
    """Retorna o impacto estimado do alerta."""
    if "estimated_impact" in alert and alert["estimated_impact"] is not None:
        return alert["estimated_impact"]
    return 4


def get_confidence(alert):
    """Retorna a confiabilidade do alerta."""
    if "alert_confidence" in alert and alert["alert_confidence"] is not None:
        return alert["alert_confidence"]
    return 4


def calculate_score(alert):
    """Calcula a pontuacao de prioridade do alerta."""
    return get_asset_weight(alert) * get_impact(alert) * get_confidence(alert)


def classify_priority(score):
    """Classifica a prioridade baseada na pontuacao."""
    if score >= P1_THRESHOLD:
        return "P1 - Critico"
    elif score >= P2_THRESHOLD:
        return "P2 - Alta"
    elif score >= P3_THRESHOLD:
        return "P3 - Media"
    else:
        return "P4 - Baixa"


def print_table(alerts):
    """Exibe a tabela formatada no terminal."""
    print()
    print("=" * 90)
    print("  FILA DE ALERTAS PRIORIZADA - RESPOSTA A INCIDENTES")
    print("=" * 90)
    print(f"  {'Prioridade':<15} {'Pontuacao':<10} {'Alerta':<12} {'Ativo':<40}")
    print("-" * 90)
    
    for alert in alerts:
        priority = alert["priority"]
        score = alert["score"]
        alert_id = alert["id"]
        asset = alert.get("asset", "N/A")[:38]
        
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
    print("=" * 90)
    print()


def print_summary(alerts):
    """Exibe um resumo por prioridade."""
    print("  RESUMO POR PRIORIDADE:")
    print()
    
    priorities = ["P1 - Critico", "P2 - Alta", "P3 - Media", "P4 - Baixa"]
    
    for priority_level in priorities:
        count = sum(1 for a in alerts if a["priority"] == priority_level)
        bar = "█" * count
        print(f"  {priority_level:<15}: {count} alerta(s) {bar}")
    
    print()


def main():
    """Funcao principal."""
    try:
        with open("aula2_1_alerts.json", "r", encoding="utf-8") as f:
            alerts = json.load(f)
    except FileNotFoundError:
        print("ERRO: Arquivo 'aula2_1_alerts.json' nao encontrado.")
        print("Certifique-se de que ele esta no mesmo diretorio deste script.")
        return
    except json.JSONDecodeError:
        print("ERRO: O arquivo JSON esta mal formatado.")
        return
    
    for alert in alerts:
        alert["score"] = calculate_score(alert)
        alert["priority"] = classify_priority(alert["score"])
    
    alerts_sorted = sorted(alerts, key=lambda x: x["score"], reverse=True)
    
    print_table(alerts_sorted)
    print_summary(alerts_sorted)


if __name__ == "__main__":
    main()
