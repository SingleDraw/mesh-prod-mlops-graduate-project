
# ==== Utility Functions for Makefile ======
define unix-endings
	@for file in $(TARGETS); do \
		echo "Converting $$file to Unix line endings..."; \
		sed -i 's/\r$$//' "$$file"; \
	done
endef

# ==== SSH rotate deploy keys ========================
define create-local-deploy-key
	@./scripts/keys/gen-keypair.sh "$(1)" "$(2)"
	@./scripts/gh/upsert-deploy-key.sh "$(3)" "$(1)" "$(2)"
endef

define rotate-deploy-key
	@./scripts/keys/gen-keypair.sh "$(1)" "$(2)"
	@./scripts/gh/upsert-deploy-key.sh "$(3)" "$(1)" "$(2)"
	@./scripts/gh/update-private-key.sh "$(4)" "$(2)"
endef

# ==== GitHub Repo Initialization from Template ======
define init-repo-from-template
	@LOCAL_REPOS=$(LOCAL_REPOS) ./scripts/repo/init-template.sh $(1)
endef

# ==== GitHub Repo Creation and Force Push ======
define create-repo
	@echo "Checking/Creating GitHub repository $(2)..."
	@gh repo view $(GH_OWNER)/$(2) >/dev/null 2>&1 || \
	gh repo create $(GH_OWNER)/$(2) --private
endef

define force-push-repo
	@echo "Initializing and force-pushing to GitHub..."
	@cd "$(LOCAL_REPOS)/$(1)" && \
		git init && \
		git checkout -b main || git branch -M main && \
		git add -A && \
		(git commit -m "Bootstrap: $(1) repo with injected vars" \
		|| echo "Nothing to commit") && \
		git remote add origin git@github.com:$(GH_OWNER)/$(2).git && \
		git push -u origin main --force
endef