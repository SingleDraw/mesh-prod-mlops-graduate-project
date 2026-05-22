
module-template-repo 	= tf-modules

# ==========================
# Terraform Modules Repository
# ==========================

init-modules-repo:
	@$(call init-repo-from-template,$(module-template-repo))
create-modules-repo:
	$(call create-repo,$(module-template-repo),$(GH_REPO_MODULES))
push-modules-repo:
	@$(call force-push-repo,$(module-template-repo),$(GH_REPO_MODULES))
	@cd "$(LOCAL_REPOS)/$(module-template-repo)" && \
	(git tag $(GH_REPO_MODULES_REF) 2>/dev/null || echo "Tag $(GH_REPO_MODULES_REF) already exists." && exit 0) && \
	git push origin $(GH_REPO_MODULES_REF) --force


# High-level target to generate and push modules repo
generate-modules-repo:
	@$(MAKE) init-modules-repo
	@$(MAKE) create-modules-repo
	@$(MAKE) push-modules-repo
