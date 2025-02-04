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
