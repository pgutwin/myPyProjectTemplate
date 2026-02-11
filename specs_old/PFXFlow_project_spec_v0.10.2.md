### Change Log

**Version:** v0.10.1

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
	Updated run.toml specification.

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
    materializes, executes, and harvests individual runs.

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
-   Harvester Framework

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
	config/ 
	design.toml
	tech.toml
	env.sh 
	inputs/
	pipeline.toml
	run.toml 
	scripts/ 
	stages/ 
	   10_synth/ 
	      reports/ 
          status.json 
	      outputs/
	   20_init/ 
	      reports/ 
          status.json 
	      outputs/
	   30_place/ 
	      reports/ 
          status.json 
	      outputs/
	   40_route/ 
	      reports/ 
          status.json 
	      outputs/
    results/ 
	     run_summary.json 
	     run_summary.csv
		 run_id.txt
         run_intent.json 
		 provenance.json 
		 inputs_manifest.json
	 pfx_vars.tcl

#### 3.5.1 Current Working Directories for Tool exeuction

The current working directory for a tool exeuction will be the stage
step. For example, in the above directory example, the invocation and
running of the synthesis step will use "stages/10_synth" as the current
working directory. All file references will be relative to this
location.



**Important:** The tool's *current working directory* is the stage directory, but **all paths declared in TOML files are run-directory relative** unless stated otherwise. PFXCore SHALL export the canonical absolute run directory path as `pfx(run.dir)` in `pfx_vars.tcl`. Stage Tcl scripts SHALL resolve run-relative paths by prefixing them with `$pfx(run.dir)`.
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
-   Stable handoff uses \` symlinks.

#### 3.7.2 pipeline.toml schema (v1)

This section defines the normative syntax and semantics of
`pipeline.toml`. All v1-compliant implementations SHALL conform to this
schema. Examples are illustrative and non-normative.

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
| outputs    | array\[string\] | \[\]    | Declared output paths |


Stage names SHALL be unique. Order values SHALL be unique and
increasing.

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
-   Stage `outputs` paths are **stage-directory relative** (i.e., relative to `stages/<NN>_<stage>/`).
-   Stage `inputs` paths are **run-directory relative** (i.e., relative to `<run_dir>/`).
-   PFXCore SHALL export `pfx(run.dir)` (absolute path) so stage scripts can convert any run-relative path into an absolute path when needed.

### 3.7.2.7 Execution Semantics

Before executing any stage, PFXCore SHALL verify that the following run prerequisites exist:

- `env.sh` (generated by PFXStudy)
- `scripts/` directory (populated by PFXStudy)

No other filesystem checks are required at stage launch time.

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
  "outputs/netlist.v",
  "outputs/constraints.sdc"
]

[stage.exec]
argv = ["genus", "-batch", "-files", "../../scripts/synth.tcl"]

[[stage]]
name = "init"
order = 20
depends_on = ["synth"]
inputs = [
  "stages/10_synth/outputs/netlist.v",
  "stages/10_synth/outputs/constraints.sdc",
  "inputs/tech/*"
]
outputs = ["outputs/design.enc"]

[stage.exec]
argv = ["innovus", "-batch", "-files", "../../scripts/init.tcl"]

[[stage]]
name = "place"
order = 30
depends_on = ["init"]
inputs = ["stages/20_init/outputs/design.enc"]
outputs = ["outputs/design_placed.enc"]

[stage.exec]
argv = ["innovus", "-batch", "-files", "../../scripts/place.tcl"]

[[stage]]
name = "harvest"
order = 90
depends_on = ["place"]
inputs = ["stages/30_place/outputs/design_placed.enc"]
outputs = ["outputs/harvest.json"]

[stage.exec]
argv = ["python3", "../../scripts/harvest.py", "--in", "../../stages/30_place/outputs/design_placed.enc", "--out", "outputs/harvest.json"]
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

### 3.8.6 `[constraints]` Table (Optional)

| Field           | Type          | Required | Semantics                     |
|-----------------|---------------|---------:|-------------------------------|
| sdc_file_dirs   | array[string] |       no | SDC constraints file paths    |
| sdc_file_names  | array[string] |       no | SDC file names                |
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
sdc_file_dirs = ["inputs/design/constraints/"]
sdc_file_names = ["aka_constraints.sdc"]

[tools.genus]
retime = true
```
<!---
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

+incdir+rtl/include +define+USE_IP

-f common.f

rtl/top.sv rtl/core.sv

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

inputs/design/rtl/filelist.f

All tools SHALL consume only the resolved filelist.

#### 3.8.4 Canonical Design Layout

Within `inputs/design/`:

``` text
inputs/design/
 rtl/
 filelist.f
 src/ # optional (copy mode)
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
--->

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

### 3.9.5 `[paths]` Table

`[paths]` binds logical technology views to directories under `inputs/tech/`. All values are **run-directory relative paths**.

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

[paths]
root = "inputs/tech"
lef_dir = "inputs/tech/lef"
lib_dir = "inputs/tech/lib"
qrc_dir = "inputs/tech/qrc"
mmmc_dir = "inputs/tech/mmmc"

[tools.genus]
effort = "high"

[tools.innovus]
route_effort = "high"
```

<!---
### 3.9 Technology Input Contract

#### 3.9.1 stage_launch.sh Generation

For each stage, PFXCore SHALL generate a `stage_launch.sh` script in the
corresponding stage directory.

This script is responsible for invoking the tool specified in
`pipeline.toml` and propagating its exit status.

Required behavior:

1.  Enable strict shell checking (`set -euo pipefail`)
2.  Change to the stage directory
3.  Source `../../env.sh`
4.  Execute the `stage.exec.argv` command
5.  Exit with the tool return code

Example `stage_launch.sh`:

``` sh
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
source ../../env.sh

exec "${PFX_ARGV[@]}"
```

### 3.9.2 Bundle Definition Schema

Bundles are stored in a managed catalog (site-controlled) and expanded
by PFXCore into explicit file sets. Technology references remain
anonymous in this document.

Bundle definitions are stored in:

\$PFX_TECH_CATALOG/bundles/`<name>`{=html}.toml

Example bundle:

``` toml
[bundle]
name = "GENERIC_ADV_NODE_V1"
version = "2026Q1"

[timing]
liberty = ["lib/ss.lib", "lib/tt.lib", "lib/ff.lib"]

[physical]
cell_lef = ["lef/cells.lef"]
macro_lef = ["lef/macros.lef"]
tech_lef = "lef/tech.lef"

[routing]
cadence_tech = "route/tech.lef"
synopsys_tf = "route/tech.tf"

[extraction]
qrc_tech = "pex/qrcTech.tch"
starrc_tech = "pex/starrc.tch"

[mmmc]
views = "mmmc/views.tcl"

[metadata]
units = "ps/um"
process = "anonymous"
```

#### 3.9.3 Normalization Rules

PFXCore SHALL expand the bundle into a run-local `inputs/tech/` capsule
and validate all required components.

PFXCore SHALL:

1.  Load bundle definition.
2.  Resolve all referenced files.
3.  Validate required components.
4.  Normalize units.
5.  Generate tool-compatible views.
6.  Populate resolved directories.

#### 3.9.4 Canonical Technology Layout

Within `inputs/tech/`:

inputs/tech/ liberty/ lef/ tech.lef cells.lef macros.lef route/
cadence_tech.lef synopsys.tf pex/ qrcTech.tch starrc.tch mmmc/ views.tcl
config/ tech_resolved.json

Notes: - The *router configuration* component is explicitly represented
under `route/`. - The *PEX tech* component is explicitly represented
under `pex/`.

#### 3.9.5 Technology Manifest

`meta/inputs_manifest.json` SHALL include technology inputs (LEF,
liberty, route tech files, extraction tech files, MMMC) with source
paths, run-local paths, and basic metadata (size, mtime, optional hash).
--->

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

1.  issue a warning,
2.  attempt an automatic migration when feasible,
3.  fail the run if migration is required but not possible or fails.

------------------------------------------------------------------------

## 3.12 Variable Propagation Model

PFXCore generates `pfx_vars.tcl` from `run.toml` and stage context.

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

<!---
### 3.12.1 Supported Data Model

- Nested tables are NOT supported
- Only flat key/value mappings are permitted
- Keys may contain only letters, digits, underscores (`_`), dots (`.`), and dashes (`-`)
- Any malformed key SHALL be rejected
--->

### 3.12.2 Value Restrictions

Variable values:

- MUST NOT contain dollar signs (`$`)
- MUST NOT contain quotes (`"` or `'`)
- MUST NOT contain newlines
- MUST NOT contain backslashes (`\`)

Values violating these rules SHALL cause execution failure.

### 3.12.3 Tcl Emission Format

All variables SHALL be emitted in the following canonical form:

```
set pfx(key) {value}
```

No alternative quoting or escaping mechanisms are permitted.

### 3.12.4 Export Sources

By default, PFXCore SHALL export **all eligible variables** from the following specification files into `pfx_vars.tcl`:

* `run.toml`
* `pipeline.toml`
* `design.toml`
* `tech.toml`

There is no selective export mechanism in v1. All variables that satisfy the supported data model and value restrictions SHALL be exported.

### 3.12.5 Reserved Exported Variables

PFXCore SHALL always export the following reserved variables (even if not present in any TOML input file):

- `pfx(run.dir)` — canonical absolute path to the run directory.
- `pfx(stage.name)` — current stage name.
- `pfx(stage.order)` — current stage order value.
- `pfx(stage.dir)` — canonical absolute path to the stage directory (`<run_dir>/stages/<NN>_<stage>/`).


Eligibility is determined solely by the rules in Sections 3.12.1 and 3.12.2.

---

### 3.12.5 Key Character Set

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

### 3.12.6 TOML to Tcl Variable Name Mapping

Variables are exported by flattening TOML key paths into a single dot-separated key, prefixed by the source file namespace.

The general mapping rule is:

```
<prefix>.<toml_path>  →  set pfx(<prefix>.<toml_path>) {value}
```

Where:

| Source File     | Prefix     |
| --------------- | ---------- |
| `run.toml`      | `run`      |
| `pipeline.toml` | `pipeline` |
| `design.toml`   | `design`   |
| `tech.toml`     | `tech`     |

---

#### 3.12.6.1 Table Flattening

For a scalar value at TOML path:

```
[a]
[b]
c = value
```

The exported Tcl variable SHALL be:

```
set pfx(a.b.c) {value}
```

Nested tables are permitted **only for the purpose of flattening**. The final flattened key MUST satisfy the key character set rules.

---

#### 3.12.6.2 Arrays

TOML arrays SHALL be exported as Tcl lists, preserving order.

Example:

```toml
[design.sources]
filelists = ["a.f", "b.f"]
```

Exports:

```tcl
set pfx(design.sources.filelists) {a.f b.f}
```

---

#### 3.12.6.3 Pipeline Stage Mapping

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
set pfx(pipeline.stage.synth.order) {10}
set pfx(pipeline.stage.synth.exec.argv) {genus -files scripts/synth.tcl}
```

Stage names MUST conform to the key character set rules in Section 3.12.5.

---

### 3.12.7 Failure Semantics

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
3.  Source \`../../env.sh is generated by PFXStudy and MUST exist before
    PFXCore execution.
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

PFXCore SHALL export the absolute run directory path into `pfx_vars.tcl` as:

```tcl
set pfx(run.dir) {<absolute path to run_dir>}
```

Tool Tcl scripts SHALL resolve run-relative paths by joining them to `pfx(run.dir)` (e.g., via Tcl `file join`).

PFXCore SHALL NOT rewrite or canonicalize run-relative paths inside `run.toml`.

### 3.15.6 `[run]` Table

| Field            | Type   | Required | Semantics                                                |
|------------------|--------|---------:|----------------------------------------------------------|
| `run_id`         | string |      yes | Unique run identifier (stable within a study)            |
| `study_name`     | string |      yes | Study identifier (human meaningful)                      |
| `semantic_path`  | string |      yes | DOE semantic path string used to place the run directory |
| `schema_version` | string |       no | Defaults to `"1"`                                        |

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


<!---
## 3.15 run.toml Schema (v1)

### 3.15.1 Required Tables

A `run.toml` file SHALL contain:

-   `[run]`
-   `[doe]`
-   `[design]`
-   `[technology]`

### 3.15.2 Optional Tables

-   `[paths]`
-   `[vars]`
-   Tool-specific tables

### 3.15.3 \[run\] Table

| Field         | Type   | Description       |
|---------------|--------|-------------------|
| run_id        | string | Unique run ID     |
| study_name    | string | Study identifier  |
| semantic_path | string | DOE semantic path |


### 3.15.4 Immutability

PFXCore SHALL NOT modify `run.toml`.

------------------------------------------------------------------------

## Example run.toml (Full DOE Instance)

``` toml
[run]
run_id = "run_0127"
study_name = "vdd_density_sweep"
semantic_path = "vdd=0.70/density=0.55/temp=25/r0127"

[doe]
vdd = 0.70
density = 0.55
temp = 25

[design]
top = "cpu_core"
rtl_type = "systemverilog"
filelist = "rtl/files.f"
include_dirs = ["rtl/include"]
defines = ["SYNTH","USE_FASTRAM"]
sdc_files = ["constraints/top.sdc"]

[technology]
bundle = "ADV14_GENERIC_V1"
corner = "tt"
voltage = 0.70
temperature = 25

[genus]
effort = "high"
retime = true

[innovus]
place_density = 0.70
cts_mode = "balanced"
route_effort = "high"
```
--->

## 3.16 status.json Schema (v1)

### 3.16.1 Purpose

Each stage directory SHALL contain a `status.json` file recording
launch and completion information.

### 3.16.2 Lifecycle Semantics

### 3.16.3 Completion and Resumption Rule

A stage SHALL be considered successfully completed if and only if:

- `end_time` is present, AND
- `exit_code` is present and equal to 0

PFXCore MAY skip re-execution of such stages unless `--force` is specified.


PFXCore SHALL:

1. Create `status.json` when a stage is launched
2. Record `start_time`
3. Update the file on process termination
4. Record `end_time` and `exit_code` if available

No additional state machine is defined.

Success or failure interpretation is left to higher layers.



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
