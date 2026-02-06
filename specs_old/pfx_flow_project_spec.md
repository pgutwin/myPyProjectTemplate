# Project: PFXflow

## 0. Meta & Status

- **Owner:** Paul Gutwin
- **Doc status:** Draft 
- **Last updated:** 2026-01-19
- **Change log:**
  - 2026-01-19 – Initial draft

---

## 1. Project Overview

### 1.1 Problem Statement

There is a need for a need for a light-weight VLSI block implementation experiment manager.
The goal of this experiment manager is, given a specific design, run the design with the same flow


The design flow should be based on a "template" set of scripts that can be modified.

Focus on *user-visible behavior*, not implementation details.

### 1.2 Goals

Concrete, testable goals.

- G1: <e.g., Parse X, Y, Z formats into a unified Python object model>
- G2: <e.g., Provide a clean, documented Python API for analyses A, B, C>
- G3: <e.g., Process datasets up to N elements within M seconds on a laptop>

### 1.3 Non-Goals

Explicit exclusions to prevent scope creep.

- NG1: <e.g., No GUI or web service in v1>
- NG2: <e.g., No distributed execution>
- NG3: <e.g., No C/C++ extensions unless strictly required>

### 1.4 Success Criteria

How do you know v1 is done?

- Functional completeness (which goals must be met)
- Performance expectations (order-of-magnitude is fine)
- Quality bar (tests passing, docs written, stable API)

---

## 2. Users, Use Cases & Workflows

### 2.1 Target Users

- **Primary users:** <e.g., Python library users, researchers, tool developers>
- **Secondary users:** <e.g., CLI-only users, students>

State assumptions about user skill level (Python familiarity, domain knowledge).

### 2.2 Key Use Cases

Describe how the project is actually used.

- **UC1: <Name>**
  - Step 1: User installs package
  - Step 2: Imports module or runs CLI
  - Step 3: Calls API / command
  - Output: Python objects, files, reports, etc.

- **UC2: <Name>**
  - ...

### 2.3 Example Scenarios

Short narrative examples that tie APIs, CLI, and data together.

---

## 3. Architecture Overview

### 3.1 High-Level Structure

Describe the major layers and how they interact.

Typical Python-oriented components:

- `core/` – domain objects and algorithms
- `io/` – file formats, parsers, serializers
- `api/` – public-facing API (often re-exported from `__init__.py`)
- `cli/` – command-line interface (argparse / typer / click)
- `utils/` – small shared helpers

### 3.2 Dependency Direction

State dependency rules explicitly.

- `core` has **no dependency** on CLI or I/O
- `io` depends on `core`
- `cli` depends on `core` and `io`

### 3.3 Data Flow

For each major workflow:

- Input → parsing → core processing → output
- Where state lives (in-memory objects, files, caches)

---

## 4. Data Model & Core Abstractions

This defines the *conceptual model* exposed to users.

### 4.1 Domain Concepts

Plain-English descriptions.

- **Entity A** – what it represents
- **Entity B** – key attributes
- **Relationships** – containment, references, graphs, etc.

### 4.2 Core Python Types

For each important type:

- Name
- Responsibility
- Attributes (with types)
- Invariants
- Mutability expectations

Example:

```text
Type: Circuit
Responsibility: In-memory representation of a circuit graph.

Attributes:
- name: str
- nets: dict[str, Net]
- devices: list[Device]

Invariants:
- Net names are unique
- Devices only reference existing nets

Notes:
- Mutable during construction, treated as read-only by algorithms
```

State whether types are:
- Plain classes
- `@dataclass`
- Frozen / immutable

### 4.3 Persistence & Serialization

- Supported formats (JSON, YAML, pickle, custom)
- Versioning strategy for serialized data
- Backward compatibility expectations

---

## 5. Algorithms & Pipelines

### 5.1 Algorithm Inventory

List all non-trivial computations.

- A1: <Name> – <summary>
- A2: <Name> – <summary>

### 5.2 Algorithm Specification Template

**A#: <Algorithm Name>**

- **Purpose:** What problem it solves
- **Inputs:** Python types, constraints
- **Outputs:** Python types, semantics
- **Complexity:** Rough time/space expectations
- **Description:**
  - Step 1: ...
  - Step 2: ...
- **Edge cases:** Enumerate explicitly
- **Testing:** Unit vs integration tests

Pseudo-code is encouraged but optional.

---

## 6. Package Layout & API Boundaries

### 6.1 Directory Structure

Example:

```text
project_root/
  pyproject.toml
  src/
    project_name/
      __init__.py
      core/
      io/
      cli/
  tests/
    unit/
    integration/
  docs/
    PROJECT_SPEC.md
```

Use a `src/` layout unless you have a reason not to.

### 6.2 Public vs Internal API

Define what is stable and what is private.

- Public API:
  - Exposed via `project_name/__init__.py`
  - Covered by compatibility guarantees

- Internal modules:
  - May change freely
  - Prefixed with `_` if appropriate

### 6.3 Naming & Style

- Module and package naming
- Type hints required or optional
- Error handling strategy (exceptions only; no error codes)

---

## 7. Dependencies, Tooling & Environment

### 7.1 Python Version & Platforms

- **Python:** <e.g., 3.10+>
- **Supported OS:** <macOS, Linux, Windows>

### 7.2 Dependencies

For each dependency:

- Name
- Purpose
- Runtime vs dev dependency

Prefer minimal dependencies; justify heavy ones.

### 7.3 Tooling

- Build / packaging: `pyproject.toml`, setuptools / hatch / poetry
- Formatting: black, ruff
- Type checking: mypy / pyright
- Testing: pytest

---

## 8. Testing & Quality Strategy

### 8.1 Test Types

- Unit tests: fast, deterministic
- Integration tests: slower, end-to-end

### 8.2 Coverage & CI

- Coverage targets (if any)
- CI expectations (what must pass before merge)

### 8.3 Error Handling & Logging

- Exception philosophy
- Logging framework and levels

---

## 9. LLM Collaboration Plan

### 9.1 Intended Use of ChatGPT

- Generate boilerplate code consistent with this spec
- Draft algorithms and test cases
- Help refactor for clarity and structure

### 9.2 Guardrails

- This document is the source of truth
- No silent API or data model changes
- Code must be runnable and testable

### 9.3 Prompt Patterns

Examples:

- “Given the Data Model section, generate Python dataclasses.”
- “Implement Algorithm A1 following the spec exactly.”
- “Write pytest tests enforcing these invariants.”

---

## 10. Roadmap & Milestones

### 10.1 Phases

1. Skeleton & packaging
2. Core data model
3. I/O and persistence
4. Algorithms
5. CLI and polish

Each phase should leave the project in a usable state.

### 10.2 Milestones

For each phase:

- Deliverables
- Exit criteria

---

## 11. Open Questions & Risks

### 11.1 Open Questions

- OQ1: ...
- OQ2: ...

### 11.2 Risks

- Technical risks
- Dependency risks
- Scope creep

---

## 12. Appendices

### 12.1 Glossary

### 12.2 References

### 12.3 Rejected Alternatives

Brief notes on approaches considered and why they were rejected.

