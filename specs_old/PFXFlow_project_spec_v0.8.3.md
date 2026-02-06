# Project: PFXFlow

## 0. Meta & Status

-   **Spec version:** v0.8.3
-   **Owner:** Paul Gutwin
-   **Doc status:** Draft (Master Specification)
-   P26-02-04

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

-   2026-02-03 -- Consolidated into unified master specification

-   2026-02-04 -- Defined Tier-1 execution semantics (freshness, grouped

-   2026-02-04 -- Tier-2 policies: tech catalog governance, core metrics

-   2026-02-04 -- Reorganized section 3 numbering; fixed duplicate

-   2026-02-04 -- Clarified study-root pipeline.toml requirement and

-   2026-02-04 -- Added explicit template syntax and semantics
    (placeholder grammar, typing rules, escaping, inheritance merge
    semantics, reserved variables) override precedence; defined
    templates; fixed semantic path terminology; cleaned formatting
    artifacts and section numbering

-   2026-02-04 -- Added formal Template Processing Model (syntax,
    expansion, inheritance, and lifecycle); clarified template
    production/consumption; bumped to v0.8.0 design sections, removed
    stray HTML artifacts; clarified study-root pipeline.toml with
    per-run overrides harvesting, per-study append-only index w/ CLI
    filters, single-parent templates (no pipeline override), per-study
    resource limits, schema migration; formalized `<semantic path>`
    stages, ordering, failure, environment ownership) subsection;
    clarified working directory for tool execution;

-   2026-02-05 -- Integrated normative DOE variable propagation
    (run.toml → pfx_vars.tcl); clarified wrapper responsibility (v0.8.3)


------------------------------------------------------------------------

## 1. Project Overview

### 1.1 Problem Statement

Modern commercial EDA flows require complex, multi-layer configuration
spanning shell scripts, Makefiles, tool launch wrappers, and Tcl runtime
setup. Due to many factors, configuration data is fragmented across
environment variables, ad-hoc shell logic, embedded Tcl scripts, and
Makefile rules. Over time, this leads to brittle, non-reproducible, and
difficult-to-maintain infrastructure.

In contemporary research and advanced methodology development, these
flows are required to be embedded in large Design of Experiments (DOE)
studies, where hundreds or thousands of parameterized runs are generated
programmatically to explore timing, density, effort, library variants,
and other design variables.

Further, research goals often focus on technology or algorithmic
questions which are unanticipated by "producton" flows, futher
exacerbating the challenge of fragmented scripts, rules and variables.

Multiple frameworks have attempted to address these issues. From one
perspective this work is just yet another flow management system.
However, this work attempts to offer solutions to the following
challenges: - A standardized interface for RTL, constraint, and
technology inputs - Deterministic normalization of design data -
Integrated license-aware and compute-aware orchestration - A regularized
mechanism for harvesting results - A structured mechanism for locating
and tracking runs by experimental intent - A consistent, meaningful
directory structure reflecting DOE structure - A robust, explicit stage
pipeline and artifact handoff contract within each run directory

PFXFlow is architected to address some of these problems through a
unified configuration, orchestration, execution, harvesting, indexing,
and pipeline framework composed of two major subsystems: PFXCore and
PFXStudy.

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
-   G13: Provide explicit stage pipelines with stable artifact handoff
    between stages/tools.

------------------------------------------------------------------------

### 1.4 Non-Goals

-   NG1: Full GUI implementation in v1.
-   NG2: Replacement of Cadence tools.
-   NG3: Cloud-native deployment.
-   NG4: General-purpose optimization framework.
-   NG5: Runtime discovery of unmanaged files.

------------------------------------------------------------------------

### 1.5 Success Criteria

-   All runs are reproducible from frozen directories (modulo tool
    nondeterminism).
-   All inputs are enumerated and validated.
-   Studies of 100+ runs execute unattended.
-   License and compute limits or restrictions are respected.
-   Each run emits a machine-readable summary.
-   Aggregated datasets require no ad-hoc parsing.
-   Users can locate runs using semantic paths and queries.
-   Stage-to-stage data handoff is deterministic and auditable within
    each run directory.

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
6.  PFXCore executes run pipelines.
7.  Results are indexed and aggregated.

#### UC2: Single Run Debug (PFXCore)

1.  User locates run via path or query.
2.  User invokes `pfxflow run` or `pfxflow run --stage <x>`.
3.  Stage prerequisites are enforced.
4.  Stage is executed.
5.  Outputs and metadata are inspected.

#### UC3: Technology Evaluation

Multiple technology variants are evaluated through overlays and
harvested metrics.

#### UC4: Flow Customization

Users attach Tcl hooks at defined phases.

#### UC5: Run Discovery

Users browse directory hierarchies or query the study index.

------------------------------------------------------------------------

## 3. Architecture Overview

### 3.1 High-Level Structure

PFXFlow consists of:

-   PFXStudy (CLI/GUI)
-   PFXCore (Execution Kernel)
-   Execution Substrate (Slurm, Cadence, etc.)

Interaction:

    User → PFXStudy → PFXCore → Tool Wrappers → Tools → Artifacts → Harvest → Index → PFXStudy

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
-   Stage Runner (C++)
-   Tool Wrappers (shell)
-   Tcl Drivers (generated)
-   Hook Executor
-   Harvester Framework

------------------------------------------------------------------------

### 3.4 Canonical Study Directory Structure

The study root directory is created and owned by PFXStudy.

    <study_name>/
      study.toml
      pipeline.toml                 # required (study-wide pipeline)
      index/
        runs.sqlite
      logs/
      exports/
      templates/

**Template definition (v1):**

-   A *template* is a reusable TOML fragment used by PFXStudy to
    generate run-specific configuration (most commonly `run.toml` and
    `request.toml`) for many runs in a study.
-   Templates live under `<study_root>/templates/` and are referenced by
    name from `study.toml`.
-   Templates may declare a single parent template to inherit defaults
    and override specific fields.

**Template inheritance policy (v1):**

-   Templates may inherit from **a single parent template**.

-   Override precedence is parent → child (child values override parent
    values).

-   Templates SHALL NOT redefine the pipeline in v1 (pipeline selection
    is controlled at the study level).

#### 3.4.2 Template Processing Model (v1)

This subsection defines the **syntax** and **semantics** of templates
used by PFXStudy to generate per-run TOML inputs.

**Key rule:** templates are consumed only by **PFXStudy**. **PFXCore
never parses templates**; it consumes only resolved TOML (`run.toml`,
`request.toml`, etc.).

##### 3.4.2.1 Template files and ownership

-   Templates SHALL be stored under:

    ``` text
    <study_root>/templates/
    ```

-   Templates SHALL be versioned with the study (or with a higher-level
    repo if the study is generated from a catalog).

-   Templates are typically authored by flow architects and advanced
    users.

-   Templates are treated as *inputs* to study generation. Changing a
    template does not retroactively change previously generated run
    directories unless the study is explicitly regenerated.

##### 3.4.2.2 Template is valid TOML + placeholders

-   A template SHALL be a valid TOML document *except* for placeholder
    tokens.
-   Placeholders follow the `${var_name}` form.
-   Variable names use `[A-Za-z0-9_]+` and are case-sensitive.

**Placeholder grammar (v1):**

``` text
placeholder := "${" var_name [ "|" default ] "}"
var_name    := [A-Za-z0-9_]+
default     := any sequence of characters not containing "}" (interpreted using the same typing rules as substitution)
```

Examples:

-   `${density}`
-   `${clock_ps|320}`
-   `"${design_name}"`

##### 3.4.2.3 Typing rules (TOML-safe substitution)

PFXStudy performs substitution with **TOML-aware typing** to avoid
"stringly typed" configs.

-   If a placeholder appears **inside a TOML string** (between quotes),
    the substituted value is inserted as a string.
    -   Example: `name = "${design_name}"`
-   If a placeholder appears **outside quotes**, the substituted value
    is inserted as a TOML literal.
    -   Numbers remain numbers, booleans remain booleans, arrays remain
        arrays, etc.
    -   Example: `density = ${density}` → `density = 0.55`
-   PFXStudy SHALL validate that the resulting file parses as TOML after
    substitution.

**Supported literal types for unquoted substitution (v1):**

-   integer: `320`
-   float: `0.55`
-   boolean: `true|false`
-   string (as a TOML string literal): `"foo"` (note: quotes required in
    the substituted value if unquoted placeholder)
-   array: `[1, 2, 3]`, `["a", "b"]`
-   inline table: `{ key = "val", n = 3 }`

**Rule of thumb:** if you want a non-string type, keep the placeholder
unquoted and ensure the bound value is representable as a TOML literal.

##### 3.4.2.4 Escaping rules

-   To emit a literal `${...}` sequence without substitution, templates
    MAY escape `$` as `$$`.
    -   Example: `note = "$${not_a_var}"` → `note = "${not_a_var}"`

##### 3.4.2.5 Binding sources and reserved variables

Variables are bound by PFXStudy from:

1.  DOE axes in `study.toml`
2.  Study metadata (`study_name`, `pipeline_name`, `tech_bundle`, etc.)
3.  Run metadata (assigned by PFXStudy during run instantiation)

**Reserved variables (v1):**

-   `study_name`
-   `run_id` (opaque stable identifier)
-   `run_seq` (monotonic integer within the study)
-   `semantic_path` (relative to `<study_root>/runs/`)
-   `created_utc` (timestamp)

Unbound variables are a **fatal** template error.

##### 3.4.2.6 Inheritance and merge semantics

Templates MAY declare a single parent template using a top-level key:

``` toml
parent = "base_run.toml"
```

**Inheritance semantics (v1):**

-   PFXStudy loads the parent template, then deep-merges the child
    template.
-   Merge rules:
    -   TOML tables: **deep-merge**, child keys override parent keys.
    -   Scalars: **replace** (child overrides parent).
    -   Arrays: **replace** (no concatenation in v1).
-   Inheritance is resolved **before** placeholder substitution.
-   Cycles are forbidden and cause validation failure.

##### 3.4.2.7 Expansion algorithm (normative)

For each run in a study, PFXStudy SHALL:

1.  Select the template(s) referenced by `study.toml` (e.g., run
    template, request template).
2.  Resolve inheritance (single-parent chain), producing a single merged
    template document.
3.  Bind variables from DOE axes + reserved/system fields.
4.  Perform placeholder substitution (with escaping rules).
5.  Parse the result as TOML; fail if invalid.
6.  Write the resolved TOML into the run directory (e.g.,
    `<run_dir>/run.toml`, `<run_dir>/request.toml`).
7.  Record the template identity (template filename + optional hash) in
    the run metadata for provenance.

##### 3.4.2.8 Consumption by PFXCore

-   PFXCore consumes only resolved TOML in run directories.
-   PFXCore SHALL treat resolved TOML as immutable inputs for the run.

Responsibilities:

-   PFXStudy creates and manages this structure.
-   PFXCore does not modify study-level metadata (except possibly via
    index updates through PFXStudy interfaces).

------------------------------------------------------------------------

#### 3.4.1 `<semantic path>`{=html} definition (v1)

PFXFlow uses a **semantic directory hierarchy** so that users can locate
runs by experimental intent without consulting the run index.

A `<semantic path>` is a relative path rooted at the study's `runs/`
directory that encodes the DOE variable assignments for a run.

**Grammar (conceptual):**

    <semantic path> := <axis_dir>+ "/" <run_leaf>
    <axis_dir>      := <axis_name> "=" <axis_value>
    <run_leaf>      := "r" <run_seq> ["__" <short_tag>]

**Rules (v1):**

-   Each DOE axis contributes exactly one `axis_dir` segment of the form
    `name=value`.
-   Axis order is defined by `study.toml` (the DOE layout definition).
    The order must be stable for the lifetime of the study.
-   `axis_name` uses `[A-Za-z0-9_]+`.
-   `axis_value` uses a restricted safe subset `[A-Za-z0-9._+-]+` and
    MUST NOT contain `/`.
    -   If a value contains other characters, PFXStudy SHALL encode it
        (v1: percent-encoding) before constructing the path.
-   The final directory is always a run leaf directory beginning with
    `r` followed by a monotonically increasing sequence number (`r0001`,
    `r0002`, ...).
    -   The run leaf enables multiple replications for identical axis
        values without changing the semantic meaning of parent
        directories.
-   The run index (`index/`) maps `run_id` ↔ `<semantic path>` for
    discovery and tooling, but semantic paths remain the primary
    user-facing locator.

**Example:**

For a study named `den_sweep` with axis `density ∈ {0.50, 0.55, 0.60}`:

    density=0.50/r0001/
    density=0.55/r0002/

For a 2D sweep with `clock_ps` and `density`:

    clock_ps=320/density=0.50/r0042/

### 3.5 Canonical Run Directory Structure

Run directories are allocated by PFXStudy and populated by PFXCore.

    <study_name>/runs/<semantic path>/
      request.toml
      run.toml
      env.sh
      config/                       # generated entrypoint scripts
        pipeline_driver.tcl
        tool_<stage>.tcl            # optional (stage-specific Tcl)
      stages/
        10_synth/
          logs/
          reports/
          outputs/
          status.json
        20_init/
        30_place/
        40_cts/
        50_route/
        90_harvest/
      current/                      # stable handoff links
      results/
        run_summary.json
        run_summary.csv
      meta/
        run_id.txt
        run_intent.json
        provenance.json
        inputs_manifest.json

#### 3.5.1 Current Working Directories for Tool exeuction

The current working directory for a tool exeuction will be the stage
step. For example, in the above directory example, the invocation and
running of the synthesis step will use "stages/10_synth" as the current
working directory. All file references will be relative to this
location.

------------------------------------------------------------------------

### 3.6 Artifact Ownership Model

  Artifact                     Created By   Purpose
  ---------------------------- ------------ -----------------------------
  study.toml                   PFXStudy     Study definition and layout
  pipeline.toml                PFXStudy     Stage DAG definition
  request.toml                 PFXStudy     Run request
  run.toml                     PFXCore      Frozen resolved config
  env.sh                       PFXCore      Environment capsule
  config/pipeline_driver.tcl   PFXCore      Entry Tcl / driver
  stages/\*                    PFXCore      Stage artifacts
  current/\*                   PFXCore      Canonical handoff links
  run_summary.json             PFXCore      Harvested metrics
  runs.sqlite                  PFXStudy     Run index
  provenance.json              PFXCore      Reproducibility data

------------------------------------------------------------------------

### 3.7 Leaf Run Flow and Pipeline Definition

This subsection defines how PFXCore manages multi-tool, multi-stage
execution within a single leaf run directory.

#### 3.7.1 Overview

A *run* is executed as a directed acyclic graph (DAG) of stages (e.g.,
`synth → init → place → cts → route → harvest`). Each stage consumes
canonical inputs and produces canonical outputs. Stages are executed by
the PFXCore Stage Runner, which invokes tool wrappers and records status
and manifests.

Key properties:

-   Stage definitions are explicit (no implicit ordering).
-   Stage inputs/outputs are contract-defined.
-   Stage execution is idempotent by default (no re-run unless `--force`
    or missing outputs).
-   Stage results are isolated in `stages/<NN_name>/`.
-   Stable handoff uses `current/` symlinks.

#### 3.7.2 pipeline.toml approach

PFXFlow uses a TOML file (`pipeline.toml`) to define the stage pipeline
for a study.

**Study-root pipeline.toml (required, v1):**

-   `<study_root>/pipeline.toml` SHALL exist and defines the pipeline
    used for the entire study by default.
-   If `<study_root>/pipeline.toml` is missing, the study is invalid and
    PFXCore SHALL fail fast.

**Per-run overrides (allowed, v1):**

-   A run MAY include a per-run override pipeline definition by placing
    a `pipeline.toml` inside the run directory
    (`<run_dir>/pipeline.toml`).
-   When present, the per-run pipeline overrides the study pipeline for
    that run only.
-   Overrides are intended for exceptional cases (debug, tool
    workarounds, experimental stages), not for normal DOE operation.

**Pipeline definition precedence (v1):**

1.  `<run_dir>/pipeline.toml` (rare; per-run override)
2.  `<study_root>/pipeline.toml` (required; study-wide pipeline)

#### 3.7.3 pipeline.toml schema (v1)

Example `pipeline.toml`:

``` toml
version = "1.0"

[pipeline]
name = "cadence_genus_innovus_v1"
description = "Genus synth + Innovus init/place/cts/route + harvest"
default_target = "harvest"

# Global conventions used by the stage runner.
[conventions]
stages_dir = "stages"
current_dir = "current"
status_file = "status.json"

# Wrappers are invoked as: <wrapper> <run_dir> <stage_name>
[wrappers]
genus = "pfx_genus_run"
innovus = "pfx_innovus_run"
harvest = "pfx_harvest_run"

[[stage]]
name = "synth"
order = 10
tool = "genus"
wrapper = "genus"
depends_on = []
inputs = ["run.toml", "resolved_inputs/design/*", "resolved_inputs/tech/*"]
outputs = [
  "stages/10_synth/outputs/netlist.v",
  "stages/10_synth/outputs/constraints.sdc"
]
exports = [
  "current/netlist.v=stages/10_synth/outputs/netlist.v",
  "current/constraints.sdc=stages/10_synth/outputs/constraints.sdc"
]

[[stage]]
name = "init"
order = 20
tool = "innovus"
wrapper = "innovus"
depends_on = ["synth"]
inputs = ["current/netlist.v", "current/constraints.sdc", "resolved_inputs/tech/*"]
outputs = ["stages/20_init/outputs/design.enc"]
exports = ["current/design.enc=stages/20_init/outputs/design.enc"]

[[stage]]
name = "place"
order = 30
tool = "innovus"
wrapper = "innovus"
depends_on = ["init"]
inputs = ["current/design.enc"]
outputs = ["stages/30_place/outputs/design.enc"]
exports = ["current/design.enc=stages/30_place/outputs/design.enc"]

[[stage]]
name = "cts"
order = 40
tool = "innovus"
wrapper = "innovus"
depends_on = ["place"]
inputs = ["current/design.enc"]
outputs = ["stages/40_cts/outputs/design.enc"]
exports = ["current/design.enc=stages/40_cts/outputs/design.enc"]

[[stage]]
name = "route"
order = 50
tool = "innovus"
wrapper = "innovus"
depends_on = ["cts"]
inputs = ["current/design.enc"]
outputs = ["stages/50_route/outputs/design.enc"]
exports = ["current/design.enc=stages/50_route/outputs/design.enc"]

[[stage]]
name = "harvest"
order = 90
tool = "harvest"
wrapper = "harvest"
depends_on = ["route"]
inputs = ["stages/**/reports/*", "stages/**/outputs/*"]
outputs = ["results/run_summary.json", "results/run_summary.csv"]
exports = []
```

Schema notes:

-   `order` is used to name stage directories (`10_synth`, `20_init`,

-   `order` specifies nominal sequential ordering only.

-   `depends_on` specifies strict dependency constraints.

-   If `order` and `depends_on` imply conflicting execution order,
    PFXCore SHALL treat this as a fatal configuration error. etc.) and
    to provide stable ordering.

-   `depends_on` defines the DAG edges (ordering + dependency
    enforcement).

-   `inputs` / `outputs` are used for validation and for determining
    up-to-date status.

-   `exports` defines the canonical handoff links created under
    `current/`.

#### 3.7.4 Stage Runner behavior (v1)

The C++ stage runner operates with these rules:

-   A stage is considered **complete** when:
    -   `stages/<NN_name>/status.json` exists and indicates success, AND
    -   all declared `outputs` exist.
-   A stage is considered **runnable** when:
    -   all `depends_on` stages are complete, AND
    -   all declared `inputs` exist.
-   Default behavior is **do not re-run** completed stages.
-   `--force` re-runs a stage and (optionally) invalidates downstream
    stages by deleting their `status.json` (v1 choice: conservative; do
    not delete outputs unless configured).

**Freshness and validity (v1):**

-   A stage is considered up-to-date if and only if:
    -   all declared output files exist, and
    -   `status.json` indicates successful completion.
-   No hashing, timestamp comparison, or automatic invalidation is
    performed in v1.
-   Users must explicitly request re-execution (e.g., `--force`) to
    invalidate prior outputs.

**Grouped stage execution policy:**

-   Stages sharing the same `exec_group` are always executed as a single
    unit.
-   Partial execution within a group (start/stop mid-group) is not
    supported in v1.
-   Declared checkpoint outputs are treated as documentation of
    tool-internal savepoints.
-   Grouped stages cannot be independently re-run.

**Failure handling:**

-   Any stage failure results in immediate termination of the run.
-   Downstream stages are not executed.
-   No automatic retry is performed within PFXCore.

#### 3.7.5 Status recording

Each stage writes `stages/<NN_name>/status.json` containing:

-   stage name, order
-   start/end timestamps
-   wrapper command line
-   tool version summary (best-effort)
-   exit code and success boolean
-   pointers to primary log/report files
-   optional hashes of canonical outputs (future extension)

#### 3.7.6 Tool wrapper contract

Wrappers are responsible for:

-   `cd` into run directory
-   sourcing `env.sh`
-   invoking the tool in batch mode with a single entry Tcl
-   writing logs under `stages/<NN_name>/logs/`
-   writing reports under `stages/<NN_name>/reports/`
-   writing canonical outputs under `stages/<NN_name>/outputs/`
-   returning non-zero on failure

Wrappers do **not** manage dependencies; only the stage runner does.

**Environment inheritance policy:**

-   PFXCore inherits the user environment by default.
-   The generated `env.sh` script SHALL assume a clean baseline
    environment.
-   `env.sh` SHALL overwrite relevant variables (PATH, LD_LIBRARY_PATH,
    tool paths, etc.), not append to them.
-   Site-specific module loading or environment setup is expected to
    occur prior to invoking PFXFlow.

**License variables:**

-   License environment management is out of scope for v1.
-   License coordination is delegated to PFXStudy and site
    infrastructure.

------------------------------------------------------------------------

### 3.8 Design Input Contract

#### 3.8.1 User-Facing Design Specification

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

#### 3.8.2 Filelist Semantics and Merge Policy

PFXFlow standardizes RTL ingestion around an EDA-style filelist. The
user may provide a `design.filelist` (recommended).
`design.include_dirs` and `design.defines` are **additive** and are
merged into a resolved filelist by PFXCore.

The resolved filelist is the only filelist consumed by tools; it
eliminates ambiguity between tool-specific command-line flags and user
conventions.

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

#### 3.8.3 Normalization Rules

PFXCore SHALL canonicalize all RTL and constraints into a run-local
capsule.

PFXCore SHALL:

1.  Expand nested `-f` directives.

2.  Resolve all paths to absolute paths.

3.  Prepend generated `+incdir` and `+define` directives from TOML.

4.  Validate top module.

5.  Order entries deterministically.

6.  Write canonical filelist to:

        resolved_inputs/design/rtl/filelist.f

All tools SHALL consume only the resolved filelist.

#### 3.8.4 Canonical Design Layout

Within `resolved_inputs/design/`:

``` text
resolved_inputs/design/
  rtl/
    filelist.f
    src/                 # optional (copy mode)
  constraints/
    merged.sdc
  config/
    design_resolved.json
```

Notes: - Copy vs symlink policy is configurable (v1 default: symlink for
performance; copy for 'frozen' runs). - `constraints/merged.sdc` is
produced deterministically from `design.sdc_files` in the order
specified.

#### 3.8.5 Design Manifest

`meta/inputs_manifest.json` SHALL include design inputs (RTL, filelists,
SDCs) with source paths, run-local paths, and basic metadata (size,
mtime, optional hash).

### 3.9 Technology Input Contract

#### 3.9.1 Technology Bundle Concept

    All technology data SHALL be referenced through named bundles:

    ``` toml
    [tech]
    bundle = "GENERIC_ADV_NODE_V1"
    corner = "tt"

Bundles are defined in a managed catalog external to studies.

#### 3.9.2 Bundle Definition Schema

Bundles are stored in a managed catalog (site-controlled) and expanded
by PFXCore into explicit file sets. Technology references remain
anonymous in this document.

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

#### 3.9.3 Normalization Rules

PFXCore SHALL expand the bundle into a run-local `resolved_inputs/tech/`
capsule and validate all required components.

PFXCore SHALL:

1.  Load bundle definition.
2.  Resolve all referenced files.
3.  Validate required components.
4.  Normalize units.
5.  Generate tool-compatible views.
6.  Populate resolved directories.

#### 3.9.4 Canonical Technology Layout

Within `resolved_inputs/tech/`:

    resolved_inputs/tech/
      liberty/
      lef/
        tech.lef
        cells.lef
        macros.lef
      route/
        cadence_tech.lef
        synopsys.tf
      pex/
        qrcTech.tch
        starrc.tch
      mmmc/
        views.tcl
      config/
        tech_resolved.json

Notes: - The *router configuration* component is explicitly represented
under `route/`. - The *PEX tech* component is explicitly represented
under `pex/`.

#### 3.9.5 Technology Manifest

`meta/inputs_manifest.json` SHALL include technology inputs (LEF,
liberty, route tech files, extraction tech files, MMMC) with source
paths, run-local paths, and basic metadata (size, mtime, optional hash).

### 3.10 Study Resource Limits (v1)

PFXStudy enforces study-level resource limits to control concurrency and
cluster load. Limits are defined in a TOML file at the study root:

    <study>/limits.toml

Example:

``` toml
[concurrency]
max_runs = 50

[concurrency.per_stage]
genus = 20
innovus = 6
harvest = 50
```

Rules (v1):

-   Concurrency limits are defined **per study** (global within that
    study).
-   Per-stage limits are supported and applied by PFXStudy when
    scheduling work.
-   PFXCore does not enforce concurrency limits; it executes a single
    run deterministically.

### 3.11 Schema Evolution and Migration (v1)

**Schema evolution policy (v1):**

-   Schema versions are checked at runtime.
-   If an older schema is detected, PFXCore SHALL:
    1.  issue a warning,
    2.  attempt an automatic migration when feasible,
    3.  fail the run if migration is required but not possible or fails.

------------------------------------------------------------------------

## 3.12 Variable Propagation Model (v1)

# PFXFlow Specification Delta --- Variable Propagation (run.toml → pfx_vars.tcl)

Version: Draft for integration after v0.8.1

------------------------------------------------------------------------

## 1. Purpose

This delta defines the normative mechanism by which Design of
Experiments (DOE) variables and run-specific parameters are propagated
from `run.toml` into stage-local Tcl execution environments via
`pfx_vars.tcl`.

This mechanism is owned by **PFXCore** and is mandatory for v1.

Wrappers SHALL NOT implement variable parsing or translation.

------------------------------------------------------------------------

## 2. Responsibility Assignment

### 2.1 PFXStudy

PFXStudy SHALL:

-   Generate `run.toml` for each leaf run directory.
-   Populate all DOE axes, design identifiers, technology identifiers,
    and user-defined control variables.

### 2.2 PFXCore

PFXCore SHALL:

-   Parse `run.toml` prior to executing each stage.

-   Generate a stage-local Tcl variable file:

        <run_dir>/stages/<order>_<stage>/pfx_vars.tcl

-   Optionally generate a stage entry script:

        <run_dir>/stages/<order>_<stage>/pfx_entry.tcl

-   Ensure that `pfx_vars.tcl` is sourced before any user stage script
    executes.

### 2.3 Wrappers

Wrappers SHALL:

-   Execute the Tcl entry script provided by PFXCore.
-   NOT parse `run.toml`.
-   NOT generate `pfx_vars.tcl`.

------------------------------------------------------------------------

## 3. run.toml Variable Contract (v1)

`run.toml` SHALL contain the following top-level sections.

All sections are mandatory unless otherwise stated.

### 3.1 \[run\]

``` toml
[run]
run_id        = "run_0001"
study_name    = "den_sweep"
semantic_path = "clock_ps=320/density=0.55"
created_utc   = "2026-02-05T14:22:00Z"
```

### 3.2 \[doe\]

DOE axis values.

``` toml
[doe]
clock_ps = 320
density  = 0.55
```

### 3.3 \[design\]

``` toml
[design]
name       = "my_design"
top        = "top_module"
filelist   = "resolved_inputs/design/filelist.f"
language   = "systemverilog"
```

### 3.4 \[technology\]

``` toml
[technology]
bundle = "Z22"
corner = "typ"
```

### 3.5 \[vars\] (User Variables)

Optional user-defined variables.

``` toml
[vars]
vt_flavor      = "LVT"
extra_effort   = true
max_fanout     = 32
target_slack   = -0.02
```

### 3.6 \[paths\] (Optional)

Optional resolved paths.

``` toml
[paths]
reports_dir = "reports"
scratch_dir = "scratch"
```

------------------------------------------------------------------------

## 4. Tcl Variable Generation Rules

PFXCore SHALL generate `pfx_vars.tcl` according to the following rules.

### 4.1 Namespace

All variables SHALL be placed in a single associative array:

``` tcl
pfx(...)
```

### 4.2 Mapping Rules

  TOML Type   Tcl Representation
  ----------- --------------------
  Integer     integer literal
  Float       float literal
  String      quoted string
  Boolean     0 / 1

### 4.3 Variable Names

Variables SHALL be named using:

    pfx(<section>.<key>)

Example:

    [doe]
    clock_ps = 320

→

    set pfx(doe.clock_ps) 320

### 4.4 Reserved Variables

PFXCore SHALL always generate:

    pfx(run.run_id)
    pfx(run.study_name)
    pfx(run.semantic_path)

------------------------------------------------------------------------

## 5. pfx_vars.tcl Format

### 5.1 Header

Each file SHALL begin with:

``` tcl
# Auto-generated by PFXCore
# Source: run.toml
# Do not edit
```

### 5.2 Content

Each variable SHALL be generated as:

``` tcl
set pfx(<name>) <value>
```

------------------------------------------------------------------------

## 6. Optional Entry Script (pfx_entry.tcl)

If enabled, PFXCore SHALL generate:

``` tcl
# Auto-generated entry script

source pfx_vars.tcl
source scripts/<stage>.tcl
```

Wrappers SHALL execute this script instead of the raw user script.

------------------------------------------------------------------------

## 7. Full Example

### 7.1 Example run.toml

``` toml
[run]
run_id        = "run_0001"
study_name    = "den_sweep"
semantic_path = "clock_ps=320/density=0.55"
created_utc   = "2026-02-05T14:22:00Z"

[doe]
clock_ps = 320
density  = 0.55

[design]
name     = "aes_core"
top      = "aes_top"
filelist = "resolved_inputs/design/filelist.f"
language = "systemverilog"

[technology]
bundle = "Z22"
corner = "typ"

[vars]
vt_flavor    = "LVT"
extra_effort = true
max_fanout   = 32
target_slack = -0.02
```

### 7.2 Generated pfx_vars.tcl

``` tcl
# Auto-generated by PFXCore
# Source: run.toml
# Do not edit

set pfx(run.run_id) "run_0001"
set pfx(run.study_name) "den_sweep"
set pfx(run.semantic_path) "clock_ps=320/density=0.55"

set pfx(doe.clock_ps) 320
set pfx(doe.density) 0.55

set pfx(design.name) "aes_core"
set pfx(design.top) "aes_top"
set pfx(design.filelist) "resolved_inputs/design/filelist.f"
set pfx(design.language) "systemverilog"

set pfx(technology.bundle) "Z22"
set pfx(technology.corner) "typ"

set pfx(vars.vt_flavor) "LVT"
set pfx(vars.extra_effort) 1
set pfx(vars.max_fanout) 32
set pfx(vars.target_slack) -0.02
```

------------------------------------------------------------------------

## 8. Compliance

Any implementation of PFXCore claiming v1 compliance SHALL implement
this variable propagation mechanism.

Wrappers that depend on environment variables or custom parsing are
non-compliant.

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

  ---------------------------------------------------------------------
  Layer                          Objects
  ------------------------------ --------------------------------------
  PFXStudy                       Study, StudyLayout, Run, StudyIndex

  PFXCore                        CFG, DesignSpec, TechSpec,
                                 HarvestSpec, RunIntent, StageRunner

  Tcl                            CFG, VARS, PFX

  Storage                        Manifests, Index
  ---------------------------------------------------------------------
