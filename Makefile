.PHONY: lint format breaking gen validate clean

# Pure-protoc compile check (no buf required).
validate:
	@protoc -I . --descriptor_set_out=/dev/null $$(find foldforge -name '*.proto')
	@echo "OK: all protos compile"

lint:
	buf lint

format:
	buf format -w

breaking:
	buf breaking --against 'https://github.com/FoldForge/proto.git#branch=main'

gen:
	buf generate

clean:
	rm -rf gen
