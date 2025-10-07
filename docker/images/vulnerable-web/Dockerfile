FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY templates/ templates/

# Создаем уязвимые конфигурации
RUN useradd -m -s /bin/bash webapp && \
    chmod 777 /app && \
    echo "webapp:password123" | chpasswd

USER webapp

EXPOSE 5000

CMD ["python", "app.py"]