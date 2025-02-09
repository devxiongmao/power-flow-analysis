.PHONY: install
install:
	gem install bundler
	bundle install

.PHONY: dev
dev:
	ruby app.rb

.PHONY: rubocop
rubocop:
	rubocop -A

.PHONY: determine-app-version
determine-app-version:
	ruby scripts/determine_app_version.rb

.PHONY: generate-changelog
generate-changelog:
	ruby scripts/generate_changelog.rb