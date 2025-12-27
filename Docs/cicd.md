# 🚀 CI/CD & Security Guide

This project implements a **DevSecOps** workflow using **GitHub Actions**. It is designed to be:

* 🔐 **Secure (Keyless)**
* 🧭 **Robust (Drift Detection)**
* 🧩 **Modular (Decoupled pipelines)**

---

## High-Level Workflow
![CI/CD Diagram](assets/cicd_architecture.png)

### CI/CD Diagram

The automation is split into **three distinct pipelines** to separate concerns:

| Pipeline                 | Trigger                        | Purpose                                              | Tools                                 |
| ------------------------ | ------------------------------ | ---------------------------------------------------- | ------------------------------------- |
| **1. Quality Gate (CI)** | PR to `main`                   | Static analysis to prevent broken code from merging  | `ruff`, `terraform fmt`, `dbt parse`  |
| **2. Infra CD**          | Push to `main` (Infra changes) | Provisions cloud resources and updates configuration | `terraform apply`, `bash` (Handshake) |
| **3. App CD**            | Push to `main` (App code)      | Builds containers and updates orchestration          | `docker`, `aws ecr`, `aws ecs`        |

---

## 🔐 Security Architecture (OIDC)

We **do NOT store AWS Access Keys** (`AWS_ACCESS_KEY_ID`) in GitHub. Long-lived credentials are a major security risk.

Instead, we use **OpenID Connect (OIDC)**.

### How It Works

1. **Trust**
   An **IAM Identity Provider** is created in AWS that trusts GitHub’s signing keys.

2. **Role**
   A dedicated IAM role (`github-actions-deployer`) is created that trusts **only this specific GitHub repository**.

3. **Exchange**

   * GitHub signs an OIDC token at runtime
   * AWS verifies:

     * The token signature
     * The repository identity (`owner/repo`)
   * AWS issues a **temporary, short-lived session token**

### Terraform Implementation

The trust logic is defined in:

```
infrastructure/aws/github_oidc.tf
```

This ensures that **no fork or unauthorized repository** can assume your AWS role.

---

## ⚙️ Configuration Setup

To enable the pipeline in a new environment (for example, a fork), configure the following in:

**GitHub Repo Settings → Secrets and variables → Actions**

---

### 1. Repository Secrets (Encrypted)

| Secret Name              | Value Description                                   | Usage                                        |
| ------------------------ | --------------------------------------------------- | -------------------------------------------- |
| `AWS_ACCOUNT_ID`         | Your 12-digit AWS Account ID (e.g., `123456788788`) | Used to construct the OIDC Role ARN          |
| `RAWG_API_KEY`           | API key from RAWG.io                                | Injected into Fargate containers & Terraform |
| `SNOWFLAKE_ACCOUNT_NAME` | Snowflake account locator (e.g., `xy12345`)         | Terraform provider                           |
| `SNOWFLAKE_ORG_NAME`     | Snowflake organization ID                           | Terraform provider                           |
| `SNOWFLAKE_USER`         | Snowflake service account username                  | Terraform provider                           |
| `SNOWFLAKE_PASSWORD`     | Snowflake service account password                  | Terraform provider                           |

---

### 2. Repository Variables (Plain Text)

| Variable Name  | Value Description             | Usage                                    |
| -------------- | ----------------------------- | ---------------------------------------- |
| `PROJECT_NAME` | e.g., `football-data-pipeline`| Naming AWS resources (buckets, clusters) |
| `AWS_REGION`   | e.g., `af-south-1`            | Target AWS region                        |

---

## 🛠️ The Pipelines in Detail

### 1. Quality Gate (CI)

**Location:**

```
.github/workflows/ci-checks.yml
```

**Steps:**

* **Python**
  Runs `ruff` to catch syntax and style issues in `ingestion/`.

* **Terraform**
  Runs `terraform fmt` and `terraform validate` to catch configuration errors early.

* **dbt**
  Runs `dbt parse` to ensure SQL models compile correctly and dependencies are valid.

---

### 2. Infrastructure Deployment (CD)

**Location:**

```
.github/workflows/cd-infra.yml
```

**Key Concepts:**

* **State Management**
  Uses an **S3 backend (remote state)** to prevent "it works on my machine" issues.

* **The Handshake**
  Automatically executes:

  ```
  scripts/deploy_infra.sh
  ```

  to resolve the circular dependency between **AWS IAM** and **Snowflake Storage Integrations**.

---

### 3. Application Deployment (CD)

**Location:**

```
.github/workflows/cd-app.yml
```

**Steps:**

* **Build**
  Builds Docker images for `ingestion` and `analytics` services.

* **Push**
  Pushes images to **Amazon ECR**.

* **Deploy**
  Performs a **zero-downtime deployment** on AWS Fargate using:

  ```bash
  aws ecs update-service --force-new-deployment
  ```

---

## 🧯 Troubleshooting & Operations

### "State Drift" (Bucket already exists)

**Problem:**
The pipeline fails because a resource already exists in AWS, but Terraform doesn’t know about it.

**Cause:**
Terraform **state file is out of sync**.

**Fix:**

* Run locally:

  ```bash
  make prod-infra-apply
  ```

  to re-sync the state with S3

* OR perform a **Terraform Import** for the existing resource

---

### "Not Authorized to Assume Role"

**Checklist:**

1. ✅ Verify the `AWS_ACCOUNT_ID` secret
2. ✅ Confirm the **Trust Policy** exactly matches:

   * `owner/repo-name`
   * Correct casing
   * No typos

---

✅ **This setup provides a secure, scalable, and production-grade CI/CD pipeline aligned with DevSecOps best practices.**
