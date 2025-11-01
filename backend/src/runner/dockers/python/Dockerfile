FROM python:3-slim

# Сначала установим Flask
RUN pip install flask

# Создаем рабочую директорию
WORKDIR /app

# Копируем server.py в контейнер
COPY backend/src/runner/dockers/python/server.py /app/server.py

# Запускаем сервер
CMD ["python", "/app/server.py"]