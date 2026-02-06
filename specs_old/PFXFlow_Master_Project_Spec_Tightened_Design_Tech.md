# Project: PFXFlow

## 0. Meta & Status

-   **Owner:** Paul Gutwin
-   **Doc status:** Draft (Master Specification)
-   **Last updated:** 2026-02-03

### Change Log

-   2026-02-02 -- Initial draft
-   2026-02-02 -- Added DOE framing, hooks, and architecture
-   2026-02-03 -- Added PFXCore / PFXStudy split and license management
-   2026-02-03 -- Added harvesting framework
-   2026-02-03 -- Added data model
-   2026-02-03 -- Added run intent and study indexing model
-   2026-02-03 -- Added semantic DOE directory layout model
-   2026-02-03 -- Added explicit study/run directory ownership model
-   2026-02-03 -- Added pipeline.toml stage definition and leaf-run flow
    subsection
-   2026-02-03 -- Added formal Design and Technology interface contracts
-   2026-02-03 -- Tightened filelist semantics and technology bundle
    schema

------------------------------------------------------------------------

## 1. Project Overview

### 1.1 Problem Statement

Modern commercial EDA flows based on Cadence Genus and Innovus require
complex, multi-layer configuration spanning shell scripts, Makefiles,
tool launch wrappers, and Tcl runtime setup. In legacy environments,
configuration data is fragmented across environment variables, ad-hoc
shell logic, embedded Tcl scripts, and Makefile rules. Over time, this
leads to brittle, non-reproducible, and difficult-to-maintain
infrastructure.

In contemporary research and advanced methodology development, these
flows are embedded in large Design of Experiments (DOE) studies.

PFXFlow addresses these problems through a unified configuration,
orchestration, execution, harvesting, indexing, and pipeline framework.

------------------------------------------------------------------------

## 2. Users, Use Cases & Workflows

### 2.1 Target Users

-   Physical design engineers
-   EDA researchers
-   CAD developers

------------------------------------------------------------------------

## 3. Architecture Overview

### 3.1 High-Level Structure

User → PFXStudy → PFXCore → Wrappers → Tools → Artifacts → Harvest →
Index

------------------------------------------------------------------------

### 3.2 Canonical Study Structure

    <study>/
      study.toml
      pipeline.toml
      index/
      exports/
      runs/

------------------------------------------------------------------------

### 3.3 Canonical Run Structure

    rNNN/
      request.toml
      run.toml
      env.sh
      resolved_inputs/
      stages/
      current/
      results/
      meta/

------------------------------------------------------------------------

### 3.4 Design Input Contract

#### 3.4.1 User-Facing Design Specification

Example in `request.toml`:

``` toml
[design]
top = "top_module"
rtl_type = "systemverilog"
filelist = "rtl/files.f"
include_dirs = ["rtl/include", "rtl/ip/include"]
defines = ["SYNTH", "FAST_MEM"]
sdc_files = ["constraints/top.sdc"]
blackboxes = ["mem_macro"]
```

#### 3.4.2 Filelist Semantics

The filelist SHALL follow standard EDA conventions:

-   Source file paths
-   `+incdir+<path>` include directives
-   `+define+<macro>` preprocessor definitions
-   `-f <other.f>` nested filelists

Example `files.f`:

    +incdir+rtl/include
    +define+USE_IP

    -f common.f

    rtl/top.sv
    rtl/core.sv

Relative paths are resolved relative to the filelist location.

#### 3.4.3 Normalization Rules

PFXCore SHALL:

1.  Expand nested `-f` directives.
2.  Resolve all paths to absolute paths.
3.  Prepend generated `+incdir` and `+define` directives from TOML.
4.  Validate top module.
5.  Order entries deterministically.
6.  Write canonical filelist to:

```{=html}
<!-- -->
```
    resolved_inputs/design/rtl/filelist.f

All tools SHALL consume only the resolved filelist.

#### 3.4.4 Canonical Design Layout

    resolved_inputs/design/
      rtl/
        filelist.f
        src/
      constraints/
        merged.sdc
      config/
        design_resolved.json

------------------------------------------------------------------------

### 3.5 Technology Input Contract

#### 3.5.1 Technology Bundle Concept

All technology data SHALL be referenced through named bundles.

Example:

``` toml
[tech]
bundle = "GENERIC_ADV_NODE_V1"
corner = "tt"
```

Bundles are defined in a managed catalog.

#### 3.5.2 Bundle Definition Schema

Bundle definitions are stored in:

    $PFX_TECH_CATALOG/bundles/<name>.toml

Example bundle:

``` toml
[bundle]
name = "GENERIC_ADV_NODE_V1"
version = "2026Q1"

[timing]
liberty = ["lib/ss.lib", "lib/tt.lib", "lib/ff.lib"]

[physical]
cell_lef  = ["lef/cells.lef"]
macro_lef = ["lef/macros.lef"]
tech_lef  = "lef/tech.lef"

[routing]
cadence_tech = "route/tech.lef"
synopsys_tf  = "route/tech.tf"

[extraction]
qrc_tech   = "pex/qrcTech.tch"
starrc_tech = "pex/starrc.tch"

[mmmc]
views = "mmmc/views.tcl"

[metadata]
units = "ps/um"
process = "anonymous"
```

#### 3.5.3 Normalization Rules

PFXCore SHALL:

1.  Load bundle definition.
2.  Resolve all referenced files.
3.  Validate required components.
4.  Normalize units.
5.  Generate tool-compatible views.
6.  Populate resolved directories.

#### 3.5.4 Canonical Technology Layout

    resolved_inputs/tech/
      liberty/
      lef/
      route/
      pex/
      mmmc/
      config/
        tech_resolved.json

------------------------------------------------------------------------

### 3.6 Artifact Ownership Summary

  Artifact          Owner      Purpose
  ----------------- ---------- -------------------
  study.toml        PFXStudy   Study definition
  pipeline.toml     PFXStudy   Pipeline DAG
  request.toml      PFXStudy   Run intent
  run.toml          PFXCore    Frozen config
  resolved_inputs   PFXCore    Normalized inputs
  stages            PFXCore    Stage artifacts
  current           PFXCore    Handoff
  results           PFXCore    Summaries
  index             PFXStudy   Discovery

------------------------------------------------------------------------

## 4. Data Model

### 4.1 Study

  Field      Type     Description
  ---------- -------- -------------
  study_id   string   Unique ID
  root_dir   path     Root
  layout     map      DOE layout
  status     enum     State

------------------------------------------------------------------------

### 4.2 Run

  Field     Type     Description
  --------- -------- -------------
  run_id    string   Unique ID
  run_dir   path     Location
  vars      map      DOE vars
  status    enum     State

------------------------------------------------------------------------

### 4.3 RunIntent

  Field       Type     Description
  ----------- -------- -------------
  vars        map      Parameters
  tech_tags   map      Tech IDs
  design_id   string   Design
  templates   list     Lineage

------------------------------------------------------------------------

### 4.4 Provenance

  Field           Type     Description
  --------------- -------- -------------
  config_hash     string   Hash
  tool_versions   map      Versions
  host            string   Host
  timestamp       time     Time
