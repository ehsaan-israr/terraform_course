import { describe, it } from "node:test";
import assert from "node:assert/strict";
import request from "supertest";
import app from "../src/server.js";

describe("course-api", () => {
  it("GET / returns course message", async () => {
    const res = await request(app).get("/");
    assert.equal(res.status, 200);
    assert.equal(res.body.module, "07-ci");
    assert.ok(res.body.message);
  });

  it("GET /health returns 200 healthy", async () => {
    const res = await request(app).get("/health");
    assert.equal(res.status, 200);
    assert.equal(res.body.status, "healthy");
    assert.equal(res.body.service, "course-api");
  });
});
