import IRunner from './IRunner';

export default class PhpRunner implements IRunner {
  private runnerUrl = process.env.NODE_ENV === 'production'
    ? 'https://runit-gwvn.onrender.com'
    : 'http://localhost:5003';

  async run(code: string) {
    try {
      console.log('Sending code to PHP runner:', code.substring(0, 100) + '...');

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
      console.log('PHP runner response:', result);

      return Promise.resolve({
        terminal: result.output.split('\n'),
        alertLogs: []
      });
    } catch (error) {
      console.error('PHP runner error:', error);
      return Promise.resolve({
        terminal: [`Error: ${error.message}`],
        alertLogs: []
      });
    }
  }
}
