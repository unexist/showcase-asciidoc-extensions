.DEFAULT_GOAL := docs
INDEX_FILE := versions.html

--guard-%:
	@if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set: $*=abc123 make $(MAKECMDGOALS)"; \
		exit 1; \
	fi

test:
	asciidoctor -r ../asciidoctor-helper-macros/src/main/resources/extensions/checkversion-inline-macro.rb \
		--trace -D . src/site/asciidoc/component-versions.adoc

open:
	open ./target/static/documentation/$(INDEX_FILE)

generate:
	mvn -P generate-docs generate-resources

publish: --guard-USER --guard-TOKEN
	CONFLUENCE_USER=$(USER) CONFLUENCE_TOKEN=$(TOKEN) mvn -P generate-docs-and-publish generate-resources

docs: generate
	@echo
	@echo "***********************************************"
	@echo "*                                             *"
	@echo "* Documentation can be found here:            *"
	@echo "* ./target/static/documentation/$(INDEX_FILE) *"
	@echo "*                                             *"
	@echo "***********************************************"
	@echo