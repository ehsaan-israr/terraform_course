const { describe, it } = require('node:test');
const assert = require('node:assert');
const { handler } = require('./server.js');

function mockReq(path) {
  return { url: path };
}

function mockRes() {
  const res = {
    statusCode: 0,
    headers: {},
    body: '',
    writeHead(code, headers) {
      this.statusCode = code;
      this.headers = headers;
    },
    end(body) {
      this.body = body;
    }
  };
  return res;
}

describe('capstone-api', () => {
  it('GET /health returns healthy JSON', () => {
    const res = mockRes();
    handler(mockReq('/health'), res);
    assert.strictEqual(res.statusCode, 200);
    const body = JSON.parse(res.body);
    assert.strictEqual(body.status, 'healthy');
  });

  it('GET /unknown returns 404', () => {
    const res = mockRes();
    handler(mockReq('/nope'), res);
    assert.strictEqual(res.statusCode, 404);
  });
});
