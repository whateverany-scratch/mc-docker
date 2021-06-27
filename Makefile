DRY_RUN ?= false

IMAGE_NAME=$(REPOSITORY_URL)/$(APP_NAME)

ENVFILE ?= .env.template
RUNNER = docker-compose run -T --rm
RUNNER-TTY = docker-compose run --rm 
RUNNER-JFROG = docker-compose -f docker-compose-jfrog.yml run --rm jfrog

JFROG_USER ?= ${JFROG_USER}
JFROG_API_KEY ?= ${JFROG_API_KEY}
.env:
	cp .env.template .env
.PHONY: .env

pre-commit:
	make lint
.PHONY: pre-commit

# Runs a superlinter on code giving you a report on how well your DockerFile is coded.
lint: .env
	$(RUNNER) -e "RUN_LOCAL=true" -e "DEFAULT_WORKSPACE=." -e "OUTPUT_FORMAT=tap" -e "FILTER_REGEX_EXCLUDE=./..*\.swp$$|^./.env$$|^./super-linter.report/.*$$" lint
.PHONY: lint

test: build
	# To be implemented
.PHONY: build

build:
	# Use make pull-build if you don't need a Dockerfile to build the image
	make file-build
.PHONY: build

pull-build: .env
	docker pull $(REPOSITORY_URL)/$(APP_NAME):$(BUILD_VERSION)
	docker tag $(REPOSITORY_URL)/$(APP_NAME):$(BUILD_VERSION) $(IMAGE_NAME):$(BUILD_VERSION)-$(CI_PIPELINE_IID)
	docker tag $(REPOSITORY_URL)/$(APP_NAME):$(BUILD_VERSION) $(IMAGE_NAME):$(BUILD_VERSION)
	docker tag $(REPOSITORY_URL)/$(APP_NAME):$(BUILD_VERSION) $(IMAGE_NAME):$(CI_PIPELINE_IID)
	docker tag $(REPOSITORY_URL)/$(APP_NAME):$(BUILD_VERSION) $(IMAGE_NAME):latest
.PHONY: pull-build

# "make file-build" will run the Docker Build using the DockerFile in your repository.
# This requires IMAGE_NAME REPOSITORY_URL BUILD_VERSION APP_NAME environment vars to be declared if running locally.
file-build: .env _env-REPOSITORY_URL _env-SOURCE_APP_NAME _env-SOURCE_VERSION _env-APP_NAME _env-BUILD_VERSION _env-IMAGE_NAME
	docker build \
		-t $(IMAGE_NAME):latest \
		--build-arg REPOSITORY_URL=$(REPOSITORY_URL) \
		--build-arg SOURCE_APP_NAME=$(SOURCE_APP_NAME) \
		--build-arg SOURCE_VERSION=$(SOURCE_VERSION) \
	.
	docker tag $(IMAGE_NAME):latest $(IMAGE_NAME):$(BUILD_VERSION)
.PHONY: file-build

publish: .env build _env-CI_PROJECT_NAME _env-JFROG_URL _env-JFROG_API_KEY _env-JFROG_USER _env-DRY_RUN
	$(RUNNER-JFROG) make _publish
.PHONY: publish

_publish:
	for tag in $(IMAGE_NAME):latest $(IMAGE_NAME):$(BUILD_VERSION) $(IMAGE_NAME):$(BUILD_VERSION)-$(CI_PIPELINE_IID); do \
		jfrog rt docker-push $${tag} $(DEV_REPOSITORY) \
			--build-name=$(CI_PROJECT_NAME) --build-number=$(CI_PIPELINE_IID) \
			--url $(JFROG_URL) --apikey $(JFROG_API_KEY) --user $(JFROG_USER); \
	done

	jfrog rt build-add-git $(CI_PROJECT_NAME) $(CI_PIPELINE_IID)

	jfrog rt build-collect-env $(CI_PROJECT_NAME) $(CI_PIPELINE_IID)

	jfrog rt build-publish $(CI_PROJECT_NAME) $(CI_PIPELINE_IID) \
		--url $(JFROG_URL) --apikey $(JFROG_API_KEY) --user $(JFROG_USER) --dry-run=$(DRY_RUN)
.PHONY: _publish

# Used within the GitLab Pipeline to run a JFrog Xray Scan on your container to find any Vulnerabilities
scan: .env _env-CI_PROJECT_NAME _env-JFROG_URL _env-JFROG_API_KEY _env-JFROG_USER _env-CI_PIPELINE_IID
	$(RUNNER-JFROG) make _scan
.PHONY: scan

_scan:
	jfrog rt build-scan $(CI_PROJECT_NAME) $(CI_PIPELINE_IID) \
		--url $(JFROG_URL) --apikey $(JFROG_API_KEY) --user $(JFROG_USER) > $(XRAY_SCAN_REPORT) || true

	python3 $$XRAY_CONVERTER $(XRAY_SCAN_REPORT)
.PHONY: _scan

shell:
	$(RUNNER-TTY) -u root image-test /bin/bash
.PHONY: shell

source-shell:
	$(RUNNER-TTY) source-test /bin/bash
.PHONY: source-shell

jfrog-shell:
	$(RUNNER-JFROG) /bin/bash
.PHONY: jfrog-shell

# Checks if your local Environment Vars are setup.
_env-%:
	@ if [ "${${*}}" = "" ]; then \
			echo "Environment variable $* not set"; \
			echo "Please check README.md for variables required"; \
			exit 1; \
	fi
	@echo "INFO: ${*}='${${*}}'";

.env:
	@ if [ \! -e .env ]; then \
	  cp $(ENVFILE) .env; \
	fi
