#!/bin/bash
set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Проверка зависимостей
check_dependencies() {
    log "Проверка зависимостей..."

    if ! command -v terraform &> /dev/null; then
        error "Terraform не установлен. Установите Terraform версии >= 1.0"
    fi

    if ! command -v ansible &> /dev/null; then
        error "Ansible не установлен. Установите Ansible версии >= 4.0"
    fi

    if ! command -v kubectl &> /dev/null; then
        error "kubectl не установлен. Установите kubectl"
    fi

    if ! command -v docker &> /dev/null; then
        error "Docker не установлен. Установите Docker"
    fi

    log "Все зависимости установлены"
}

# Проверка конфигурации
check_config() {
    log "Проверка конфигурации..."

    if [ ! -f "terraform/proxmox/terraform.tfvars" ]; then
        warn "Файл terraform.tfvars не найден. Создаем из примера..."
        cp terraform/proxmox/terraform.tfvars.example terraform/proxmox/terraform.tfvars
        error "Отредактируйте terraform/proxmox/terraform.tfvars и запустите снова"
    fi

    if [ ! -f "ansible/inventories/production/hosts.yml" ]; then
        error "Файл инвентаря Ansible не найден. Создайте ansible/inventories/production/hosts.yml"
    fi

    log "Конфигурация проверена"
}

# Развертывание инфраструктуры через Terraform
deploy_infrastructure() {
    log "Развертывание инфраструктуры через Terraform..."

    cd terraform/proxmox

    log "Инициализация Terraform..."
    terraform init

    log "Планирование изменений..."
    terraform plan -out=plan.out

    log "Применение изменений..."
    terraform apply plan.out

    log "Получение выходных данных..."
    terraform output -json > ../../infrastructure-outputs.json

    cd ../..
    log "Инфраструктура развернута"
}

# Настройка окружения через Ansible
configure_environment() {
    log "Настройка окружения через Ansible..."

    cd ansible

    log "Проверка подключения к хостам..."
    ansible all -i inventories/production/hosts.yml -m ping

    log "Запуск основного playbook..."
    ansible-playbook -i inventories/production/hosts.yml playbooks/site.yml

    cd ..
    log "Окружение настроено"
}

# Настройка Kubernetes
setup_kubernetes() {
    log "Настройка Kubernetes кластера..."

    # Получаем kubeconfig с мастер ноды
    log "Получение kubeconfig..."
    MASTER_IP=$(jq -r '.k8s_master_ips.value[0]' infrastructure-outputs.json)

    if [ "$MASTER_IP" == "null" ] || [ -z "$MASTER_IP" ]; then
        error "Не удалось получить IP мастер ноды"
    fi

    scp ubuntu@$MASTER_IP:~/.kube/config ~/.kube/config

    log "Применение Kubernetes манифестов..."
    kubectl apply -f kubernetes/manifests/namespaces/
    kubectl apply -f kubernetes/manifests/network-policies/
    kubectl apply -f kubernetes/manifests/monitoring/

    log "Установка Helm чартов..."
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update

    helm install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring --create-namespace

    log "Kubernetes настроен"
}

# Развертывание приложений
deploy_applications() {
    log "Развертывание приложений..."

    # Сборка и загрузка Docker образов
    log "Сборка Docker образов..."
    docker build -t cyber-range/vulnerable-web:latest docker/images/vulnerable-web/
    docker build -t cyber-range/attack-tools:latest docker/images/attack-tools/

    # Развертывание через Kubernetes манифесты
    kubectl apply -f kubernetes/manifests/applications/

    log "Приложения развернуты"
}

# Проверка развертывания
verify_deployment() {
    log "Проверка развертывания..."

    log "Статус нод Kubernetes:"
    kubectl get nodes

    log "Статус подов:"
    kubectl get pods --all-namespaces

    log "Статус сервисов:"
    kubectl get services --all-namespaces

    log "Получение URL для доступа..."
    GRAFANA_URL=$(kubectl get service -n monitoring prometheus-grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

    if [ ! -z "$GRAFANA_URL" ]; then
        log "Grafana доступен по адресу: http://$GRAFANA_URL:3000"
        log "Логин: admin / Пароль: получите командой 'kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode'"
    fi

    log "Развертывание завершено успешно!"
}

# Главная функция
main() {
    log "Начало развертывания киберполигона..."

    check_dependencies
    check_config
    deploy_infrastructure
    configure_environment
    setup_kubernetes
    deploy_applications
    verify_deployment

    log "Развертывание завершено!"
}

# Обработка аргументов командной строки
case "${1:-}" in
    "infra")
        deploy_infrastructure
        ;;
    "config")
        configure_environment
        ;;
    "k8s")
        setup_kubernetes
        ;;
    "apps")
        deploy_applications
        ;;
    "verify")
        verify_deployment
        ;;
    "full"|"")
        main
        ;;
    *)
        echo "Использование: $0 [infra|config|k8s|apps|verify|full]"
        echo "  infra  - Развертывание инфраструктуры"
        echo "  config - Настройка окружения"
        echo "  k8s    - Настройка Kubernetes"
        echo "  apps   - Развертывание приложений"
        echo "  verify - Проверка развертывания"
        echo "  full   - Полное развертывание (по умолчанию)"
        exit 1
        ;;
esac