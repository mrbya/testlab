.POSIX:
.PHONY: *
.EXPORT_ALL_VARIABLES:

env ?= prod

KUBECONFIG = $(shell pwd)/metal/kubeconfig-${env}.yaml
KUBE_CONFIG_PATH = $(KUBECONFIG)

ifeq ($(env), dev)
default: metal bootstrap smoke-test post-install clean
else
default: metal system external smoke-test post-install clean
endif

configure:
	./scripts/configure
	git status

metal:
	make -C metal env=${env}

bootstrap:
	make -C bootstrap env=${env}

external:
	make -C external

smoke-test:
	make -C test filter=Smoke

post-install:
	@./scripts/hacks

tools:
	@docker run \
		--rm \
		--interactive \
		--tty \
		--network host \
		--env "KUBECONFIG=${KUBECONFIG}" \
		--volume "/var/run/docker.sock:/var/run/docker.sock" \
		--volume $(shell pwd):$(shell pwd) \
		--volume ${HOME}/.ssh:/root/.ssh \
		--volume ${HOME}/.terraform.d:/root/.terraform.d \
		--volume homelab-tools-cache:/root/.cache \
		--volume homelab-tools-nix:/nix \
		--workdir $(shell pwd) \
		docker.io/nixos/nix nix --experimental-features 'nix-command flakes' develop

test:
	make -C test

clean:
	docker compose --project-directory ./metal/roles/pxe_server/files down

docs:
	mkdocs serve

git-hooks:
	pre-commit install
