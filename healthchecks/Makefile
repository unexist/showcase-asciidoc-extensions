.DEFAULT_GOAL := docs
INDEX_FILE := healthchecks

--guard-%:
	@if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set: $*=abc123 make $(MAKECMDGOALS)"; \
		exit 1; \
	fi

test:
	asciidoctor \
		-r ../asciidoctor-helper-macros/src/main/resources/extensions/env.rb \
		-r ../asciidoctor-helper-macros/src/main/resources/extensions/healthcheck-block-macro.rb \
		--trace -D . src/site/asciidoc/$(INDEX_FILE).adoc

test-open:
	open ./$(INDEX_FILE).html

open:
	open ./target/static/documentation/$(INDEX_FILE).html

generate:
	mvn -P generate-docs generate-resources

publish: --guard-USER --guard-TOKEN
	CONFLUENCE_USER=$(USER) CONFLUENCE_TOKEN=$(TOKEN) mvn -P generate-docs-and-publish generate-resources

docs: generate
	@echo
	@echo "***************************************************"
	@echo "*                                                 *"
	@echo "* Documentation can be found here:                *"
	@echo "* ./target/static/documentation/$(INDEX_FILE).html *"
	@echo "*                                                 *"
	@echo "***************************************************"
	@echo