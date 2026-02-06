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

In addition, legacy flows often lack: - A consistent, enforceable
interface for design sources (RTL, constraints) and technology inputs
(libraries, LEFs, RC data), resulting in undocumented assumptions and
fragile, environment-dependent behavior. - A regularized mechanism to
**harvest** key results from tool reports into a structured dataset
suitable for study-level analysis. This "harvest" step is often the most
time-consuming and least respected part of running large studies, and
historically has been implemented via ad-hoc scripts that parse report
files and produce a top-level CSV.

PFXFlow addresses these problems by introducing a unified, deterministic
configuration, orchestration, and results-harvesting framework for
physical design flows. The system is composed of two primary subsystems:

-   **PFXCore**: A headless run compilation and execution kernel
    responsible for configuration validation, normalization,
    materialization, deterministic tool execution, and standardized
    run-level result harvesting hooks/interfaces.
-   **PFXStudy**: A study orchestration and user interaction layer
    responsible for DOE management, scheduling, license management, run
    monitoring, and study-level aggregation (including building
    consolidated datasets across runs).

PFXFlow enables both manually authored and automatically generated
configurations to be converted into fully reproducible execution
artifacts, executed at scale under centralized resource control, and
summarized into analysis-ready datasets.

The system is designed for Linux-based HPC and Slurm environments,
supports runtime Tcl configuration requirements of commercial tools, and
avoids reliance on Python or dynamically managed package ecosystems.

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
-   G15: Define and support a **standardized results harvesting**
    mechanism that produces a regularized run-level summary dataset and
    supports study-level aggregation.

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
-   NG10: No attempt to standardize *all* possible report semantics in
    v1; harvesting will focus on a scoped, high-value set of metrics
    with an extensible mechanism for adding more.

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

-   Each run produces a regularized summary output (machine-readable)
    suitable for study-level aggregation.

-   A study can generate a consolidated dataset (e.g., CSV/Parquet)
    without bespoke parsing per run.

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
    -   PFXCore validates, normalizes, executes, and harvests.
    -   User inspects resolved artifacts and summaries.
-   **UC3: Library and Technology Evaluation**
    -   User defines tech overlays.
    -   PFXStudy runs comparative studies.
    -   Results are harvested per run and aggregated automatically.
-   **UC4: Flow Customization**
    -   User attaches Tcl hooks.
    -   PFXCore executes hooks at defined phases.
-   **UC5: Results Harvesting and Aggregation**
    -   PFXCore produces run-level summary metrics in a standard
        location and format.
    -   PFXStudy aggregates run summaries into a single dataset at the
        study root.

### 2.3 Example Scenarios

**Scenario 1: High-Throughput Study**\
An engineer launches a 500-point sweep via PFXStudy. The system queues
runs based on Innovus license availability and dispatches them through
PFXCore. Each run emits a standard run summary. PFXStudy aggregates all
run summaries into a single consolidated dataset.

**Scenario 2: Targeted Debug**\
A power user extracts a failing run and replays it locally using
`pfxflow run`, including regeneration of the run summary to verify
harvesting logic.

**Scenario 3: Methodology Development**\
A researcher evaluates multiple Vt variants using overlays and
post-route analysis hooks. The harvesting pipeline extracts key
timing/area/power/QoR deltas for rapid comparison.

------------------------------------------------------------------------

## 3. Architecture Overview

### 3.1 High-Level Component Diagram (Textual)

PFXFlow is structured as follows:

-   **PFXStudy (CLI/GUI)**
    -   Study Manager
    -   Template Catalog
    -   License Manager
    -   Scheduler / Dispatcher
    -   Results Database / Aggregator
    -   Dataset Exporter (CSV/Parquet)
-   **PFXCore (Execution Kernel)**
    -   Config Composer
    -   Schema Validator
    -   Design/Tech Normalizer
    -   Run Materializer
    -   Tool Wrappers
    -   Tcl Drivers
    -   Hook Executor
    -   **Harvester Framework** (run-level summaries)
-   **Execution Substrate**
    -   Make
    -   Slurm
    -   Cadence Tools

Interaction chain:

User → PFXStudy → PFXCore → Execution Substrate → Run Summaries →
PFXStudy Aggregation

------------------------------------------------------------------------

### 3.2 Subsystem Responsibilities

#### PFXStudy

-   Manage DOE definitions
-   Maintain template/overlay catalog
-   Allocate licenses
-   Gate job execution
-   Monitor runs
-   Aggregate results across runs
-   Export consolidated datasets
-   Provide CLI/GUI

#### PFXCore

-   Merge templates and overlays
-   Validate schemas
-   Resolve design and tech inputs
-   Generate run directories
-   Execute tool flows
-   Emit provenance and status
-   Produce standardized run-level summary outputs via a harvester
    mechanism

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
    run_summary.json
    run_summary.csv
  meta/
```

Notes: - `results/run_summary.*` is the primary run-level harvested
output. - The exact fields are versioned and extensible; consumers must
tolerate additive changes.

------------------------------------------------------------------------

### 3.4 Interface Contract (PFXStudy ↔ PFXCore)

**Inputs to PFXCore:** - Base template IDs/paths - Overlay list - VARS
dictionary - Run identifier - Execution stages - (Optional) harvesting
profile selection (which metrics set to emit)

**Outputs from PFXCore:** - Materialized run directory - Status
markers - Provenance records - Resolved input manifests - Run summary
dataset(s) in standard location(s)

------------------------------------------------------------------------

### 3.5 Execution Pipeline

1.  PFXStudy authorizes execution (including license gating).
2.  PFXCore composes configuration.
3.  Inputs normalized and frozen.
4.  Make pipeline executes.
5.  PFXCore harvesting stage generates run summaries.
6.  Status propagated.
7.  PFXStudy indexes results and aggregates study datasets.

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

PFXCore assumes licenses are available when invoked for a stage.

------------------------------------------------------------------------

### 3.8 Results Harvesting Architecture (Framing)

The harvesting problem is intentionally separated into two layers:

#### Run-Level Harvesting (PFXCore)

-   Produces a machine-readable run summary in a standard location.
-   May include:
    -   direct extraction of known report fields
    -   controlled, run-local analysis (e.g., timing report
        post-processing)
-   Is implemented as a **harvester framework** with a stable interface,
    not as ad-hoc scripts.
-   Supports incremental extension by adding new harvesters or metrics
    groups without changing the run directory contract.

#### Study-Level Aggregation (PFXStudy)

-   Consumes run-level summaries across many runs.
-   Produces consolidated datasets at the study root (CSV/Parquet).
-   Supports filtering, grouping, and labeling by DOE variables.

The exact metric definitions and complex timing analysis are out of
scope for this architecture section, but the system must anticipate that
timing harvesting may require specialized tool commands and lightweight
analysis.

------------------------------------------------------------------------

### 3.9 Provenance and Reproducibility

Each run records:

-   Template lineage
-   Input hashes
-   Hook hashes
-   Tool versions
-   Host/timestamp
-   Harvester version and metric-set identifiers

------------------------------------------------------------------------

### 3.10 Extension Strategy

-   Backward-compatible schemas
-   New hook phases
-   New harvester modules / metric sets
-   Optional study modules
-   Stable core interfaces
