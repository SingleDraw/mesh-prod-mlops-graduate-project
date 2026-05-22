## Azure CLI - ACR Management

### 1. Requirements

* Role assigned: `AcrPush` (minimum) on ACR
* Logged in via Azure CLI or OIDC

```bash
az login
az acr login --name <ACR_NAME>
```

---

### 2. List repositories

```bash
az acr repository list \
  --name <ACR_NAME> \
  --output table
```

---

### 3. List tags in repository

```bash
az acr repository show-tags \
  --name <ACR_NAME> \
  --repository <REPO_NAME> \
  --output table
```

---

### 4. Delete specific image (tag)

```bash
az acr repository delete \
  --name <ACR_NAME> \
  --image <REPO_NAME>:<TAG> \
  --yes
```

---

### 5. Delete entire repository

```bash
az acr repository delete \
  --name <ACR_NAME> \
  --repository <REPO_NAME> \
  --yes
```

---

### 6. Bulk delete (example: all tags)

```bash
for tag in $(az acr repository show-tags \
  --name <ACR_NAME> \
  --repository <REPO_NAME> \
  --output tsv); do
  az acr repository delete \
    --name <ACR_NAME> \
    --image <REPO_NAME>:$tag \
    --yes
done
```

---

### 7. Automated cleanup (ACR task)

```bash
az acr task create \
  --registry <ACR_NAME> \
  --name purge-task \
  --cmd "acr purge --filter '<REPO_NAME>:.*' --ago 7d" \
  --schedule "0 0 * * *" \
  --context /dev/null
```

---

### Notes

* Admin user is not required
* RBAC + OIDC fully covers authentication and authorization
* `AcrPush` role is sufficient for delete operations
