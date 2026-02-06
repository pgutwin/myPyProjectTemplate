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

In addition, legacy flows often lack a consistent, enforceable interface
for design sources (RTL, constraints) and technology inputs (libraries,
LEFs, RC data). This results in undocumented assumptions and fragile,
environment-dependent behavior.

PFXFlow addresses these problems by introducing a unified, deterministic
configuration and orchestration framework for physical design flows. The
system is composed of two primary subsystems:

-   **PFXCore**: A headless run compilation and execution kernel
    responsible for configuration validation, normalization,
    materialization, and deterministic tool execution.
-   **PFXStudy**: A study orchestration and user interaction layer
    responsible for DOE management, scheduling, license management, and
    result aggregation.

PFXFlow enables both manually authored and automatically generated
configurations to be converted into fully reproducible execution
artifacts and executed at scale under centralized resource control.

The system is designed for Linux-based HPC and Slurm environments,
supports the runtime Tcl configuration requirements of commercial tools,
and avoids reliance on Python or dynamically managed package ecosystems.

### 1.2 Goals

Concrete, testable goals.

-   G1: Provide a single, authoritative TOML-based configuration format
    for defining individual Genus/Innovus runs.
-   G2: Implement PFXCore as a C++-based run compiler and
    materialization engine.
-   G3: Generate deterministic per-run artifacts (config.tcl, env.sh,
    frozen run config).
-   G4: Support fully reproducible execution via self-contained run
    directories.
-   G5: Integrate cleanly with existing CSH, Make, and Slurm-based
    infrastructures.
-   G6: Provide clear failure propagation and status reporting across
    all stages.
-   G7: Enable schema validation and early error detection before tool
    invocation.
-   G8: Support large-scale DOE workflows via PFXStudy.
-   G9: Emit per-run provenance metadata suitable for study-level
    aggregation and analysis.
-   G10: Support arbitrary per-run control variables for DOE and
    experimentation.
-   G11: Provide a structured, extensible Tcl hook mechanism for
    controlled flow customization.
-   G12: Provide standardized, validated interfaces for RTL, constraint,
    and technology inputs.
-   G13: Materialize a resolved, immutable manifest of all design and
    technology inputs per run.
-   G14: Centralize license and resource management in PFXStudy.

### 1.3 Non-Goals

-   NG1: No graphical user interface in v1 (GUI architecture only).
-   NG2: No replacement of Cadence tool functionality.
-   NG3: No distributed scheduling layer beyond existing Slurm
    integration.
-   NG4: No embedded scripting language beyond Tcl for tool control.
-   NG5: No dynamic plugin system in initial versions.
-   NG6: No cloud-native or container-first deployment model in v1.
-   NG7: No adaptive or optimization-driven DOE framework in v1.
-   NG8: No unrestricted execution of untracked Tcl or shell scripts.
-   NG9: No implicit discovery of design or technology files at runtime.

### 1.4 Success Criteria

-   All flows are expressible in TOML without environment-variable
    plumbing.

-   A complete Genus → Innovus flow executes from a frozen run
    directory.

-   95% of configuration errors are detected before tool launch.

-   Re-running a frozen run directory reproduces behavior.

-   100+ run DOE studies execute without manual scripting.

-   License limits are respected without manual intervention.

-   Hooks and variables are extensible without infrastructure changes.

------------------------------------------------------------------------

## 2. Users, Use Cases & Workflows

### 2.1 Target Users

-   **Primary users:** Physical design engineers and researchers running
    DOE studies via PFXStudy.
-   **Secondary users:** CAD infrastructure developers and advanced
    users interfacing directly with PFXCore.

### 2.2 Key Use Cases

-   **UC1: DOE Creation and Execution (PFXStudy)**
    -   User defines sweep parameters in PFXStudy.
    -   PFXStudy selects templates and overlays.
    -   PFXStudy schedules runs under license limits.
    -   PFXCore materializes and executes runs.
-   **UC2: Advanced Run Debugging (PFXCore)**
    -   User invokes `pfxflow run` on a single configuration.
    -   PFXCore validates, normalizes, and executes.
    -   User inspects resolved artifacts.
-   **UC3: Library and Technology Evaluation**
    -   User defines tech overlays.
    -   PFXStudy runs comparative studies.
    -   Results aggregated automatically.
-   **UC4: Flow Customization**
    -   User attaches Tcl hooks.
    -   PFXCore executes hooks at defined phases.

### 2.3 Example Scenarios

**Scenario 1: High-Throughput Study**\
An engineer launches a 500-point sweep via PFXStudy. The system queues
runs based on Innovus license availability and dispatches them through
PFXCore.

**Scenario 2: Targeted Debug**\
A power user extracts a failing run and replays it locally using
`pfxflow run`.

**Scenario 3: Methodology Development**\
A researcher evaluates multiple Vt variants using overlays and
post-route analysis hooks.

------------------------------------------------------------------------

## 3. Architecture Overview

### 3.1 High-Level Component Diagram (Textual)

PFXFlow is structured as follows:

-   **PFXStudy (CLI/GUI)**
    -   Study Manager
    -   Template Catalog
    -   License Manager
    -   Scheduler / Dispatcher
    -   Results Database
-   **PFXCore (Execution Kernel)**
    -   Config Composer
    -   Schema Validator
    -   Design/Tech Normalizer
    -   Run Materializer
    -   Tool Wrappers
    -   Tcl Drivers
    -   Hook Executor
-   **Execution Substrate**
    -   Make
    -   Slurm
    -   Cadence Tools

Interaction chain:

User → PFXStudy → PFXCore → Execution Substrate → Results → PFXStudy

------------------------------------------------------------------------

### 3.2 Subsystem Responsibilities

#### PFXStudy

-   Manage DOE definitions
-   Maintain template/overlay catalog
-   Allocate licenses
-   Gate job execution
-   Monitor runs
-   Aggregate results
-   Provide CLI/GUI

#### PFXCore

-   Merge templates and overlays
-   Validate schemas
-   Resolve design and tech inputs
-   Generate run directories
-   Execute tool flows
-   Emit provenance and status

------------------------------------------------------------------------

### 3.3 Canonical Run Directory Structure

``` text
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
  meta/
```

------------------------------------------------------------------------

### 3.4 Interface Contract (PFXStudy ↔ PFXCore)

**Inputs to PFXCore:** - Base template IDs/paths - Overlay list - VARS
dictionary - Run identifier - Execution stages

**Outputs from PFXCore:** - Materialized run directory - Status
markers - Provenance records - Resolved input manifests

------------------------------------------------------------------------

### 3.5 Execution Pipeline

1.  PFXStudy authorizes execution.
2.  PFXCore composes configuration.
3.  Inputs normalized and frozen.
4.  Make pipeline executes.
5.  Status propagated.
6.  Results indexed.

------------------------------------------------------------------------

### 3.6 Tcl Driver and Hook Architecture

Drivers expose:

-   CFG
-   VARS
-   PFX context

Hooks execute only via standardized entry points.

------------------------------------------------------------------------

### 3.7 License and Resource Management

PFXStudy maintains:

-   License pool definitions
-   Allocation counters
-   Concurrency limits
-   Failure/retry policies

PFXCore assumes licenses are available.

------------------------------------------------------------------------

### 3.8 Provenance and Reproducibility

Each run records:

-   Template lineage
-   Input hashes
-   Hook hashes
-   Tool versions
-   Host/timestamp

------------------------------------------------------------------------

### 3.9 Extension Strategy

-   Backward-compatible schemas
-   New hook phases
-   Optional study modules
-   Stable core interfaces
