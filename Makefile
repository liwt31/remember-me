.PHONY: format, publish, build, test

format:
	black .

build:
	rm -rf dist/
	python setup.py sdist

publish: build
	twine upload -s dist/*

test:
	pytest
