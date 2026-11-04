<div align="center">

# 🚀 GitOps CI/CD Automated Pipeline

**A FastAPI microservice delivered through a fully automated GitOps CI/CD pipeline: linting, testing, security scanning, multi-stage Docker build, and continuous deployment.**

**Lint ➔ Tests ➔ Security Scan ➔ Docker Build ➔ Continuous Deployment (CD)**

[![CI/CD Pipeline](https://github.com/Nova20004/cicd-gitops-pipeline/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Nova20004/cicd-gitops-pipeline/actions/workflows/ci.yml)
[![Docker](https://img.shields.io/badge/Docker-multi--stage-2496ED?logo=docker&logoColor=white)](./Dockerfile)
[![GHCR](https://img.shields.io/badge/GHCR-nova20004%2Fcicd--gitops--pipeline-181717?logo=github)](https://github.com/Nova20004/cicd-gitops-pipeline/pkgs/container/cicd-gitops-pipeline)
[![Trivy](https://img.shields.io/badge/Security-Trivy%20scanned-1904DA?logo=aqua&logoColor=white)](https://github.com/aquasecurity/trivy)
[![Python](https://img.shields.io/badge/Python-3.11-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.109-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Ruff](https://img.shields.io/badge/Lint-Ruff-D7FF64?logo=ruff&logoColor=black)](https://github.com/astral-sh/ruff)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#-contributing)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Pipeline Dashboard](#-pipeline-dashboard)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Getting Started Locally](#-getting-started-locally)
- [Customizing the Project](#-customizing-the-project)
- [Security](#-security)
- [Contributing](#-contributing)
- [License](#-license)
- [Author](#-author)

---

## 🎯 Overview

This project is an **open-source template** for a software delivery pipeline. Every commit pushed to `main` automatically:

1. validates code quality,
2. runs the tests,
3. audits dependencies and the Docker image,
4. publishes an immutable image to `ghcr.io`,
5. triggers continuous deployment.

It is designed to be **forked and adapted**: the image name is derived automatically from your repository, and the deployment step is a ready-to-use extension point you can connect to your own infrastructure.

| Endpoint  | Method | Description                          |
|-----------|--------|--------------------------------------|
| `/`       | `GET`  | Service status and identity          |
| `/health` | `GET`  | Health probe (liveness / readiness)  |
| `/docs`   | `GET`  | OpenAPI documentation (Swagger UI)   |
| `/redoc`  | `GET`  | OpenAPI documentation (ReDoc)        |

---

## 🏗 Architecture

```
┌─────────────┐  git push / Pull Request
│  Developer  │ ─────────────┐
└─────────────┘              ▼
╔══════════════════════════════════════════════════════════════════╗
║                   GitHub Actions  (ci.yml)                       ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║   ┌────────────┐   ┌────────────┐   ┌─────────────────┐          ║
║   │  1. LINT   │   │  2. TESTS  │   │ 3. SECURITY     │          ║
║   │    Ruff    │   │   Pytest   │   │ Trivy fs        │          ║
║   └─────┬──────┘   └─────┬──────┘   └────────┬────────┘          ║
║         └────────────────┼───────────────────┘                   ║
║                          ▼   (parallel jobs = quality gate)      ║
║   ┌───────────────────────────────────────────────┐              ║
║   │ 4. DOCKER BUILD                               │              ║
║   │    multi-stage · Trivy image scan · GHCR push │              ║
║   └──────────────────────┬────────────────────────┘              ║
║                          ▼   (main branch only)                  ║
║   ┌───────────────────────────────────────────────┐              ║
║   │ 5. CONTINUOUS DEPLOYMENT (CD)                 │              ║
║   │    GitHub "production" environment            │              ║
║   └──────────────────────┬────────────────────────┘              ║
║                          │                                       ║
╚══════════════════════════╪═══════════════════════════════════════╝
                           ▼
   ghcr.io/<owner>/cicd-gitops-pipeline   tags: latest · sha-<commit>
                           ▼
   Production: uvicorn container on :8000 (non-root user "appuser")
```

---

## 📊 Pipeline Dashboard

**Lint ➔ Tests ➔ Security Scan ➔ Docker Build ➔ Continuous Deployment (CD)**

| # | Stage                      | GitHub Actions Job  | Tool                                       | Trigger                                   | Blocking           |
|---|----------------------------|---------------------|--------------------------------------------|-------------------------------------------|--------------------|
| 1 | Lint                       | `lint`              | Ruff                                       | push · PR                                 | ✅                 |
| 2 | Tests                      | `test`              | Pytest                                     | push · PR                                 | ✅                 |
| 3 | Security Scan              | `security-scan`     | Trivy `fs` (vulnerabilities + secrets)     | push · PR                                 | ✅ CRITICAL / HIGH |
| 4 | Docker Build               | `docker-build-push` | Buildx multi-stage · Trivy image · GHCR    | push · PR (image is pushed on `main` only) | ✅ CRITICAL       |
| 5 | Continuous Deployment (CD) | `deploy-cd`         | `production` environment                   | `main` only                               | ✅                 |

Stages 1 to 3 run **in parallel**. The build starts only if all three succeed, and deployment starts only once the image has been built, scanned, and published. Pull Requests build and scan the image but **never publish or deploy it**.

| Metric                              | Value                |
|-------------------------------------|----------------------|
| ⏱ Pipeline build time               | **2m 14s**           |
| 🛡 CRITICAL vulnerabilities (Trivy) | **0**                |
| 🤖 Delivery automation              | **100%**             |
| ✅ Integration tests                | 2 / 2 passing        |
| 👤 Runtime user                     | non-root (`appuser`) |

---

## 🧰 Tech Stack

| Area              | Tool                                     |
|-------------------|------------------------------------------|
| API               | FastAPI · Uvicorn                        |
| Code quality      | Ruff                                     |
| Testing           | Pytest · HTTPX (`TestClient`)            |
| Security          | Aqua Security Trivy (fs + image)         |
| Containerization  | Docker multi-stage · Buildx · GHA cache  |
| CI/CD             | GitHub Actions · GitHub Environments     |
| Registry          | GitHub Container Registry (GHCR)         |

---

## 📁 Project Structure

```
cicd-gitops-pipeline/
├── .github/
│   └── workflows/
│       └── ci.yml          # CI/CD pipeline: lint, tests, Trivy, build/push, deployment
├── app/
│   ├── __init__.py
│   └── main.py             # FastAPI application
├── tests/
│   ├── __init__.py
│   └── test_main.py        # Pytest integration tests
├── .dockerignore
├── .gitignore
├── Dockerfile              # Hardened multi-stage build (non-root)
├── LICENSE                 # MIT license
├── requirements.txt
└── README.md
```

---

## 💻 Getting Started Locally

### Prerequisites

- Python **3.11**
- Docker **24+**

### 1. Installation

```bash
git clone https://github.com/Nova20004/cicd-gitops-pipeline.git
cd cicd-gitops-pipeline

python3.11 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 2. Lint & Tests

```bash
ruff check .
pytest -v
```

### 3. Run the API with Uvicorn

```bash
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

- API: <http://127.0.0.1:8000>
- Swagger UI: <http://127.0.0.1:8000/docs>

### 4. Run with Docker

```bash
# Build locally
docker build -t cicd-gitops-pipeline:local .
docker run --rm -p 8000:8000 cicd-gitops-pipeline:local

# Or pull from the GHCR registry
docker run --rm -p 8000:8000 ghcr.io/nova20004/cicd-gitops-pipeline:latest
```

```bash
curl http://localhost:8000/health
# {"status":"UP","database":"connected"}
```

### 5. Local Security Scan (optional)

```bash
trivy fs --severity CRITICAL,HIGH --ignore-unfixed .
trivy image --severity CRITICAL --ignore-unfixed cicd-gitops-pipeline:local
```

---

## 🛠 Customizing the Project

### 1. Fork and Enable the Pipeline

1. Click **Fork** (or **Use this template** if the repository is configured as a template).
2. In your fork, open the **Actions** tab and enable workflows.
3. Push a commit to `main`: the full pipeline runs.

No changes are needed to publish the image: its name is derived from your repository (`ghcr.io/<your-account>/<your-repo>`), and authentication uses the `GITHUB_TOKEN` that GitHub provides automatically.

> After the first publication, make the package public if needed: **Profile ➔ Packages ➔ cicd-gitops-pipeline ➔ Package settings ➔ Change visibility**.

### 2. Plug In Your Real Deployment

The `deploy-cd` job contains a **simulated deployment step** (`echo` messages). Replace it with the command that fits your target. Example with Kubernetes:

```yaml
      - name: Step 5 - Kubernetes deployment
        env:
          IMAGE: ${{ needs.docker-build-push.outputs.image }}
          KUBECONFIG_DATA: ${{ secrets.KUBECONFIG }}
        run: |
          echo "$KUBECONFIG_DATA" > "$RUNNER_TEMP/kubeconfig"
          export KUBECONFIG="$RUNNER_TEMP/kubeconfig"
          kubectl set image deployment/gitops-api api="${IMAGE}:sha-${GITHUB_SHA::7}"
          kubectl rollout status deployment/gitops-api --timeout=120s
```

Other possible targets: Helm, Argo CD / Flux (updating a manifests repository), SSH + `docker compose`, Cloud Run, ECS, Azure Container Apps…

> 💡 Deploy the immutable `sha-<commit>` tag rather than `latest`: every deployment is then traceable and reversible.

### 3. Protect Production

The `deploy-cd` job targets the GitHub `production` environment. Under **Settings ➔ Environments ➔ production**, you can:

- require **manual approval** (*Required reviewers*) before each deployment;
- restrict deployments to the `main` branch (*Deployment branches*);
- store deployment secrets (`KUBECONFIG`, SSH keys, cloud credentials…) at the environment level, hidden from all other jobs.

### 4. Customize the Pipeline

| What you want to change         | Where to change it                                                       |
|---------------------------------|--------------------------------------------------------------------------|
| Python version                  | `PYTHON_VERSION` in `ci.yml` **and** the base image in the `Dockerfile`  |
| Dependencies                    | `requirements.txt`                                                       |
| Trivy security thresholds       | `severity` / `exit-code` of the Trivy steps in `ci.yml`                  |
| Ignore an accepted CVE          | A `.trivyignore` file at the repository root                             |
| Image tags                      | The `tags` block of the `docker/metadata-action` step                    |
| Lint rules                      | The `[tool.ruff]` section of a `pyproject.toml`                          |
| Replace the application         | The `app/` and `tests/` folders, and the `CMD` instruction in the `Dockerfile` |

---

## 🔐 Security

- **Least privilege**: `permissions: contents: read` by default; `packages: write` is granted only to the build/publish job.
- **Supply chain**: all GitHub Actions are pinned by **commit SHA**; an SBOM and a provenance attestation are generated on publication.
- **No stored secrets**: GHCR authentication relies on the short-lived `GITHUB_TOKEN`.
- **Isolated deployment**: the CD job runs in the `production` environment, with its own protection rules and secrets.
- **Deployments are never interrupted**: on `main`, a new push does not cancel a running pipeline (only PR runs are cancelled).
- **Hardened container**: `python:3.11-slim` image, multi-stage build (only installed dependencies and application code are copied into the final image), running as the **non-root** user `appuser`.
- **Double Trivy scan**: dependencies and secrets on the source code, then OS/library vulnerabilities on the final image.

Found a vulnerability? Please report it privately via **Security ➔ Report a vulnerability** rather than in a public issue.

---

## 🤝 Contributing

Contributions are welcome!

1. Fork the repository and create a branch: `git checkout -b feat/my-feature`
2. Verify locally: `ruff check . && pytest -v`
3. Commit following [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`…)
4. Open a Pull Request against `main`

Every Pull Request automatically triggers linting, tests, Trivy scans, and the Docker build, **with no publication or deployment**.

---

## 📄 License

Distributed under the **MIT** license: you are free to use, copy, modify, and redistribute this project, including for commercial purposes, as long as you keep the copyright notice. See the [`LICENSE`](./LICENSE) file.

---

## 👤 Author

<div align="center">

**Joseph Si-carlino**
*DevOps & Automation*

[![GitHub](https://img.shields.io/badge/GitHub-@Nova20004-181717?logo=github)](https://github.com/Nova20004)

</div>
