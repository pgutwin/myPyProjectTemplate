# Project: PFXFlow

## 0. Meta & Status

-   **Owner:** Paul Gutwin
-   **Doc status:** Draft
-   **Last updated:** 2026-02-02
-   **Change log:**
    -   2026-02-02 -- Initial draft
    -   2026-02-02 -- Added DOE framing, control variables, and Tcl hook
        system (Option A)
    -   2026-02-02 -- Added Architecture section

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
-   G10: Support arbitrary per-run control variables for DOE and
    experimentation.
-   G11: Provide a structured, extensible Tcl hook mechanism for
    controlled flow customization.

### 1.3 Non-Goals

-   NG1: No graphical user interface in v1.
-   NG2: No replacement of Cadence tool functionality.
-   NG3: No distributed scheduling layer beyond existing Slurm
    integration.
-   NG4: No embedded scripting language beyond Tcl for tool control.
-   NG5: No dynamic plugin system in initial versions.
-   NG6: No cloud-native or container-first deployment model in v1.
-   NG7: No full-featured adaptive or optimization-driven DOE framework
    in v1.
-   NG8: No unrestricted execution of untracked Tcl or shell scripts
    outside defined hook points.

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
-   Arbitrary experimental variables can be introduced without modifying
    core infrastructure.
-   Hooks can be added and removed without modifying canonical driver
    scripts.
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
    -   Step 1: User or external tool defines a parameter sweep.
    -   Step 2: DOE generator produces multiple per-run TOML files.
    -   Step 3: Each TOML file is compiled by flowcfg into a run
        directory.
    -   Step 4: Runs are submitted and monitored via Slurm and Make.
    -   Output: Structured study directory with reproducible sub-runs
        and manifests.
-   **UC4: Flow Customization via Hooks**
    -   Step 1: User writes pre/post Tcl hook scripts.
    -   Step 2: User references hooks in the TOML configuration.
    -   Step 3: flowcfg validates and materializes hook files.
    -   Step 4: Canonical drivers invoke hooks at defined phases.
    -   Output: Customized flow behavior with preserved reproducibility.
-   **UC5: Debug and Reproduction**
    -   Step 1: User locates archived run directory.
    -   Step 2: User inspects frozen config, hooks, and environment
        files.
    -   Step 3: User re-runs Make targets locally.
    -   Output: Reproduced behavior for debugging and root-cause
        analysis.
-   **UC6: Infrastructure Maintenance**
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

**Scenario 3: Experimental Library Evaluation**\
A methodology engineer evaluates multiple Vt and special-cell libraries.
Each variant is encoded in the TOML configuration and applied through
library overlays. Hooks are used to insert additional reporting scripts.
All variants are archived with full provenance.

**Scenario 4: Post-Mortem Debugging**\
A failed tapeout rehearsal is investigated months later. The archived
run directory contains the frozen TOML, generated Tcl, environment
snapshot, hook scripts, and provenance metadata. The engineer replays
the run and isolates a constraint misconfiguration without
reconstructing historical scripts.

------------------------------------------------------------------------

## 3. Architecture Overview

### 3.1 High-Level Component Diagram (Textual)

PFXFlow is organized as a layered system with explicit responsibility
boundaries.

**Primary Components:**

-   **Kickoff Layer (CSH / Slurm Interface)**
    -   Entry point for users and DOE generators.
    -   Submits jobs and establishes execution context.
    -   Performs minimal logic.
-   **Configuration Compiler (`flowcfg`, C++)**
    -   Parses and validates TOML configurations.
    -   Applies overrides and merges inputs.
    -   Materializes run directories.
    -   Generates derived artifacts (config.tcl, env.sh, manifests).
-   **Run Directory**
    -   Self-contained execution unit.
    -   Contains frozen configuration, hooks, logs, and status files.
    -   Serves as the unit of reproducibility.
-   **Build Orchestration (Make)**
    -   Encodes stage dependencies.
    -   Manages failure propagation.
    -   Produces status markers.
-   **Tool Launch Wrappers (Shell / C++)**
    -   Source environment.
    -   Invoke Cadence tools deterministically.
    -   Capture logs and exit status.
-   **Canonical Tcl Drivers**
    -   Implement standard Genus and Innovus flows.
    -   Provide defined hook points.
    -   Expose configuration and utilities to hooks.
-   **Hook Scripts (Optional Tcl)**
    -   User-provided extensions.
    -   Executed at defined phases.
    -   Operate within controlled context.

**Interaction Summary:**

Kickoff → flowcfg → Run Directory → Make → Tool Launcher → Tcl Driver →
Hooks

All configuration flows from the TOML input through flowcfg into
generated artifacts.

------------------------------------------------------------------------

### 3.2 Study-Level vs Run-Level Architecture

PFXFlow distinguishes between two organizational layers:

#### Study Level

-   Represents a DOE or experiment campaign.
-   Typically managed by an external generator.
-   Produces multiple per-run TOML files.
-   Maintains study-level manifests and summaries.

Study-level responsibilities are intentionally kept outside PFXFlow
core.

#### Run Level

-   Represents a single point in parameter space.
-   Implemented as one run directory.
-   Fully self-contained.
-   Executable and reproducible in isolation.

PFXFlow operates primarily at the run level.

------------------------------------------------------------------------

### 3.3 Run Directory Structure

A canonical run directory has the following structure:

``` text
run_<id>/
  run.toml
  config.tcl
  env.sh
  hooks/
    *.tcl
  logs/
    genus.log
    innovus.log
  status/
    genus.ok / genus.fail
    innovus.ok / innovus.fail
  reports/
  results/
  meta/
    provenance.json
    hashes.txt
```

All files required to reproduce the run are contained within this
directory.

------------------------------------------------------------------------

### 3.4 Configuration Flow

1.  Input TOML files are provided by user or DOE generator.
2.  flowcfg parses and validates inputs.
3.  Overrides and defaults are applied.
4.  A frozen run.toml is written.
5.  Derived artifacts are generated:
    -   config.tcl (Tcl dicts: CFG, VARS, PFX)
    -   env.sh (environment exports)
    -   hook copies
6.  Provenance metadata is recorded.

Downstream components never reinterpret the original TOML.

------------------------------------------------------------------------

### 3.5 Execution Pipeline

For each run directory:

1.  Kickoff submits job and enters run directory.
2.  Make initializes targets.
3.  Genus stage executes:
    -   tool wrapper
    -   canonical driver
    -   pre/post hooks
4.  Innovus stage executes:
    -   tool wrapper
    -   canonical driver
    -   pre/post hooks
5.  Status files are written.
6.  Make terminates on success or failure.

Each stage produces explicit artifacts consumed by later stages.

------------------------------------------------------------------------

### 3.6 Tcl Driver and Hook Architecture

Canonical drivers implement fixed execution phases.

Example phases:

-   genus.pre
-   genus.main
-   genus.post
-   innovus.pre_init
-   innovus.post_init
-   innovus.pre_route
-   innovus.post_route
-   innovus.post_signoff

Drivers invoke hooks via a common utility:

``` tcl
pfx::run_hooks "genus.pre"
```

#### Execution Context

Before hook execution, drivers define:

-   `CFG` : Structured configuration dict
-   `VARS` : Free-form DOE variable dict
-   `PFX` : Runtime context dict
-   Utility procedures (log, die, require_var, etc.)

Hooks must operate only through this interface.

------------------------------------------------------------------------

### 3.7 Provenance and Reproducibility

For each run, PFXFlow records:

-   Frozen configuration (run.toml)
-   Hashes of all hook scripts
-   flowcfg version and git commit
-   Tool versions (if available)
-   Host and timestamp

These records are stored under `meta/` and enable long-term
reproducibility.

------------------------------------------------------------------------

### 3.8 Extension and Evolution Strategy

PFXFlow is designed to evolve by:

-   Adding new hook phases without breaking existing runs.
-   Extending TOML schema in backward-compatible ways.
-   Introducing optional study-level tooling externally.
-   Avoiding cross-layer dependencies.

Major architectural changes require updating this specification.
