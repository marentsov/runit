<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    $code = $input['code'] ?? '';

    // Убираем PHP теги если они есть
    $code = preg_replace('/^\s*<\?php\s*/', '', $code);
    $code = preg_replace('/\s*\?>\s*$/', '', $code);

    $tempFile = tempnam(sys_get_temp_dir(), 'php_') . '.php';

    // Добавляем PHP теги для выполнения
    file_put_contents($tempFile, "<?php\n" . $code . "\n?>");

    ob_start();
    $result = include $tempFile;
    $output = ob_get_clean();

    unlink($tempFile);

    echo json_encode([
        'output' => $output ?: 'Code executed (no output)',
        'success' => $result !== false
    ]);
    exit;
}

echo json_encode(['status' => 'PHP runner OK']);
?>