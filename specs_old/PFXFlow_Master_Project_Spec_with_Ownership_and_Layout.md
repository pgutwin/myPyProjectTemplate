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
-   A consistent, meaningful directory structure reflecting DOE
    structure

PFXFlow addresses these problems through a unified configuration,
orchestration, execution, harvesting, and indexing framework composed of
two major subsystems: PFXCore and PFXStudy.

------------------------------------------------------------------------

### 1.2 System Definition

PFXFlow is composed of:

-   **PFXCore**\
    A headless execution kernel that validates, normalizes,
    materializes, executes, and harvests individual runs.

-   **PFXStudy**\
    A study-level orchestration and user interface layer (CLI + future
    GUI) that manages DOE workflows, directory layout, scheduling,
    licensing, indexing, and aggregation.

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
-   G12: Provide deterministic, human-readable DOE directory
    hierarchies.

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
-   Users can locate runs using semantic paths and queries.

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
2.  Study layout policy is defined.
3.  PFXStudy creates study directory structure.
4.  Templates and overlays are selected.
5.  PFXStudy schedules jobs under license limits.
6.  PFXCore executes runs.
7.  Results are indexed and aggregated.

#### UC2: Single Run Debug (PFXCore)

1.  User locates run via path or query.
2.  User invokes `pfxflow run`.
3.  Configuration is validated.
4.  Run is materialized and executed.
5.  Outputs and metadata are inspected.

#### UC3: Technology Evaluation

Multiple technology variants are evaluated through overlays and
harvested metrics.

#### UC4: Flow Customization

Users attach Tcl hooks at defined phases.

#### UC5: Run Discovery

Users browse directory hierarchies or query the study index.

------------------------------------------------------------------------

### 2.3 Example Scenarios

**Scenario: Density Sweep**

    den_sweep/
      runs/
        density=0p50/
        density=0p55/
        density=0p60/
        density=0p65/
        density=0p70/

**Scenario: Clock and Density Sweep**

    clk_den_sweep/
      runs/
        clock_ps=100ps/
          density=0p50/
          density=0p55/
        clock_ps=150ps/
          density=0p50/

**Scenario: Repeat Runs**

    density=0p50/
      r001/
      r002/

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
-   Layout Manager
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

### 3.4 Canonical Study Directory Structure

The study root directory is created and owned by PFXStudy.

    <study_name>/
      study.toml
      index/
        runs.sqlite
      logs/
      exports/
      templates/
      runs/
        <semantic DOE hierarchy>/

Responsibilities:

-   PFXStudy creates and manages this structure.
-   PFXCore does not modify study-level metadata.

------------------------------------------------------------------------

### 3.5 Canonical Run Directory Structure

Run directories are allocated by PFXStudy and populated by PFXCore.

    <study_name>/runs/<semantic path>/rNNN/
      request.toml
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
        run_id.txt
        run_intent.json
        provenance.json
        inputs_manifest.json

------------------------------------------------------------------------

### 3.6 Artifact Ownership Model

  Artifact           Created By   Purpose
  ------------------ ------------ -----------------------------
  study.toml         PFXStudy     Study definition and layout
  request.toml       PFXStudy     Run request
  run.toml           PFXCore      Frozen resolved config
  config.tcl         PFXCore      Tool driver
  env.sh             PFXCore      Environment setup
  run_summary.json   PFXCore      Harvested metrics
  runs.sqlite        PFXStudy     Run index
  provenance.json    PFXCore      Reproducibility data

------------------------------------------------------------------------

### 3.7 Interface Contract

#### Inputs to PFXCore

-   Target run directory
-   request.toml
-   Template references
-   Overlay list
-   VARS dictionary
-   Execution stages
-   Harvest profile

#### Outputs from PFXCore

-   Populated run directory
-   Status markers
-   Provenance
-   Input manifests
-   Run summaries
-   Run intent record

------------------------------------------------------------------------

### 3.8 Execution Pipeline

1.  Study creation (PFXStudy)
2.  DOE path allocation (PFXStudy)
3.  Run slot allocation (PFXStudy)
4.  Composition (PFXCore)
5.  Normalization
6.  Execution
7.  Harvesting
8.  Intent recording
9.  Indexing
10. Aggregation

------------------------------------------------------------------------

### 3.9 License Management

PFXStudy manages:

-   License pools
-   Allocation
-   Concurrency limits
-   Retry policies

PFXCore assumes licenses are available.

------------------------------------------------------------------------

### 3.10 Results Harvesting

-   Run-level harvesting in PFXCore
-   Study-level aggregation in PFXStudy
-   Versioned metric sets
-   Extensible harvesters

------------------------------------------------------------------------

### 3.11 Run Indexing and Discovery

Each study maintains a persistent run index mapping:

    run_id ↔ run_intent ↔ filesystem path

-   Supports structured queries
-   Updated on state transitions
-   Used by CLI and GUI

------------------------------------------------------------------------

### 3.12 Extension Strategy

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

  Field             Type          Description
  ----------------- ------------- ------------------------
  study_id          string        Unique ID
  root_dir          path          Root directory
  variables         map           Sweep definitions
  layout            StudyLayout   Directory policy
  runs              list          Run IDs
  license_profile   string        License policy
  status            enum          active/complete/failed

------------------------------------------------------------------------

### 4.3 StudyLayout Model

  Field            Type             Description
  ---------------- ---------------- --------------------
  path_variables   list\[string\]   Variables in path
  formatters       map              Value format rules
  base_dir         string           Root name
  repeat_policy    enum             suffix/timestamp

------------------------------------------------------------------------

### 4.4 Run Model

  Field      Type        Description
  ---------- ----------- -----------------------------
  run_id     string      Unique ID
  study_id   string      Parent
  run_dir    path        Location
  vars       map         DOE variables
  intent     RunIntent   Semantic descriptor
  status     enum        pending/running/done/failed

------------------------------------------------------------------------

### 4.5 RunIntent Model

  Field       Type     Description
  ----------- -------- ------------------------
  vars        map      DOE variables
  tech_tags   map      Library/VT identifiers
  templates   list     Template lineage
  design_id   string   Design identifier
  user_tags   list     Optional annotations

Serialized as `meta/run_intent.json`.

------------------------------------------------------------------------

### 4.6 Configuration Model (CFG)

  Field        Type          Description
  ------------ ------------- -------------
  design       DesignSpec    RTL/SDC
  tech         TechSpec      Technology
  tools        ToolSpec      Tool params
  hooks        HookSpec      Hooks
  harvesting   HarvestSpec   Metrics
  metadata     map           User info

------------------------------------------------------------------------

### 4.7 DesignSpec

  Field          Type           Description
  -------------- -------------- -----------------------
  rtl_files      list\[path\]   RTL list
  rtl_type       enum           verilog/systemverilog
  include_dirs   list           Includes
  defines        list           Defines
  sdc_files      list           Constraints
  blackboxes     list           Abstract modules

------------------------------------------------------------------------

### 4.8 TechSpec

  Field           Type           Description
  --------------- -------------- -------------
  liberty_files   list\[path\]   Libraries
  tech_lef        path           Tech LEF
  cell_lefs       list\[path\]   Cell LEFs
  macro_lefs      list\[path\]   Macros
  rc_models       list\[path\]   RC data
  corners         list           MMMC

------------------------------------------------------------------------

### 4.9 ToolSpec

  Field       Type   Description
  ----------- ------ ----------------
  genus       map    Genus params
  innovus     map    Innovus params
  env         map    Env overrides
  resources   map    CPU/Mem hints

------------------------------------------------------------------------

### 4.10 HookSpec

  Field      Type           Description
  ---------- -------------- ---------------
  phase      string         Phase
  scripts    list\[path\]   Scripts
  on_error   enum           fail/continue

------------------------------------------------------------------------

### 4.11 HarvestSpec

  Field     Type     Description
  --------- -------- ----------------
  profile   string   Profile
  metrics   list     Metrics
  outputs   list     Formats
  version   string   Schema version

------------------------------------------------------------------------

### 4.12 Provenance Model

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

### 4.13 Study Index Model

  Field      Type     Description
  ---------- -------- ---------------
  run_id     string   Run ID
  study_id   string   Study
  intent     json     Run intent
  status     enum     Run status
  path       path     Run directory

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
  PFXStudy   Study, StudyLayout, Run, StudyIndex
  PFXCore    CFG, DesignSpec, TechSpec, HarvestSpec, RunIntent
  Tcl        CFG, VARS, PFX
  Make       Stage state
  Storage    Manifests, Index
