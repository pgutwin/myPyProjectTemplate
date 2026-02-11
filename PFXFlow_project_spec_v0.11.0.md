### Change Log

**Version:** v0.11.0

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
-   2026-02-05 -- Added scripts/ directory to run layout; removed
    pipeline.toml exec semantics (v0.8.6) exec.argv model (v0.8.6)
-   2026-02-05 -- Rewrote Section 3.7.2 with normative pipeline.toml
    syntax and semantics; moved example to non-normative role (v0.8.7)
-   2026-02-05 -- Removed directory and current_dir convention;
    eliminated related stage outputs semantics to avoid confusion with
    working directory (v0.8.8)
-   2026-02-05 -- Restored and formalized variable propagation; defined
    stage_launch.sh contract; added run.toml and status.json schemas;
    clarified logging and execution semantics (v0.9.9)
-   2026-02-06 -- A bunch of manual edits to clean up so much... so much
-   2026-02-09 -- Added new sections on design and technology specification; 
	Updated run.toml specification; Fixing numerous small conflicts in spec;
-   2026-02-10 -- Continute to resolve ambiguities, over and over again.
-   2026-02-11 -- More ambiguitie resolution
-   2026-02-11 -- Added Section 3.17: Language Export Specification defining 
    formal rules for exporting TOML configuration to Tcl and Python with 
    flattening rules, type mappings, naming conventions, and escaping rules (v0.10.9)
	Also cleaned up other sections refering to tcl variable format
-   2026-02-11 -- Added Section 3.18: Process Management and Cleanup with normative 
	requirements for process group management, timeout handling, orphan cleanup, 
	stale process detection, and processes.json artifact specification; added 
    stage_timeout_seconds to run.toml; added timeout and interrupted states to 
    status.json; added G14 goal for subprocess cleanup (v0.11.0)

------------------------------------------------------------------------

## 1. Project Overview

### 1.1 Problem Statement

Modern commercial EDA flows require complex, multi-layer configuration
spanning shell scripts, Makefiles, stage launch scripts, and Tcl runtime
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
    materializes, executes, and optionally harvests individual runs.

-   **PFXStudy**\
    A study-level orchestration and user interface layer (CLI + future
    GUI) that manages DOE workflows, directory layout, scheduling,
    licensing, indexing, and aggregation.

The user-facing interface is exposed through:

pfxflow `<verb>` \[options\]

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
-   G14: Ensure robust cleanup of sub-process trees spawned by EDA tools.

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
2.  User invokes `pfxcore run` or `pfxcore run --stage <x>`.
3.  Stage prerequisites are enforced.
4.  Stage is executed.
5.  Outputs and metadata are inspected.

#### UC3: Technology Evaluation

Multiple technology variants are evaluated through overlays and
optional harvested metrics.

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

→ Index → PFXStudy

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
-   Tcl Drivers (generated)
-   Hook Executor
-   Language Exporters (Tcl, Python)
-   Process Manager (cleanup, timeout, orphan detection)


#### 3.3.1 PFXCore CLI

The PFXCore executable shall be named `pfxcore`.

The minimal CLI interface shall be
- `run` will look for requird collatral files (`run.toml`, `pipeline.toml`, etc.) and proceed with execution
- `status` will interrogate the `status.json` files available and report the last recorded stage and success/failure of that stage. The last recorded stage is defined as the highest `order` stage with a valid `status.json` file. 
   If no `status.json` files exist at all, report "no status available". 
- `--force` will restart the execution, ignoring any existing execution output and overwriting existing files.
- `--silent` will run without any output to the command line
- `--log <filename>` will mirror any `pfxcore` output to file <filename>. The use of `--silent` together with `--log` implies that all output goes to a log file rather than the terminal.
- Running `pfxcore` without any arguments will be equivilent to using the flag `run`
- During excecution, `pfxcore` will report stage launch and stage completion to the terminal with a single line for each event stating the stage name and action.
- `pfxcore` will terminate when the last stage defined in `pipeline.toml` is complete.


------------------------------------------------------------------------

### 3.4 Canonical Study Directory Structure

The study root directory is created and owned by PFXStudy.

`<study_name>`/ 
   study.toml 
   pipeline.toml \# required (study-widepipeline) 
   index/ 
   runs.sqlite 
   logs/ 
   stage outputs/ 
   templates/

**Template definition (v1):**

-   A *template* is a reusable TOML fragment used by PFXStudy to
    generate run-specific configuration (most commonly `run.toml`) 
	for many runs in a study.
-   Templates live under `<study_root>/templates/` and are referenced by
    name from `study.toml`.
-   Templates may declare a single parent template to inherit defaults
    and override specific fields.
-   Templates are owned and managed by PFXStudy

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
never parses templates**; it consumes only resolved TOML (`run.toml`).

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
| placeholder := "${" var_name [ " | " default ] "}" |
var_name := [A-Za-z0-9_]+
default := any sequence of characters not containing "}" (interpreted using the same typing rules as substitution)
```

Examples:

| - `${clock_ps | 320}` \|

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

-   integer: `320` \| - boolean: `true | false` \|
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
    `<run_dir>/run.toml`).
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

#### 3.4.1 `<semantic path>` definition (v1)

PFXFlow uses a **semantic directory hierarchy** so that users can locate
runs by experimental intent without consulting the run index.

A `<semantic path>` is a relative path rooted at the study's `runs/`
directory that encodes the DOE variable assignments for a run.

**Grammar (conceptual):**

`<semantic path>` := `<axis_dir>`+ "/" `<run_leaf>` `<axis_dir>` :=
`<axis_name>` "=" `<axis_value>` `<run_leaf>` := "r" `<run_seq>`
\["\_\_" `<short_tag>`\]

**Rules (v1):**

-   Each DOE axis contributes exactly one `axis_dir` segment of the form
    `name=value`.
-   Axis order is defined by `study.toml` (the DOE layout definition).
    The order must be stable for the lifetime of the study.
-   `axis_name` uses `[A-Za-z0-9_]+`.
-   `axis_value` uses a restricted safe subset `[A-Za-z0-9._+-]+` and
    MUST NOT contain `/`.
-   If a value contains other characters, PFXStudy SHALL encode it (v1:
    percent-encoding) before constructing the path.
-   The final directory is always a run leaf directory beginning with
    `r` followed by a monotonically increasing sequence number (`r0001`,
    `r0002`, ...).
-   The run leaf enables multiple replications for identical axis values
    without changing the semantic meaning of parent directories.
-   The run index (`index/`) maps `run_id` ↔ `<semantic path>` for
    discovery and tooling, but semantic paths remain the primary
    user-facing locator.

**Example:**

For a study named `den_sweep` with axis `density ∈ {0.50, 0.55, 0.60}`:

   density=0.50/r0001/ 
   density=0.55/r0002/
   density=0.60/r0003/

For a 2D sweep with `clock_ps` and `density`:

   clock_ps=320/density=0.50/r0042/

### 3.5 Canonical Run Directory Structure

Run directories are allocated and partially populated by PFXStudy. 
PFXCore shall consume prepopulated information in the run directory.

`<study_name>`/runs/`<semantic path>`/ 
	design.toml
	tech.toml
	env.sh 
	inputs/
	   design/
	   tech/
	pipeline.toml
	run.toml 
	scripts/ 
	stages/ 
	   10_synth/ 
	      reports/ 
          status.json 
	      outputs/
		  pfx_vars.tcl
	   20_init/ 
	      reports/ 
          status.json 
	      outputs/
		  pfx_vars.tcl
	   30_place/ 
	      reports/ 
          status.json 
	      outputs/
		  pfx_vars.tcl
	   40_route/ 
	      reports/ 
          status.json 
	      outputs/
		  pfx_vars.tcl
    results/ 


#### 3.5.1 Stage Directory and Current Working Directories for Tool exeuction

The "stage directory" is synonymous with "current working directory".

The stage directory name SHALL be `<order>_<name>` with `order` rendered
in base-10 with no padding.

The current working directory for a tool exeuction will be the stage
step. For example, in the above directory example, the invocation and
running of the synthesis step will use "stages/10_synth" as the current
working directory. 


**Important:** The tool's *current working directory* is the stage directory, but **all paths declared in TOML files are run-directory relative** unless stated otherwise. PFXCore SHALL export the canonical absolute run directory path as `pfx_run_dir` in `pfx_vars.tcl` and `pfx_vars.py`. Stage scripts SHALL resolve run-relative paths by prefixing them with `$pfx_run_dir` (Tcl) or `pfx_run_dir` (Python).
------------------------------------------------------------------------


This section defines ownership and responsibility for all primary
artifacts.

| Artifact      | Created By | Purpose                             |
|---------------|------------|-------------------------------------|
| pipeline.toml | PFXStudy   | Stage DAG definition                |
| run.toml      | PFXStudy   | Frozen resolved configuration       |
| design.toml   | PFXStudy   | Specification of design details     |
| tech.toml     | PFXStudy   | Specification of technology details |
| env.sh        | PFXStudy   | exist before PFXCore execution.     |
| stages/\*     | PFXCore    | Stage artifacts and execution       |
| outputs       | PFXCore    | Stage artifacts and execution       |
| reports       | PFXCore    | State artifacts and execution       |



### 3.7 Leaf Run Flow and Pipeline Definition

This subsection defines how PFXCore manages multi-tool, multi-stage
execution within a single leaf run directory.

#### 3.7.1 Overview

A *run* is executed as a directed acyclic graph (DAG) of stages (e.g.,
`synth → init → place → cts → route → harvest`). Each stage consumes
canonical inputs and produces canonical outputs. Stages are executed by
the PFXCore Stage Runner, which invokes stage launch scripts and records
status and manifests.

Key properties:

-   Stage definitions are explicit (no implicit ordering).
-   Stage inputs/outputs are contract-defined.
-   Stage execution is idempotent by default (no re-run unless `--force`
    or missing outputs).
-   Stage results are isolated in `stages/<NN_name>/`.

#### 3.7.2 pipeline.toml schema (v1)

This section defines the normative syntax and semantics of
`pipeline.toml`. All v1-compliant implementations SHALL conform to this
schema. Examples are illustrative and non-normative.

*NOTE:* the `pipeline.toml` file is immutable once created. PFXCore should
consider `pipeline.toml` as a read-only artifact.

### 3.7.2.1 File Structure

A `pipeline.toml` file SHALL contain:

-   One `[pipeline]` table.
-   Zero or one `[conventions]` table.
-   One or more `[[stage]]` tables.

### 3.7.2.2 \[pipeline\] Table

Required fields:

| Field | Type   | Description         |
|-------|--------|---------------------|
| name  | string | Pipeline identifier |


Optional fields:

| Field           | Type   | Description                         |
|-----------------|--------|-------------------------------------|
| description     | string | Human-readable description          |
| default\_target | string | Defult terminal stage name          |
| schema_version  | string | Pipeline schema version (default 1) |
|                 |        |                                     |


### 3.7.2.3 \[conventions\] Table (Optional)

The `[conventions]` table defines pipeline-wide defaults used by PFXCore
when materializing stage directories and filenames.

| Field                | Type   | Default       | Description                  |
|----------------------|--------|---------------|------------------------------|
| stages\_dir          | string | "stages"      | Stage directory root         |
| stages\_inputs\_dir  | string | "inputs"      | Stage inputs directory root  |
| stages\_outputs\_dir | string | "outputs"     | Stage outputs directory root |
| status\_file         | string | "status.json" | Stage status filename        |


### 3.7.2.4 \[\[stage\]\] Tables

Each pipeline SHALL define one or more stages.

Required fields:

| Field | Type   | Description            |
|-------|--------|------------------------|
| name  | string | Unique stage name      |
| order | int    | Strict execution order |


Optional fields:

| Field      | Type            | Default | Description           |
|------------|-----------------|---------|-----------------------|
| depends_on | array\[string\] | \[\]    | Stage dependency list |
| inputs     | array\[string\] | \[\]    | Input file patterns   |
| outputs    | array\[string\] | \[\]    | Declared output files |


Stage names SHALL be unique. Order values SHALL be unique and
increasing. `order` values are for naming. `depends_on` values form 
the execution graph. A conflict between `order` and `depends_on` is a fatel error.
The stage `order` value referred to in a `depends_on` reference SHALL be of lower value, and
if not SHALL be a fatel error.

### 3.7.2.5 \[stage.exec\] Table

Each stage SHALL define exactly one `stage.exec` table.

Required fields:

| Field | Type            | Description                     |
|-------|-----------------|---------------------------------|
| argv  | array\[string\] | Tool invocation argument vector |


Optional fields:

| Field       | Type            | Description                       |
|-------------|-----------------|-----------------------------------|
| env         | table\[string\] | Environment overrides             |


### 3.7.2.6 Path Resolution Rules

-   The tool *current working directory* is the stage directory: `stages/<NN>_<stage>/`.
-   `exec.argv` is executed with the working directory set to the stage directory.
-   Relative paths inside `exec.argv` are resolved from the stage directory.
-   Stage `inputs` and `outputs` paths are **run-directory relative** (i.e., relative to `<run_dir>/`).
-   PFXCore SHALL export `FPX_RUN_DIR` (absolute path) so stage scripts can convert any run-relative path into an absolute path when needed.

### 3.7.2.7 Execution Semantics

Before executing any stage, PFXCore SHALL verify that the following run prerequisites exist:

- `env.sh` (generated by PFXStudy)
- `scripts/` directory (populated by PFXStudy)

No other filesystem checks are required before beginning stage launch sequence.

For each stage, PFXCore SHALL:

1.  Verify dependency completion.
2.  Generate `stage_launch.sh`.
3.  Execute `exec.argv` via `stage_launch.sh`.
4.  Capture the exit status.
5.  Validate declared outputs.
6.  Update `status.json`.

A stage SHALL be considered successful only if:

-   The execution returns exit code 0, and
-   All declared outputs exist.

If a stage does not complete successfully, PFXCore SHALL
stop pipeline execution immediately, emit an error message 
and exit with a nonzero completion code.

### 3.7.2.8 Export Semantics

In v1, stages SHALL exchange data exclusively through declared `outputs`
paths.

Use of directory-level export aliases (e.g., `current/`) is not
supported.

### 3.7.2.9 Validation Rules

PFXCore SHALL treat the following as fatal errors:

-   Missing required fields.
-   Duplicate stage names or order values.
-   Empty `exec.argv`.
-   Missing declared outputs.
-   Cyclic stage dependencies.

Missing optional fields SHALL use default values.

### 3.7.2.10 Versioning

If `schema_version` is present and unsupported, PFXCore SHALL reject the
file.

#### 3.7.3 pipeline.toml schema (v1)

``` toml
[pipeline]
name = "default_pdk_flow"
description = "genus synth + innovus init/place + harvest"
default_target = "harvest"
schema_version = "1"

[conventions]
stages_dir = "stages"
status_file = "status.json"

[[stage]]
name = "synth"
order = 10
depends_on = []
inputs = ["run.toml", "inputs/design/*", "inputs/tech/*"]
outputs = [
  "stages/10_synth/outputs/netlist.v",
]

[stage.exec]
argv = ["genus", "-batch", "-files", "../../scripts/synth.tcl"]

[[stage]]
name = "init"
order = 20
depends_on = ["synth"]
inputs = [
  "stages/10_synth/outputs/netlist.v",
]
outputs = ["stages/20_init/outputs/design.enc"]

[stage.exec]
argv = ["innovus", "-batch", "-files", "../../scripts/init.tcl"]

[[stage]]
name = "place"
order = 30
depends_on = ["init"]
inputs = ["stages/20_init/outputs/design.enc"]
outputs = ["stages/30_place/outputs/design.enc"]

[stage.exec]
argv = ["innovus", "-batch", "-files", "../../scripts/place.tcl"]

[[stage]]
name = "route"
order = 40
depends_on = ["place"]
inputs = ["stages/30_place/outputs/design.enc"]
outputs = ["stages/40_route/outputs/design.enc"]

[stage.exec]
argv = ["innovus", "-batch", "-files", "../../scripts/route.tcl"]

[[stage]]
name = "harvest"
order = 99
depends_on = ["route"]
inputs = ["stages/40_route/outputs/design.enc"]
outputs = ["outputs/harvest.json"]

[stage.exec]
argv = ["python3", "../../scripts/harvest.py", "--in", "../../stages/40_route/outputs/design.enc", "--out", "../../outputs/harvest.json"]
```

### 3.8 Design Sepcification Specification, Syntax and Semantics (v1)

### 3.8.1 Purpose 

`design.toml` defines the design bundle for a run. It binds tool-agnostic design metadata (top module, filelists, constraints) to a concrete directory tree under:

```
<run_dir>/inputs/design/
```

PFXCore only requires that `inputs/design/` exists. PFXStudy is responsible for populating it.

### 3.8.2 Location

`design.toml` SHALL be located at:

```
<run_dir>/design.toml
```

`run.toml` SHALL reference it:

```toml
[design]
spec_file = "design.toml"
```

### 3.8.3 Required Tables

`design.toml` SHALL contain:

- `[design]` (required)
- `[sources]` (required)
- `[constraints]` (optional)
- `[tools.<tool_name>]` (optional)

### 3.8.4 `[design]` Table

| Field           | Type   | Required | Semantics                            |
|-----------------|--------|---------:|--------------------------------------|
| design_top      | string |      yes | Top module / design name             |
| design_nickname | string |       no | Nickname or short name of design     |
| rtl_type        | string |       no | e.g., `"verilog"`, `"systemverilog"` |
| schema_version  | string |       no | Defaults to `"1"`                    |

### 3.8.5 `[sources]` Table

All paths are **run-directory relative** unless otherwise stated.

| Field           | Type          | Required | Semantics                                   |
|-----------------|---------------|---------:|---------------------------------------------|
| hdl_filelist    | array[string] |      yes | Leaf HDL file name list                     |
| hdl_search_dirs | array[string] |       no | Directories to search for files in filelist |
| defines         | array[string] |       no | Preprocessor defines                        |
| rtl_root        | string        |       no | Optional base directory for RTL             |

Semantics:
- PFXCore does not parse RTL; it exports these paths/flags so tool scripts can consume them.
- `hdl_filelist` and `hdl_search_dirs` are arrays of strings.
- Directories listed in `hdl_search_dirs` are relative to run directory.

### 3.8.6 `[constraints]` Table (Optional)

| Field           | Type          | Required | Semantics                     |
|-----------------|---------------|---------:|-------------------------------|
| sdc\_file       | string        |       no | SDC constraints file          |
| clocks          | array[string] |       no | Optional list of clock names  |
| clock_period_ps | int           |       no | Optional nominal clock period |

Semantics:
- These values exist for tool scripts and traceability.

### 3.8.7 Optional Tool Overrides: `[tools.<tool_name>]`

Same semantics as in `tech.toml`: tool-specific knobs may be recorded and selectively exported, but PFXCore does not interpret them.


### 3.8.8 Example `design.toml`

```toml
[design]
design_top = "cpu_core"
design_nickname = "aka_core"
rtl_type = "systemverilog"
schema_version = "1"

[sources]
hdl_filelist = ["aka_cpu_core.sv","aka_cpu_assist.sv","custom_blocks.sv"]
hdl_search_dirs = ["inputs/design/rtl/","inputs/design/rtl/include"]
defines = ["SYNTH", "USE_FASTRAM"]

[constraints]
sdc_file = "inputs/design/constraints/aka_constraints.sdc"

[tools.genus]
retime = true
```

## 3.9 Technology Specificaiton Specifics, Syntax and Semantics (v1)

### 3.9.1 Purpose

`tech.toml` defines the technology bundle for a run. It binds tool-agnostic technology metadata (corner, PVT, naming) to a concrete directory tree under the run directory:

```
<run_dir>/inputs/tech/
```

PFXCore **does not validate** the contents of the bundle; it only requires that:

- `<run_dir>/inputs/tech/` exists (and is a directory)

PFXStudy is responsible for populating the bundle.

### 3.9.2 Location

`tech.toml` SHALL be located at:

```
<run_dir>/tech.toml
```

`run.toml` SHALL reference it:

```toml
[technology]
spec_file = "tech.toml"
```

### 3.9.3 Required Tables

`tech.toml` SHALL contain:

- `[tech]` (required)
- `[collateral]` (required)
- `[tools.<tool_name>]` (optional)

### 3.9.4 `[tech]` Table

| Field          | Type   | Required | Semantics                                                   |
|----------------|--------|---------:|-------------------------------------------------------------|
| name           | string |      yes | Technology bundle identifier (human meaningful)             |
| corner         | string |       no | Corner name (e.g., tt, ss, ff, etc.)                        |
| voltage        | float  |       no | Nominal voltage (V) for informational/traceability use      |
| temperature_c  | float  |       no | Nominal temperature (°C) for informational/traceability use |
| schema_version | string |       no | Defaults to `"1"`                                           |

Semantics:
- `name` is metadata. PFXCore does not interpret it.

### 3.9.5 `[collateral]` Table

`[collateral]` binds logical technology views to directories under `inputs/tech/`. All values are **run-directory relative paths**.

| Field           | Type          | Required | Semantics                                               |
|-----------------|---------------|---------:|---------------------------------------------------------|
| lef_dirs        | array[string] |      yes | Directories containing LEF/tech LEF                     |
| lef_files       | array[string] |      yes | List of LEF files                                       |
| router_ctl_file | string        |      yes | Path and file name of router control file               |
| lib_dirs        | array[string] |      yes | List of directories containing Liberty timing libraries |
| lib_files       | array[string] |      yes | List of Liberty files                                   |
| pex_file        | string        |      yes | Path and file containing QRC/RC models                  |
| mmmc_dir        | string        |       no | Directory containing MMMC files (if used)               |
| pdk_misc_dir    | string        |       no | Optional directory for tool-specific collateral         |

Semantics:
- PFXStudy populates these directories; PFXCore does not check file presence.
- Paths are used only for **variable export** and/or for tool scripts to locate assets.
- Directory fields in `lef_dirs`, `router_ctl_file`, `lib_dirs`, `pex_file`, `mmmc_dir`, and `pdk_misc_dir` are relative to the run directory.

### 3.9.6 Optional Tool Overrides: `[tools.<tool_name>]`

Tool-specific settings may be included for traceability and variable export.

Example:

```toml
[tools.genus]
effort = "high"
use_physical = true

[tools.innovus]
route_effort = "high"
```

Semantics:
- PFXCore MAY export selected values to `pfx_vars.tcl` **only if** they meet export restrictions (see below).
- PFXCore MUST NOT enforce any tool semantics.

### 3.9.8 Example `tech.toml`

```toml
[tech]
name = "ADV14_GENERIC_V1"
corner = "tt"
voltage = 0.70
temperature_c = 25
schema_version = "1"

[collateral]
root = "inputs/tech"
lef_dirs = ["inputs/tech/lef"]
lef_files = ["adv14_6t.lef","adv16_6t.special.lef"]
router_ctl_file = "inputs/tech/lef/adv16_6t.tech.lef"
lib_dirs = ["inputs/tech/lib"]
lib_files = ["adv14_6t.lib","adv14_6t.special.lib"]
pex_file = "inputs/tech/adv14.qrc"
mmmc_dir = "inputs/tech/mmmc"

[tools.genus]
effort = "high"

[tools.innovus]
route_effort = "high"
```


### 3.10 Study Resource Limits (v1)

PFXStudy enforces study-level resource limits to control concurrency and
cluster load. Limits are defined in a TOML file at the study root:

`<study>`/limits.toml

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

1.  fail the run

------------------------------------------------------------------------

## 3.12 Variable Propagation Model

**Note:** This section provides a high-level overview of variable export. The complete, normative specification for language export including detailed flattening rules, type mappings, escaping rules, and support for both Tcl and Python export is defined in **Section 3.17: Language Export Specification**. In case of conflict, Section 3.17 takes precedence.

PFXCore generates `pfx_vars.tcl` and `pfx_vars.py` from `run.toml` and stage context.

### 3.12.1 Supported Export Data Model

The variable model exported into `pfx_vars.tcl` is a **flat key/value map**.

While TOML input files (`run.toml`, `pipeline.toml`, `design.toml`, `tech.toml`) 
MAY contain structured tables and arrays, only **scalar values and arrays** that 
can be flattened into a single key/value mapping are supported for export.

The exported variable model has the following constraints:

- Exported variables form a flat key/value namespace
- Nested Tcl data structures are NOT supported
- TOML tables are flattened into dot-separated keys during export
- Arrays are exported as Tcl lists
- Keys MUST conform to the character set defined in Section 3.12.5
- Any value or structure that cannot be flattened according to Section 3.12.6 SHALL be rejected

### 3.12.2 Value Restrictions

Variable values containing special characters SHALL be properly escaped according to the rules defined in Section 3.17.5.3 (Tcl) and Section 3.17.6.3 (Python).

Special characters include:
- Dollar signs (`$`)
- Quotes (`"` or `'`)
- Newlines
- Backslashes (`\`)
- Tcl-specific: square brackets (`[`, `]`)

See Section 3.17 for complete escaping specifications.

### 3.12.3 Tcl Emission Format

Variables SHALL be emitted with the `pfx_` prefix convention defined in Section 3.17.

Example format:
```
set pfx_design_name "my_core"
set pfx_timing_setup_margin 0.1
```

For complete emission rules including array handling, escaping, and reserved word handling, see Section 3.17.5.

### 3.12.4 Export Sources

By default, PFXCore SHALL export **all eligible variables** from the following specification files into `pfx_vars.tcl` and `pfx_vars.py`:

* `run.toml`
* `pipeline.toml`
* `design.toml`
* `tech.toml`

There is no selective export mechanism in v1. All variables that satisfy the supported data model SHALL be exported to both Tcl and Python formats according to the rules in Section 3.17.

### 3.12.5 Reserved Exported Variables

PFXCore SHALL always export the following reserved variables (even if not present in any TOML input file):

- `pfx_run_dir` — canonical absolute path to the run directory.
- `pfx_stage_name` — current stage name.
- `pfx_stage_order` — current stage order value.
- `pfx_stage_dir` — canonical absolute path to the stage directory (`<run_dir>/stages/<NN>_<stage>/`).



Eligibility is determined solely by the rules in Sections 3.12.1 and 3.12.2.

---

### 3.12.6 Key Character Set

Exported variable keys MUST match the following character set:

* Letters (`A–Z`, `a–z`)
* Digits (`0–9`)
* Underscore (`_`)
* Period (`.`)
* Dash (`-`)

Formally, exported keys MUST match:

```
[A-Za-z0-9._-]+
```

Any key that does not conform SHALL cause execution failure.

This restriction applies to:

* Table names
* Field names
* Stage names (when used in variable keys)

---

### 3.12.7 TOML to Tcl Variable Name Mapping

Variables are exported by flattening TOML key paths into a single dot-separated key, prefixed by the source file namespace.

The general mapping rule is:

```
<prefix>.<toml_key_path>  →  set pfx_<prefix>_<toml_key_path> {value}
```

Where:

| Source File     | Prefix     |
| --------------- | ---------- |
| `run.toml`      | `run`      |
| `pipeline.toml` | `pipeline` |
| `design.toml`   | `design`   |
| `tech.toml`     | `tech`     |



PFXCore SHALL parse all TOML input files using standard TOML semantics. Each scalar value defined in a TOML file produces a fully qualified TOML key path as defined by the TOML specification (e.g., `a.b.c`).

When exporting values to the Tcl variable namespace, PFXCore SHALL prefix every exported key with a namespace corresponding to the source file from which the value was read (e.g., `run`, `pipeline`, `design`, `tech`). This prefix is determined solely by the identity of the source file and is independent of the TOML table structure within that file.

The exported Tcl variable name SHALL therefore have the form:

```
<prefix>_<toml_key_path>
```

where `<toml_key_path>` is the key path produced by standard TOML parsing, and `<prefix>` is the file namespace assigned by PFXCore. The prefix SHALL NOT be inferred from, derived from, or dependent on the first (or any) TOML table name within the file.

---

#### 3.12.7.1 Table Flattening

Using purely syntactic/non-normative values, 
a scalar value at TOML path for `pipeline.toml`:

```
[exec.a]
b = value
[exec.c]
d = anotherValue
```

The exported Tcl variable SHALL be:

```
set pfx_pipeline_exec_a_b {value}
set pfx_pipeline_exec_c_d {anotherValue}
```

Nested tables are permitted **only for the purpose of flattening**. The final flattened key MUST satisfy the key character set rules.

---

#### 3.12.7.2 Arrays

TOML arrays SHALL be exported as Tcl lists, preserving order.

Example:

```toml
[design.sources]
filelists = ["a.f", "b.f"]
```

Exports:

```tcl
set pfx_design_sources_filelists {a.f b.f}
```

---

#### 3.12.7.3 Pipeline Stage Mapping

`pipeline.toml` stages are arrays of tables (`[[stage]]`). For variable export, stages are addressed **by stage name**, not by index.

Given:

```toml
[[stage]]
name = "synth"
order = 10

  [stage.exec]
  argv = ["genus", "-files", "scripts/synth.tcl"]
```

The following variables SHALL be exported:

```tcl
set pfx_pipeline_stage_synth_order {10}
set pfx_pipeline_stage_synth_exec_argv {genus -files scripts/synth.tcl}
```

Stage names MUST conform to the key character set rules in Section 3.12.5.

---

### 3.12.8 Failure Semantics

PFXCore SHALL fail execution prior to stage launch if:

* Any variable key violates the allowed character set
* Any variable value violates the value restrictions
* Any required TOML file cannot be parsed
* Any array or table structure cannot be flattened according to the rules above


## 3.14 Stage Launch Script Contract (v1)

For each stage, PFXCore SHALL generate:

    stages/<NN>_<stage>/stage_launch.sh

### 3.14.1 Responsibilities

The script SHALL:

1.  Set `set -euo pipefail`.
2.  Change directory to the stage directory.
3.  Source "../../env.sh" (which is generated by PFXStudy and MUST exist before PFXCore execution).
4.  Invoke `stage.exec.argv`.
5.  Propagate the tool exit code.

### 3.14.2 Regeneration

`stage_launch.sh` is generated once and regenerated only with `--force`.

------------------------------------------------------------------------

## 3.15 `run.toml` Schema (v1)

### 3.15.1 Purpose

`run.toml` is the **immutable, run-instance binding** generated by PFXStudy for each DOE leaf directory.
It records:

* the run identity and provenance-friendly metadata
* the DOE point (axis values)
* the binding to **design** and **technology** specifications (`design.toml`, `tech.toml`)
* optional run-local scalar overrides (exported to Tcl)

PFXCore SHALL treat `run.toml` as read-only input and SHALL NOT modify it.

### 3.15.2 Location

`run.toml` SHALL be located at the root of the run directory:

```
<run_dir>/run.toml
```

### 3.15.3 Required Tables

A `run.toml` file SHALL contain the following tables:

* `[run]`
* `[doe]`
* `[design]`
* `[technology]`

### 3.15.4 Optional Tables

The following tables MAY be present:

* `[vars]` — run-local scalar key/value overrides (exported)
* tool-specific tables (e.g. `[genus]`, `[innovus]`) — run-local tool knobs (exported)

No other top-level tables are reserved by this spec.

### 3.15.5 Path Semantics

All paths appearing in `run.toml` SHALL be interpreted as **run-directory-relative** paths unless explicitly stated otherwise.

Because tools execute with stage working directory:

```
<run_dir>/stages/<NN>_<stage>/
```

PFXCore SHALL export the absolute run directory path into `pfx_vars.tcl` and `pfx_vars.py` as:

**Tcl:**
```tcl
set pfx_run_dir {<absolute path to run_dir>}
```

**Python:**
```python
pfx_run_dir = "<absolute path to run_dir>"
```

Tool scripts SHALL resolve run-relative paths by joining them to `pfx_run_dir`.

See Section 3.17.8 for complete list of special variables.

PFXCore SHALL NOT rewrite or canonicalize run-relative paths inside `run.toml`.

### 3.15.6 `[run]` Table

| Field                   | Type    | Required | Semantics                                                     |
|-------------------------|---------|---------:|---------------------------------------------------------------|
| `run_id`                | string  |      yes | Unique run identifier (stable within a study)                 |
| `study_name`            | string  |      yes | Study identifier (human meaningful)                           |
| `semantic_path`         | string  |      yes | DOE semantic path string used to place the run directory      |
| `schema_version`        | string  |       no | Defaults to `"1"`                                             |
| `stage_timeout_seconds` | integer |       No | Global timeout for all stages in seconds.                     |
|                         |         |          | Default: 3596400 (999 hours). If a stage exceeds this timeout |
|                         |         |          | it will be terminated via SIGTERM → SIGKILL sequence.         |
|                         |         |          | See Section 3.18.3 for timeout enforcement details.           |



Semantics:

* `semantic_path` is informational for PFXCore; it is exported for provenance and for scripts that want to reconstruct labels.

### 3.15.7 `[doe]` Table

`[doe]` records the resolved DOE axis values for this run instance.

| Field  | Type  | Required | Semantics                                                 |
|--------|-------|---------:|-----------------------------------------------------------|
| `axes` | table |      yes | Flat key/value mapping of DOE axis names to scalar values |

Constraints:

* `axes` MUST be a flat mapping (no nested tables).
* Each axis value MUST be a scalar (`string`, `int`, `float`, `bool`).

Example:

```toml
[doe.axes]
vdd = 0.70
density = 0.55
temperature_c = 25
```

Export rule:

* `doe.axes.<axis>` is exported under the `run` prefix (because it comes from `run.toml`), yielding Tcl keys like:

  * `run.doe.axes.vdd`
  * `run.doe.axes.density`

### 3.15.8 `[design]` Table

`[design]` binds the run to a design specification file.

| Field       | Type   | Required | Semantics                                                       |
|-------------|--------|---------:|-----------------------------------------------------------------|
| `spec_file` | string |      yes | Path to the design specification TOML (typically `design.toml`) |

Semantics:

* `spec_file` is run-relative.
* PFXCore SHALL load the referenced `design.toml` and export it according to the Variable Propagation Model.

### 3.15.9 `[technology]` Table

`[technology]` binds the run to a technology specification file.

| Field       | Type   | Required | Semantics                                                         |
|-------------|--------|---------:|-------------------------------------------------------------------|
| `spec_file` | string |      yes | Path to the technology specification TOML (typically `tech.toml`) |

Semantics:

* `spec_file` is run-relative.
* PFXCore SHALL load the referenced `tech.toml` and export it according to the Variable Propagation Model.

### 3.15.10 `[vars]` Table (Optional)

`[vars]` provides run-local scalar overrides intended for scripts.

Constraints:

* `[vars]` MUST be a flat mapping (no nested tables).
* Values MUST be scalar (`string`, `int`, `float`, `bool`) or `array` of scalars.

Example:

```toml
[vars]
notes = "trial_7"
max_threads = 16
```

### 3.15.11 Tool-Specific Tables (Optional)

Run-local tool-specific tables MAY be provided for convenience, e.g.:

```toml
[genus]
effort = "high"

[innovus]
route_effort = "high"
```

Semantics:

* These values are exported (subject to key/value restrictions) but are not interpreted by PFXCore.

### 3.15.12 Example `run.toml`

```toml
[run]
run_id = "run_0127"
study_name = "vdd_density_sweep"
semantic_path = "vdd=0.70/density=0.55/temp=25/r0127"
schema_version = "1"
stage_timeout_seconds = 43200  # 12 hours

[doe.axes]
vdd = 0.70
density = 0.55
temperature_c = 25

[design]
spec_file = "design.toml"

[technology]
spec_file = "tech.toml"

[vars]
notes = "trial_7"
max_threads = 16

[genus]
effort = "high"

[innovus]
route_effort = "high"
```

## 3.16 status.json Schema (v1)

### 3.16.1 Purpose

Each stage directory SHALL contain a `status.json` file recording
launch and completion information.

### 3.16.2 Lifecycle Semantics

PFXCore SHALL update `status.json` using atomic replace operation such that the file is always
absent or contains a complete, valid JSON document. 

### 3.16.3 `status.json` Format

This section defines the normative structure and semantics of the per-stage `status.json` file written by PFXCore.

### Design Goals

* Deterministic stage state tracking (not started / running / complete / failed / incomplete)
* Robust against crashes via atomic replacement
* Easy for external tools to consume
* Minimal but extensible

---

### File Encoding

* `status.json` SHALL be a single JSON object encoded as UTF-8.
* Updates to `status.json` SHALL be performed via atomic replace (write complete new file, then rename).

---

### Timestamp Format

* All timestamps SHALL be recorded in the host's local time with an eexplicit numberic UTC offset (RFC 3339).
* Example: `2026-02-11T07:22:14-05:00`

---

### Top-Level Structure

`status.json` SHALL contain the following top-level keys:

* `schema_version` (string)
* `stage` (object)
* `timing` (object)
* `result` (object)
* `io` (object)
* `exec` (object, optional)

---

### Field Definitions

#### `schema_version`

String identifying the `status.json` schema version (e.g. `"1.0"`).

---

#### `stage` Object

Identifies the stage instance.

```json
{
  "name": "synth",
  "order": 10,
  "dir_rel": "stages/10_synth",
  "dir_abs": "/abs/path/to/run/stages/10_synth"
}
```

* `name`: stage name
* `order`: numeric execution order
* `dir_rel`: stage directory relative to run directory
* `dir_abs`: absolute path to stage directory

---

#### `timing` Object

Records execution timing.

```json
{
  "start_time": "2026-02-11T07:22:14-05:00",
  "end_time": "2026-02-11T07:28:03-05:00",
  "duration_sec": 349.1
}
```

* `start_time`: timestamp when stage execution began
* `end_time`: timestamp when stage execution ended, or `null` if incomplete
* `duration_sec`: wall-clock duration in seconds, or `null` if incomplete

---

#### `result` Object

Defines completion and success state.

```json
{
  "state": "complete",
  "success": true,
  "exit_code": 0,
  "signal": null,
  "message": null
}
```

* `state`: one of `"not_started"`, `"running"`, `"complete"`, `"failed"`, `"timeout"`, `"interrupted"`
* `success`: boolean; SHALL be true iff `exit_code == 0` AND all declared outputs are present
* `exit_code`: process exit code, or `null` if incomplete
* `signal`: terminating signal if applicable, else `null`
* `message`: optional human-readable message

If `end_time` or `exit_code` is `null`, the stage SHALL be be in the `"running"` state.

---

#### `io` Object

Captures declared inputs/outputs and observed file presence.

```json
{
  "declard_inputs": [
    "stages/10_synth/outputs/design.vg"
  ],
  "declared_outputs": [
    "outputs/design.enc",
    "reports/place.rpt"
  ],
  "inputs_present": {
    "stages/10_synth/outputs/design.vg": true
  },
  "outputs_present": {
    "outputs/design.enc": true,
    "reports/place.rpt": true
  },
  "outputs_missing": []
}
```

* `declared_inputs`: list of input paths declared by the stage
* `declared_outputs`: list of output paths declared by the stage
* `inputs_present`: map of input path → boolean presence at stage start
* `outputs_present`: map of output path → boolean presence at stage end
* `outputs_missing`: list of declared outputs not present at stage end

---

#### `exec` Object (Optional)

Records how the stage was launched.

```json
{
  "launcher": "stage_launch.sh",
  "cwd_abs": "/abs/path/to/run/stages/10_synth",
  "argv": ["bash", "stage_launch.sh"],
  "env_file_rel": "env.sh",
  "pfx_vars_tcl_rel": "pfx_vars.tcl",
  "pfx_vars_py_rel": "pfx_vars.py",
  "stdout_log_rel": "logs/stdout.log",
  "stderr_log_rel": "logs/stderr.log"
}
```

This object is informational and MAY be omitted or extended.

---

### 3.16.4 Completion and Resumption Rule

PFXCore SHALL:

1. Create `status.json` when a stage is launched
2. Record `start_time`
3. Update the file on process termination
4. Record `end_time` and `exit_code` if available
5. Record the presence or absence of all files listed in stage `declared_outputs`.


A stage SHALL be considered successfully completed if and only if:

- `end_time` is present, AND
- `state` is `complete`, AND
- `exit_code` is present and equal to 0, AND
- `declared_outputs` files all exists

PFXCore MAY skip re-execution of such stages unless `--force` is specified.
All times to be recorded in local time of the host machine. 

`io.outputs_present[path]` SHALL be set for every path in `io.declared_outputs`.
`io.outputs_missing` SHALL equal the subset of `io.declared_outputs` whos `outputs_present[path]` is false.

A stage `status.json` that does not contain `end_time`, `exit_code` and `declared_outputs` file information
shall be incomplete and no further pipeline execution can continue, except when the `--force` flag
is used to invoke PFXCore. This strict continuation critera is due to the nature of the flow:
a stage crash or incomplete status requires user intervention and is outside the scope of PFXCore's mission.

No additional state machine is defined.



## 3.17 Language Export Specification

PFXCore SHALL generate configuration files in multiple target languages to enable integration with diverse EDA tools. This section defines the normative rules for exporting TOML configuration data to Tcl and Python.

---

### 3.17.1 Overview

PFXCore generates language-specific configuration files during run materialization:

* `pfx_vars.tcl` - Tcl variable definitions for Genus, Innovus, and other Tcl-based tools
* `pfx_vars.py` - Python dictionary/variable definitions for Python-based tools and scripts

These files SHALL contain all variables defined in `run.toml`, `design.toml`, `tech.toml`, and `pipeline.toml`, fully expanded and flattened according to the rules in this section.

---

### 3.17.2 General Principles

1. **Immutability**: Exported files represent a snapshot of the fully-resolved configuration at materialization time.

2. **Completeness**: All user-defined variables and PFX-reserved variables SHALL be exported.

3. **Type Preservation**: TOML types SHALL be mapped to semantically equivalent types in each target language.

4. **Flattening**: Nested TOML tables SHALL be flattened using dot notation for variable names.

5. **Escaping**: Special characters SHALL be properly escaped according to each language's syntax rules.

6. **Reserved Words**: Target language reserved words SHALL be detected and avoided through name transformation.

---

### 3.17.3 Flattening Rules

Nested TOML tables SHALL be flattened to dot-separated variable names.

#### Flattening Algorithm

Given a TOML structure:

```toml
[design]
name = "my_core"
top_module = "cpu_top"

[design.timing]
setup_margin = 0.1
hold_margin = 0.05
```

The flattened representation SHALL be:

```
design.name = "my_core"
design.top_module = "cpu_top"
design.timing.setup_margin = 0.1
design.timing.hold_margin = 0.05
```

#### Naming Convention

* Table keys SHALL be joined with a single dot (`.`) character
* Array indices SHALL be represented as zero-based numeric suffixes: `files.0`, `files.1`, etc.
* Top-level keys SHALL have no prefix
* All variable names SHALL be prefixed with `pfx_` when exported

**Example:**

```toml
input_files = ["a.v", "b.v", "c.v"]
```

Flattens to:

```
pfx_input_files_0 = "a.v"
pfx_input_files_1 = "b.v"
pfx_input_files_2 = "c.v"
pfx_input_files_count = 3
```

Note: The `_count` suffix is automatically added for arrays.

---

### 3.17.4 Type Mapping

The following table defines the canonical mapping from TOML types to Tcl and Python:

| TOML Type | Tcl Representation | Python Representation | Notes |
|-----------|--------------------|-----------------------|-------|
| String | `"value"` | `"value"` | Quoted with escaping |
| Integer | `42` | `42` | Numeric literal |
| Float | `3.14` | `3.14` | Numeric literal |
| Boolean | `1` (true), `0` (false) | `True`, `False` | Tcl uses 1/0 convention |
| Array | Tcl list or indexed vars | Python list `[...]` | See array handling below |
| Table | Flattened dot notation | Nested dict or flat | See table handling below |
| Datetime | ISO 8601 string | ISO 8601 string | Represented as string |

---

### 3.17.5 Tcl Export Format

#### 3.17.5.1 General Structure

The generated `pfx_vars.tcl` file SHALL have the following structure:

```tcl
#!/usr/bin/env tclsh
# Auto-generated by PFXCore
# Run: <run_name>
# Generated: <timestamp>
# DO NOT EDIT

# Scalar variables
set pfx_design_name "my_core"
set pfx_tech_node "7nm"
set pfx_timing_setup_margin 0.1

# Array variables (option 1: Tcl list)
set pfx_input_files {file1.v file2.v file3.v}

# Array variables (option 2: indexed variables)
set pfx_input_files_0 "file1.v"
set pfx_input_files_1 "file2.v"
set pfx_input_files_2 "file3.v"
set pfx_input_files_count 3

# Boolean variables (as 0/1)
set pfx_enable_dpt 1
set pfx_disable_opt 0
```

#### 3.17.5.2 Array Handling

PFXCore SHALL export arrays using **indexed variables** (not Tcl lists) for maximum compatibility:

```tcl
set pfx_layers_0 "M1"
set pfx_layers_1 "M2"
set pfx_layers_2 "M3"
set pfx_layers_count 3
```

Rationale: This avoids Tcl list parsing ambiguities and enables simple iteration:

```tcl
for {set i 0} {$i < $pfx_layers_count} {incr i} {
    set layer [set pfx_layers_${i}]
    # use $layer
}
```

#### 3.17.5.3 Escaping Rules

* Backslash (`\`) SHALL be escaped as `\\`
* Double quote (`"`) SHALL be escaped as `\"`
* Newline SHALL be escaped as `\n`
* Dollar sign (`$`) SHALL be escaped as `\$` (to prevent variable expansion)
* Square brackets (`[`, `]`) SHALL be escaped as `\[`, `\]` (to prevent command substitution)

Example:

```toml
message = "Hello \"world\"\nPath: $HOME"
```

Exports to:

```tcl
set pfx_message "Hello \\\"world\\\"\\nPath: \$HOME"
```

#### 3.17.5.4 Reserved Word Handling

Tcl reserved words SHALL be detected and prefixed with an underscore:

* `if`, `else`, `elseif`, `for`, `foreach`, `while`, `switch`, `catch`, `return`, `break`, `continue`, `proc`, `namespace`, `variable`, `global`, `upvar`, `set`, `unset`, `array`, `list`, `dict`, `string`, `expr`, `eval`, `source`

Example:

```toml
[config]
set = "value"  # "set" is a Tcl reserved word
```

Exports to:

```tcl
set pfx_config__set "value"  # Note double underscore
```

---

### 3.17.6 Python Export Format

#### 3.17.6.1 General Structure

The generated `pfx_vars.py` file SHALL have the following structure:

```python
#!/usr/bin/env python3
"""
Auto-generated by PFXCore
Run: <run_name>
Generated: <timestamp>
DO NOT EDIT
"""

# Option 1: Flat namespace (simple)
pfx_design_name = "my_core"
pfx_tech_node = "7nm"
pfx_timing_setup_margin = 0.1

# Arrays as Python lists
pfx_input_files = ["file1.v", "file2.v", "file3.v"]

# Booleans as Python bools
pfx_enable_dpt = True
pfx_disable_opt = False
```

**OR**

```python
# Option 2: Nested dictionary (preserves structure)
pfx_config = {
    'design': {
        'name': 'my_core',
        'top_module': 'cpu_top',
        'timing': {
            'setup_margin': 0.1,
            'hold_margin': 0.05
        }
    },
    'tech': {
        'node': '7nm',
        'lef_files': ['tech.lef', 'cells.lef']
    },
    'input_files': ['file1.v', 'file2.v', 'file3.v'],
    'enable_dpt': True
}
```

**Default**: PFXCore SHALL use **Option 1 (flat namespace)** by default for simplicity and consistency with Tcl export.

Future versions MAY add configuration to select nested dictionary export.

#### 3.17.6.2 Array Handling

Arrays SHALL be exported as Python lists:

```python
pfx_layers = ["M1", "M2", "M3"]
```

This is more idiomatic Python than indexed variables.

#### 3.17.6.3 Escaping Rules

Python string escaping SHALL follow standard Python literal rules:

* Backslash (`\`) SHALL be escaped as `\\`
* Single quote (`'`) SHALL be escaped as `\'` in single-quoted strings
* Double quote (`"`) SHALL be escaped as `\"` in double-quoted strings
* Newline SHALL be escaped as `\n`

PFXCore SHALL use double-quoted strings for consistency.

Example:

```toml
message = "Hello \"world\"\nPath: $HOME"
```

Exports to:

```python
pfx_message = "Hello \"world\"\nPath: $HOME"
```

Note: No escaping needed for `$` in Python strings.

#### 3.17.6.4 Reserved Word Handling

Python reserved words SHALL be detected and suffixed with an underscore:

* `False`, `None`, `True`, `and`, `as`, `assert`, `async`, `await`, `break`, `class`, `continue`, `def`, `del`, `elif`, `else`, `except`, `finally`, `for`, `from`, `global`, `if`, `import`, `in`, `is`, `lambda`, `nonlocal`, `not`, `or`, `pass`, `raise`, `return`, `try`, `while`, `with`, `yield`

Example:

```toml
[config]
class = "standard"  # "class" is a Python reserved word
```

Exports to:

```python
pfx_config_class_ = "standard"  # Note trailing underscore
```

---

### 3.17.7 Variable Name Transformation

All exported variable names SHALL follow these transformation rules:

1. **Prefix**: Add `pfx_` prefix to all variable names
2. **Case**: Convert to uppercase for consistency (configurable)
3. **Dot Notation**: Replace table nesting dots with underscores in flat export
4. **Reserved Words**: Transform reserved words as specified in 3.17.5.4 and 3.17.6.4

Example transformation:

```toml
[design.timing]
setup_margin = 0.1
```

Becomes:

* Tcl: `set pfx_design_timing_setup_margin 0.1`
* Python: `pfx_design_timing_setup_margin = 0.1`

---

### 3.17.8 Special Variables

PFXCore SHALL automatically export the following special variables:

* `pfx_run_name`: Name of the run
* `pfx_stage_order`: Numberic order of current stage
* `pfx_run_dir`: Absolute path to run directory
* `pfx_stage_name`: Name of current stage (when exporting stage-specific vars)
* `pfx_stage_dir`: Absolute path to current stage directory
* `pfx_schema_version`: Schema version of the configuration

---

### 3.17.9 Export File Location

Language export files SHALL be generated at the following locations:

* **Run-level exports**: `<run_dir>/pfx_vars.tcl`, `<run_dir>/pfx_vars.py`
* **Stage-level exports**: `<run_dir>/stages/<NN>_<stage>/pfx_vars.tcl`, `<run_dir>/stages/<NN>_<stage>/pfx_vars.py`

Stage-level exports MAY include stage-specific overrides and SHALL include stage-specific special variables.

---

### 3.17.10 Validation Requirements

PFXCore SHALL validate exported files:

* Syntax validity (Tcl/Python parseable)
* No name collisions after transformation
* All required variables present
* Type consistency maintained

If validation fails, PFXCore SHALL abort materialization with a descriptive error message.

---

### 3.17.11 Example: Complete Export

Given the following `run.toml`:

```toml
run_name = "test_run_001"

[design]
name = "aes_cipher"
top_module = "aes_top"

[design.timing]
setup_margin = 0.1
hold_margin = 0.05

[tech]
node = "7nm"
lef_files = ["tech.lef", "cells.lef"]

[variables]
clock_period = 2.5
enable_dpt = true
```

#### Generated `pfx_vars.tcl`:

```tcl
#!/usr/bin/env tclsh
# Auto-generated by PFXCore
# Run: test_run_001
# Generated: 2026-02-11T10:30:00-05:00
# DO NOT EDIT

set pfx_run_name "test_run_001"
set pfx_design_name "aes_cipher"
set pfx_design_top_module "aes_top"
set pfx_design_timing_setup_margin 0.1
set pfx_design_timing_hold_margin 0.05
set pfx_tech_node "7nm"
set pfx_tech_lef_files_0 "tech.lef"
set pfx_tech_lef_files_1 "cells.lef"
set pfx_tech_lef_files_count 2
set pfx_variables_clock_period 2.5
set pfx_variables_enable_dpt 1
```

#### Generated `pfx_vars.py`:

```python
#!/usr/bin/env python3
"""
Auto-generated by PFXCore
Run: test_run_001
Generated: 2026-02-11T10:30:00-05:00
DO NOT EDIT
"""

pfx_run_name = "test_run_001"
pfx_design_name = "aes_cipher"
pfx_design_top_module = "aes_top"
pfx_design_timing_setup_margin = 0.1
pfx_design_timing_hold_margin = 0.05
pfx_tech_node = "7nm"
pfx_tech_lef_files = ["tech.lef", "cells.lef"]
pfx_variables_clock_period = 2.5
pfx_variables_enable_dpt = True
```

---

### 3.17.12 Implementation Notes (Non-Normative)

* PFXCore MAY cache the reserved word lists for performance
* PFXCore SHOULD emit warnings for variable names that are nearly identical after transformation
* PFXCore MAY provide a configuration option to select nested vs. flat Python export in future versions
* PFXCore SHOULD provide a validation mode that checks exported files against expected schemas


## 3.18 Process Management and Cleanup

PFXCore manages subprocess lifecycles to ensure robust cleanup of process trees spawned by EDA tools. This section defines normative requirements for process group management, timeout handling, orphan cleanup, and process tracking.

---

### 3.18.1 Overview

EDA tools frequently spawn complex process trees consisting of multiple worker processes. These subprocesses may outlive their parent processes during crashes or abnormal termination, leading to resource leaks and zombie processes.

PFXCore SHALL:
- Launch stages in isolated process groups
- Track the root process and process group ID
- Detect and terminate orphaned subprocesses
- Clean up stale processes from previous crashed runs
- Record all process management actions in `processes.json`

---

### 3.18.2 Process Group Management

#### 3.18.2.1 Process Group Creation

PFXCore SHALL launch `stage_launch.sh` in a new process group:

1. After `fork()` in the child process, call `setpgid(0, 0)` to create a new process group
2. The process group ID (PGID) SHALL equal the child process ID (PID)
3. All descendant processes SHALL inherit this process group

This isolation allows PFXCore to terminate the entire process tree with a single `killpg()` call.

#### 3.18.2.2 Process Group Recording

PFXCore SHALL record the following information at stage launch:

- Root process PID
- Process group ID (PGID)
- Launch timestamp
- Command and arguments

This information SHALL be written to `processes.json` immediately after process creation.

---

### 3.18.3 Timeout Handling

#### 3.18.3.1 Timeout Configuration

The global stage timeout SHALL be specified in `run.toml` in the `[run]` table:

```toml
[run]
stage_timeout_seconds = 3596400  # Default: 999 hours
```

If `stage_timeout_seconds` is not specified, the default value of 3596400 seconds (999 hours) SHALL be used.

#### 3.18.3.2 Timeout Enforcement

PFXCore SHALL monitor stage execution time:

1. Record stage start time when launching root process
2. Periodically check elapsed time (polling interval: 1 second)
3. If elapsed time exceeds `stage_timeout_seconds`:
   - Log timeout event
   - Proceed to termination procedure (Section 3.18.4)
   - Set `result.state` to `"timeout"` in `status.json`

#### 3.18.3.3 Timeout vs. Slurm Time Limits

If running under Slurm or another job scheduler with time limits:
- Scheduler time limits take precedence
- PFXCore timeout should be set higher than scheduler limits
- If scheduler kills the job, PFXCore cleanup procedures may not execute

---

### 3.18.4 Process Termination and Cleanup

#### 3.18.4.1 Normal Termination

When the root process exits normally (via `waitpid()` return):

1. Record exit code and end time
2. Scan for orphaned processes (Section 3.18.4.3)
3. Terminate any orphans (Section 3.18.4.4)
4. Update `processes.json` with cleanup actions
5. Finalize `status.json`

#### 3.18.4.2 Timeout Termination

When stage execution exceeds the timeout:

1. Send `SIGTERM` to the entire process group:
   ```c
   killpg(pgid, SIGTERM);
   ```
2. Wait 5 seconds (grace period)
3. Send `SIGKILL` to the entire process group:
   ```c
   killpg(pgid, SIGKILL);
   ```
4. Wait for root process to exit (it should exit immediately after SIGKILL)
5. Scan for orphaned processes
6. Force-kill any remaining orphans individually
7. Record all actions in `processes.json`

#### 3.18.4.3 Orphan Detection

After root process termination, PFXCore SHALL scan for orphaned processes:

1. Read `/proc/*/stat` for all processes on the system
2. Identify processes where the 5th field (PGID) matches the stage's PGID
3. Exclude the root process PID (already exited)
4. Any remaining PIDs are orphaned subprocesses

PFXCore MAY cache `/proc` scans or use more efficient methods (e.g., `/proc/<pgid>/task/`).

#### 3.18.4.4 Orphan Termination

For each orphaned process found:

1. Send `SIGTERM`:
   ```c
   kill(pid, SIGTERM);
   ```
2. Record signal in `processes.json`

After sending SIGTERM to all orphans:

1. Wait 5 seconds (grace period)
2. Re-scan for remaining processes
3. For each remaining process, send `SIGKILL`:
   ```c
   kill(pid, SIGKILL);
   ```
4. Record SIGKILL actions in `processes.json`

After SIGKILL:

1. Reap zombie processes:
   ```c
   waitpid(pid, &status, WNOHANG);
   ```
2. Record final process count in `processes.json`

The 5-second grace period is fixed and not configurable in v1.

#### 3.18.4.5 Cleanup Verification

After termination procedure completes, PFXCore SHALL:

1. Perform a final orphan scan
2. If any processes remain:
   - Log error to stage logs
   - Record remaining PIDs in `processes.json`
   - Set `cleanup.cleanup_complete` to `false`
3. If all processes terminated:
   - Set `cleanup.cleanup_complete` to `true`

PFXCore SHALL NOT fail the stage based on orphan cleanup status. Stage success is determined solely by `status.json` exit code and output file presence.

---

### 3.18.5 Stale Process Cleanup

#### 3.18.5.1 Problem Statement

If PFXCore crashes or is killed before completing cleanup (e.g., due to power loss, OOM killer, or user intervention), orphaned processes from the previous run may persist.

#### 3.18.5.2 Stale Process Detection

Before launching a stage, PFXCore SHALL:

1. Check if `processes.json` exists in the stage directory
2. If it exists and `cleanup.cleanup_complete` is `false`:
   - Read the `root_process.pgid` value
   - Scan `/proc` for processes in that process group
   - If processes found, proceed to stale process cleanup
3. If `processes.json` does not exist, skip stale process cleanup

#### 3.18.5.3 Stale Process Termination

For each stale process found:

1. Log warning: "Stale process detected from previous run: PID <pid>"
2. Send `SIGTERM` to each process
3. Wait 5 seconds
4. Send `SIGKILL` to remaining processes
5. Reap zombies

Record all stale process cleanup actions in a new `processes.json` under a `startup_cleanup` section:

```json
{
  "startup_cleanup": {
    "stale_pgid": 12345,
    "stale_processes_found": [12346, 12347],
    "termination_actions": [...]
  }
}
```

#### 3.18.5.4 Cleanup Failure

If stale processes cannot be killed (e.g., due to permissions or unkillable state):

- Log error to stage logs
- Abort stage execution with error message
- User must manually intervene to kill processes

PFXCore SHALL NOT attempt to launch a new stage while stale processes remain.

---

### 3.18.6 Signal Handling

#### 3.18.6.1 Supported Signals

PFXCore SHALL handle the following signals:

- `SIGINT` (Ctrl-C): Graceful shutdown
- `SIGTERM`: Graceful shutdown
- `SIGCHLD`: Process status change (optional)

#### 3.18.6.2 Graceful Shutdown

When PFXCore receives `SIGINT` or `SIGTERM`:

1. Log signal receipt
2. Terminate the currently executing stage:
   - Send `SIGTERM` to process group
   - Wait 5 seconds
   - Send `SIGKILL` to process group
3. Clean up orphans as per Section 3.18.4.3-3.18.4.4
4. Finalize `status.json` with `state: "interrupted"`
5. Finalize `processes.json`
6. Exit with status code 130 (SIGINT) or 143 (SIGTERM)

#### 3.18.6.3 Non-Graceful Exit

If PFXCore is killed with `SIGKILL` or crashes:
- No cleanup occurs
- Stale processes remain
- Next invocation will detect and clean up via Section 3.18.5

---

### 3.18.7 Process Tracking Artifact: processes.json

#### 3.18.7.1 Overview

PFXCore SHALL create a `processes.json` file in each stage directory to record process management actions. This artifact is mandatory and serves as an audit trail for debugging hung processes, timeouts, and cleanup failures.

**Location:**
```
<run_dir>/stages/<NN>_<stage>/processes.json
```

**Lifecycle:**
- Created when stage is launched (with root process info)
- Updated on termination with cleanup actions
- Finalized before PFXCore exits

#### 3.18.7.2 Schema Version 1.0

```json
{
  "schema_version": "1.0",
  "root_process": {
    "pid": <integer>,
    "pgid": <integer>,
    "command": "<string>",
    "argv": [<string>, ...],
    "start_time": "<ISO 8601 timestamp>",
    "end_time": "<ISO 8601 timestamp or null>",
    "exit_code": <integer or null>,
    "signal": "<string or null>",
    "status": "<string>"
  },
  "timeout": {
    "limit_seconds": <integer>,
    "exceeded": <boolean>
  },
  "process_tree": [
    {
      "pid": <integer>,
      "ppid": <integer>,
      "command": "<string>",
      "discovered_at": "<ISO 8601 timestamp>",
      "status": "<string>"
    }
  ],
  "cleanup": {
    "orphans_found": [<integer>, ...],
    "kill_signals_sent": [
      {
        "pid": <integer>,
        "signal": "<string>",
        "timestamp": "<ISO 8601 timestamp>",
        "success": <boolean>
      }
    ],
    "cleanup_complete": <boolean>,
    "zombies_remaining": <integer>
  },
  "startup_cleanup": {
    "stale_pgid": <integer or null>,
    "stale_processes_found": [<integer>, ...],
    "termination_actions": [...]
  }
}
```

#### 3.18.7.3 Field Definitions

##### `schema_version`
String identifying the schema version (current: `"1.0"`).

##### `root_process` Object
Information about the root process (`stage_launch.sh`):

- `pid`: Process ID of root process
- `pgid`: Process group ID (typically equal to PID)
- `command`: Command name (typically `"bash"`)
- `argv`: Full command-line arguments array
- `start_time`: Launch timestamp (ISO 8601 with UTC offset)
- `end_time`: Termination timestamp (null if interrupted before termination detected)
- `exit_code`: Exit code (null if killed by signal or not yet exited)
- `signal`: Terminating signal name if applicable (e.g., `"SIGTERM"`, `"SIGKILL"`)
- `status`: One of:
  - `"running"`: Still executing
  - `"exited"`: Exited normally
  - `"killed"`: Killed by signal
  - `"timeout"`: Killed due to timeout
  - `"interrupted"`: PFXCore received SIGINT/SIGTERM

##### `timeout` Object
Timeout configuration and status:

- `limit_seconds`: Timeout value from `run.toml` (default: 3596400)
- `exceeded`: Boolean indicating if timeout was exceeded

##### `process_tree` Array (Optional)
List of discovered descendant processes. This array is best-effort and MAY be incomplete or empty.

Each entry:
- `pid`: Process ID
- `ppid`: Parent process ID
- `command`: Command name (from `/proc/<pid>/comm`)
- `discovered_at`: Timestamp when process was first detected
- `status`: One of `"running"`, `"exited"`, `"orphaned"`

PFXCore MAY populate this array by periodic `/proc` scanning during execution, or only populate it during orphan detection. Implementation is optional and best-effort.

##### `cleanup` Object
Cleanup actions taken after root process termination:

- `orphans_found`: Array of PIDs found after root process exited
- `kill_signals_sent`: Array of kill attempt records:
  - `pid`: Target process ID
  - `signal`: Signal name (`"SIGTERM"` or `"SIGKILL"`)
  - `timestamp`: When signal was sent
  - `success`: Boolean indicating if `kill()` syscall succeeded
- `cleanup_complete`: Boolean:
  - `true`: All processes terminated successfully
  - `false`: Some processes remain or couldn't be killed
- `zombies_remaining`: Count of processes that couldn't be reaped

##### `startup_cleanup` Object (Optional)
Present only if stale processes were detected at stage launch:

- `stale_pgid`: Process group ID from previous run
- `stale_processes_found`: Array of stale PIDs detected
- `termination_actions`: Array of kill attempts (same format as `cleanup.kill_signals_sent`)

If no stale processes were found, this object MAY be omitted or set to `null`.

#### 3.18.7.4 Example: Normal Execution

Stage completes successfully with no orphans:

```json
{
  "schema_version": "1.0",
  "root_process": {
    "pid": 12345,
    "pgid": 12345,
    "command": "bash",
    "argv": ["bash", "stage_launch.sh"],
    "start_time": "2026-02-11T10:30:00-05:00",
    "end_time": "2026-02-11T13:45:30-05:00",
    "exit_code": 0,
    "signal": null,
    "status": "exited"
  },
  "timeout": {
    "limit_seconds": 3596400,
    "exceeded": false
  },
  "process_tree": [],
  "cleanup": {
    "orphans_found": [],
    "kill_signals_sent": [],
    "cleanup_complete": true,
    "zombies_remaining": 0
  }
}
```

#### 3.18.7.5 Example: Orphan Cleanup

Stage exits normally but leaves orphaned worker:

```json
{
  "schema_version": "1.0",
  "root_process": {
    "pid": 12345,
    "pgid": 12345,
    "command": "bash",
    "argv": ["bash", "stage_launch.sh"],
    "start_time": "2026-02-11T10:30:00-05:00",
    "end_time": "2026-02-11T13:45:30-05:00",
    "exit_code": 0,
    "signal": null,
    "status": "exited"
  },
  "timeout": {
    "limit_seconds": 3596400,
    "exceeded": false
  },
  "process_tree": [
    {
      "pid": 12347,
      "ppid": 12346,
      "command": "genus_worker",
      "discovered_at": "2026-02-11T13:45:31-05:00",
      "status": "orphaned"
    }
  ],
  "cleanup": {
    "orphans_found": [12347],
    "kill_signals_sent": [
      {
        "pid": 12347,
        "signal": "SIGTERM",
        "timestamp": "2026-02-11T13:45:31-05:00",
        "success": true
      },
      {
        "pid": 12347,
        "signal": "SIGKILL",
        "timestamp": "2026-02-11T13:45:36-05:00",
        "success": true
      }
    ],
    "cleanup_complete": true,
    "zombies_remaining": 0
  }
}
```

#### 3.18.7.6 Example: Timeout

Stage exceeds timeout, process tree terminated:

```json
{
  "schema_version": "1.0",
  "root_process": {
    "pid": 12345,
    "pgid": 12345,
    "command": "bash",
    "argv": ["bash", "stage_launch.sh"],
    "start_time": "2026-02-11T10:30:00-05:00",
    "end_time": "2026-02-11T22:30:05-05:00",
    "exit_code": null,
    "signal": "SIGKILL",
    "status": "timeout"
  },
  "timeout": {
    "limit_seconds": 43200,
    "exceeded": true
  },
  "process_tree": [
    {
      "pid": 12346,
      "ppid": 12345,
      "command": "genus",
      "discovered_at": "2026-02-11T22:30:05-05:00",
      "status": "orphaned"
    }
  ],
  "cleanup": {
    "orphans_found": [12346],
    "kill_signals_sent": [
      {
        "pid": 12346,
        "signal": "SIGKILL",
        "timestamp": "2026-02-11T22:30:05-05:00",
        "success": true
      }
    ],
    "cleanup_complete": true,
    "zombies_remaining": 0
  }
}
```

#### 3.18.7.7 Example: Stale Process Cleanup

Previous run crashed, stale processes cleaned up at next launch:

```json
{
  "schema_version": "1.0",
  "startup_cleanup": {
    "stale_pgid": 11000,
    "stale_processes_found": [11001, 11002],
    "termination_actions": [
      {
        "pid": 11001,
        "signal": "SIGTERM",
        "timestamp": "2026-02-11T14:00:00-05:00",
        "success": true
      },
      {
        "pid": 11002,
        "signal": "SIGTERM",
        "timestamp": "2026-02-11T14:00:00-05:00",
        "success": true
      },
      {
        "pid": 11001,
        "signal": "SIGKILL",
        "timestamp": "2026-02-11T14:00:05-05:00",
        "success": true
      },
      {
        "pid": 11002,
        "signal": "SIGKILL",
        "timestamp": "2026-02-11T14:00:05-05:00",
        "success": true
      }
    ]
  },
  "root_process": {
    "pid": 12345,
    "pgid": 12345,
    "command": "bash",
    "argv": ["bash", "stage_launch.sh"],
    "start_time": "2026-02-11T14:00:10-05:00",
    "end_time": "2026-02-11T16:30:00-05:00",
    "exit_code": 0,
    "signal": null,
    "status": "exited"
  },
  "timeout": {
    "limit_seconds": 3596400,
    "exceeded": false
  },
  "process_tree": [],
  "cleanup": {
    "orphans_found": [],
    "kill_signals_sent": [],
    "cleanup_complete": true,
    "zombies_remaining": 0
  }
}
```

---

### 3.18.8 Relationship to status.json

`processes.json` is independent of `status.json`:

- **Stage success** is determined by `status.json` (exit code, output files)
- **Process cleanup** is recorded in `processes.json`

A stage MAY be successful (exit code 0, outputs present) even if orphan cleanup was required. The presence of orphans does NOT affect stage success determination.

Conversely, a stage MAY fail (exit code non-zero) even if process cleanup was perfect.

`processes.json` is purely for debugging and audit purposes.

---

### 3.18.9 Implementation Notes (Non-Normative)

#### Orphan Detection Performance

Scanning `/proc` for all processes can be slow on systems with many processes. Implementations MAY optimize by:

- Caching `/proc` directory listings
- Using `/proc/<pgid>/task/` if supported
- Maintaining a process tree during execution via `SIGCHLD` handlers

However, a full `/proc` scan at termination is required to ensure no processes are missed.

#### PGID Persistence

The PGID must be stored persistently (in `processes.json`) to enable stale process cleanup. If `processes.json` is corrupted or deleted, stale process detection will fail.

#### Permissions

Process cleanup requires sufficient permissions to send signals to all processes in the process group. If the stage switches user IDs or escalates privileges, cleanup may fail.

#### Unkillable Processes

Processes in uninterruptible sleep (D state) cannot be killed. If orphan cleanup encounters such processes:
- Log error
- Set `cleanup.cleanup_complete` to `false`
- Continue with stage execution

User must manually intervene if unkillable processes persist.

---

### 3.18.10 Future Extensions

Future versions of this specification MAY add:

- Real-time process tree tracking with resource usage
- Per-stage timeout overrides in `pipeline.toml`
- Configurable grace periods
- Integration with process accounting (Linux `taskstats`)
- Automatic detection of hung processes during execution
- Process CPU/memory usage tracking

---

## 4. Data Model and Core Abstractions

This section defines the logical objects PFXCore operates on. These are
**conceptual** models; they do not imply a class hierarchy, but they
define the information PFXCore must be able to load, validate, and act
on.

### 4.1 Core Objects

  -----------------------------------------------------------------------
| Object | Description                         |
|--------|-------------------------------------|
| Study  | A collection of runs defined by DOE |
|        | axes and study-wide policies        |
|        |                                     |


  Run                                 A single DOE leaf instance (one run
                                      directory)

  Pipeline                            The ordered set of stages defined
                                      in `pipeline.toml`

  Stage                               A single ordered execution unit
                                      within a run

  StageStatus                         The minimal persisted state
                                      recorded in `status.json`
  -----------------------------------------------------------------------

### 4.2 Object-to-Artifact Mapping

  -----------------------------------------------------------------------
| Object | Primary Artifact(s)            |
|--------|--------------------------------|
| Study  | `study.toml`, `pipeline.toml`, |
|        | `limits.toml`, `templates/`    |
|        |                                |


  Run                                 `run.toml`,
                                      `env.sh`, `inputs/`, `scripts/`,
                                      `stages/`, `results/`

  Pipeline                            `pipeline.toml`

  Stage                               `stages/<NN>_<stage>/`

  StageStatus                         `stages/<NN>_<stage>/status.json`
  -----------------------------------------------------------------------

### 4.3 Notes for PFXCore Implementation

-   PFXCore SHALL treat `run.toml` as immutable input.
-   PFXCore SHALL assume `env.sh` exists (generated by PFXStudy).
-   PFXCore SHALL only require that `inputs/design/` and `inputs/tech/`
    exist.
-   PFXCore SHALL materialize per-stage directories and
    `stage_launch.sh`.

------------------------------------------------------------------------

## Concurrency

Concurrent execution within the same run directory is unsupported. Any
resulting corruption is user responsibility.

## Slurm Integration (Placeholder)

Version v1 defines only a stub interface for Slurm-based execution. Full
scheduler integration is deferred to later revisions.
