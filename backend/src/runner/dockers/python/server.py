from flask import Flask, request, jsonify
import subprocess
import tempfile
import os

app = Flask(__name__)


@app.route('/execute', methods=['POST'])
def execute():
    data = request.json
    code = data.get('code', '')

    with tempfile.NamedTemporaryFile(mode='w', suffix='.py', delete=False) as f:
        f.write(code)
        temp_file = f.name

    try:
        result = subprocess.run(
            ['python', temp_file],
            capture_output=True,
            text=True,
            timeout=10
        )

        output = result.stdout if result.stdout else result.stderr
        return jsonify({
            'output': output,
            'exit_code': result.returncode
        })

    except Exception as e:
        return jsonify({'output': f'Error: {str(e)}'})

    finally:
        os.unlink(temp_file)


@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'Python runner is ready'})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002)