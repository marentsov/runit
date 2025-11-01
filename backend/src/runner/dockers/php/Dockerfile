FROM php:8.2-cli
WORKDIR /app
COPY backend/src/runner/dockers/php/server.php /app/server.php
CMD ["php", "-S", "0.0.0.0:5003", "server.php"]
