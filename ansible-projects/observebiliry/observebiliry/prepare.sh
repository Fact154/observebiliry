#!/bin/bash

# Создание основной структуры Ansible
mkdir -p ./{playbooks,roles,group_vars,inventory,files,templates}

# Создание inventory файла
cat <<EOF > ./inventory/hosts.yml
all:
  children:
    kubernetes:
      hosts:
        # Добавьте сюда хосты k8s-кластера
    exporters:
      hosts:
        # Добавьте сюда хосты с экспортерами
EOF

# Создание group_vars файлов
cat <<EOF > ./group_vars/kubernetes.yml
kubeconfig_path: "~/.kube/config"
namespace: "monitoring"
EOF

# Создание плейбуков
cat <<EOF > ./playbooks/update_monitoring.yml
---
- name: Update monitoring stack in Kubernetes
  hosts: localhost
  gather_facts: no
  vars_files:
    - ../group_vars/kubernetes.yml
  tasks:
    - name: Update Prometheus stack using Helm
      ansible.builtin.command:
        cmd: "helm upgrade --install prometheus prometheus-community/kube-prometheus-stack --namespace {{ namespace }} --kubeconfig {{ kubeconfig_path }}"
      register: helm_output
      changed_when: "'Release "prometheus" has been upgraded' in helm_output.stdout"
EOF

cat <<EOF > ./playbooks/update_components.yml
---
- name: Update individual monitoring components
  hosts: localhost
  gather_facts: no
  vars_files:
    - ../group_vars/kubernetes.yml
  tasks:
    - name: Update Prometheus
      ansible.builtin.command:
        cmd: "helm upgrade prometheus prometheus-community/kube-prometheus-stack --namespace {{ namespace }} --kubeconfig {{ kubeconfig_path }} --set prometheus.enabled=true"
      when: "'prometheus' in ansible_run_tags"

    - name: Update Loki
      ansible.builtin.command:
        cmd: "helm upgrade loki grafana/loki-stack --namespace {{ namespace }} --kubeconfig {{ kubeconfig_path }}"
      when: "'loki' in ansible_run_tags"

    - name: Update Grafana
      ansible.builtin.command:
        cmd: "helm upgrade grafana grafana/grafana --namespace {{ namespace }} --kubeconfig {{ kubeconfig_path }}"
      when: "'grafana' in ansible_run_tags"
EOF

echo "Ansible структура создана в директории ansible"