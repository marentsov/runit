import IRunner from './IRunner';

export default class PythonRunner implements IRunner {
  private runnerUrl = process.env.NODE_ENV === 'production'
    ? 'https://твой-python-runner.onrender.com'
    : 'http://localhost:5000';

  async run(code: string) {
    try {
      console.log('Sending code to Python runner:', code.substring(0, 100) + '...');

      const response = await fetch(`${this.runnerUrl}/execute`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ code })
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const result = await response.json();
      console.log('Python runner response:', result);

      return Promise.resolve({
        terminal: result.output.split('\n'),
        alertLogs: []
      });
    } catch (error) {
      console.error('Python runner error:', error);
      return Promise.resolve({
        terminal: [`Error: ${error.message}`],
        alertLogs: []
      });
    }
  }
}