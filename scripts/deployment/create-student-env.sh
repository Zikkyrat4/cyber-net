#!/bin/bash
set -e

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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

# Функция для создания студенческого окружения
create_student_environment() {
    local student_id=$1
    local lab_type=$2

    if [ -z "$student_id" ] || [ -z "$lab_type" ]; then
        error "Использование: $0 <student_id> <lab_type>"
    fi

    log "Создание окружения для студента $student_id, тип лабораторной: $lab_type"

    # Создание namespace
    kubectl create namespace "student-$student_id" --dry-run=client -o yaml | kubectl apply -f -

    # Создание network policy для изоляции
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: student-$student_id-isolation
  namespace: student-$student_id
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  egress:
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
  - to: []
    ports:
    - protocol: TCP
      port: 80
    - protocol: TCP
      port: 443
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
EOF

    # Создание resource quota
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: student-$student_id-quota
  namespace: student-$student_id
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    count/pods: "5"
    count/services: "3"
EOF

    # Развертывание приложений в зависимости от типа лабораторной
    case $lab_type in
        "web-security")
            deploy_web_security_lab $student_id
            ;;
        "network-security")
            deploy_network_security_lab $student_id
            ;;
        "malware-analysis")
            deploy_malware_analysis_lab $student_id
            ;;
        *)
            error "Неизвестный тип лабораторной: $lab_type"
            ;;
    esac

    log "Окружение для студента $student_id создано"

    # Вывод информации для подключения
    show_student_info $student_id
}

# Развертывание лабораторной по веб-безопасности
deploy_web_security_lab() {
    local student_id=$1

    log "Развертывание лабораторной по веб-безопасности..."

    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vulnerable-web
  namespace: student-$student_id
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vulnerable-web
  template:
    metadata:
      labels:
        app: vulnerable-web
    spec:
      containers:
      - name: vulnerable-web
        image: cyber-range/vulnerable-web:latest
        ports:
        - containerPort: 5000
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
---
apiVersion: v1
kind: Service
metadata:
  name: vulnerable-web-svc
  namespace: student-$student_id
spec:
  selector:
    app: vulnerable-web
  ports:
  - port: 80
    targetPort: 5000
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: attack-tools
  namespace: student-$student_id
spec:
  replicas: 1
  selector:
    matchLabels:
      app: attack-tools
  template:
    metadata:
      labels:
        app: attack-tools
    spec:
      containers:
      - name: kali-tools
        image: cyber-range/attack-tools:latest
        stdin: true
        tty: true
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
          limits:
            cpu: 1000m
            memory: 1Gi
EOF
}

# Развертывание лабораторной по сетевой безопасности
deploy_network_security_lab() {
    local student_id=$1

    log "Развертывание лабораторной по сетевой безопасности..."

    # Здесь будет более сложная конфигурация с несколькими подами
    # для симуляции сетевой инфраструктуры
}

# Показ информации для студента
show_student_info() {
    local student_id=$1

    log "Информация для подключения студента $student_id:"

    echo "=================================="
    echo "Namespace: student-$student_id"
    echo "=================================="

    kubectl get pods -n "student-$student_id"
    kubectl get services -n "student-$student_id"

    # Получение URL для доступа к приложениям
    if kubectl get service vulnerable-web-svc -n "student-$student_id" &>/dev/null; then
        CLUSTER_IP=$(kubectl get service vulnerable-web-svc -n "student-$student_id" -o jsonpath='{.spec.clusterIP}')
        echo "Vulnerable Web App: http://$CLUSTER_IP"
    fi

    # Команда для подключения к attack tools
    if kubectl get deployment attack-tools -n "student-$student_id" &>/dev/null; then
        echo "Для подключения к attack tools выполните:"
        echo "kubectl exec -it -n student-$student_id deployment/attack-tools -- /bin/bash"
    fi
}

# Удаление студенческого окружения
cleanup_student_environment() {
    local student_id=$1

    if [ -z "$student_id" ]; then
        error "Укажите ID студента для удаления"
    fi

    warn "Удаление окружения студента $student_id..."

    kubectl delete namespace "student-$student_id" --ignore-not-found=true

    log "Окружение студента $student_id удалено"
}

# Обработка аргументов
case "${1:-}" in
    "create")
        create_student_environment "$2" "$3"
        ;;
    "cleanup")
        cleanup_student_environment "$2"
        ;;
    "info")
        show_student_info "$2"
        ;;
    *)
        echo "Использование: $0 <action> [arguments]"
        echo "Actions:"
        echo "  create <student_id> <lab_type>  - Создать окружение"
        echo "  cleanup <student_id>            - Удалить окружение"
        echo "  info <student_id>               - Показать информацию"
        echo ""
        echo "Lab types: web-security, network-security, malware-analysis"
        exit 1
        ;;
esac