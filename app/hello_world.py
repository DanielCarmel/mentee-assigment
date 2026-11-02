import os

from fastapi import FastAPI

APP_VERSION = os.getenv("APP_VERSION", "0.0.0-dev")

app = FastAPI(title="hello-world", version=APP_VERSION)


@app.get("/")
def root():
    return {"message": "hello world"}


@app.get("/version")
def version():
    return {"version": APP_VERSION}


@app.get("/health")
def health():
    return {"status": "ok"}
