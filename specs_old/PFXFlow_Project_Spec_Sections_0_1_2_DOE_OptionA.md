# Project: PFXFlow

## 0. Meta & Status

-   **Owner:** Paul Gutwin
-   **Doc status:** Draft
-   **Last updated:** 2026-02-02
-   **Change log:**
    -   2026-02-02 -- Initial draft with DOE framing (Option A)

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
programmatically to explore timing, density, effort, and other design
variables.

PFXFlow addresses this problem by introducing a unified, deterministic
configuration and orchestration framework for physical design flows. The
project provides a C++-based configuration compiler, standardized run
directory materialization, and well-defined interfaces between job
submission, build orchestration, tool launch, and Tcl execution. It
enables both manually authored and automatically generated
configurations to be converted into fully reproducible execution
artifacts.

The system is designed for Linux-based HPC and Slurm environments,
supports the runtime Tcl configuration requirements of commercial tools,
and avoids reliance on Python or dynamically managed package ecosystems.

### 1.2 Goals

Concrete, testable goals.

-   G1: Provide a single, authoritative TOML-based configuration format
    for defining individual Genus/Innovus runs.
-   G2: Implement a C++ "flowcfg" compiler that validates, merges, and
    materializes per-run configurations.
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
-   G8: Support large-scale DOE workflows by enabling efficient
    generation and management of many independent run directories.
-   G9: Emit per-run provenance metadata suitable for study-level
    aggregation and analysis.

### 1.3 Non-Goals

-   NG1: No graphical user interface in v1.
-   NG2: No replacement of Cadence tool functionality.
-   NG3: No distributed scheduling layer beyond existing Slurm
    integration.
-   NG4: No embedded scripting language beyond Tcl for tool control.
-   NG5: No dynamic plugin system in initial versions.
-   NG6: No cloud-native or container-first deployment model in v1.
-   NG7: No full-featured adaptive or optimization-driven DOE framework
    in v1 (only external DOE generators are supported).

### 1.4 Success Criteria

-   All production and research flows can be expressed in TOML without
    auxiliary environment-variable plumbing.
-   A complete Genus → Innovus flow can be executed from a single frozen
    run directory.
-   Configuration errors are detected prior to tool launch in \>95% of
    misconfiguration cases.
-   Re-running a frozen run directory produces identical results (modulo
    tool nondeterminism).
-   Large DOE studies (100+ runs) can be generated and executed without
    manual per-run scripting.
-   New projects can be onboarded with minimal custom infrastructure
    development.
-   The flow infrastructure can be maintained without uncontrolled
    growth in shell and Tcl complexity.

------------------------------------------------------------------------

## 2. Users, Use Cases & Workflows

### 2.1 Target Users

-   **Primary users:** Physical design engineers, EDA researchers, and
    CAD infrastructure developers conducting block- and system-level
    studies.
-   **Secondary users:** Methodology engineers, research interns, and
    advanced tool users performing parameter sweeps and characterization
    studies.

### 2.2 Key Use Cases

-   **UC1: Standard Block Implementation**
    -   Step 1: User selects or generates a baseline TOML configuration.
    -   Step 2: User invokes the kickoff script with the configuration.
    -   Step 3: PFXFlow generates a new run directory.
    -   Step 4: Make orchestrates Genus and Innovus execution.
    -   Step 5: Tools consume generated Tcl configuration.
    -   Output: Complete implemented block with logs and reports.
-   **UC2: Configuration Override and Experimentation**
    -   Step 1: User creates an override TOML file or programmatically
        generates parameter variants.
    -   Step 2: User invokes kickoff with base + override.
    -   Step 3: flowcfg merges and validates inputs.
    -   Step 4: Modified run is materialized.
    -   Output: Experimental run isolated from baseline.
-   **UC3: Large-Scale DOE Execution**
    -   Step 1: User or external tool defines a parameter sweep (e.g.,
        clock period, density).
    -   Step 2: DOE generator produces multiple per-run TOML files.
    -   Step 3: Each TOML file is compiled by flowcfg into a run
        directory.
    -   Step 4: Runs are submitted and monitored via Slurm and Make.
    -   Output: Structured study directory with reproducible sub-runs
        and manifests.
-   **UC4: Debug and Reproduction**
    -   Step 1: User locates archived run directory.
    -   Step 2: User inspects frozen config and environment files.
    -   Step 3: User re-runs Make targets locally.
    -   Output: Reproduced behavior for debugging and root-cause
        analysis.
-   **UC5: Infrastructure Maintenance**
    -   Step 1: Developer updates flow scripts or validation rules.
    -   Step 2: flowcfg schema and checks are updated.
    -   Step 3: Regression and DOE-style validation runs are executed.
    -   Output: Verified and stable infrastructure update.

### 2.3 Example Scenarios

**Scenario 1: New Block Bring-Up**\
An engineer creates a new block-level configuration by copying a
template TOML file and modifying library and constraint paths. After
invoking the kickoff script, PFXFlow materializes a clean run directory
and launches the standard Genus/Innovus pipeline. Errors in library
paths are detected by flowcfg before tool startup.

**Scenario 2: Parameter Sweep Study**\
A researcher defines a DOE sweeping clock period from 100 ps to 300 ps
and placement density from 0.5 to 0.7. An external generator produces a
grid of TOML files. PFXFlow compiles each into a structured run
directory hierarchy and executes the full study under Slurm control.

**Scenario 3: Post-Mortem Debugging**\
A failed tapeout rehearsal is investigated months later. The archived
run directory contains the frozen TOML, generated Tcl, environment
snapshot, and provenance metadata. The engineer replays the run and
isolates a constraint misconfiguration without reconstructing historical
scripts.
