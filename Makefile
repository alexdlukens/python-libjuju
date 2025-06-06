BIN := .tox/py/bin
PY := $(BIN)/python3
PIP := $(BIN)/pip3
VERSION := $(shell python3 -c "from juju.version import CLIENT_VERSION; print(CLIENT_VERSION)")

.PHONY: clean
clean:
	find . -name __pycache__ -type d -exec rm -r {} +
	find . -name *.pyc -delete
	rm -rf .tox
	rm -rf build dist docs/_build/

.PHONY: client
client:
	tox -r --notest -e py3
	$(PY) -m juju.client.facade -s "juju/client/schemas*" -o juju/client/
	pre-commit run --files $(shell echo juju/client/_[cd]*.py)

.PHONY: run-unit-tests
run-unit-tests:
	uvx tox -e unit

.PHONY: run-integration-tests
run-integration-tests:
	uvx tox -e integration

.PHONY: run-all-tests
test: run-unit-tests run-integration-tests

.PHONY: docs
docs:
	uvx tox -e docs

.PHONY: build-test
build-test:
	rm -rf venv
	uv build
	python3 -m venv venv
	. venv/bin/activate
	pip install dist/juju-${VERSION}-py3-none-any.whl
	python3 -c "from juju.controller import Controller"
	rm dist/*.tar.gz dist/*.whl

.PHONY: release
release:
	git fetch --tags
	rm dist/*.tar.gz dist/*.whl || true
	uv build
	uvx twine check dist/*
	uvx twine upload --repository juju dist/*
	git tag ${VERSION}
	git push --tags

.PHONY: upload
upload: release

.PHONY: tox-install
tox-install:
	tox

.PHONY: install-deb-build-deps
install-deb-build-deps:
	sudo apt install -y python3-all debhelper sbuild schroot ubuntu-dev-tools dh-python devscripts equivs

.PHONY: build-deb
build-deb: install-deb-build-deps
	rm -rf deb_dist
	dpkg-buildpackage -us -uc -S -jauto
	mkdir -p deb_dist
	mv ../*.dsc ../*.tar.* ../*.changes ../*.buildinfo deb_dist/

.PHONY: sign-deb
sign-deb: build-deb
	debsign -k $(GPG_KEY_ID) ./deb_dist/python-libjuju_*source.changes

.PHONY: upload-deb
upload-deb: sign-deb
	dput ppa:alexdlukens/python-libjuju ./deb_dist/python-libjuju_*source.changes
