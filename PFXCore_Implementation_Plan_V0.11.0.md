# PFXCore Implementation Plan

**Version:** 2.0  
**Date:** 2026-02-11  
**Based on:** PFXFlow Project Spec v0.11.0

---

## Executive Summary

This plan breaks PFXCore implementation into 7 phases, progressing from foundational data structures through complete execution capability with robust subprocess management. Each phase produces testable, working code that builds toward the full specification.

**Estimated Timeline:** 9.5-13.5 weeks for core functionality (Phases 1-5)  
**Language:** C++20  
**Key Dependencies:** Header-only libraries: toml11 (TOML parsing), nlohmann/json (JSON parsing)  
**Architecture:** Custom POSIX subprocess management, standard exception-based error handling, sequential stage execution

---

## Phase 1: Foundation and Core Data Structures

**Duration:** 1-2 weeks  
**Goal:** Establish project structure, configuration parsing, and immutable core types

### 1.1 Project Setup
- [ ] Initialize git repository with modern C++20 structure
- [ ] Set up CMake build system with proper target organization
- [ ] Configure compiler flags for C++20 features
- [ ] Set up test framework (Google Test or Catch2)
- [ ] Create directory structure matching spec requirements
- [ ] Integrate header-only dependencies (toml11, nlohmann/json)
  - Add as git submodules or via CMake FetchContent
  - Verify compilation with simple test programs

### 1.2 TOML Configuration Parser
- [ ] Implement TOML parsing wrapper with type-safe accessors
- [ ] Create schema validation framework for TOML files
- [ ] Implement error reporting with file/line context
- [ ] Add comprehensive tests for TOML edge cases

### 1.3 Core Immutable Types
- [ ] **RunConfig**: Parsed representation of `run.toml`
  - Run metadata (name, design, technology)
  - Variable definitions with type information
  - Validation rules
  - **New:** `stage_timeout_seconds` field (default: 3596400)
- [ ] **PipelineConfig**: Parsed representation of `pipeline.toml`
  - Stage definitions with ordering
  - Input/output declarations
  - Hook specifications
- [ ] **StageDefinition**: Individual stage metadata
  - Name, order, execution config
  - Input/output file specifications
  - Environment requirements
- [ ] **TemplateVariables**: Type-safe variable container
  - Support for string, int, float, boolean types
  - Immutable after construction
  - Validation against declared schemas

### 1.4 Path Abstractions
- [ ] **RunPath**: Type-safe path operations within run directory
  - Absolute/relative conversions
  - Validation of path structure
  - Semantic path component accessors
- [ ] **StagePath**: Stage-specific path handling
  - Input/output path resolution
  - Cross-stage reference validation

**Deliverables:**
- Compiling library with core types
- Comprehensive unit tests (>80% coverage)
- Documentation for data structures
- Example programs demonstrating type usage

---

## Phase 2: Configuration Validation and Composition

**Duration:** 1.5-2 weeks  
**Goal:** Implement full configuration validation and composition logic

### 2.1 Schema Validator
- [ ] **ConfigValidator**: Master validation orchestrator
  - Schema version checking
  - Required field validation
  - Type constraint enforcement
  - Cross-reference validation
- [ ] **DesignValidator**: Design-specific validation
  - RTL file existence checks
  - Constraint file validation
  - Module hierarchy validation
- [ ] **TechnologyValidator**: Technology catalog validation
  - LEF/LIB file validation
  - Layer map consistency
  - Technology node requirements

### 2.2 Variable Expansion and Template Processing
- [ ] **TemplateExpander**: Variable substitution engine
  - Placeholder syntax parsing (`${VAR}`, `${VAR:default}`)
  - Recursive expansion with cycle detection
  - Type-aware expansion
  - Error reporting for undefined variables
- [ ] **TemplateComposer**: Multi-layer template merging
  - Base template loading
  - Overlay application with precedence rules
  - Inheritance chain validation
  - Final configuration generation

### 2.3 Dependency Resolution
- [ ] **StageGraph**: Stage dependency analyzer
  - Build DAG from pipeline.toml
  - Detect circular dependencies
  - Generate execution order
  - Validate input/output chaining
- [ ] **FileTracker**: Input/output file tracking
  - Expected file declarations
  - Presence validation
  - Cross-stage file handoff verification

**Deliverables:**
- Working validator with comprehensive error messages
- Template expansion system with full test coverage
- Stage dependency resolver
- CLI tool for validating configurations in isolation

---

## Phase 3: Run Materialization Engine

**Duration:** 2.5 weeks  
**Goal:** Generate complete run directories from validated configurations

### 3.1 Directory Materializer
- [ ] **RunMaterializer**: Master directory generator
  - Create semantic directory structure
  - Ensure ownership model compliance
  - Generate required stub files
- [ ] **StageMaterializer**: Per-stage directory setup
  - Create `stages/<NN>_<stage>/` structure
  - Set up `inputs/`, `outputs/`, `reports/`, `logs/` subdirs
  - Initialize `status.json` with "not_started" state
  - Initialize `processes.json` placeholder
  - Generate placeholder files as needed

### 3.2 Script Generation
- [ ] **LaunchScriptGenerator**: Generate `stage_launch.sh`
  - Bash script template with error handling
  - Environment sourcing logic
  - Tool invocation with proper argv
  - Output validation hooks
- [ ] **EnvScriptGenerator**: Generate stage-specific environment
  - Export pfx_* variables from run.toml
  - Stage-specific path variables
  - Tool license variables
  - Working directory setup
- [ ] **TclDriverGenerator**: Generate tool-specific Tcl drivers
  - Parse hook specifications
  - Generate init/pre/post Tcl scripts
  - Variable passing from shell to Tcl
  - Error propagation

### 3.3 Language Exporters (New in v0.11.0)
- [ ] **TclExporter**: Generate `pfx_vars.tcl`
  - Flatten nested TOML tables with underscores
  - Export arrays as indexed variables (pfx_array_0, pfx_array_1, ...)
  - Proper escaping (backslash, quotes, dollar signs, brackets)
  - Reserved word handling (suffix with underscore)
  - Type mapping (boolean → 0/1, etc.)
- [ ] **PythonExporter**: Generate `pfx_vars.py`
  - Flatten nested TOML tables with underscores
  - Export arrays as Python lists
  - Proper escaping (standard Python rules)
  - Reserved word handling (suffix with underscore)
  - Type mapping (boolean → True/False, etc.)
- [ ] **ExporterBase**: Common flattening and escaping logic
  - Dot → underscore conversion
  - Special variable export (pfx_run_dir, pfx_stage_name, etc.)
  - Reserved word detection
  - Validation of exported files

### 3.4 Input/Script Linking
- [ ] **InputLinker**: Symlink/copy input files
  - Design files from normalized location
  - Technology files from tech catalog
  - Constraint files
  - Custom scripts from `scripts/` directory
- [ ] **ScriptCollector**: Gather stage scripts
  - Collect tool-specific Tcl files
  - Copy custom launch wrappers
  - Validate script permissions

**Deliverables:**
- Fully materialized run directories
- Generated launch scripts for all stages
- Both pfx_vars.tcl and pfx_vars.py in each stage
- Comprehensive integration tests
- Materialization dry-run capability for debugging

**Testing Focus:**
- Round-trip validation (TOML → Tcl → parse → verify)
- Round-trip validation (TOML → Python → import → verify)
- Reserved word handling in both languages
- Special character escaping
- Array flattening correctness

---

## Phase 4: Stage Execution Engine with Process Management

**Duration:** 3-4 weeks  
**Goal:** Execute individual stages with full subprocess management, timeout enforcement, and robust cleanup

### 4.1 Stage Executor Core
- [ ] **StageRunner**: Single-stage execution manager
  - Prerequisite validation
  - Stale process cleanup (Section 3.18.5)
  - Launch script execution via subprocess
  - Real-time output capture (stdout/stderr)
  - Exit code handling
  - Signal handling for interrupts
  - Timeout monitoring
- [ ] **ProcessManager**: Custom POSIX subprocess management
  - **Process group creation:**
    - `fork()` + `setpgid(0, 0)` for new process group
    - PGID = root PID for isolation
  - **Stdout/stderr redirection** to log files via pipes
  - **Environment inheritance** and modification
  - **Working directory** management
  - **Timeout enforcement:**
    - Poll loop (1 second interval)
    - Elapsed time tracking
    - Termination on timeout exceeded
  - **Process group termination:**
    - `killpg(pgid, SIGTERM)` for entire tree
    - 5-second grace period (hardcoded)
    - `killpg(pgid, SIGKILL)` for force kill
  - **Signal propagation** (SIGINT, SIGTERM handling)

### 4.2 Orphan Detection and Cleanup
- [ ] **OrphanDetector**: Scan for orphaned processes
  - `/proc` scanning for PGID matches
  - Parse `/proc/<pid>/stat` for process group info
  - Identify descendants after root exit
  - Performance optimization (cache directory listings)
- [ ] **OrphanTerminator**: Kill orphaned processes
  - Send SIGTERM to each orphan individually
  - 5-second grace period
  - Send SIGKILL to remaining processes
  - Reap zombies via `waitpid()`
  - Record all actions in processes.json

### 4.3 Stale Process Cleanup
- [ ] **StaleProcessDetector**: Detect processes from crashed runs
  - Read previous `processes.json` in stage directory
  - Check `cleanup.cleanup_complete` flag
  - Extract PGID from previous run
  - Scan `/proc` for processes in that PGID
- [ ] **StaleProcessCleaner**: Terminate stale processes
  - SIGTERM → 5 sec → SIGKILL sequence
  - Record in `startup_cleanup` section of processes.json
  - Abort stage if cleanup fails (unkillable processes)
  - Error reporting for permission issues

### 4.4 Status Tracking
- [ ] **StatusWriter**: Manage `status.json` lifecycle
  - Initialize on stage start with timestamp
  - Update during execution
  - Finalize on completion with results
  - Handle new states: "timeout", "interrupted"
  - Atomic write operations for safety
- [ ] **StatusReader**: Parse and validate status.json
  - Read existing stage status
  - Determine if stage can be skipped
  - Validate schema version compatibility
- [ ] **CompletionChecker**: Stage success validation
  - Verify exit code == 0
  - Verify state == "complete"
  - Check all declared outputs exist
  - Update `success` flag accurately
  - Generate human-readable status messages

### 4.5 Process Tracking (New in v0.11.0)
- [ ] **ProcessTracker**: Generate and update processes.json
  - **On stage start:**
    - Create processes.json with root process info
    - Record PID, PGID, command, argv
    - Record timeout configuration
    - Record start_time
  - **On termination:**
    - Record end_time, exit_code, signal
    - Record orphan detection results
    - Record all cleanup actions
  - **Cleanup section:**
    - orphans_found list
    - kill_signals_sent array with timestamps
    - cleanup_complete boolean
    - zombies_remaining count
  - **Startup cleanup section** (if stale processes detected)
  - Schema validation on write

### 4.6 File Validation
- [ ] **FilePresenceChecker**: Pre/post execution file validation
  - Check declared inputs before execution
  - Check declared outputs after execution
  - Generate `outputs_missing` list
  - Record findings in status.json

### 4.7 Signal Handling
- [ ] **SignalHandler**: Graceful shutdown on interrupts
  - SIGINT handler → terminate stage, cleanup, exit
  - SIGTERM handler → terminate stage, cleanup, exit
  - Set status to "interrupted"
  - Ensure cleanup procedures execute
  - Proper signal mask management during cleanup

### 4.8 Execution Logger
- [ ] **ExecutionLogger**: Structured logging
  - Stage start/end events
  - Error and warning capture
  - Performance metrics (wall time, etc.)
  - Process management events (orphans, timeouts)
  - Structured log format (JSON or similar)

**Deliverables:**
- Working single-stage execution
- Complete status.json lifecycle
- Complete processes.json lifecycle
- Robust process cleanup (orphans, stale processes)
- Timeout enforcement
- Comprehensive error handling
- Integration tests for stage execution
- Log analysis utilities

**Testing Requirements (Critical):**
- Hung process that ignores SIGTERM (needs SIGKILL)
- Process tree depth (3-4 levels of subprocesses)
- Timeout enforcement (process runs too long)
- Stale process detection (simulate PFXCore crash)
- Orphan cleanup after normal exit
- SIGINT during execution (graceful shutdown)
- Unkillable process in D state (cleanup_complete = false)
- Race conditions (process exits during orphan scan)
- Permission denied on kill() syscall
- Large process tree (1000+ processes) performance

---

## Phase 5: Pipeline Orchestration

**Duration:** 1.5-2 weeks  
**Goal:** Execute complete multi-stage pipelines with dependency management

### 5.1 Pipeline Executor
- [ ] **PipelineRunner**: Multi-stage orchestration
  - Load pipeline definition from `pipeline.toml`
  - Execute stages in dependency order
  - Handle stage skipping for completed stages
  - Support `--stage` flag for single-stage runs
  - Support `--from-stage` for partial runs
  - Implement `--force` flag for re-execution
  - **Timeout inheritance:** Apply global timeout to all stages

### 5.2 Continuation and Resumption
- [ ] **ResumptionLogic**: Smart pipeline restart
  - Detect completed stages via status.json
  - Check for "timeout" or "interrupted" states
  - Find first incomplete or failed stage
  - Resume from that point
  - Validate prerequisites still satisfied
- [ ] **ForceRunner**: Forced re-execution handler
  - Clear old status.json files
  - Clear old processes.json files
  - Reset outputs directory
  - Re-run specified stages

### 5.3 Error Handling and Recovery
- [ ] **FailureHandler**: Pipeline failure management
  - Stage failure detection
  - Timeout detection and reporting
  - Interrupted state handling
  - Clean termination of pipeline
  - Status preservation for debugging
  - User-friendly error messages
  - Suggest recovery actions (check processes.json for hung processes)

### 5.4 Hook Integration
- [ ] **HookExecutor**: Custom hook execution
  - Pre-stage hooks
  - Post-stage hooks
  - Error hooks (optional)
  - Hook timeout and error handling

**Deliverables:**
- Complete pipeline execution capability
- Resume/continue functionality
- Integration tests for multi-stage flows
- Error recovery documentation
- Example pipelines for testing
- Timeout/interrupt handling across pipeline

---

## Phase 6: Advanced Features and Polish

**Duration:** 1-2 weeks  
**Goal:** Add convenience features, diagnostics, and usability improvements

### 6.1 Diagnostic Tools
- [ ] **RunInspector**: Query run status and metadata
  - Show pipeline progress
  - Display stage status summary
  - Report file presence/absence
  - Estimate remaining time
  - **New:** Show process cleanup status from processes.json
  - **New:** Identify hung processes
- [ ] **StatusAnalyzer**: Status.json analysis
  - Aggregate statistics across stages
  - Identify bottlenecks
  - Generate reports
  - **New:** Timeout analysis
- [ ] **ProcessAnalyzer**: Process management diagnostics
  - Parse processes.json for debugging
  - Identify patterns in orphan creation
  - Report on cleanup success rates
  - Stale process detection history

### 6.2 Validation Enhancements
- [ ] **DryRunMode**: Validate without execution
  - Full materialization simulation
  - Report what would be created
  - Validate all configurations
  - Estimate resource requirements
  - **New:** Show timeout configuration
- [ ] **ConfigDumper**: Export effective configuration
  - Show fully expanded variables
  - Display final stage configurations
  - Export to human-readable format
  - **New:** Show flattened pfx_* variables (both Tcl and Python)

### 6.3 Performance Optimization
- [ ] **CachingLayer**: Reduce redundant file operations
  - Cache file presence checks
  - Reduce status.json re-reads
  - Reduce processes.json re-reads
  - Optimize directory scans
  - **New:** Cache /proc scans during orphan detection

### 6.4 User Interface Polish
- [ ] **ProgressReporter**: Real-time execution feedback
  - Stage progress bar
  - Time estimates
  - Current operation display
  - **New:** Timeout countdown display
- [ ] **ErrorFormatter**: Beautiful error messages
  - Color-coded output
  - Context-aware suggestions
  - File/line references for config errors
  - **New:** Subprocess cleanup diagnostics

**Deliverables:**
- Diagnostic and inspection tools
- Dry-run validation mode
- Performance benchmarks
- Polished user experience
- Process management debugging tools

---

## Phase 7: Documentation and Hardening

**Duration:** 1 week  
**Goal:** Complete documentation, comprehensive testing, and production readiness

### 7.1 Documentation
- [ ] **API Documentation**: Doxygen or similar
  - All public APIs documented
  - Usage examples for major types
  - Architecture diagrams
  - **New:** ProcessManager implementation details
- [ ] **User Guide**: End-user documentation
  - Command-line reference
  - Configuration examples
  - Troubleshooting guide
  - Best practices
  - **New:** Debugging hung processes
  - **New:** Timeout configuration guide
  - **New:** Interpreting processes.json
- [ ] **Developer Guide**: Internal documentation
  - Architecture overview
  - Adding new features
  - Testing guidelines
  - Release process
  - **New:** Subprocess management implementation

### 7.2 Test Coverage Expansion
- [ ] **Integration Test Suite**
  - Full pipeline execution tests
  - Error recovery scenarios
  - Edge case handling
  - Performance regression tests
  - **New:** Subprocess management test suite (see Phase 4 testing requirements)
  - **New:** Timeout enforcement tests
  - **New:** Stale process cleanup tests
- [ ] **Fuzzing Harness** (optional)
  - Configuration fuzzing
  - Error injection testing
  - Crash detection

### 7.3 Production Hardening
- [ ] **Memory Safety**: Valgrind/AddressSanitizer clean
- [ ] **Error Handling**: All error paths tested
- [ ] **Resource Cleanup**: RAII enforcement, no leaks
  - **New:** Verify no zombie processes after execution
  - **New:** Verify process group cleanup
- [ ] **Signal Handling**: Graceful shutdown on SIGINT/SIGTERM
  - **New:** Verify cleanup on interrupted execution
- [ ] **File System Safety**: Atomic operations, error recovery

### 7.4 Build and Packaging
- [ ] **Installation**: Standard install target
- [ ] **Package Scripts**: RPM/DEB packaging
- [ ] **Version Management**: Semantic versioning
- [ ] **Release Notes**: Change log and migration guides

**Deliverables:**
- Complete documentation set
- >90% test coverage
- Production-ready binary
- Packaging for distribution
- Release checklist

---

## Cross-Cutting Concerns

### Error Handling Strategy
- Use C++20 standard exceptions with custom exception hierarchy
  - `PFXException` base class with contextual information
  - Derived exceptions: `ConfigError`, `ValidationError`, `ExecutionError`, `FileSystemError`
  - **New:** `ProcessManagementError` for subprocess failures
- Provide rich context in all error messages (file, line, variable name, expected vs. actual)
- Include actionable suggestions for fixing common errors
- Log all errors to structured log files with full stack context
- Use RAII to ensure cleanup on exception paths
- **New:** Always attempt process cleanup even on exception

### Testing Strategy
- Unit tests for all isolated components (>80% coverage target)
- Integration tests for end-to-end workflows
- Regression tests for bug fixes
- Performance benchmarks for key operations
- Test with realistic configurations from day one
- **New:** Extensive subprocess management testing (see Phase 4)
- **New:** Timeout and interrupt testing
- **New:** Stale process cleanup testing

### Code Quality
- Enforce const-correctness throughout
- Use RAII for all resource management
- Prefer immutability by default
- Use std::optional for nullable values
- Use std::variant for type-safe unions
- Leverage C++20 concepts for template constraints
- Follow modern C++ core guidelines
- **New:** Careful signal handling (no async-unsafe functions in handlers)

### Dependencies
- **Required (all header-only):**
  - TOML parsing: toml11 (https://github.com/ToruNiina/toml11)
  - JSON parsing: nlohmann/json (https://github.com/nlohmann/json)
  - Filesystem: std::filesystem (C++17/20 standard library)
  - Process execution: Custom POSIX implementation (fork/exec/waitpid)
- **Optional (header-only preferred):**
  - Logging: spdlog (header-only mode)
  - CLI parsing: CLI11 (header-only)
  - Testing: Google Test or Catch2 (header-only)

---

## Risk Management

### Technical Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| TOML edge cases in toml11 | Medium | Comprehensive test suite, report issues upstream |
| Complex variable expansion edge cases | High | Implement comprehensive test suite, fuzz testing |
| Platform-specific path issues | Medium | Use std::filesystem exclusively, test on target platforms |
| Custom subprocess implementation bugs | High | Reference POSIX specs carefully, extensive testing with edge cases (signals, zombies, orphans), study existing implementations |
| Status.json corruption from crashes | High | Atomic writes with temp files, backup mechanism, validation on read |
| Process cleanup on abnormal termination | High | Process groups, proper signal handlers, timeout mechanisms, comprehensive testing |
| Stale process detection failures | Medium | Robust /proc parsing, permission error handling, user abort on failure |
| Unkillable processes | Medium | Detect D state, set cleanup_complete=false, inform user |

### Schedule Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Template processing complexity | High | Allocate buffer time in Phase 2, consider simplified initial impl |
| Subprocess management complexity | High | Already budgeted in Phase 4 timeline, extensive testing plan, reference implementations |
| Language export edge cases | Medium | Comprehensive reserved word lists, round-trip testing, fuzzing |
| Hook integration complications | Medium | Defer complex hooks to Phase 6 if needed |
| Performance issues at scale | Medium | Profile early, optimize hot paths incrementally |

---

## Success Metrics

### Phase Completion Criteria
Each phase must meet these criteria before advancing:
- All planned features implemented
- Unit test coverage >80%
- Integration tests passing
- Documentation updated
- Code review completed
- No known critical bugs

### Overall Success Criteria
- Execute sample 5-stage pipeline successfully
- Handle stage failure and resumption correctly
- Generate valid status.json for all stages
- Generate valid processes.json for all stages
- Validate all inputs/outputs correctly
- Complete test suite >85% coverage
- Performance: <100ms overhead per stage launch
- Clean Valgrind/ASan runs
- **New:** Timeout enforcement works correctly
- **New:** Orphan cleanup succeeds in 100% of test cases
- **New:** Stale process cleanup detects and cleans up crashed runs
- **New:** No zombie processes after execution
- **New:** Graceful shutdown on SIGINT

---

## Development Workflow Recommendations

### Initial Setup (Week 1)
1. Set up repository and build system
2. Integrate TOML and JSON libraries
3. Create skeleton project structure
4. Write first failing test
5. Establish code review process

### Iteration Cadence
- Daily: Commit working code, update tests
- Weekly: Phase progress review, adjust priorities
- Bi-weekly: Integration test runs, documentation updates
- Phase completion: Formal review, demo to stakeholders

### Quality Gates
- All tests pass before commit
- No compiler warnings
- Clang-tidy clean (or documented exceptions)
- Memory-safe (ASan/Valgrind clean for release builds)
- **New:** No leaked processes (verify with ps/pgrep after tests)

---

## Testing Strategy for Subprocess Management

### Unit Tests
- [ ] Process group creation (PGID == PID)
- [ ] killpg() wrapper with error handling
- [ ] /proc parsing for PGID matching
- [ ] Grace period timing (exactly 5 seconds)
- [ ] SIGTERM → SIGKILL sequence
- [ ] Zombie reaping
- [ ] processes.json generation
- [ ] Stale process detection logic

### Integration Tests
- [ ] Normal stage execution, no orphans
- [ ] Stage exits with orphaned subprocess
- [ ] Stage timeout → tree termination
- [ ] PFXCore SIGINT → graceful cleanup
- [ ] Stale processes from previous run
- [ ] Hung process (ignores SIGTERM)
- [ ] Deep process tree (4+ levels)
- [ ] Very large process tree (1000+ processes)

### Edge Cases
- [ ] Process ignores SIGTERM (needs SIGKILL)
- [ ] Process in D state (unkillable)
- [ ] Permission denied on kill()
- [ ] /proc unavailable
- [ ] processes.json corrupted
- [ ] Race: process exits during cleanup
- [ ] Multiple signals in rapid succession

---

## Appendix A: File Structure After Phase 3

```
run_001/
├── run.toml                 # Immutable run configuration (includes stage_timeout_seconds)
├── env.sh                   # Generated environment setup
├── pfx_vars.tcl             # Run-level Tcl variables
├── pfx_vars.py              # Run-level Python variables
├── inputs/
│   ├── design/             # Normalized design files
│   └── tech/               # Normalized technology files
├── scripts/                # Custom user scripts
├── stages/
│   ├── 10_synth/
│   │   ├── stage_launch.sh # Generated launch script
│   │   ├── env.sh          # Stage environment
│   │   ├── pfx_vars.tcl    # Stage-level Tcl variables
│   │   ├── pfx_vars.py     # Stage-level Python variables
│   │   ├── status.json     # Stage execution status
│   │   ├── processes.json  # Process management tracking
│   │   ├── inputs/         # Stage-specific inputs
│   │   ├── outputs/        # Stage outputs
│   │   ├── reports/        # Reports directory
│   │   └── logs/           # Execution logs (stdout.log, stderr.log)
│   ├── 20_place/
│   └── 30_route/
└── results/                # Study-level results (PFXStudy owned)
```

---

## Appendix B: Key Section 3.18 Requirements

### Process Group Management (3.18.2)
- Launch with `setpgid(0, 0)` to create new process group
- PGID = root PID for isolation
- Record PGID in processes.json immediately

### Timeout Handling (3.18.3)
- Global timeout: `stage_timeout_seconds` in run.toml (default: 999 hours)
- Poll every 1 second during execution
- On timeout: killpg(SIGTERM) → 5 sec → killpg(SIGKILL)
- Set status.json state to "timeout"

### Orphan Cleanup (3.18.4)
- After root exit, scan /proc for PGID matches
- SIGTERM to each orphan → 5 sec → SIGKILL
- Reap zombies with waitpid()
- Record all actions in processes.json

### Stale Process Cleanup (3.18.5)
- Before stage launch, check previous processes.json
- If cleanup_complete == false, extract PGID
- Scan /proc for processes in that group
- Kill with SIGTERM → SIGKILL sequence
- Abort if cleanup fails (user must intervene)
- Record in startup_cleanup section

### Signal Handling (3.18.6)
- SIGINT/SIGTERM → graceful cleanup
- Terminate process group
- Clean up orphans
- Set status to "interrupted"
- Exit cleanly

### processes.json Artifact (3.18.7)
- Mandatory for all stages
- Schema version 1.0
- Root process: PID, PGID, command, argv, times, exit_code
- Timeout: limit, exceeded flag
- Process tree: optional descendant tracking
- Cleanup: orphans found, signals sent, completion status
- Startup cleanup: stale PGID, stale processes, termination actions

---

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-11 | Initial implementation plan based on spec v0.10.8 |
| 1.1 | 2026-02-11 | Updated with header-only library requirements: toml11 for TOML, nlohmann/json for JSON; specified custom POSIX subprocess implementation; removed parallel execution; clarified standard exception-based error handling |
| 2.0 | 2026-02-11 | Major update for spec v0.11.0: Added Section 3.18 subprocess management requirements to Phase 4 (process groups, timeout, orphan cleanup, stale process detection); added language exporters to Phase 3 (Tcl and Python); expanded testing requirements; updated timeline to 9.5-13.5 weeks |
