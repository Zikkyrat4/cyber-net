# Руководство по установке киберполигона

Данное руководство поможет вам развернуть полнофункциональный киберполигон для обучения сетевой безопасности.

## Системные требования

### Минимальные требования:
- **CPU**: 8 ядер (Intel VT-x/AMD-V)
- **RAM**: 32 GB
- **Дисковое пространство**: 500 GB SSD
- **Сеть**: 1 Gbps

### Рекомендуемые требования:
- **CPU**: 16+ ядер
- **RAM**: 64+ GB
- **Дисковое пространство**: 1+ TB NVMe SSD
- **Сеть**: 10 Gbps

## Установка Proxmox VE

### 1. Загрузка Proxmox VE

Скачайте последнюю версию Proxmox VE с официального сайта:
```bash
wget https://www.proxmox.com/en/downloads/proxmox-virtual-environment/iso
```

### 2. Установка

1. Создайте загрузочный USB
2. Загрузитесь с USB и следуйте инструкциям установщика
3. Настройте сетевые параметры
4. Создайте root пароль

### 3. Первоначальная настройка

После установки подключитесь к веб-интерфейсу:
```
https://your-proxmox-ip:8006
```

Выполните следующие настройки:

1. **Обновление системы:**
```bash
apt update && apt upgrade -y
```

2. **Настройка репозиториев:**
```bash
# Отключите enterprise репозиторий (если нет подписки)
echo "# deb https://enterprise.proxmox.com/debian/pve bullseye pve-enterprise" > /etc/apt/sources.list.d/pve-enterprise.list

# Добавьте no-subscription репозиторий
echo "deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list
```

3. **Настройка хранилища:**
- Создайте LVM storage для VM дисков
- Настройте NFS/iSCSI при необходимости

## Подготовка шаблонов VM

### 1. Создание Ubuntu шаблона

1. Скачайте Ubuntu Cloud Image:
```bash
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
```

2. Создайте VM в Proxmox:
```bash
qm create 9000 --memory 2048 --core 2 --name ubuntu-2004-template --net0 virtio,bridge=vmbr0
qm importdisk 9000 focal-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm template 9000
```

### 2. Создание pfSense шаблона

1. Скачайте pfSense ISO
2. Создайте VM и установите pfSense (pfsense-template)
3. Выполните базовую настройку
4. Конвертируйте в шаблон

### 3. Настройка сетевых мостов

Создайте дополнительные мосты для изоляции:

```bash
# В /etc/network/interfaces добавьте:
auto vmbr1
iface vmbr1 inet static
    address 192.168.10.1/24
    bridge_ports none
    bridge_stp off
    bridge_fd 0

auto vmbr2
iface vmbr2 inet static
    address 192.168.20.1/24
    bridge_ports none
    bridge_stp off
    bridge_fd 0
```

## Установка зависимостей на управляющей машине

### 1. Установка Terraform

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### 2. Установка Ansible

```bash
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible
```

### 3. Установка kubectl

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### 4. Установка Helm

```bash
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

### 5. Установка Docker

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

## Конфигурация проекта

### 1. Клонирование и настройка

```bash
git clone <repository-url>
cd cyber-range-infra
```

### 2. Настройка Terraform переменных

```bash
cp terraform/proxmox/terraform.tfvars.example terraform/proxmox/terraform.tfvars
```

Отредактируйте `terraform.tfvars`:
```hcl
proxmox_api_url = "https://your-proxmox:8006/api2/json"
proxmox_user = "root@pam"
proxmox_password = "your-password"
proxmox_node = "your-node-name"
storage_name = "local-lvm"
ubuntu_template = "ubuntu-2004-template"
pfsense_template = "pfsense-template"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2E... your-key"
ci_password = "ubuntu"
```

### 3. Настройка Ansible инвентаря

```bash
cp ansible/inventories/production/hosts.yml.example ansible/inventories/production/hosts.yml
```

Отредактируйте `hosts.yml`:
```yaml
all:
  children:
    proxmox:
      hosts:
        proxmox-node:
          ansible_host: your-proxmox-ip
          ansible_user: root

    k8s_cluster:
      children:
        k8s_master:
          hosts:
            k8s-master-1:
              ansible_host: 192.168.10.10
            k8s-master-2:
              ansible_host: 192.168.10.11
            k8s-master-3:
              ansible_host: 192.168.10.12

        k8s_workers:
          hosts:
            k8s-worker-1:
              ansible_host: 192.168.10.20
            k8s-worker-2:
              ansible_host: 192.168.10.21
            k8s-worker-3:
              ansible_host: 192.168.10.22
```

## Развертывание

### 1. Проверка конфигурации

```bash
# Проверка Terraform
make validate

# Проверка подключения к Proxmox
cd terraform/proxmox
terraform init
terraform plan
```

### 2. Полное развертывание

```bash
# Полное развертывание
chmod +x scripts/deployment/deploy.sh
make deploy

# Или поэтапно:
make deploy-infra
make deploy-apps
```

### 3. Проверка развертывания

```bash
# Проверка статуса
make status

# Проверка мониторинга
make monitor
```

## Настройка pfSense

### 1. Первоначальная настройка

1. Подключитесь к консоли pfSense VM
2. Настройте WAN интерфейс (получение IP от DHCP или статический)
3. Настройте LAN интерфейс (192.168.1.1/24)

### 2. Веб-интерфейс

1. Откройте https://192.168.1.1
2. Войдите (admin/pfsense)
3. Пройдите мастер настройки

### 3. Настройка VLAN

1. Перейдите в `Interfaces > Assignments > VLANs`
2. Создайте VLAN:
   - VLAN 10 (Office): vtnet1, ID 10
   - VLAN 20 (Branch): vtnet1, ID 20
   - VLAN 30 (DMZ): vtnet1, ID 30
   - VLAN 100 (Management): vtnet1, ID 100

3. Назначьте интерфейсы:
   - `Interfaces > Assignments`
   - Добавьте каждый VLAN как отдельный интерфейс

4. Настройте IP адреса:
   - Office: 192.168.10.1/24
   - Branch: 192.168.20.1/24
   - DMZ: 192.168.30.1/24
   - Management: 192.168.100.1/24

### 4. Настройка Firewall правил

См. детальные инструкции в лабораторных сценариях.

## Настройка мониторинга

### 1. Доступ к Grafana

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

Откройте http://localhost:3000
- Логин: admin
- Пароль: получите командой `kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode`

### 2. Импорт дашбордов

1. Скачайте дашборды из Grafana.com:
   - Kubernetes Cluster Monitoring: ID 315
   - Node Exporter Full: ID 1860
   - pfSense: ID 12023

2. Импортируйте через веб-интерфейс Grafana

## Создание первого студенческого окружения

```bash
# Создание окружения
make student-env STUDENT_ID=001 LAB_TYPE=web-security

# Проверка созданного окружения
kubectl get all -n student-student001

# Получение информации для подключения
kubectl get services -n student-student001
```

## Устранение неполадок

### Общие проблемы:

1. **Terraform ошибки подключения к Proxmox:**
   - Проверьте URL API
   - Убедитесь в правильности учетных данных
   - Проверьте сертификаты

2. **Ansible не может подключиться к хостам:**
   - Проверьте SSH ключи
   - Убедитесь в доступности хостов
   - Проверьте настройки файрвола

3. **Kubernetes поды не запускаются:**
   - Проверьте ресурсы нод: `kubectl describe nodes`
   - Проверьте образы: `kubectl describe pod <pod-name>`
   - Проверьте логи: `kubectl logs <pod-name>`

### Полезные команды для диагностики:

```bash
# Проверка состояния Terraform
terraform show

# Проверка Ansible подключений
ansible all -m ping

# Проверка Kubernetes
kubectl get events --sort-by=.metadata.creationTimestamp

# Проверка ресурсов
kubectl top nodes
kubectl top pods --all-namespaces
```

## Резервное копирование

### 1. Резервная копия конфигураций

```bash
make backup
```

### 2. Резервная копия VM в Proxmox

```bash
# Создание snapshot
qm snapshot <vmid> snapshot-name

# Backup
vzdump <vmid> --compress gzip --storage backup-storage
```

## Масштабирование

### Добавление новых нод Kubernetes:

1. Создайте новые VM через Terraform
2. Обновите Ansible инвентарь
3. Выполните playbook присоединения к кластеру

### Добавление новых типов лабораторных:

1. Создайте Docker образы
2. Добавьте Kubernetes манифесты
3. Обновите скрипт создания окружений

## Мониторинг производительности

### Ключевые метрики для отслеживания:

- Загрузка CPU и памяти хостов
- Использование дискового пространства
- Сетевая активность
- Количество активных студенческих сессий
- Время отклика приложений

### Алерты:

Настройте алерты в Prometheus для:
- Высокой загрузки ресурсов (>80%)
- Недоступности сервисов
- Ошибок в логах приложений
- Подозрительной сетевой активности

Это завершает руководство по установке. После выполнения всех шагов у вас будет полностью функциональный киберполигон готовый для обучения студентов.