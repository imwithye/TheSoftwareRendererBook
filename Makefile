build:
	rm -rf docs/
	jupyter-book build .
	mkdir -p docs/
	cp -r _build/html/* docs/

.PHONY: build
