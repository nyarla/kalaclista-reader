all:
	@echo hi,

up: build
	env DOCKER_BUILDKIT=1 flyctl deploy -a kalaclista-reader --local-only --image-label latest

build:
	nix eval --json --file src/h2o.nix >runtime/h2o.json
	nix eval --json --file src/litestream.nix >runtime/litestream.json
	env DOCKER_BUILDKIT=1 docker build -t kalaclista-reader $(EXTRA_FLAGS) .

rebuild:
	@$(MAKE) EXTRA_FLAGS="--no-cache" build

test: build
	docker run --rm --env-file .env.test -it --mount type=bind,source="$(shell pwd)/data",target=/data -p 127.0.0.1:8080:8080 kalaclista-reader

shell: build
	docker run --rm --env-file .env.test -it --mount type=bind,source="$(shell pwd)/data",target=/data -p 127.0.0.1:8080:8080 --entrypoint /bin/sh kalaclista-reader
