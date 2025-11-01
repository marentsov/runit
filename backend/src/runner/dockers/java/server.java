import com.sun.net.httpserver.HttpServer;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpExchange;
import java.io.*;
import java.net.InetSocketAddress;
import java.nio.file.Files;
import java.nio.file.Path;

public class server {
    public static void main(String[] args) throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress(5004), 0);
        server.createContext("/execute", new CodeHandler());
        server.createContext("/health", new HealthHandler());
        server.setExecutor(null);
        server.start();
        System.out.println("Java runner started on port 5004"); //
    }

    static class HealthHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            String response = "{\"status\":\"Java runner is running\"}";
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.getResponseHeaders().set("Access-Control-Allow-Origin", "*");
            exchange.sendResponseHeaders(200, response.length());
            OutputStream os = exchange.getResponseBody();
            os.write(response.getBytes());
            os.close();
        }
    }

    static class CodeHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            exchange.getResponseHeaders().set("Access-Control-Allow-Origin", "*");
            exchange.getResponseHeaders().set("Access-Control-Allow-Methods", "POST, OPTIONS");
            exchange.getResponseHeaders().set("Access-Control-Allow-Headers", "Content-Type");

            if ("OPTIONS".equals(exchange.getRequestMethod())) {
                exchange.sendResponseHeaders(200, -1);
                return;
            }

            if (!"POST".equals(exchange.getRequestMethod())) {
                exchange.sendResponseHeaders(405, -1);
                return;
            }

            try {
                InputStream is = exchange.getRequestBody();
                String requestBody = new String(is.readAllBytes());

                // ЛУЧШИЙ JSON ПАРСИНГ
                String code = extractCodeFromJson(requestBody);

                Path tempFile = Files.createTempFile("java_", ".java");
                Files.writeString(tempFile, "public class TempClass { public static void main(String[] args) { " + code + " } }");

                ProcessBuilder pb = new ProcessBuilder("java", tempFile.toString());
                Process process = pb.start();
                String output = new String(process.getInputStream().readAllBytes());
                String error = new String(process.getErrorStream().readAllBytes());

                String result = output.isEmpty() ? error : output;
                String response = "{\"output\":\"" + escapeJson(result) + "\"}"; // ← ЭКРАНИРОВАНИЕ

                exchange.getResponseHeaders().set("Content-Type", "application/json");
                exchange.sendResponseHeaders(200, response.length());
                OutputStream os = exchange.getResponseBody();
                os.write(response.getBytes());
                os.close();

                Files.delete(tempFile);
            } catch (Exception e) {
                String response = "{\"output\":\"Error: " + e.getMessage() + "\"}";
                exchange.sendResponseHeaders(500, response.length());
                OutputStream os = exchange.getResponseBody();
                os.write(response.getBytes());
                os.close();
            }
        }

        private String extractCodeFromJson(String json) {
            try {
                // Простой парсинг JSON
                int start = json.indexOf("\"code\":\"") + 8;
                int end = json.lastIndexOf("\"");
                if (start > 8 && end > start) {
                    return json.substring(start, end)
                              .replace("\\n", "\n")
                              .replace("\\\"", "\"")
                              .replace("\\\\", "\\");
                }
            } catch (Exception e) {
                // Если парсинг не удался, вернем как есть
            }
            return "";
        }

        private String escapeJson(String text) {
            return text.replace("\\", "\\\\")
                      .replace("\"", "\\\"")
                      .replace("\n", "\\n")
                      .replace("\r", "\\r")
                      .replace("\t", "\\t");
        }
    }
}