# FoldForge `proto`

Source of truth for every cross-service contract in FoldForge:

- **gRPC** schemas for the four GPU sidecars (`rfdiffusion`, `proteinmpnn`,
  `boltz`, `af2`) and the `orchestrator`.
- **OpenAPI 3.1** spec for the public HTTP `gateway`.

This repo is intentionally **public** — open contracts build trust and let
collaborators integrate before any implementation is open-sourced.

## Layout

```
foldforge/
  common/v1/common.proto            shared types: ResourceSpec, Artifact, JobState, ...
  rfdiffusion/v1/rfdiffusion.proto  backbone generation
  proteinmpnn/v1/proteinmpnn.proto  inverse folding (sequence design)
  boltz/v1/boltz.proto              AF3-class complex prediction
  af2/v1/af2.proto                  AlphaFold2 + first-class MSA cache
  orchestrator/v1/orchestrator.proto  workflow DAG submission & streaming
openapi/
  gateway.v1.yaml                   public REST surface
```

## Design conventions

- Every long-running sidecar exposes a single server-streaming `Run` that emits
  `common.v1.ProgressEvent` heartbeats and terminates with a `RunResult` or
  `common.v1.ErrorDetail` (`RunUpdate` oneof).
- Large blobs (PDB/CIF/MSA) are passed **by reference** via `common.v1.Artifact`
  (R2 object), never inlined, except for tiny optional motif inputs.
- AF2 MSA generation is CPU-bound and dominates cost, so MSA caching is promoted
  to first-class API surface (`MsaCachePolicy`, `QueryMsaCache`).

## Consuming the contracts

### Rust (gateway, orchestrator)
Vendor this repo as a git submodule and compile with `tonic-build` in `build.rs`:

```rust
// build.rs
tonic_build::configure()
    .build_server(true)
    .build_client(true)
    .compile_protos(
        &["proto/foldforge/orchestrator/v1/orchestrator.proto"],
        &["proto"],
    )?;
```

### Python (sidecars)
Generate stubs with `grpcio-tools` (pinned in each sidecar) or `buf generate`:

```bash
python -m grpc_tools.protoc -I proto \
  --python_out=gen --grpc_python_out=gen --pyi_out=gen \
  proto/foldforge/af2/v1/af2.proto
```

## Local checks

```bash
make validate   # protoc compile check, no buf needed
make lint       # buf lint (requires buf)
make breaking   # buf breaking-change detection against main
```

## License
Apache-2.0
