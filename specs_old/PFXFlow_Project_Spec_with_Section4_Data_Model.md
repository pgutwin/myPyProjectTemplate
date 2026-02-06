# Project: PFXFlow

## 0. Meta & Status

-   **Owner:** Paul Gutwin
-   **Doc status:** Draft
-   **Last updated:** 2026-02-03
-   **Change log:**
    -   2026-02-02 -- Initial draft
    -   2026-02-02 -- Added DOE framing, control variables, and Tcl hook
        system
    -   2026-02-02 -- Added Architecture section
    -   2026-02-03 -- Added standardized design/technology interfaces
    -   2026-02-03 -- Introduced PFXCore / PFXStudy subsystem model and
        license management
    -   2026-02-03 -- Added results harvesting and standardized summary
        outputs framing
    -   2026-02-03 -- Added Data Model and Core Abstractions (Section 4)

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
flows are rarely executed as single, isolated runs. Instead, they are
typically embedded in large Design of Experiments (DOE) studies, where
hundreds or thousands of parameterized runs are generated
programmatically to explore timing, density, effort, library variants,
and other design variables.

In addition, legacy flows often lack consistent interfaces for design,
technology, and results data.

PFXFlow addresses these problems through a unified configuration,
orchestration, execution, and harvesting framework composed of PFXCore
and PFXStudy.

------------------------------------------------------------------------

## 2. Users, Use Cases & Workflows

(See previous sections.)

------------------------------------------------------------------------

## 3. Architecture Overview

(See previous sections.)

------------------------------------------------------------------------

## 4. Data Model and Core Abstractions

### 4.1 Overview

This section defines the primary logical data objects manipulated by
PFXCore and PFXStudy. These abstractions form the contract between
configuration, execution, harvesting, and aggregation layers. All
persistent artifacts are derived from these core models.

The data model is designed to be:

-   Explicit and strongly validated
-   Deterministic and serializable
-   Backward-compatible where feasible
-   Independent of UI and workflow concerns

------------------------------------------------------------------------

### 4.2 Study Model

A **Study** represents a collection of related runs generated from a
common experimental intent.

#### Study Object

  Field             Type        Description
  ----------------- ----------- -------------------------------------
  study_id          string      Unique identifier
  root_dir          path        Study root directory
  created_at        timestamp   Creation time
  templates         list        Template/overlay references
  variables         map         Sweep variable definitions
  runs              list        Associated Run IDs
  license_profile   string      License policy reference
  status            enum        active / paused / complete / failed

The Study object is owned by PFXStudy.

------------------------------------------------------------------------

### 4.3 Run Model

A **Run** represents a single executable point in parameter space.

#### Run Object

  Field              Type        Description
  ------------------ ----------- ---------------------------------------
  run_id             string      Unique identifier
  study_id           string      Parent study
  run_dir            path        Run directory
  vars               map         DOE variables
  template_lineage   list        Base + overlays
  status             enum        pending / running / complete / failed
  created_at         timestamp   Creation time
  started_at         timestamp   Start time
  finished_at        timestamp   Completion time

Run objects are jointly managed by PFXStudy and PFXCore.

------------------------------------------------------------------------

### 4.4 Configuration Model

The configuration model represents validated, merged TOML content.

#### Config Object (CFG)

  Field        Type          Description
  ------------ ------------- -----------------------
  design       DesignSpec    RTL/constraint inputs
  tech         TechSpec      Technology inputs
  tools        ToolSpec      Tool parameters
  hooks        HookSpec      Hook configuration
  harvesting   HarvestSpec   Harvest profile
  metadata     map           User metadata

CFG is serialized into `config.tcl` and frozen in `run.toml`.

------------------------------------------------------------------------

### 4.5 Design Specification (DesignSpec)

Defines design inputs.

  Field          Type             Description
  -------------- ---------------- -------------------------
  rtl_files      list\[path\]     Resolved RTL list
  rtl_type       enum             verilog / systemverilog
  include_dirs   list\[path\]     Include paths
  defines        list\[string\]   Preprocessor defines
  sdc_files      list\[path\]     Timing constraints
  blackboxes     list\[string\]   Abstract modules

All fields are resolved and validated by PFXCore.

------------------------------------------------------------------------

### 4.6 Technology Specification (TechSpec)

Defines technology inputs.

  Field           Type             Description
  --------------- ---------------- ------------------
  liberty_files   list\[path\]     Timing libraries
  tech_lef        path             Technology LEF
  cell_lefs       list\[path\]     Cell LEFs
  macro_lefs      list\[path\]     Macro LEFs
  rc_models       list\[path\]     RC data
  corners         list\[string\]   MMMC corners

------------------------------------------------------------------------

### 4.7 Tool Specification (ToolSpec)

Defines tool-specific configuration.

  Field       Type   Description
  ----------- ------ -----------------------
  genus       map    Genus parameters
  innovus     map    Innovus parameters
  env         map    Environment overrides
  resources   map    CPU/memory hints

------------------------------------------------------------------------

### 4.8 Hook Specification (HookSpec)

Defines Tcl hook attachments.

  Field      Type           Description
  ---------- -------------- -----------------
  phase      string         Hook phase
  scripts    list\[path\]   Script files
  on_error   enum           fail / continue

Multiple HookSpec entries may exist.

------------------------------------------------------------------------

### 4.9 Harvest Specification (HarvestSpec)

Defines run-level result extraction.

  Field     Type             Description
  --------- ---------------- -----------------------
  profile   string           Harvest profile name
  metrics   list\[string\]   Enabled metrics
  outputs   list\[string\]   Output formats
  version   string           Metric schema version

HarvestSpec controls which harvesters are enabled.

------------------------------------------------------------------------

### 4.10 Provenance Model

Defines metadata required for reproducibility.

  Field               Type        Description
  ------------------- ----------- --------------------
  config_hash         string      Frozen config hash
  input_hashes        map         Input file hashes
  hook_hashes         map         Hook hashes
  tool_versions       map         Tool version info
  harvester_version   string      Harvester version
  host                string      Host identifier
  timestamp           timestamp   Execution time

------------------------------------------------------------------------

### 4.11 Manifest Objects

PFXCore produces machine-readable manifests.

#### Input Manifest

Lists all resolved design and tech inputs.

#### Run Summary Manifest

Contains harvested metrics and derived values.

#### Study Summary Manifest

Aggregates run summaries.

All manifests are versioned and schema-validated.

------------------------------------------------------------------------

### 4.12 In-Memory vs Persistent Representations

-   In-memory models are implemented as strongly-typed C++ classes.
-   Persistent models are serialized as TOML, JSON, or CSV.
-   All persistent formats include schema/version tags.

------------------------------------------------------------------------

### 4.13 Evolution and Compatibility

-   Additive changes are preferred.
-   Deprecated fields remain readable.
-   Breaking changes require migration tools.
-   Schema versions are explicit.

------------------------------------------------------------------------

### 4.14 Mapping to Implementation

  Layer      Primary Objects
  ---------- ----------------------------------------
  PFXStudy   Study, Run
  PFXCore    CFG, DesignSpec, TechSpec, HarvestSpec
  Tcl        CFG, VARS, PFX dicts
  Make       Stage state
  Storage    Manifests, Summaries

This mapping guides implementation boundaries.
