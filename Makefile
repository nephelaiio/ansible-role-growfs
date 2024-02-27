.PHONY: all ${MAKECMDGOALS}

MOLECULE_SCENARIO ?= ubuntu
GALAXY_API_KEY ?=
GITHUB_REPOSITORY ?= $$(git config --get remote.origin.url | cut -d: -f 2 | cut -d. -f 1)
GITHUB_ORG = $$(echo ${GITHUB_REPOSITORY} | cut -d/ -f 1)
GITHUB_REPO = $$(echo ${GITHUB_REPOSITORY} | cut -d/ -f 2)
DEBIAN_DISTRO ?= current
DEBIAN_SHASUMS = https://mirror.cogentco.com/debian-cd/${DEBIAN_DISTRO}/amd64/iso-cd/SHA256SUMS
DEBIAN_MIRROR = $$(dirname ${DEBIAN_SHASUMS})
DEBIAN_BASENAME = $$(curl -s ${DEBIAN_SHASUMS} | grep "debian-[0-9]" | awk '{print $$2}')
DEBIAN_ISO=${DEBIAN_MIRROR}/${DEBIAN_BASENAME}
UBUNTU_DISTRO ?= jammy
UBUNTU_SHASUMS = https://releases.ubuntu.com/${UBUNTU_DISTRO}/SHA256SUMS
UBUNTU_MIRROR = $$(dirname ${UBUNTU_SHASUMS})
UBUNTU_BASENAME = $$(curl -s ${UBUNTU_SHASUMS} | grep "live-server-amd64" | awk '{print $$2}' | sed -e 's/\*//g')
UBUNTU_ISO=${UBUNTU_MIRROR}/${UBUNTU_BASENAME}
REQUIREMENTS = requirements.yml

ifeq (${MOLECULE_SCENARIO}, ubuntu)
MOLECULE_DISTRO=${UBUNTU_DISTRO}
MOLECULE_ISO=${UBUNTU_ISO}
else ifeq (${MOLECULE_SCENARIO}, debian)
MOLECULE_DISTRO=${DEBIAN_DISTRO}
MOLECULE_ISO=${DEBIAN_ISO}
endif

all: install version lint test

test: lint
	MOLECULE_DISTRO=${MOLECULE_DISTRO} \
	MOLECULE_ISO=${MOLECULE_ISO} \
	poetry run molecule $@ -s ${MOLECULE_SCENARIO}

install:
	@type poetry >/dev/null || pip3 install poetry
	@sudo apt-get install -y libvirt-dev
	@poetry install --no-root

lint: install
	poetry run yamllint .
	poetry run ansible-lint .

roles:
	[ -f ${REQUIREMENTS} ] && yq '.$@[] | .name' -r < ${REQUIREMENTS} \
		| xargs -L1 poetry run ansible-galaxy role install --force || exit 0

collections:
	[ -f ${REQUIREMENTS} ] && yq '.$@[]' -r < ${REQUIREMENTS} \
		| xargs -L1 echo poetry run ansible-galaxy -vvv collection install --force || exit 0

requirements: roles collections

dependency create prepare converge idempotence side-effect verify destroy login reset:
	MOLECULE_DISTRO=${MOLECULE_DISTRO} \
	MOLECULE_ISO=${MOLECULE_ISO} \
	poetry run molecule $@ -s ${MOLECULE_SCENARIO}

ignore:
	poetry run ansible-lint --generate-ignore

clean: destroy reset
	@poetry env remove $$(which python) >/dev/null 2>&1 || exit 0

publish:
	@echo publishing repository ${GITHUB_REPOSITORY}
	@echo GITHUB_ORGANIZATION=${GITHUB_ORG}
	@echo GITHUB_REPOSITORY=${GITHUB_REPO}
	@poetry run ansible-galaxy role import \
		--api-key ${GALAXY_API_KEY} ${GITHUB_ORG} ${GITHUB_REPO}

version:
	@poetry run molecule --version

debug: version
	sudo ufw status
	@poetry export --dev --without-hashes
