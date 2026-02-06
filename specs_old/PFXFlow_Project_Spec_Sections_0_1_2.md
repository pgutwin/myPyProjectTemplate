# Project: PFXFlow

## 0. Meta & Status

-   **Owner:** Paul Gutwin
-   **Doc status:** Draft
-   **Last updated:** 2026-02-02
-   **Change log:**
    -   2026-02-02 -- Initial draft

------------------------------------------------------------------------

## 1. Project Overview

### 1.1 Problem Statement

Modern commercial EDA flows based on Cadence Genus and Innovus require
complex, multi-layer configuration spanning shell scripts, Makefiles,
tool launch wrappers, and Tcl runtime setup. In legacy environments,
configuration data is fragmented across environment variables, ad-hoc
shell logic, embedded Tcl scripts, and Makefile rules. Over time, this
leads to brittle, non-reproducible, and difficult-to-maintain
"spaghetti" infrastructure.

PFXFlow addresses this problem by introducing a unified, deterministic
configuration and orchestration framework for physical design flows. The
project provides a C++-based configuration compiler, standardized run
directory materialization, and well-defined interfaces between job
submission, build orchestration, tool launch, and Tcl execution. The
goal is to replace implicit, scattered state with explicit,
version-controlled, and reproducible run artifacts.

The system is designed for Linux-based HPC and Slurm environments,
supports runtime Tcl configuration requirements of commercial tools, and
avoids reliance on Python or dynamically managed package ecosystems.

### 1.2 Goals

Concrete, testable goals.

-   G1: Provide a single, authoritative TOML-based configuration format
    for defining Genus/Innovus runs.
-   G2: Implement a C++ "flowcfg" compiler that validates, merges, and
    materializes configurations.
-   G3: Generate deterministic per-run artifacts (config.tcl, env.sh,
    frozen run config).
-   G4: Support reproducible execution via self-contained run
    directories.
-   G5: Integrate cleanly with existing CSH, Make, and Slurm-based
    infrastructures.
-   G6: Provide clear failure propagation and status reporting across
    all stages.
-   G7: Enable schema validation and early error detection before tool
    invocation.

### 1.3 Non-Goals

-   NG1: No graphical user interface in v1.
-   NG2: No replacement of Cadence tool functionality.
-   NG3: No distributed scheduling layer beyond existing Slurm
    integration.
-   NG4: No embedded scripting language beyond Tcl for tool control.
-   NG5: No dynamic plugin system in initial versions.
-   NG6: No cloud-native or container-first deployment model in v1.

### 1.4 Success Criteria

-   All production flows can be expressed in TOML without auxiliary
    environment-variable plumbing.
-   A complete Genus → Innovus flow can be executed from a single frozen
    run directory.
-   Configuration errors are detected prior to tool launch in \>95% of
    misconfiguration cases.
-   Re-running a frozen run directory produces identical results (modulo
    tool nondeterminism).
-   New projects can be onboarded with minimal custom scripting.
-   The flow infrastructure can be maintained without uncontrolled
    growth in shell/Tcl complexity.

------------------------------------------------------------------------

## 2. Users, Use Cases & Workflows

### 2.1 Target Users

-   **Primary users:** Physical design engineers, EDA researchers, and
    CAD infrastructure developers.
-   **Secondary users:** Methodology engineers, research interns, and
    advanced tool users.

### 2.2 Key Use Cases

-   **UC1: Standard Block Implementation**
    -   Step 1: User selects a baseline TOML configuration.
    -   Step 2: User invokes kickoff script with the config.
    -   Step 3: PFXFlow generates a new run directory.
    -   Step 4: Make orchestrates Genus and Innovus execution.
    -   Step 5: Tools consume generated Tcl configuration.
    -   Output: Complete implemented block with logs and reports.
-   **UC2: Configuration Override and Experimentation**
    -   Step 1: User creates an override TOML file.
    -   Step 2: User invokes kickoff with base + override.
    -   Step 3: flowcfg merges and validates inputs.
    -   Step 4: Modified run is materialized.
    -   Output: Experimental run isolated from baseline.
-   **UC3: Debug and Reproduction**
    -   Step 1: User locates archived run directory.
    -   Step 2: User inspects frozen config and env files.
    -   Step 3: User re-runs Make targets locally.
    -   Output: Reproduced behavior for debugging.
-   **UC4: Infrastructure Maintenance**
    -   Step 1: Developer updates flow scripts.
    -   Step 2: flowcfg schema and validation rules are updated.
    -   Step 3: Regression runs are executed.
    -   Output: Verified infrastructure update.

### 2.3 Example Scenarios

**Scenario 1: New Block Bring-Up**\
An engineer creates a new block-level configuration by copying a
template TOML file and modifying library and constraint paths. After
invoking the kickoff script, PFXFlow materializes a clean run directory
and launches the standard Genus/Innovus pipeline. Errors in library
paths are detected by flowcfg before tool startup.

**Scenario 2: Corner Sweep Study**\
A researcher prepares multiple override files specifying different PVT
corners and effort levels. Each override is run through PFXFlow,
producing separate, fully reproducible run directories. Results are
compared without ambiguity about configuration provenance.

**Scenario 3: Post-Mortem Debugging**\
A failed tapeout rehearsal is investigated months later. The archived
run directory contains the frozen TOML, generated Tcl, and environment
snapshot. The engineer replays the run and isolates a constraint
misconfiguration without reconstructing historical scripts.
