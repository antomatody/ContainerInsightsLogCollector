# ContainerInsightsLogCollector

## Introduction
This script is designed to collect related logs from OMS Agent pod enabled with Container Insights.
https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-overview

## Prerequistes
Bash environment with kubectl connected to target cluster.

## Usage
`wget https://raw.githubusercontent.com/antomatody/ContainerInsightsLogCollector/main/ContianerInsightsLogCollector.sh && bash ContianerInsightsLogCollector.sh`

## Function
1. Let you choose if you want to delete current OMS agent pods first.(will be recreated)
2. Collect:
- omsagent deployment
- configmap 
3. For omsagent-rs-xxxxx pod , collect:
- describe pod
- pod log
- agent log
- cim log
4. For 1 random omsagent-xxxxx pod, collect:
- describe pod
- pod log
- agent log
- cim log
