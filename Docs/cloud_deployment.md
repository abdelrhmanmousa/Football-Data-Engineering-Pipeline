# ☁️ Cloud Deployment Guide

> **Note:** Routine deployments are handled automatically by **GitHub Actions**. This guide covers the **Initial Bootstrap** and **Disaster Recovery** scenarios.

## 1. Prerequisites
*   AWS CLI configured with Admin permissions.
*   Terraform installed.
*   Docker running.

## 2. Initial Bootstrap (Establishing Trust)
Before GitHub Actions can deploy, AWS must be taught to trust your GitHub Repository.

1.  **Configure Environment**:
    ```bash
    export TF_VAR_github_repo="your-user/your-repo"
    export PROJECT_NAME="game-market-analytics"
    ```
2.  **Apply Infrastructure**:
    ```bash
    make prod-infra-apply
    ```
    *This creates the OIDC Identity Provider and the IAM Role required for CI/CD.*

## 3. Disaster Recovery
If Terraform State becomes corrupted (Drift), you can reset the environment:

1.  **Manually Delete** resources in AWS Console (S3, ECR, IAM Roles).
2.  **Delete** the state folder in your S3 State Bucket.
3.  **Run Bootstrap** (Step 2 above) to recreate the universe from scratch.

## 4. Manual Operations
*   **Force Restart:** `make prod-restart` (Kicks ECS tasks).
*   **Build & Push:** `make prod-build-push` (Updates Docker images manually).