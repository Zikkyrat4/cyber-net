# Киберполигон для обучения сетевой безопасности

Автоматизированная система для создания индивидуальных лабораторных окружений по сетевой безопасности на базе Proxmox VE, pfSense и Kubernetes.

## 🏗️ Архитектура

Система состоит из следующих компонентов:

- **Proxmox VE** - платформа виртуализации
- **pfSense** - сетевой шлюз, firewall, VPN, IDS/IPS
- **Kubernetes** - оркестрация контейнеров
- **Docker** - контейнеризация приложений
- **Terraform** - управление инфраструктурой как кодом
- **Ansible** - автоматизация конфигурации
- **Prometheus + Grafana** - мониторинг
- **GitLab CI/CD** - непрерывная интеграция и развертывание

<img width="700" height="500" alt="cyber_range_architecture" src="https://github.com/user-attachments/assets/e6f6abda-1fb4-4993-8338-d39cdcd3bade" />

## 🚀 Быстрый старт

### Предварительные требования

- Proxmox VE 9.0-1
- Terraform 1.5.7
- Ansible 4.0+
- kubectl
- Docker
- Helm 3.0+

### Установка

1. Клонируйте репозиторий:
```bash
git clone <repository-url>
cd cyber-range-infra
```

2. Настройте переменные окружения:
```bash
cp terraform/proxmox/terraform.tfvars.example terraform/proxmox/terraform.tfvars
# Отредактируйте terraform.tfvars согласно вашей среде
```

3. Настройте инвентарь Ansible:
```bash
cp ansible/inventories/production/hosts.yml.example ansible/inventories/production/hosts.yml
# Отредактируйте hosts.yml
```

4. Запустите развертывание:
```bash
make deploy
# или
./scripts/deployment/deploy.sh
```

## 📚 Использование

### Создание окружения для студента

```bash
# Создать окружение для веб-безопасности
make student-env STUDENT_ID=001 LAB_TYPE=web-security

# Создать окружение для сетевой безопасности
make student-env STUDENT_ID=002 LAB_TYPE=network-security
```

### Управление

```bash
# Показать статус системы
make status

# Просмотр логов
make logs

# Создание резервной копии
make backup

# Мониторинг
make monitor
```

### Доступ к интерфейсам

- **Grafana**: `kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80`
- **Prometheus**: `kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090`
- **pfSense**: https://192.168.1.1 (настройте согласно вашей сети)

## 🧪 Лабораторные сценарии

### Доступные типы лабораторных работ:

1. **web-security** - Веб-безопасность (SQL Injection, XSS, Command Injection)
2. **network-security** - Сетевая безопасность (сканирование, анализ трафика)
3. **malware-analysis** - Анализ вредоносного ПО

### Пример выполнения лабораторной работы

См. [LAB_SCENARIOS.md](docs/LAB_SCENARIOS.md)

## 🔧 Разработка

### Локальная разработка

```bash
# Запуск в режиме разработки
make dev

# Остановка
make dev-stop
```

### Добавление новых лабораторных

1. Создайте Docker образ в `docker/images/`
2. Добавьте Kubernetes манифесты в `kubernetes/manifests/applications/`
3. Обновите скрипт `scripts/deployment/create-student-env.sh`

## 🛠️ Структура проекта

```
cyber-range-infra/
├── terraform/              # Terraform конфигурации
│   ├── proxmox/            # Конфигурация Proxmox
│   └── modules/            # Terraform модули
├── ansible/                # Ansible playbooks
│   ├── playbooks/          # Основные playbooks
│   ├── roles/              # Ansible роли
│   └── inventories/        # Инвентари
├── kubernetes/             # Kubernetes манифесты
│   ├── manifests/          # YAML манифесты
│   └── helm/               # Helm чарты
├── docker/                 # Docker образы
│   ├── images/             # Dockerfile'ы
│   └── compose/            # Docker Compose файлы
├── scripts/                # Скрипты управления
│   ├── deployment/         # Скрипты развертывания
│   └── management/         # Скрипты управления
└── docs/                   # Документация
```

## 🔒 Безопасность

- Все студенческие окружения изолированы через Network Policies
- Ресурсы ограничены через Resource Quotas  
- Сетевые сегменты разделены через VLAN
- Мониторинг всех активностей через Prometheus

## 🤝 Вклад в проект

1. Fork репозитория
2. Создайте ветку для изменений
3. Внесите изменения и добавьте тесты
4. Создайте Pull Request

## 📞 Поддержка

Для вопросов и поддержки создайте Issue в репозитории.
