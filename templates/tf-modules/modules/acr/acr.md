
---
Guide for using **GitHub Actions + OIDC + Azure Container Registry (ACR)**.
---

# 1. Prerequisites (must be configured)

### Azure

* ACR deployed (your Terraform is OK)
* User Assigned Managed Identity
* Federated Identity Credential (GitHub OIDC)
* RBAC:

  * `AcrPush` for CI
  * `AcrPull` if needed

### GitHub Secrets

Set:

```
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
ACR_NAME
ACR_LOGIN_SERVER
```

Example:

```
ACR_NAME=myacr12345
ACR_LOGIN_SERVER=myacr12345.azurecr.io
```

---

# 2. Basic Workflow (build + push)

```yaml
name: build-and-push

on:
  push:
    branches: [ "main" ]

permissions:
  id-token: write
  contents: read

env:
  ACR_NAME: ${{ secrets.ACR_NAME }}
  ACR_LOGIN_SERVER: ${{ secrets.ACR_LOGIN_SERVER }}
  IMAGE_NAME: app

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Azure login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: ACR login
        run: az acr login --name $ACR_NAME

      - name: Build image
        run: |
          docker build \
            -t $ACR_LOGIN_SERVER/$IMAGE_NAME:${{ github.sha }} \
            .

      - name: Push image
        run: |
          docker push \
            $ACR_LOGIN_SERVER/$IMAGE_NAME:${{ github.sha }}
```

---

# 3. Tagging strategy (recommended)

Add additional tags:

```yaml
- name: Tag image
  run: |
    docker tag \
      $ACR_LOGIN_SERVER/$IMAGE_NAME:${{ github.sha }} \
      $ACR_LOGIN_SERVER/$IMAGE_NAME:latest
```

```yaml
- name: Push tags
  run: |
    docker push $ACR_LOGIN_SERVER/$IMAGE_NAME:latest
```

Optional: branch-based tag

```yaml
BRANCH_TAG=${GITHUB_REF##*/}
docker tag $ACR_LOGIN_SERVER/$IMAGE_NAME:${{ github.sha }} \
           $ACR_LOGIN_SERVER/$IMAGE_NAME:$BRANCH_TAG
```

---

# 4. Using Docker Buildx (faster + cache)

```yaml
- name: Set up Buildx
  uses: docker/setup-buildx-action@v3

- name: Build and push (Buildx)
  run: |
    docker buildx build \
      --platform linux/amd64 \
      -t $ACR_LOGIN_SERVER/$IMAGE_NAME:${{ github.sha }} \
      -t $ACR_LOGIN_SERVER/$IMAGE_NAME:latest \
      --push \
      .
```

---

# 5. Critical requirements

1. OIDC must match exactly:

```
repo:ORG/REPO:ref:refs/heads/main
```

2. RBAC:

```
AcrPush assigned to principal_id of identity
```

3. ACR must be reachable:

```
public_network_access_enabled = true
```

4. Do not use:

* admin credentials
* service principal secrets

---

# 6. Common failure cases

### Unauthorized

* missing `AcrPush`
* wrong `principal_id`

### OIDC login fails

* wrong `subject`
* missing `id-token: write`

### Push fails

* wrong `ACR_LOGIN_SERVER`
* missing `az acr login`

---

# 7. Minimal checklist

* ACR exists
* Identity exists
* Federated credential configured
* RBAC assigned
* GitHub secrets set
* Workflow uses `azure/login@v2`

---

clean, secure, passwordless CI pipeline.
