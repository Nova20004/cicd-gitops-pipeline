from fastapi import FastAPI

app = FastAPI(
    title="DevOps GitOps Microservice",
    description="API de démonstration pour pipeline CI/CD automatisé",
    version="1.0.0"
)

@app.get("/")
def read_root():
    return {"status": "healthy", "service": "GitOps Pipeline Demo", "environment": "production"}

@app.get("/health")
def health_check():
    return {"status": "UP", "database": "connected"}
