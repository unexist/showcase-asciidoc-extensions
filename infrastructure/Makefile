IMAGE_NAME := showcase-extension-builder

--guard-%:
	@if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set: $*=abc123 make $(MAKECMDGOALS)"; \
		exit 1; \
	fi

build:
	podman build -t $(IMAGE_NAME) -f Containerfile

push: --guard-VERSION build
	podman login docker.io
	podman push $(IMAGE_NAME):latest docker.io/$(USER)/$(IMAGE_NAME):$(VERSION)