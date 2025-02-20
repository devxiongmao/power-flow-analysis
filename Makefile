.PHONY: install
install:
	gem install bundler
	bundle install

.PHONY: dev
dev:
	ruby app.rb

.PHONY: test
test:
	rspec

.PHONY: rubocop
rubocop:
	rubocop -A

.PHONY: docker-build
docker-build:
	docker build -t power-flow-analysis-app .

.PHONY: docker-up
docker-up:
	docker compose up

.PHONY: determine-app-version
determine-app-version:
	ruby scripts/determine_app_version.rb

.PHONY: generate-changelog
generate-changelog:
	ruby scripts/generate_changelog.rb
