import IRunner from './IRunner';

export default class JavaRunner implements IRunner {
  private runnerUrl = process.env.NODE_ENV === 'production'
    ? 'https://твой-java-runner.onrender.com'
    : 'http://localhost:5004';

  async run(code: string) {
    try {
      const response = await fetch(`${this.runnerUrl}/execute`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ code })
      });

      const result = await response.json();
      return Promise.resolve({
        terminal: result.output.split('\n'),
        alertLogs: []
      });
    } catch (error) {
      return Promise.resolve({
        terminal: [`Error: ${error.message}`],
        alertLogs: []
      });
    }
  }
}