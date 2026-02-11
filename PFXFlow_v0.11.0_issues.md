## Issues I've found
- In `design.toml` I've defined `desgin_top`. But the Tcl variable comes out weird as `pfx_design_design_top`
  - Consider changing back to simply `top`.
  - Same deal for `design_nickname`. Consider simply `nickname`
- In `pipeline.toml` section, the stage name and directory are explicitly called `pfx_stage_name` and `pfx_stage_dir`
  - Consider changing tohse to `pfx_current_stage_name` and `pfx_current_stage_dir` which would be clearer.
- Currently the spec does not explicitly say what happens if unspecified keys are added
  - Spec should specifically deal with those.
  - ## Extensibility and Unknown Keys

```
### Open Tables (Default)

Unless explicitly stated otherwise, **all TOML tables defined by this specification are open and extensible**.

Implementations **MUST** accept additional keys not explicitly listed in the table definitions. The presence of unknown keys **MUST NOT** cause validation failure.

Unknown keys and their associated values:

* **MUST** be preserved during parsing
* **MUST** be preserved through configuration composition and merging
* **MUST** be included in language export mechanisms (e.g., Tcl, Python), subject to normal name‑flattening and escaping rules

Implementations **MAY** emit warnings for unknown keys, but **MUST** provide a mechanism to disable such warnings.

---

### Closed Tables (Explicit Exception)

A table may be treated as **closed** only when this specification explicitly declares it to be closed.

For closed tables:

* Unknown keys **MUST** be treated as errors
* Validation **MUST** fail if unknown keys are present

In the absence of an explicit declaration that a table is closed, the table **MUST** be treated as open.

---

### Validation Requirements

Configuration validators:

* **MUST NOT** reject configurations solely due to the presence of unknown keys in open tables
* **MAY** warn about unknown keys
* **MUST NOT** drop or ignore unknown keys silently

---

### Language Export and Reserved Name Collisions

When exporting configuration values to language bindings (e.g., Tcl or Python):

* Unknown keys **MUST** be exported using the same flattening and naming rules as known keys
* If an exported variable name collides with a reserved or special variable name defined by this specification, the implementation **MUST** resolve the collision deterministically (e.g., by appending a suffix such as `_` or `_user`)
* Such collisions **SHOULD** be reported as warnings

This ensures extensibility without compromising deterministic behavior or overwriting specification‑defined variables.
```
