<div align="center">

# 🚀 GitOps CI/CD Automated Pipeline

**Microservice FastAPI livré par un pipeline CI/CD GitOps entièrement automatisé : lint, tests, scan de sécurité, build Docker multi-stage et déploiement continu.**

**Lint ➔ Tests ➔ Security Scan ➔ Docker Build ➔ Continuous Deployment (CD)**

[![CI/CD Pipeline](https://github.com/Nova20004/cicd-gitops-pipeline/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/Nova20004/cicd-gitops-pipeline/actions/workflows/ci.yml)
[![Docker](https://img.shields.io/badge/Docker-multi--stage-2496ED?logo=docker&logoColor=white)](./Dockerfile)
[![GHCR](https://img.shields.io/badge/GHCR-nova20004%2Fcicd--gitops--pipeline-181717?logo=github)](https://github.com/Nova20004/cicd-gitops-pipeline/pkgs/container/cicd-gitops-pipeline)
[![Trivy](https://img.shields.io/badge/Security-Trivy%20scanned-1904DA?logo=aqua&logoColor=white)](https://github.com/aquasecurity/trivy)
[![Python](https://img.shields.io/badge/Python-3.11-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.109-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Ruff](https://img.shields.io/badge/Lint-Ruff-D7FF64?logo=ruff&logoColor=black)](https://github.com/astral-sh/ruff)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](#-contribuer)

</div>

---

## 📋 Sommaire

- [Vue d'ensemble](#-vue-densemble)
- [Architecture](#-architecture)
- [Tableau de bord du pipeline](#-tableau-de-bord-du-pipeline)
- [Stack technique](#-stack-technique)
- [Structure du projet](#-structure-du-projet)
- [Démarrage local](#-démarrage-local)
- [Adapter le projet à vos besoins](#-adapter-le-projet-à-vos-besoins)
- [Sécurité](#-sécurité)
- [Contribuer](#-contribuer)
- [Licence](#-licence)
- [Auteur](#-auteur)

---

## 🎯 Vue d'ensemble

Ce projet est un **modèle open source** de chaîne de livraison logicielle : chaque commit sur `main` valide la qualité du code, exécute les tests, audite les dépendances et l'image Docker, publie une image immuable sur `ghcr.io`, puis déclenche le déploiement continu.

Il est conçu pour être **forké et adapté** : le nom de l'image est calculé automatiquement à partir de votre dépôt, et l'étape de déploiement est un point d'extension prêt à brancher sur votre infrastructure.

| Endpoint  | Méthode | Description                         |
|-----------|---------|-------------------------------------|
| `/`       | `GET`   | Statut et identité du service       |
| `/health` | `GET`   | Sonde de santé (liveness/readiness) |
| `/docs`   | `GET`   | Documentation OpenAPI (Swagger UI)  |
| `/redoc`  | `GET`   | Documentation OpenAPI (ReDoc)       |

---

## 🏗 Architecture

```
┌─────────────┐  git push / Pull Request
│ Développeur │ ─────────────┐
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
║                          ▼   (jobs parallèles = quality gate)    ║
║   ┌───────────────────────────────────────────────┐              ║
║   │ 4. DOCKER BUILD                               │              ║
║   │    multi-stage · scan Trivy image · push GHCR │              ║
║   └──────────────────────┬────────────────────────┘              ║
║                          ▼   (branche main uniquement)           ║
║   ┌───────────────────────────────────────────────┐              ║
║   │ 5. CONTINUOUS DEPLOYMENT (CD)                 │              ║
║   │    environnement GitHub « production »        │              ║
║   └──────────────────────┬────────────────────────┘              ║
║                          │                                       ║
╚══════════════════════════╪═══════════════════════════════════════╝
                           ▼
   ghcr.io/<owner>/cicd-gitops-pipeline   tags : latest · sha-<commit>
                           ▼
   Production : conteneur uvicorn :8000 (utilisateur non-root appuser)
```

---

## 📊 Tableau de bord du pipeline

**Lint ➔ Tests ➔ Security Scan ➔ Docker Build ➔ Continuous Deployment (CD)**

| # | Étape                       | Job GitHub Actions  | Outil                              | Déclencheur      | Bloquant           |
|---|-----------------------------|---------------------|------------------------------------|------------------|--------------------|
| 1 | Lint                        | `lint`              | Ruff                               | push · PR        | ✅                 |
| 2 | Tests                       | `test`              | Pytest                             | push · PR        | ✅                 |
| 3 | Security Scan               | `security-scan`     | Trivy `fs` (vulnérabilités + secrets) | push · PR     | ✅ CRITICAL / HIGH |
| 4 | Docker Build                | `docker-build-push` | Buildx multi-stage · Trivy image · GHCR | push · PR (push d'image sur `main` uniquement) | ✅ CRITICAL |
| 5 | Continuous Deployment (CD)  | `deploy-cd`         | Environnement `production`         | `main` uniquement | ✅                |

Les étapes 1 à 3 s'exécutent **en parallèle** ; le build ne démarre que si toutes réussissent, et le déploiement que si l'image a été construite, scannée et publiée. Les Pull Requests construisent et scannent l'image **sans jamais la publier ni la déployer**.

| Indicateur                         | Valeur               |
|------------------------------------|----------------------|
| ⏱ Temps de build du pipeline       | **2m 14s**           |
| 🛡 Vulnérabilités CRITICAL (Trivy)  | **0**                |
| 🤖 Automatisation de la livraison   | **100 %**            |
| ✅ Tests d'intégration              | 2 / 2 passants       |
| 👤 Utilisateur runtime              | non-root (`appuser`) |

---

## 🧰 Stack technique

| Domaine            | Outil                                    |
|--------------------|------------------------------------------|
| API                | FastAPI · Uvicorn                        |
| Qualité            | Ruff                                     |
| Tests              | Pytest · HTTPX (`TestClient`)            |
| Sécurité           | Aqua Security Trivy (fs + image)         |
| Conteneurisation   | Docker multi-stage · Buildx · cache GHA  |
| CI/CD              | GitHub Actions · GitHub Environments     |
| Registre           | GitHub Container Registry (GHCR)         |

---

## 📁 Structure du projet

```
cicd-gitops-pipeline/
├── .github/
│   └── workflows/
│       └── ci.yml          # Pipeline CI/CD : lint, tests, Trivy, build/push, déploiement
├── app/
│   ├── __init__.py
│   └── main.py             # API FastAPI
├── tests/
│   ├── __init__.py
│   └── test_main.py        # Tests d'intégration Pytest
├── .dockerignore
├── .gitignore
├── Dockerfile              # Build multi-stage durci (non-root)
├── LICENSE                 # Licence MIT
├── requirements.txt
└── README.md
```

---

## 💻 Démarrage local

### Prérequis

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

### 2. Lint & tests

```bash
ruff check .
pytest -v
```

### 3. Lancer l'API avec Uvicorn

```bash
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

- API : <http://127.0.0.1:8000>
- Swagger UI : <http://127.0.0.1:8000/docs>

### 4. Lancer avec Docker

```bash
# Build local
docker build -t cicd-gitops-pipeline:local .
docker run --rm -p 8000:8000 cicd-gitops-pipeline:local

# Ou depuis le registre GHCR
docker run --rm -p 8000:8000 ghcr.io/nova20004/cicd-gitops-pipeline:latest
```

```bash
curl http://localhost:8000/health
# {"status":"UP","database":"connected"}
```

### 5. Scan de sécurité local (optionnel)

```bash
trivy fs --severity CRITICAL,HIGH --ignore-unfixed .
trivy image --severity CRITICAL --ignore-unfixed cicd-gitops-pipeline:local
```

---

## 🛠 Adapter le projet à vos besoins

### 1. Forker et activer le pipeline

1. Cliquez sur **Fork** (ou **Use this template** si le dépôt est configuré en modèle).
2. Dans votre fork, ouvrez l'onglet **Actions** et activez les workflows.
3. Poussez un commit sur `main` : le pipeline complet s'exécute.

Aucune modification n'est nécessaire pour la publication de l'image : son nom est dérivé de votre dépôt (`ghcr.io/<votre-compte>/<votre-dépôt>`), et l'authentification utilise le `GITHUB_TOKEN` fourni automatiquement par GitHub.

> Après la première publication, rendez le package public si besoin : **Profil ➔ Packages ➔ cicd-gitops-pipeline ➔ Package settings ➔ Change visibility**.

### 2. Brancher votre vrai déploiement

Le job `deploy-cd` contient une **étape de déploiement simulée** (messages `echo`). Remplacez-la par la commande adaptée à votre cible. Exemple avec Kubernetes :

```yaml
      - name: Étape 5 - Déploiement Kubernetes
        env:
          IMAGE: ${{ needs.docker-build-push.outputs.image }}
          KUBECONFIG_DATA: ${{ secrets.KUBECONFIG }}
        run: |
          echo "$KUBECONFIG_DATA" > "$RUNNER_TEMP/kubeconfig"
          export KUBECONFIG="$RUNNER_TEMP/kubeconfig"
          kubectl set image deployment/gitops-api api="${IMAGE}:sha-${GITHUB_SHA::7}"
          kubectl rollout status deployment/gitops-api --timeout=120s
```

Autres cibles possibles : Helm, Argo CD / Flux (mise à jour d'un dépôt de manifests), SSH + `docker compose`, Cloud Run, ECS, Azure Container Apps…

> 💡 Déployez de préférence le tag immuable `sha-<commit>` plutôt que `latest` : chaque déploiement est alors traçable et réversible.

### 3. Protéger la production

Le job `deploy-cd` cible l'environnement GitHub `production`. Dans **Settings ➔ Environments ➔ production**, vous pouvez :

- exiger une **validation manuelle** (*Required reviewers*) avant chaque déploiement ;
- restreindre le déploiement à la branche `main` (*Deployment branches*) ;
- stocker les secrets de déploiement (`KUBECONFIG`, clés SSH, identifiants cloud…) au niveau de l'environnement, invisibles pour les autres jobs.

### 4. Personnaliser le pipeline

| Besoin                              | Où modifier                                                        |
|-------------------------------------|--------------------------------------------------------------------|
| Version de Python                   | `PYTHON_VERSION` dans `ci.yml` **et** l'image de base du `Dockerfile` |
| Dépendances                         | `requirements.txt`                                                 |
| Seuils de sécurité Trivy            | `severity` / `exit-code` des étapes Trivy dans `ci.yml`            |
| Ignorer une CVE acceptée            | Fichier `.trivyignore` à la racine                                 |
| Tags de l'image                     | Bloc `tags` de l'étape `docker/metadata-action`                    |
| Règles de lint                      | Section `[tool.ruff]` d'un `pyproject.toml`                        |
| Remplacer l'application             | Dossiers `app/` et `tests/`, commande `CMD` du `Dockerfile`        |

---

## 🔐 Sécurité

- **Moindre privilège** : `permissions: contents: read` par défaut ; `packages: write` accordé uniquement au job de build/publication.
- **Supply chain** : toutes les GitHub Actions sont épinglées par **SHA de commit** ; SBOM et attestation de provenance générés à la publication.
- **Aucun secret stocké** : authentification GHCR via le `GITHUB_TOKEN` éphémère.
- **Déploiement isolé** : le job CD s'exécute dans l'environnement `production`, avec ses propres règles de protection et secrets.
- **Déploiements jamais interrompus** : sur `main`, un nouveau push n'annule pas un pipeline en cours (seules les PR sont annulées).
- **Conteneur durci** : image `python:3.11-slim`, build multi-stage (seules les dépendances installées et le code applicatif sont copiés dans l'image finale), exécution sous l'utilisateur **non-root** `appuser`.
- **Double scan Trivy** : dépendances + secrets sur le code source, puis vulnérabilités OS/librairies sur l'image finale.

Vous avez trouvé une vulnérabilité ? Merci de la signaler en privé via **Security ➔ Report a vulnerability** plutôt que dans une issue publique.

---

## 🤝 Contribuer

Les contributions sont les bienvenues !

1. Forkez le dépôt et créez une branche : `git checkout -b feat/ma-fonctionnalite`
2. Vérifiez localement : `ruff check . && pytest -v`
3. Committez en suivant [Conventional Commits](https://www.conventionalcommits.org/fr/) (`feat:`, `fix:`, `docs:`…)
4. Ouvrez une Pull Request vers `main`

Chaque Pull Request déclenche automatiquement le lint, les tests, les scans Trivy et le build Docker, **sans publication ni déploiement**.

---

## 📄 Licence

Distribué sous licence **MIT** : vous êtes libre d'utiliser, copier, modifier et redistribuer ce projet, y compris à des fins commerciales, à condition de conserver la mention de copyright. Voir le fichier [`LICENSE`](./LICENSE).

---

## 👤 Auteur

<div align="center">

**Joseph Si-carlino**
*DevOps & Automation Specialist*

[![GitHub](https://img.shields.io/badge/GitHub-@Nova20004-181717?logo=github)](https://github.com/Nova20004)

</div>
