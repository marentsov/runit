FROM python:3-slim
WORKDIR /app
RUN pip install flask flask-cors
COPY backend/src/runner/dockers/python/server.py /app/server.py
CMD ["python", "/app/server.py"]

# FROM python:3-slim
#
# # Сначала установим Flask
# RUN pip install flask
#
# # Создаем рабочую директорию
# WORKDIR /app
#
# # Копируем server.py в контейнер
# COPY backend/src/runner/dockers/python/server.py /app/server.py
#
# # Запускаем сервер
# CMD ["python", "/app/server.py"]