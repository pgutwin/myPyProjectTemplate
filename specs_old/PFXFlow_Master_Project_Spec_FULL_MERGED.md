# Project: PFXFlow

## 0. Meta & Status

-   Owner: Paul Gutwin
-   Document Status: Draft (Master Specification)
-   Last Updated: 2026-02-03

### Change Log

-   2026-02-02 -- Initial draft
-   2026-02-02 -- Added DOE framing and hooks
-   2026-02-03 -- Added PFXCore / PFXStudy split
-   2026-02-03 -- Added harvesting framework
-   2026-02-03 -- Added run intent and indexing
-   2026-02-03 -- Added semantic DOE layout
-   2026-02-03 -- Added directory ownership model
-   2026-02-03 -- Added pipeline.toml stage framework
-   2026-02-03 -- Added design/tech contracts
-   2026-02-03 -- Tightened filelist and tech bundle definitions

------------------------------------------------------------------------

## 1. Project Overview

### 1.1 Problem Statement

Modern commercial EDA flows based on Cadence Genus and Innovus rely on
layered configuration involving shell scripts, Makefiles, tool wrappers,
and Tcl. Configuration is fragmented across environment variables and
ad-hoc scripts, resulting in fragile, irreproducible infrastructure.

These flows are embedded in large Design of Experiments (DOE) studies
requiring deterministic execution, indexing, harvesting, and
reproducibility.

PFXFlow addresses these problems through a unified orchestration,
execution, and data-management framework.

------------------------------------------------------------------------

### 1.2 System Definition

PFXFlow consists of:

-   PFXCore: Run execution and normalization kernel
-   PFXStudy: DOE orchestration and UI layer

User interface:

    pfxflow <verb> [options]

------------------------------------------------------------------------

### 1.3 Goals

-   Unified TOML configuration
-   Reproducible run capsules
-   Normalized design/tech inputs
-   Scalable DOE execution
-   License-aware scheduling
-   Extensible hooks
-   Standardized summaries
-   Deterministic pipelines
-   Queryable results
-   Semantic directory layouts

------------------------------------------------------------------------

### 1.4 Non-Goals

-   Full GUI in v1
-   Tool replacement
-   Cloud deployment

------------------------------------------------------------------------

### 1.5 Success Criteria

-   Fully reproducible runs
-   Auditable provenance
-   Deterministic pipelines
-   Stable artifact handoff
-   Structured discovery

------------------------------------------------------------------------

## 2. Users, Use Cases & Workflows

### 2.1 Target Users

-   Physical design engineers
-   EDA researchers
-   CAD infrastructure developers

------------------------------------------------------------------------

### 2.2 Use Cases

#### DOE Execution

1.  Define sweep
2.  Generate layout
3.  Allocate runs
4.  Schedule jobs
5.  Execute pipelines
6.  Harvest results
7.  Aggregate data

#### Debugging

-   Locate run
-   Re-run stages
-   Inspect artifacts

#### Technology Evaluation

-   Compare bundles
-   Analyze QoR

------------------------------------------------------------------------

## 3. Architecture Overview

### 3.1 System Structure

User → PFXStudy → PFXCore → Wrappers → Tools → Artifacts → Harvest →
Index

------------------------------------------------------------------------

### 3.2 Components

#### PFXStudy

-   Study Manager
-   Scheduler
-   License Manager
-   Layout Manager
-   Index Manager
-   Aggregator
-   Exporter

#### PFXCore

-   Config Composer
-   Validator
-   Normalizer
-   Stage Runner
-   Tool Wrappers
-   Tcl Drivers
-   Hook Manager
-   Harvester

------------------------------------------------------------------------

### 3.3 Study Directory Layout

    <study>/
      study.toml
      pipeline.toml
      index/
        runs.sqlite
      logs/
      exports/
      templates/
      runs/

------------------------------------------------------------------------

### 3.4 Run Directory Layout

    rNNN/
      request.toml
      run.toml
      env.sh
      config/
      resolved_inputs/
      stages/
      current/
      results/
      meta/

------------------------------------------------------------------------

### 3.5 Artifact Ownership

  Artifact          Owner      Purpose
  ----------------- ---------- ------------------
  study.toml        PFXStudy   Study definition
  pipeline.toml     PFXStudy   Pipeline
  request.toml      PFXStudy   Run request
  run.toml          PFXCore    Frozen config
  env.sh            PFXCore    Environment
  resolved_inputs   PFXCore    Inputs
  stages            PFXCore    Stage data
  index             PFXStudy   Discovery

------------------------------------------------------------------------

### 3.6 Leaf Run Pipeline

Runs execute as DAGs defined in pipeline.toml. Stages have explicit
dependencies, inputs, and outputs.

#### Stage Principles

-   Isolated directories
-   Canonical handoff via current/
-   Deterministic execution
-   Status tracking

------------------------------------------------------------------------

### 3.7 pipeline.toml Framework

Pipeline definitions reside in:

-   Default: PFXCore share
-   Override: study root

Example:

``` toml
version = "1.0"

[pipeline]
name = "cadence_v1"
default_target = "harvest"

[wrappers]
genus = "pfx_genus_run"
innovus = "pfx_innovus_run"
harvest = "pfx_harvest_run"

[[stage]]
name = "synth"
order = 10
wrapper = "genus"
depends_on = []
exports = ["current/netlist.v=stages/10_synth/outputs/design.v"]
```

(Full example omitted here for brevity; see appendix.)

------------------------------------------------------------------------

### 3.8 Stage Runner Semantics

-   Enforces dependencies
-   Checks inputs/outputs
-   Records status.json
-   Supports --force

------------------------------------------------------------------------

### 3.9 Status Files

Each stage emits status.json with:

-   timestamps
-   exit code
-   success flag
-   logs
-   versions

------------------------------------------------------------------------

### 3.10 Harvesting

-   Run-level: PFXCore
-   Study-level: PFXStudy
-   Profiles define metrics

------------------------------------------------------------------------

### 3.11 Run Index

Persistent mapping:

run_id ↔ intent ↔ path ↔ status

------------------------------------------------------------------------

### 3.12 License Management

-   Centralized pools
-   Concurrency control
-   Retry logic

------------------------------------------------------------------------

## 4. Design Input Contract

### 4.1 User Specification

``` toml
[design]
top = "top"
rtl_type = "systemverilog"
filelist = "rtl/files.f"
include_dirs = ["rtl/include"]
defines = ["SYNTH"]
sdc_files = ["constraints/top.sdc"]
```

------------------------------------------------------------------------

### 4.2 Filelist Semantics

Supports:

-   +incdir+
-   +define+
-   -f nesting

Relative paths resolved to filelist directory.

------------------------------------------------------------------------

### 4.3 Normalization

PFXCore:

-   Expands -f
-   Injects include_dirs/defines
-   Absolutizes paths
-   Writes resolved filelist

------------------------------------------------------------------------

### 4.4 Canonical Layout

    resolved_inputs/design/
      rtl/filelist.f
      constraints/merged.sdc
      config/design_resolved.json

------------------------------------------------------------------------

## 5. Technology Input Contract

### 5.1 Bundle Reference

``` toml
[tech]
bundle = "GENERIC_ADV_NODE_V1"
corner = "tt"
```

------------------------------------------------------------------------

### 5.2 Bundle Schema

Bundles stored in catalog.

``` toml
[bundle]
name = "GENERIC_ADV_NODE_V1"

[timing]
liberty = ["lib/tt.lib"]

[physical]
cell_lef = ["lef/cells.lef"]
tech_lef = "lef/tech.lef"

[routing]
cadence_tech = "route/tech.lef"
synopsys_tf = "route/tech.tf"

[extraction]
qrc_tech = "pex/qrcTech.tch"

[mmmc]
views = "mmmc/views.tcl"
```

------------------------------------------------------------------------

### 5.3 Normalization

-   Validate files
-   Normalize units
-   Generate MMMC
-   Populate resolved_inputs/tech

------------------------------------------------------------------------

### 5.4 Canonical Layout

    resolved_inputs/tech/
      liberty/
      lef/
      route/
      pex/
      mmmc/
      config/tech_resolved.json

------------------------------------------------------------------------

## 6. Data Model

### 6.1 Study

  Field      Type     Description
  ---------- -------- -------------
  study_id   string   ID
  root_dir   path     Root
  layout     map      Layout
  status     enum     State

------------------------------------------------------------------------

### 6.2 Run

  Field     Type     Description
  --------- -------- -------------
  run_id    string   ID
  run_dir   path     Path
  vars      map      Params
  status    enum     State

------------------------------------------------------------------------

### 6.3 RunIntent

  Field       Type     Description
  ----------- -------- -------------
  vars        map      DOE vars
  tech_tags   map      Tech IDs
  design_id   string   Design
  templates   list     Lineage

------------------------------------------------------------------------

### 6.4 Provenance

  Field           Type     Description
  --------------- -------- -------------
  config_hash     string   Hash
  tool_versions   map      Versions
  host            string   Host
  timestamp       time     Time

------------------------------------------------------------------------

## 7. Compatibility & Evolution

-   Additive changes preferred
-   Schema versioning required
-   Migration tools mandatory

------------------------------------------------------------------------

## Appendix A: Default Pipeline Example

(Full pipeline.toml example to be included here in future revision.)
