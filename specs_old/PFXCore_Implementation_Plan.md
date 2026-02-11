# PFXCore Implementation Plan

**Version:** 1.1  
**Date:** 2026-02-11  
**Based on:** PFXFlow Project Spec v0.10.8

---

## Executive Summary

This plan breaks PFXCore implementation into 7 phases, progressing from foundational data structures through complete execution capability. Each phase produces testable, working code that builds toward the full specification.

**Estimated Timeline:** 8-12 weeks for core functionality (Phases 1-5)  
**Language:** C++20  
**Key Dependencies:** Header-only libraries: toml11 (TOML parsing), nlohmann/json (JSON parsing)  
**Architecture:** Custom subprocess management, standard exception-based error handling, sequential stage execution

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

**Duration:** 2 weeks  
**Goal:** Generate complete run directories from validated configurations

### 3.1 Directory Materializer
- [ ] **RunMaterializer**: Master directory generator
  - Create semantic directory structure
  - Ensure ownership model compliance
  - Generate required stub files
- [ ] **StageMaterializer**: Per-stage directory setup
  - Create `stages/<NN>_<name>/` structure
  - Set up `inputs/`, `outputs/`, `reports/`, `logs/` subdirs
  - Initialize `status.json` with "not_started" state
  - Generate placeholder files as needed

### 3.2 Script Generation
- [ ] **LaunchScriptGenerator**: Generate `stage_launch.sh`
  - Bash script template with error handling
  - Environment sourcing logic
  - Tool invocation with proper argv
  - Output validation hooks
- [ ] **EnvScriptGenerator**: Generate stage-specific environment
  - Export PFX_* variables from run.toml
  - Stage-specific path variables
  - Tool license variables
  - Working directory setup
- [ ] **TclDriverGenerator**: Generate tool-specific Tcl drivers
  - Parse hook specifications
  - Generate init/pre/post Tcl scripts
  - Variable passing from shell to Tcl
  - Error propagation

### 3.3 Input/Script Linking
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
- Comprehensive integration tests
- Materialization dry-run capability for debugging

---

## Phase 4: Stage Execution Engine

**Duration:** 2-3 weeks  
**Goal:** Execute individual stages with full tracking and error handling

### 4.1 Stage Executor Core
- [ ] **StageRunner**: Single-stage execution manager
  - Prerequisite validation
  - Launch script execution via subprocess
  - Real-time output capture (stdout/stderr)
  - Exit code handling
  - Signal handling for interrupts
- [ ] **ProcessManager**: Custom subprocess lifecycle management
  - POSIX fork/exec implementation with proper error handling
  - stdout/stderr redirection to log files
  - Environment inheritance and modification
  - Working directory management
  - Robust waitpid handling with timeout capability
  - Signal propagation (SIGINT, SIGTERM)
  - **Implementation notes:**
    - Use `fork()` + `execve()` for maximum control
    - Set up pipes before fork for stdout/stderr capture
    - Use `setpgid()` for process group management (clean termination)
    - Implement `SIGCHLD` handler or polling for async notification
    - Handle `EINTR` properly in all syscalls
    - Implement timeout via `SIGALRM` or non-blocking `waitpid()` loops
    - Ensure proper cleanup of zombie processes
    - Reference implementation: study POSIX spawn semantics carefully

### 4.2 Status Tracking
- [ ] **StatusWriter**: Manage `status.json` lifecycle
  - Initialize on stage start with timestamp
  - Update during execution
  - Finalize on completion with results
  - Atomic write operations for safety
- [ ] **StatusReader**: Parse and validate status.json
  - Read existing stage status
  - Determine if stage can be skipped
  - Validate schema version compatibility
- [ ] **CompletionChecker**: Stage success validation
  - Verify exit code == 0
  - Check all declared outputs exist
  - Update `success` flag accurately
  - Generate human-readable status messages

### 4.3 File Validation
- [ ] **FilePresenceChecker**: Pre/post execution file validation
  - Check declared inputs before execution
  - Check declared outputs after execution
  - Generate `outputs_missing` list
  - Record findings in status.json

### 4.4 Logging Infrastructure
- [ ] **ExecutionLogger**: Structured logging
  - Stage start/end events
  - Error and warning capture
  - Performance metrics (wall time, etc.)
  - Structured log format (JSON or similar)

**Deliverables:**
- Working single-stage execution
- Complete status.json lifecycle
- Comprehensive error handling
- Integration tests for stage execution
- Log analysis utilities

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

### 5.2 Continuation and Resumption
- [ ] **ResumptionLogic**: Smart pipeline restart
  - Detect completed stages via status.json
  - Find first incomplete or failed stage
  - Resume from that point
  - Validate prerequisites still satisfied
- [ ] **ForceRunner**: Forced re-execution handler
  - Clear old status.json files
  - Reset outputs directory
  - Re-run specified stages

### 5.3 Error Handling and Recovery
- [ ] **FailureHandler**: Pipeline failure management
  - Stage failure detection
  - Clean termination of pipeline
  - Status preservation for debugging
  - User-friendly error messages
  - Suggest recovery actions

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
- [ ] **StatusAnalyzer**: Status.json analysis
  - Aggregate statistics across stages
  - Identify bottlenecks
  - Generate reports

### 6.2 Validation Enhancements
- [ ] **DryRunMode**: Validate without execution
  - Full materialization simulation
  - Report what would be created
  - Validate all configurations
  - Estimate resource requirements
- [ ] **ConfigDumper**: Export effective configuration
  - Show fully expanded variables
  - Display final stage configurations
  - Export to human-readable format

### 6.3 Performance Optimization
- [ ] **CachingLayer**: Reduce redundant file operations
  - Cache file presence checks
  - Reduce status.json re-reads
  - Optimize directory scans

### 6.4 User Interface Polish
- [ ] **ProgressReporter**: Real-time execution feedback
  - Stage progress bar
  - Time estimates
  - Current operation display
- [ ] **ErrorFormatter**: Beautiful error messages
  - Color-coded output
  - Context-aware suggestions
  - File/line references for config errors

**Deliverables:**
- Diagnostic and inspection tools
- Dry-run validation mode
- Performance benchmarks
- Polished user experience

---

## Phase 7: Documentation and Hardening

**Duration:** 1 week  
**Goal:** Complete documentation, comprehensive testing, and production readiness

### 7.1 Documentation
- [ ] **API Documentation**: Doxygen or similar
  - All public APIs documented
  - Usage examples for major types
  - Architecture diagrams
- [ ] **User Guide**: End-user documentation
  - Command-line reference
  - Configuration examples
  - Troubleshooting guide
  - Best practices
- [ ] **Developer Guide**: Internal documentation
  - Architecture overview
  - Adding new features
  - Testing guidelines
  - Release process

### 7.2 Test Coverage Expansion
- [ ] **Integration Test Suite**
  - Full pipeline execution tests
  - Error recovery scenarios
  - Edge case handling
  - Performance regression tests
- [ ] **Fuzzing Harness** (optional)
  - Configuration fuzzing
  - Error injection testing
  - Crash detection

### 7.3 Production Hardening
- [ ] **Memory Safety**: Valgrind/AddressSanitizer clean
- [ ] **Error Handling**: All error paths tested
- [ ] **Resource Cleanup**: RAII enforcement, no leaks
- [ ] **Signal Handling**: Graceful shutdown on SIGINT/SIGTERM
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
- Provide rich context in all error messages (file, line, variable name, expected vs. actual)
- Include actionable suggestions for fixing common errors
- Log all errors to structured log files with full stack context
- Use RAII to ensure cleanup on exception paths

### Testing Strategy
- Unit tests for all isolated components (>80% coverage target)
- Integration tests for end-to-end workflows
- Regression tests for bug fixes
- Performance benchmarks for key operations
- Test with realistic configurations from day one

### Code Quality
- Enforce const-correctness throughout
- Use RAII for all resource management
- Prefer immutability by default
- Use std::optional for nullable values
- Use std::variant for type-safe unions
- Leverage C++20 concepts for template constraints
- Follow modern C++ core guidelines

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
| Process cleanup on abnormal termination | Medium | Implement process groups, proper signal handlers, timeout mechanisms |

### Schedule Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Template processing complexity | High | Allocate buffer time in Phase 2, consider simplified initial impl |
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
- Validate all inputs/outputs correctly
- Complete test suite >85% coverage
- Performance: <100ms overhead per stage launch
- Clean Valgrind/ASan runs

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

---

## Open Questions for Discussion

1. **Logging Level**: How verbose should default logging be? (INFO, DEBUG, or configurable?)
2. **Hook Language Support**: Tcl-only initially, or support Python hooks from the start?
3. **Status Schema Evolution**: How to handle schema version migrations in status.json?
4. **Testing Infrastructure**: Containerized tests or native only?
5. **ProcessManager Implementation Details**: 
   - Should we use posix_spawn or traditional fork/exec?
   - How to handle very long-running stages (hours/days)?
   - Should we implement process groups for proper cleanup?
6. **Configuration Caching**: Should we cache parsed TOML between invocations?

---

## Appendix A: File Structure After Phase 3

```
run_001/
├── run.toml                 # Immutable run configuration
├── env.sh                   # Generated environment setup
├── inputs/
│   ├── design/             # Normalized design files
│   └── tech/               # Normalized technology files
├── scripts/                # Custom user scripts
├── stages/
│   ├── 10_synth/
│   │   ├── stage_launch.sh # Generated launch script
│   │   ├── env.sh          # Stage environment
│   │   ├── pfx_vars.tcl    # Variables for Tcl
│   │   ├── status.json     # Stage execution status
│   │   ├── inputs/         # Stage-specific inputs
│   │   ├── outputs/        # Stage outputs
│   │   ├── reports/        # Reports directory
│   │   └── logs/           # Execution logs
│   ├── 20_place/
│   └── 30_route/
└── results/                # Study-level results (PFXStudy owned)
```

---

## Appendix B: Recommended Test Cases

### Phase 1 Tests
- Parse valid run.toml with all field types
- Parse pipeline.toml with multiple stages
- Reject invalid TOML syntax
- Validate missing required fields
- Type constraint enforcement

### Phase 2 Tests
- Variable expansion with defaults
- Circular dependency detection
- Template overlay precedence
- Cross-stage file reference validation
- Undefined variable detection

### Phase 3 Tests
- Create complete run directory
- Generate valid stage_launch.sh
- Generate Tcl driver with hooks
- Handle existing directories (error or skip)
- Symlink vs. copy logic

### Phase 4 Tests
- Execute successful stage
- Handle stage failure (non-zero exit)
- Handle missing input files
- Handle missing output files after execution
- Proper status.json lifecycle
- Timestamp and duration recording

### Phase 5 Tests
- Execute multi-stage pipeline
- Resume from failed stage
- Skip completed stages
- Force re-execution of completed stages
- Partial pipeline execution (--stage flag)
- Hook execution at proper times

---

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-11 | Initial implementation plan based on spec v0.10.8 |
| 1.1 | 2026-02-11 | Updated with header-only library requirements: toml11 for TOML, nlohmann/json for JSON; specified custom POSIX subprocess implementation; removed parallel execution; clarified standard exception-based error handling |
