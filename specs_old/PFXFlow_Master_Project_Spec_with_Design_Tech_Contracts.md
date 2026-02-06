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
flows are embedded in large Design of Experiments (DOE) studies, where
hundreds or thousands of parameterized runs are generated
programmatically to explore timing, density, effort, library variants,
and other design variables.

Legacy flows also lack:

-   A standardized interface for RTL, constraint, and technology inputs
-   Deterministic normalization of design and technology data
-   Integrated license-aware orchestration
-   A regularized mechanism for harvesting results
-   A structured mechanism for locating runs by experimental intent
-   A consistent, meaningful directory structure reflecting DOE
    structure
-   A robust, explicit stage pipeline and artifact handoff contract

PFXFlow addresses these problems through a unified configuration,
orchestration, execution, harvesting, indexing, and pipeline framework
composed of two major subsystems: PFXCore and PFXStudy.

------------------------------------------------------------------------

### 1.2 System Definition

PFXFlow consists of:

-   **PFXCore** -- Headless execution kernel
-   **PFXStudy** -- DOE orchestration and UI layer

------------------------------------------------------------------------

### 1.3 Goals

-   Provide authoritative TOML configuration
-   Ensure reproducible runs
-   Normalize design and tech inputs
-   Support large DOE studies
-   Centralize license management
-   Enable extensible hooks
-   Produce standardized summaries
-   Maintain explicit pipelines

------------------------------------------------------------------------

### 1.4 Non-Goals

-   Full GUI in v1
-   Cloud deployment
-   Tool replacement

------------------------------------------------------------------------

### 1.5 Success Criteria

-   Deterministic pipelines
-   Auditable inputs
-   Reliable handoff
-   Queryable results

------------------------------------------------------------------------

## 2. Users, Use Cases & Workflows

### 2.1 Target Users

-   Physical design engineers
-   EDA researchers
-   CAD developers

------------------------------------------------------------------------

### 2.2 Key Use Cases

-   DOE execution
-   Run debugging
-   Technology evaluation
-   Flow customization
-   Run discovery

------------------------------------------------------------------------

## 3. Architecture Overview

### 3.1 High-Level Structure

User → PFXStudy → PFXCore → Wrappers → Tools → Artifacts → Harvest →
Index

------------------------------------------------------------------------

### 3.2 Components

#### PFXStudy

-   Study Manager
-   Scheduler
-   License Manager
-   Index Manager
-   Aggregator

#### PFXCore

-   Config Composer
-   Validator
-   Normalizer
-   Stage Runner
-   Wrappers
-   Harvester

------------------------------------------------------------------------

### 3.3 Canonical Study Structure

    <study>/
      study.toml
      pipeline.toml
      index/
      exports/
      runs/

------------------------------------------------------------------------

### 3.4 Canonical Run Structure

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

### 3.5 Leaf Run Flow and Pipeline Definition

(See previous pipeline.toml subsection; unchanged)

------------------------------------------------------------------------

### 3.6 Design Input Contract

This subsection defines how RTL and timing constraints are specified,
normalized, and materialized.

#### 3.6.1 User-Facing Design Specification

Defined in `request.toml` and templates:

``` toml
[design]
top = "top_module"
rtl_type = "systemverilog"
filelist = "rtl/files.f"
include_dirs = ["rtl/include"]
defines = ["SYNTH"]
sdc_files = ["constraints/top.sdc"]
blackboxes = ["mem_macro"]
```

#### 3.6.2 Normalization Rules

PFXCore SHALL:

-   Resolve all paths to absolute paths
-   Validate existence and readability
-   Enforce a single top module
-   Expand filelists and globs
-   Canonicalize include and define lists
-   Order SDC files deterministically

All resolved values are written to `run.toml`.

#### 3.6.3 Canonical Design Layout

Within `resolved_inputs/design/`:

    design/
      rtl/
        filelist.f
        src/
      constraints/
        merged.sdc
      config/
        design_resolved.json

#### 3.6.4 Design Manifest

`meta/inputs_manifest.json` SHALL include:

-   Original path
-   Resolved path
-   Size and timestamp
-   Optional hash

------------------------------------------------------------------------

### 3.7 Technology Input Contract

This subsection defines how technology data is specified and normalized.

#### 3.7.1 Technology Bundle Concept

All technology data SHALL be referenced through named bundles:

``` toml
[tech]
bundle = "GENERIC_ADV_NODE_V1"
corner = "tt"
```

Bundles are defined in a managed catalog external to studies.

#### 3.7.2 User-Facing Tech Specification

Example:

``` toml
[tech]
bundle = "GENERIC_ADV_NODE_V1"
lib_set = "stdcell_Z22"
rc_model = "default"
mmmc_profile = "base"
```

#### 3.7.3 Normalization Rules

PFXCore SHALL:

-   Expand bundles into explicit file sets
-   Validate all required files
-   Normalize units
-   Resolve corner definitions
-   Generate tool-compatible MMMC views

Resolved data is written to `run.toml`.

#### 3.7.4 Canonical Tech Layout

Within `resolved_inputs/tech/`:

    tech/
      lef/
      liberty/
      mmmc/
      rc/
      config/
        tech_resolved.json

#### 3.7.5 Technology Manifest

Included in `meta/inputs_manifest.json` alongside design data.

------------------------------------------------------------------------

### 3.8 Artifact Ownership Summary

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

## 4. Data Model and Core Abstractions

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

### 4.4 CFG

  Field        Type         Description
  ------------ ------------ -------------
  design       DesignSpec   Design
  tech         TechSpec     Tech
  tools        map          Tool params
  hooks        map          Hooks
  harvesting   map          Harvest

------------------------------------------------------------------------

### 4.5 Provenance

  Field           Type     Description
  --------------- -------- -------------
  config_hash     string   Hash
  tool_versions   map      Versions
  host            string   Host
  timestamp       time     Time

------------------------------------------------------------------------

### 4.6 Representation

-   C++ classes in memory
-   TOML/JSON/SQLite on disk
-   Versioned formats

------------------------------------------------------------------------

### 4.7 Compatibility

-   Additive changes preferred
-   Migration tools required
