# Proposed Spec Sections: `tech.toml` and `design.toml` (v1)

This document proposes two new run-directory collateral files:

- `tech.toml` — technology specification (run-local binding to an `inputs/tech/` bundle)
- `design.toml` — design specification (run-local binding to an `inputs/design/` bundle)

These sections are written in “spec voice” so they can be dropped into the master PFXFlow project spec with minimal editing.

---

## X. `tech.toml` Syntax and Semantics (v1)

### X.1 Purpose

`tech.toml` defines the technology bundle for a run. It binds tool-agnostic technology metadata (corner, PVT, naming) to a concrete directory tree under the run directory:

```
<run_dir>/inputs/tech/
```

PFXCore **does not validate** the contents of the bundle; it only requires that:

- `<run_dir>/inputs/tech/` exists (and is a directory)

PFXStudy is responsible for populating the bundle.

### X.2 Location

`tech.toml` SHALL be located at:

```
<run_dir>/tech.toml
```

`run.toml` SHALL reference it:

```toml
[technology]
spec_file = "tech.toml"
```

### X.3 Required Tables

`tech.toml` SHALL contain:

- `[tech]` (required)
- `[paths]` (required)
- `[export]` (optional)
- `[tools.<tool_name>]` (optional)

### X.4 `[tech]` Table

| Field | Type | Required | Semantics |
|---|---|---:|---|
| name | string | yes | Technology bundle identifier (human meaningful) |
| corner | string | yes | Corner name (e.g., tt, ss, ff, etc.) |
| voltage | float | no | Nominal voltage (V) for informational/traceability use |
| temperature_c | float | no | Nominal temperature (°C) for informational/traceability use |
| schema_version | string | no | Defaults to `"1"` |

Semantics:
- `name` is metadata. PFXCore does not interpret it.
- `corner` is metadata but commonly used to select tool scripts; PFXCore exports it (see `export`).

### X.5 `[paths]` Table

`paths` binds logical technology views to directories under `inputs/tech/`. All values are **run-directory relative paths**.

| Field | Type | Required | Semantics |
|---|---|---:|---|
| root | string | no | Defaults to `"inputs/tech"`; used as base for relative paths |
| lef_dir | string | no | Directory containing LEF/tech LEF |
| lib_dir | string | no | Directory containing Liberty timing libraries |
| qrc_dir | string | no | Directory containing QRC/RC models |
| mmmc_dir | string | no | Directory containing MMMC files (if used) |
| pdk_misc_dir | string | no | Optional directory for tool-specific collateral |

Semantics:
- PFXStudy populates these directories; PFXCore does not check file presence.
- Paths are used only for **variable export** and/or for tool scripts to locate assets.

### X.6 Optional Tool Overrides: `[tools.<tool_name>]`

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

### X.7 Variable Export: `[export]`

If present, `[export]` declares which `tech.toml` values are exported into `pfx_vars.tcl`.

#### X.7.1 Exported Keyspace

Exported keys use dot notation and a stable prefix:

- `tech.<field>` for values from `[tech]`
- `tech.paths.<field>` for values from `[paths]`
- `tech.tools.<tool>.<field>` for values from `[tools.<tool>]`

#### X.7.2 Export Restrictions (Hard)

To be exported, each value MUST satisfy:

- Value is scalar (`string`, `int`, `float`, `bool`) or `array[string|int|float|bool]`
- **No nested tables** at any exported key
- Exported key MUST match regex: `[A-Za-z0-9.-]+`
- Exported value MUST NOT contain: `$`, `"`, `'`, backslash, or newline

Violations SHALL cause PFXCore to fail the stage before launch.

#### X.7.3 Default Export Set (if `[export]` omitted)

If `[export]` is omitted, PFXCore exports the following defaults:

- `tech.name`
- `tech.corner`
- `tech.voltage` (if present)
- `tech.temperature_c` (if present)
- `tech.paths.root` (if present)
- any non-empty `paths.*` fields

### X.8 Example `tech.toml`

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

---

## Y. `design.toml` Syntax and Semantics (v1)

### Y.1 Purpose

`design.toml` defines the design bundle for a run. It binds tool-agnostic design metadata (top module, filelists, constraints) to a concrete directory tree under:

```
<run_dir>/inputs/design/
```

PFXCore only requires that `inputs/design/` exists. PFXStudy is responsible for populating it.

### Y.2 Location

`design.toml` SHALL be located at:

```
<run_dir>/design.toml
```

`run.toml` SHALL reference it:

```toml
[design]
spec_file = "design.toml"
```

### Y.3 Required Tables

`design.toml` SHALL contain:

- `[design]` (required)
- `[sources]` (required)
- `[constraints]` (optional)
- `[export]` (optional)
- `[tools.<tool_name>]` (optional)

### Y.4 `[design]` Table

| Field | Type | Required | Semantics |
|---|---|---:|---|
| top | string | yes | Top module / design name |
| rtl_type | string | no | e.g., `"verilog"`, `"systemverilog"` |
| schema_version | string | no | Defaults to `"1"` |

### Y.5 `[sources]` Table

All paths are **run-directory relative** unless otherwise stated.

| Field | Type | Required | Semantics |
|---|---|---:|---|
| filelists | array[string] | yes | One or more filelist paths |
| include_dirs | array[string] | no | Include directories |
| defines | array[string] | no | Preprocessor defines |
| rtl_root | string | no | Optional base directory for RTL |

Semantics:
- PFXCore does not parse RTL; it exports these paths/flags so tool scripts can consume them.
- Filelist format is tool-defined (e.g., `-f` style); PFXCore treats them as opaque strings.

### Y.6 `[constraints]` Table (Optional)

| Field | Type | Required | Semantics |
|---|---|---:|---|
| sdc_files | array[string] | no | SDC constraints file paths |
| clocks | array[string] | no | Optional list of clock names |
| clock_period_ps | int | no | Optional nominal clock period |

Semantics:
- These values exist for tool scripts and traceability.

### Y.7 Optional Tool Overrides: `[tools.<tool_name>]`

Same semantics as in `tech.toml`: tool-specific knobs may be recorded and selectively exported, but PFXCore does not interpret them.

### Y.8 Variable Export: `[export]`

Exported keys use prefixes:

- `design.<field>` for `[design]`
- `design.sources.<field>` for `[sources]`
- `design.constraints.<field>` for `[constraints]`
- `design.tools.<tool>.<field>` for tool overrides

Export restrictions are identical to `tech.toml` (see X.7.2). Nested tables SHALL NOT be exported.

### Y.9 Default Export Set (if `[export]` omitted)

If `[export]` is omitted, PFXCore exports:

- `design.top`
- `design.rtl_type` (if present)
- `design.sources.filelists`
- `design.sources.include_dirs` (if present)
- `design.sources.defines` (if present)
- `design.constraints.sdc_files` (if present)

### Y.10 Example `design.toml`

```toml
[design]
top = "cpu_core"
rtl_type = "systemverilog"
schema_version = "1"

[sources]
filelists = ["inputs/design/rtl/files.f"]
include_dirs = ["inputs/design/rtl/include"]
defines = ["SYNTH", "USE_FASTRAM"]

[constraints]
sdc_files = ["inputs/design/constraints/top.sdc"]

[tools.genus]
retime = true
```
