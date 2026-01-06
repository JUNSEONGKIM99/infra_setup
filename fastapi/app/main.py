from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def root():
    return {"message": "FastAPI is Running!!"}

@app.get("/health")
def health():
    return {"status": "ok"}

