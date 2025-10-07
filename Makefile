# Makefile для управления киберполигоном

.PHONY: help install deploy destroy status logs clean student-env

# Переменные
TERRAFORM_DIR = terraform/proxmox
ANSIBLE_DIR = ansible
STUDENT_ID ?= 001
LAB_TYPE ?= web-security

help: ## Показать эту справку
	@echo 'Доступные команды:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Установить зависимости
	@echo "Установка зависимостей..."
	@scripts/deployment/setup-dependencies.sh

validate: ## Валидация конфигурации
	@echo "Валидация Terraform..."
	@cd $(TERRAFORM_DIR) && terraform fmt -check && terraform validate
	@echo "Валидация Ansible..."
	@cd $(ANSIBLE_DIR) && ansible-playbook --syntax-check playbooks/*.yml

deploy: ## Полное развертывание
	@echo "Запуск полного развертывания..."
	@scripts/deployment/deploy.sh full

deploy-infra: ## Развертывание только инфраструктуры
	@echo "Развертывание инфраструктуры..."
	@scripts/deployment/deploy.sh infra

deploy-apps: ## Развертывание только приложений
	@echo "Развертывание приложений..."
	@scripts/deployment/deploy.sh apps

destroy: ## Уничтожение инфраструктуры
	@echo "ВНИМАНИЕ: Это удалит всю инфраструктуру!"
	@read -p "Вы уверены? [y/N] " confirm && [ "$$confirm" = "y" ]
	@cd $(TERRAFORM_DIR) && terraform destroy

status: ## Показать статус
	@echo "Статус Kubernetes кластера:"
	@kubectl get nodes
	@echo "\nСтатус подов:"
	@kubectl get pods --all-namespaces
	@echo "\nСтатус сервисов:"
	@kubectl get services --all-namespaces

logs: ## Показать логи
	@echo "Логи системных подов:"
	@kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50

student-env: ## Создать окружение для студента
	@echo "Создание окружения для студента $(STUDENT_ID), тип: $(LAB_TYPE)"
	@scripts/deployment/create-student-env.sh create $(STUDENT_ID) $(LAB_TYPE)

student-cleanup: ## Удалить окружение студента
	@echo "Удаление окружения студента $(STUDENT_ID)"
	@scripts/deployment/create-student-env.sh cleanup $(STUDENT_ID)

backup: ## Создать резервную копию
	@echo "Создание резервной копии..."
	@scripts/management/backup.sh

restore: ## Восстановить из резервной копии
	@echo "Восстановление из резервной копии..."
	@scripts/management/restore.sh

clean: ## Очистка временных файлов
	@echo "Очистка временных файлов..."
	@find . -name "*.tfstate*" -type f -delete
	@find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -name "*.retry" -type f -delete
	@docker system prune -f

monitor: ## Открыть мониторинг
	@echo "Получение URL мониторинга..."
	@kubectl get service -n monitoring prometheus-grafana
	@echo "Для доступа к Grafana выполните: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"

dev: ## Запуск в режиме разработки
	@echo "Запуск в режиме разработки..."
	@docker-compose -f docker/compose/docker-compose.yml up -d

dev-stop: ## Остановка режима разработки
	@echo "Остановка режима разработки..."
	@docker-compose -f docker/compose/docker-compose.yml down