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
-   2026-02-03 -- Consolidated into unified master specification

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
-   Deterministic normalization of design data
-   Integrated license-aware orchestration
-   A regularized mechanism for harvesting results
-   A structured mechanism for locating runs by experimental intent

PFXFlow addresses these problems through a unified configuration,
orchestration, execution, and harvesting framework composed of two major
subsystems: PFXCore and PFXStudy.

------------------------------------------------------------------------

### 1.2 System Definition

PFXFlow is composed of:

-   **PFXCore**\
    A headless execution kernel that validates, normalizes,
    materializes, executes, and harvests individual runs.

-   **PFXStudy**\
    A study-level orchestration and user interface layer (CLI + future
    GUI) that manages DOE workflows, scheduling, licensing, indexing,
    and aggregation.

The user-facing interface is exposed through:

    pfxflow <verb> [options]

Where `<verb>` includes `study`, `run`, `validate`, and related
commands.

------------------------------------------------------------------------

### 1.3 Goals

-   G1: Provide a single authoritative TOML-based configuration format.
-   G2: Implement PFXCore as a deterministic run compiler/executor.
-   G3: Generate fully reproducible run directories.
-   G4: Normalize all design and technology inputs.
-   G5: Support large-scale DOE execution.
-   G6: Centralize license management.
-   G7: Provide extensible Tcl hooks.
-   G8: Produce standardized run-level summaries.
-   G9: Enable automated study-level aggregation.
-   G10: Ensure strong schema validation.
-   G11: Enable structured search and retrieval of runs by intent.

------------------------------------------------------------------------

### 1.4 Non-Goals

-   NG1: Full GUI implementation in v1.
-   NG2: Replacement of Cadence tools.
-   NG3: Cloud-native deployment.
-   NG4: General-purpose optimization framework.
-   NG5: Runtime discovery of unmanaged files.

------------------------------------------------------------------------

### 1.5 Success Criteria

-   All runs are reproducible from frozen directories.
-   All inputs are enumerated and validated.
-   Studies of 100+ runs execute unattended.
-   License limits are respected.
-   Each run emits a machine-readable summary.
-   Aggregated datasets require no ad-hoc parsing.
-   Users can locate runs using semantic queries.

------------------------------------------------------------------------

## 2. Users, Use Cases & Workflows

### 2.1 Target Users

-   Physical design engineers
-   EDA researchers
-   CAD infrastructure developers
-   Methodology engineers

------------------------------------------------------------------------

### 2.2 Key Use Cases

#### UC1: DOE Execution (PFXStudy)

1.  User defines parameter sweep.
2.  Templates and overlays are selected.
3.  PFXStudy schedules jobs under license limits.
4.  PFXCore executes runs.
5.  Results are indexed and aggregated.

#### UC2: Single Run Debug (PFXCore)

1.  User invokes `pfxflow run`.
2.  Configuration is validated.
3.  Run is materialized and executed.
4.  Outputs and metadata are inspected.

#### UC3: Technology Evaluation

Multiple technology variants are evaluated through overlays and
harvested metrics.

#### UC4: Flow Customization

Users attach Tcl hooks at defined phases.

#### UC5: Run Discovery

Users query the study index to locate runs matching specific
experimental parameters.

------------------------------------------------------------------------

### 2.3 Example Scenarios

**Scenario: Large Parameter Sweep**\
A 400-point sweep is executed with automatic queuing based on Innovus
licenses. Runs are later filtered by clock, density, and library.

**Scenario: Failure Investigation**\
A historical run is located using semantic search and replayed locally.

**Scenario: Library Comparison**\
Multiple Vt libraries are compared using indexed QoR metrics.

------------------------------------------------------------------------

## 3. Architecture Overview

### 3.1 High-Level Structure

PFXFlow consists of:

-   PFXStudy (CLI/GUI)
-   PFXCore (Execution Kernel)
-   Execution Substrate (Make, Slurm, Cadence)

Interaction:

    User → PFXStudy → PFXCore → Tools → Summaries → Index → PFXStudy

------------------------------------------------------------------------

### 3.2 PFXStudy Components

-   Study Manager
-   Template Catalog
-   License Manager
-   Scheduler
-   Run Monitor
-   Index Manager
-   Aggregator
-   Dataset Exporter

------------------------------------------------------------------------

### 3.3 PFXCore Components

-   Config Composer
-   Validator
-   Design/Tech Normalizer
-   Run Materializer
-   Tool Wrappers
-   Tcl Drivers
-   Hook Executor
-   Harvester Framework

------------------------------------------------------------------------

### 3.4 Canonical Run Directory

    run_<id>/
      run.toml
      config.tcl
      env.sh
      resolved_inputs/
      hooks/
      logs/
      status/
      reports/
      results/
        run_summary.json
        run_summary.csv
      meta/
        run_intent.json
        provenance.json

------------------------------------------------------------------------

### 3.5 Interface Contract

#### Inputs to PFXCore

-   Template references
-   Overlay list
-   VARS dictionary
-   Run ID
-   Execution stages
-   Harvest profile

#### Outputs from PFXCore

-   Run directory
-   Status markers
-   Provenance
-   Input manifests
-   Run summaries
-   Run intent record

------------------------------------------------------------------------

### 3.6 Execution Pipeline

1.  Authorization (PFXStudy)
2.  Composition (PFXCore)
3.  Normalization
4.  Execution
5.  Harvesting
6.  Intent recording
7.  Indexing
8.  Aggregation

------------------------------------------------------------------------

### 3.7 License Management

PFXStudy manages:

-   License pools
-   Allocation
-   Concurrency limits
-   Retry policies

PFXCore assumes licenses are available.

------------------------------------------------------------------------

### 3.8 Results Harvesting

-   Run-level harvesting in PFXCore
-   Study-level aggregation in PFXStudy
-   Versioned metric sets
-   Extensible harvesters

------------------------------------------------------------------------

### 3.9 Run Indexing and Discovery

Each study maintains a persistent run index mapping semantic run
descriptors to run directories.

-   Supports structured queries over variables, technology, and status
-   Backed by SQLite, Parquet, or equivalent
-   Updated on run state transitions
-   Used by CLI and GUI search interfaces

------------------------------------------------------------------------

### 3.10 Extension Strategy

-   Backward-compatible schemas
-   Modular harvesters
-   New hook phases
-   Stable interfaces

------------------------------------------------------------------------

## 4. Data Model and Core Abstractions

### 4.1 Overview

This section defines the logical data objects used throughout PFXFlow.
All persistent artifacts are derived from these models.

------------------------------------------------------------------------

### 4.2 Study Model

  Field             Type     Description
  ----------------- -------- ------------------------
  study_id          string   Unique ID
  root_dir          path     Root directory
  variables         map      Sweep definitions
  runs              list     Run IDs
  license_profile   string   License policy
  status            enum     active/complete/failed

------------------------------------------------------------------------

### 4.3 Run Model

  Field      Type        Description
  ---------- ----------- -----------------------------
  run_id     string      Unique ID
  study_id   string      Parent
  run_dir    path        Location
  vars       map         DOE variables
  intent     RunIntent   Semantic descriptor
  status     enum        pending/running/done/failed

------------------------------------------------------------------------

### 4.4 RunIntent Model

Defines the semantic meaning of a run.

  Field       Type     Description
  ----------- -------- ------------------------
  vars        map      DOE variables
  tech_tags   map      Library/VT identifiers
  templates   list     Template lineage
  design_id   string   Design identifier
  user_tags   list     Optional annotations

Serialized as `meta/run_intent.json`.

------------------------------------------------------------------------

### 4.5 Configuration Model (CFG)

  Field        Type          Description
  ------------ ------------- -------------
  design       DesignSpec    RTL/SDC
  tech         TechSpec      Technology
  tools        ToolSpec      Tool params
  hooks        HookSpec      Hooks
  harvesting   HarvestSpec   Metrics
  metadata     map           User info

------------------------------------------------------------------------

### 4.6 DesignSpec

  Field          Type           Description
  -------------- -------------- -----------------------
  rtl_files      list\[path\]   RTL list
  rtl_type       enum           verilog/systemverilog
  include_dirs   list           Includes
  defines        list           Defines
  sdc_files      list           Constraints
  blackboxes     list           Abstract modules

------------------------------------------------------------------------

### 4.7 TechSpec

  Field           Type           Description
  --------------- -------------- -------------
  liberty_files   list\[path\]   Libraries
  tech_lef        path           Tech LEF
  cell_lefs       list\[path\]   Cell LEFs
  macro_lefs      list\[path\]   Macros
  rc_models       list\[path\]   RC data
  corners         list           MMMC

------------------------------------------------------------------------

### 4.8 ToolSpec

  Field       Type   Description
  ----------- ------ ----------------
  genus       map    Genus params
  innovus     map    Innovus params
  env         map    Env overrides
  resources   map    CPU/Mem hints

------------------------------------------------------------------------

### 4.9 HookSpec

  Field      Type           Description
  ---------- -------------- ---------------
  phase      string         Phase
  scripts    list\[path\]   Scripts
  on_error   enum           fail/continue

------------------------------------------------------------------------

### 4.10 HarvestSpec

  Field     Type     Description
  --------- -------- ----------------
  profile   string   Profile
  metrics   list     Metrics
  outputs   list     Formats
  version   string   Schema version

------------------------------------------------------------------------

### 4.11 Provenance Model

  Field               Type        Description
  ------------------- ----------- --------------
  config_hash         string      Config hash
  input_hashes        map         File hashes
  hook_hashes         map         Hook hashes
  tool_versions       map         Versions
  harvester_version   string      Harvester ID
  host                string      Host
  timestamp           timestamp   Time

------------------------------------------------------------------------

### 4.12 Study Index Model

Defines the persistent index used for run discovery.

  Field      Type     Description
  ---------- -------- -------------------
  run_id     string   Run ID
  study_id   string   Study
  clock_ps   number   Clock period
  density    number   Placement density
  lib        string   Library tag
  status     enum     Run status
  path       path     Run directory

Additional fields may be added as needed.

------------------------------------------------------------------------

### 4.13 Manifest Objects

-   Input Manifest
-   Run Summary Manifest
-   Study Summary Manifest

All are schema-validated and versioned.

------------------------------------------------------------------------

### 4.14 Representation Strategy

-   In-memory: Strongly typed C++ classes
-   On-disk: TOML, JSON, CSV, SQLite
-   All formats versioned

------------------------------------------------------------------------

### 4.15 Compatibility

-   Additive changes preferred
-   Deprecation supported
-   Migration tools required for breaking changes

------------------------------------------------------------------------

### 4.16 Implementation Mapping

  Layer      Objects
  ---------- ---------------------------------------------------
  PFXStudy   Study, Run, StudyIndex
  PFXCore    CFG, DesignSpec, TechSpec, HarvestSpec, RunIntent
  Tcl        CFG, VARS, PFX
  Make       Stage state
  Storage    Manifests, Index
