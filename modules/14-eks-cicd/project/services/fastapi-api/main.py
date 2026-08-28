from fastapi import FastAPI

app = FastAPI(title="fastapi-api")


@app.get("/health")
def health():
    return {"status": "ok", "service": "fastapi-api"}
