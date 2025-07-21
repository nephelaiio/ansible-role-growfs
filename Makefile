.PHONY: all ${MAKECMDGOALS}

MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MAKEFILE_DIR := $(dir $(MAKEFILE_PATH))

MOLECULE_SCENARIO ?= ubuntu
GALAXY_API_KEY ?=
GITHUB_REPOSITORY ?= $$(git config --get remote.origin.url | cut -d':' -f 2 | cut -d'.' -f 1)
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
COLLECTION_NAMESPACE = $$(yq -r '.namespace' < galaxy.yml)
COLLECTION_NAME = $$(yq -r '.name' < galaxy.yml)
COLLECTION_VERSION = $$(yq -r '.version' < galaxy.yml)
COLLECTION_PATH = $(MAKEFILE_DIR)
ROLE_PATH = $(MAKEFILE_DIR)/roles

LOGIN_ARGS ?=

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
	uv run molecule $@ -s ${MOLECULE_SCENARIO}

install:
	@uv sync
	@uv run ansible-galaxy collection install \
		--force --no-deps \
		.

lint: install
	uv run yamllint . -c .yamllint
	ANSIBLE_COLLECTIONS_PATH=$(COLLECTION_PATH) \
	ANSIBLE_ROLES_PATH=$(ROLE_PATH) \
	uv run ansible-lint .

ifeq (login,$(firstword $(MAKECMDGOALS)))
    LOGIN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
    $(eval $(subst $(space),,$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))):;@:)
endif

dependency create prepare converge idempotence side-effect verify destroy cleanup reset list login:
	rm -rf ansible_collections
	ANSIBLE_COLLECTIONS_PATH=$(COLLECTION_PATH) \
	ANSIBLE_ROLES_PATH=$(ROLE_PATH) \
	MOLECULE_DISTRO=${MOLECULE_DISTRO} \
	MOLECULE_ISO=${MOLECULE_ISO} \
	uv run dotenv molecule $@ -s ${MOLECULE_SCENARIO} ${LOGIN_ARGS}

ignore:
	uv run ansible-lint --generate-ignore

clean: destroy reset
	@uv env remove $$(which python) >/dev/null 2>&1 || exit 0

publish: build
	uv run ansible-galaxy collection publish --api-key ${GALAXY_API_KEY} \
		"${COLLECTION_NAMESPACE}-${COLLECTION_NAME}-${COLLECTION_VERSION}.tar.gz"

version:
	@uv run molecule --version

debug: version
	@uv export --all-packages --no-hashes
