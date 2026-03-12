from fastapi import FastAPI

app = FastAPI(title="SL1C3D-L4BS API Scaffold")


@app.get("/health")
def health():
    return {"ok": True}
