FROM openjdk:21-slim
WORKDIR /app
COPY backend/src/runner/dockers/java/server.java /app/server.java
RUN javac server.java
CMD ["java", "server"]