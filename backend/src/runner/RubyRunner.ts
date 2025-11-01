import IRunner from './IRunner';

export default class RubyRunner implements IRunner {
  private runnerUrl = process.env.NODE_ENV === 'production'
    ? 'https://runit-ruby-docker.onrender.com'
    : 'http://localhost:5005';

  async run(code: string) {
    try {
      console.log('Sending code to Ruby runner:', code.substring(0, 100) + '...');

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
      console.log('Ruby runner response:', result);

      return Promise.resolve({
        terminal: result.output.split('\n'),
        alertLogs: []
      });
    } catch (error) {
      console.error('Ruby runner error:', error);
      return Promise.resolve({
        terminal: [`Error: ${error.message}`],
        alertLogs: []
      });
    }
  }
}