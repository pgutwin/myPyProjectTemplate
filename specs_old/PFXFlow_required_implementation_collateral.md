# PFXFlow Required Implementation Collateral

This document lists the canonical example files and directory structures
required to support initial PFXCore implementation and validation.

These files serve as reference inputs for development, testing, and
debugging.

------------------------------------------------------------------------

## 1. Example pipeline.toml (Minimal)

Purpose: Demonstrates the smallest valid pipeline definition.

Contents: - Two stages (synth → place) - Required fields only - Explicit
exec.argv - Explicit outputs - Stage-local logging

File: examples/pipeline_minimal.toml

------------------------------------------------------------------------

## 2. Example pipeline.toml (Full Production Flow)

Purpose: Demonstrates a realistic multi-stage EDA flow.

Contents: - synth → init → place → cts → route → harvest - Concrete tool
invocations - Consistent output conventions - Primary log definitions

File: examples/pipeline_full.toml

------------------------------------------------------------------------

## 3. Example run.toml (DOE Leaf Instance)

Purpose: Defines a complete DOE leaf run configuration.

Contents: - \[run\] metadata - \[doe\] axis values - \[design\] inputs -
\[technology\] references - Tool-specific configuration tables

File: examples/run_example.toml

------------------------------------------------------------------------

## 4. Example Tcl Control Scripts

Purpose: Demonstrate how tool control files consume PFX variables.

Required Files: - scripts/synth.tcl - scripts/init.tcl -
scripts/place.tcl

Contents: - source of pfx_vars.tcl - Variable usage examples - Explicit
error handling - Deterministic exit behavior

Directory: examples/scripts/

------------------------------------------------------------------------

## 5. Example Generated pfx_vars.tcl

Purpose: Defines the canonical variable mapping contract.

Contents: - Integer, float, boolean variables - Strings with special
characters - Arrays/lists - Nested table flattening

File: examples/generated/pfx_vars.tcl

------------------------------------------------------------------------

## 6. Example Generated stage_launch.sh

Purpose: Demonstrates correct stage execution wrapper behavior.

Contents: - Strict shell mode (set -euo pipefail) - Directory handling -
Environment sourcing - Log redirection - Exit code propagation

File: examples/generated/stage_launch.sh

------------------------------------------------------------------------

## 7. Example status.json (Success Case)

Purpose: Defines the required completion metadata for a successful
stage.

Contents: - Stage metadata - Timestamps - Exit code - Output validation
status - Log reference

File: examples/status_success.json

------------------------------------------------------------------------

## 8. Example status.json (Failure Case)

Purpose: Demonstrates failure reporting semantics.

Contents: - Non-zero exit code - success=false - Partial outputs - Error
indicators

File: examples/status_failure.json

------------------------------------------------------------------------

## 9. Example Run Directory Layout

Purpose: Illustrates the canonical on-disk layout of a completed run.

Contents:

run_0007/ pipeline.toml run.toml env.sh scripts/ synth.tcl place.tcl
stages/ 10_synth/ stage_launch.sh pfx_vars.tcl synth.log outputs/
netlist.v status.json 20_place/ stage_launch.sh pfx_vars.tcl place.log
outputs/ design_placed.enc status.json

File: examples/run_tree.txt

------------------------------------------------------------------------

## 10. Example env.sh

Purpose: Defines environment setup shared across all stages.

Contents: - License variables - Tool paths - Runtime configuration

File: examples/env.sh

------------------------------------------------------------------------

## 11. Validation Test Set

Purpose: Supports automated testing of PFXCore.

Contents: - Valid pipeline/run pairs - Invalid schema cases - Missing
outputs - Cyclic dependencies - Resume behavior tests

Directory: tests/validation/

------------------------------------------------------------------------

## 12. Reference README

Purpose: Documents how the collateral is used in development.

Contents: - Build instructions - Example invocations - Debug workflows -
Common failure modes

File: examples/README.md

------------------------------------------------------------------------

## 13. Version Control Policy

All collateral files SHALL be version-controlled alongside the PFXCore
source to ensure reproducibility and regression tracking.

------------------------------------------------------------------------

End of Document
