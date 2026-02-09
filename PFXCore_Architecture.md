# PFXCore Implementation Architecture

## 1. Overview

PFXCore is the headless execution kernel for PFXFlow, responsible for validating, normalizing, materializing, executing, and harvesting individual runs. This architecture prioritizes determinism, immutability, and clear ownership semantics.

## 2. Core Design Principles

1. **Immutability**: `run.toml` and `pipeline.toml` are read-only inputs
2. **Determinism**: Same inputs produce identical outputs (modulo tool nondeterminism)
3. **Validation-First**: All inputs validated before any materialization
4. **Single-Pass Execution**: No dependency resolution beyond stage ordering
5. **Error-Fail-Fast**: Invalid state terminates immediately with clear diagnostics
6. **Minimal State**: Only `status.json` tracks runtime state per stage

## 3. Module Architecture

```
PFXCore/
├── core/               # Core abstractions and data structures
│   ├── Study.hpp       # Study representation and validation
│   ├── Run.hpp         # Run configuration and metadata
│   ├── Pipeline.hpp    # Stage pipeline definition
│   ├── Stage.hpp       # Individual stage abstraction
│   └── Status.hpp      # StageStatus handling
├── config/             # Configuration parsing and validation
│   ├── TomlParser.hpp  # TOML parsing wrapper
│   ├── Schema.hpp      # Schema validation
│   └── Validator.hpp   # Semantic validation
├── materializer/       # Run directory materialization
│   ├── Materializer.hpp
│   ├── DirectoryLayout.hpp
│   └── TemplateEngine.hpp
├── normalizer/         # Input normalization
│   ├── DesignNormalizer.hpp
│   └── TechNormalizer.hpp
├── executor/           # Stage execution
│   ├── StageRunner.hpp
│   ├── TclGenerator.hpp
│   └── HookExecutor.hpp
├── harvester/          # Result harvesting
│   ├── Harvester.hpp
│   └── MetricsCollector.hpp
└── util/               # Utilities
    ├── FileSystem.hpp  # Path handling, file operations
    ├── Validation.hpp  # Key/value validation
    └── Logger.hpp      # Structured logging
```

## 4. Core Data Structures

### 4.1 Study

```cpp
namespace pfx::core {

struct StudyConfig {
    std::string name;
    std::filesystem::path root_path;
    std::filesystem::path pipeline_path;  // Absolute path to pipeline.toml
    
    // Optional study-level configuration
    std::optional<ConcurrencyLimits> concurrency;
    std::optional<ResourceLimits> resource_limits;
    
    // Validation state
    bool validated{false};
};

class Study {
public:
    explicit Study(std::filesystem::path study_root);
    
    // Load and validate study.toml
    void load();
    
    // Access configuration
    const StudyConfig& config() const noexcept { return config_; }
    std::filesystem::path root() const noexcept { return config_.root_path; }
    
    // Pipeline access
    const Pipeline& pipeline() const;
    
private:
    StudyConfig config_;
    std::unique_ptr<Pipeline> pipeline_;
};

} // namespace pfx::core
```

### 4.2 Run

```cpp
namespace pfx::core {

struct RunMetadata {
    std::string run_id;
    std::string study_name;
    std::string semantic_path;
};

struct DoeParameters {
    // Flat key-value map from [doe] table
    std::map<std::string, std::variant<double, int64_t, std::string, bool>> params;
};

struct DesignConfig {
    std::string top;
    std::string rtl_type;
    std::filesystem::path filelist;
    std::vector<std::filesystem::path> include_dirs;
    std::vector<std::string> defines;
    std::vector<std::filesystem::path> sdc_files;
};

struct TechnologyConfig {
    std::string bundle;
    std::string corner;
    double voltage;
    int temperature;
};

// Flat key-value store for [vars] and tool-specific sections
using VariableStore = std::map<std::string, std::string>;

class Run {
public:
    explicit Run(std::filesystem::path run_dir);
    
    // Load run.toml (immutable)
    void load();
    
    // Access configuration
    const RunMetadata& metadata() const noexcept { return metadata_; }
    const DoeParameters& doe() const noexcept { return doe_; }
    const DesignConfig& design() const noexcept { return design_; }
    const TechnologyConfig& technology() const noexcept { return tech_; }
    const VariableStore& variables() const noexcept { return vars_; }
    
    // Directory structure
    std::filesystem::path root() const noexcept { return run_dir_; }
    std::filesystem::path inputs_dir() const;
    std::filesystem::path stages_dir() const;
    std::filesystem::path results_dir() const;
    std::filesystem::path scripts_dir() const;
    
    // Check if run.toml exists and is valid
    bool is_valid() const noexcept { return validated_; }
    
private:
    std::filesystem::path run_dir_;
    RunMetadata metadata_;
    DoeParameters doe_;
    DesignConfig design_;
    TechnologyConfig tech_;
    VariableStore vars_;
    bool validated_{false};
};

} // namespace pfx::core
```

### 4.3 Pipeline

```cpp
namespace pfx::core {

struct ExecConfig {
    std::vector<std::string> argv;  // Command and arguments
    std::string working_dir_policy; // "stage" (default)
};

struct StageConfig {
    std::string name;
    int order;  // NN in stages/NN_<name>/
    
    ExecConfig exec;
    
    // Optional stage-specific overrides
    std::optional<std::map<std::string, std::string>> vars;
    
    // Hooks (future)
    std::vector<std::string> pre_hooks;
    std::vector<std::string> post_hooks;
};

class Pipeline {
public:
    explicit Pipeline(std::filesystem::path pipeline_toml);
    
    // Load and validate pipeline definition
    void load();
    
    // Access stages in execution order
    const std::vector<StageConfig>& stages() const noexcept { return stages_; }
    
    // Query specific stage
    std::optional<StageConfig> find_stage(const std::string& name) const;
    
    // Validation
    bool is_valid() const noexcept { return validated_; }
    
private:
    std::filesystem::path path_;
    std::vector<StageConfig> stages_;
    bool validated_{false};
    
    void validate_ordering();
    void validate_unique_names();
};

} // namespace pfx::core
```

### 4.4 Stage and StageStatus

```cpp
namespace pfx::core {

struct StageStatus {
    std::string stage_name;
    std::optional<std::string> start_time;  // ISO 8601
    std::optional<std::string> end_time;    // ISO 8601
    std::optional<int> exit_code;
    std::optional<std::string> error_message;
    
    // Check if stage completed successfully
    bool is_complete() const noexcept {
        return end_time.has_value() && 
               exit_code.has_value() && 
               exit_code.value() == 0;
    }
    
    // Serialization
    static StageStatus from_json(const std::filesystem::path& json_path);
    void to_json(const std::filesystem::path& json_path) const;
};

class Stage {
public:
    Stage(const StageConfig& config, 
          std::filesystem::path stage_dir,
          const Run& run,
          const Pipeline& pipeline);
    
    // Directory structure
    std::filesystem::path dir() const noexcept { return stage_dir_; }
    std::filesystem::path launch_script() const;
    std::filesystem::path status_file() const;
    
    // Execution state
    StageStatus load_status() const;
    void save_status(const StageStatus& status) const;
    bool is_complete() const;
    
    // Configuration access
    const StageConfig& config() const noexcept { return config_; }
    std::string name() const noexcept { return config_.name; }
    int order() const noexcept { return config_.order; }
    
private:
    StageConfig config_;
    std::filesystem::path stage_dir_;
    const Run& run_;
    const Pipeline& pipeline_;
};

} // namespace pfx::core
```

## 5. Component Interfaces

### 5.1 Config Composer and Validator

```cpp
namespace pfx::config {

// Schema validation
class Validator {
public:
    explicit Validator();
    
    // Validate entire run.toml structure
    void validate_run_config(const toml::table& config);
    
    // Validate pipeline.toml structure
    void validate_pipeline_config(const toml::table& config);
    
    // Validate individual tables
    void validate_run_table(const toml::table& run);
    void validate_doe_table(const toml::table& doe);
    void validate_design_table(const toml::table& design);
    void validate_technology_table(const toml::table& tech);
    void validate_vars_table(const toml::table& vars);
    
private:
    void check_required_fields(const toml::table& table,
                              const std::vector<std::string>& required);
    void validate_key_format(const std::string& key);
    void validate_value_restrictions(const std::string& value);
};

// Variable validation per Section 3.12
class VariableValidator {
public:
    // Check key format: letters, digits, dots, dashes only
    static bool is_valid_key(const std::string& key);
    
    // Check value restrictions: no $, quotes, newlines, backslashes
    static bool is_valid_value(const std::string& value);
    
    // Validate entire variable store
    static void validate_store(const std::map<std::string, std::string>& vars);
};

} // namespace pfx::config
```

### 5.2 Materializer

```cpp
namespace pfx::materializer {

class Materializer {
public:
    explicit Materializer(const core::Run& run,
                         const core::Pipeline& pipeline);
    
    // Create complete run directory structure
    void materialize(bool force = false);
    
    // Individual materialization steps
    void create_directory_structure();
    void generate_stage_directories();
    void generate_launch_scripts();
    void initialize_status_files();
    
private:
    const core::Run& run_;
    const core::Pipeline& pipeline_;
    
    void create_stage_dir(const core::StageConfig& stage);
    void generate_launch_script(const core::StageConfig& stage,
                               const std::filesystem::path& stage_dir);
};

} // namespace pfx::materializer
```

### 5.3 TclGenerator

```cpp
namespace pfx::executor {

class TclGenerator {
public:
    explicit TclGenerator(const core::Run& run,
                         const core::Stage& stage);
    
    // Generate pfx_vars.tcl
    void generate_vars_file();
    
    // Generate stage-specific Tcl if needed
    void generate_stage_script();
    
private:
    const core::Run& run_;
    const core::Stage& stage_;
    
    // Emit variable in canonical Tcl form
    std::string emit_tcl_variable(const std::string& key, 
                                  const std::string& value) const;
    
    // Collect all variables for stage (run.toml + stage overrides)
    std::map<std::string, std::string> collect_variables() const;
};

} // namespace pfx::executor
```

### 5.4 StageRunner

```cpp
namespace pfx::executor {

class StageRunner {
public:
    explicit StageRunner(core::Stage& stage,
                        const core::Run& run);
    
    // Execute stage pipeline
    int execute(bool force = false);
    
    // Check if stage should run
    bool should_execute(bool force) const;
    
private:
    core::Stage& stage_;
    const core::Run& run_;
    
    // Execution helpers
    void prepare_environment();
    void update_status_start();
    int run_launch_script();
    void update_status_end(int exit_code);
    
    // Logging
    std::filesystem::path stage_log_file() const;
};

} // namespace pfx::executor
```

### 5.5 Normalizer Components

```cpp
namespace pfx::normalizer {

// Design input normalization
class DesignNormalizer {
public:
    explicit DesignNormalizer(const core::DesignConfig& config,
                             std::filesystem::path inputs_dir);
    
    // Validate and normalize RTL inputs
    void normalize();
    
    // Check all referenced files exist
    void validate_file_references();
    
    // Copy/symlink design files to inputs/design/
    void materialize_inputs();
    
private:
    const core::DesignConfig& config_;
    std::filesystem::path inputs_dir_;
    
    void process_filelist();
    void process_sdc_files();
    void process_include_dirs();
};

// Technology input normalization
class TechNormalizer {
public:
    explicit TechNormalizer(const core::TechnologyConfig& config,
                           std::filesystem::path inputs_dir);
    
    // Validate and normalize tech inputs
    void normalize();
    
    // Validate technology bundle exists
    void validate_bundle();
    
    // Link tech files to inputs/tech/
    void materialize_inputs();
    
private:
    const core::TechnologyConfig& config_;
    std::filesystem::path inputs_dir_;
};

} // namespace pfx::normalizer
```

## 6. Execution Flow

### 6.1 Main Execution Orchestrator

```cpp
namespace pfx {

class PFXCore {
public:
    explicit PFXCore();
    
    // Single run execution
    int execute_run(std::filesystem::path run_dir, 
                   const ExecutionOptions& opts);
    
    // Single stage execution
    int execute_stage(std::filesystem::path run_dir,
                     const std::string& stage_name,
                     const ExecutionOptions& opts);
    
private:
    // Execution phases
    void validate_phase(const core::Run& run, 
                       const core::Pipeline& pipeline);
    void normalize_phase(core::Run& run);
    void materialize_phase(const core::Run& run, 
                          const core::Pipeline& pipeline,
                          bool force);
    int execute_phase(const core::Run& run,
                     const core::Pipeline& pipeline,
                     const ExecutionOptions& opts);
};

struct ExecutionOptions {
    bool force{false};              // Ignore completed stages
    bool validate_only{false};       // Stop after validation
    std::optional<std::string> stage_name;  // Execute single stage
    bool verbose{false};
};

} // namespace pfx
```

### 6.2 Execution Sequence

```
1. Load Phase
   - Load run.toml (immutable)
   - Load pipeline.toml (study-level)
   - Verify env.sh exists

2. Validation Phase
   - Validate run.toml schema
   - Validate pipeline.toml schema
   - Check key/value format
   - Verify required tables exist
   
3. Normalization Phase
   - Validate design inputs (RTL, SDC, etc.)
   - Validate technology inputs
   - Create inputs/design/ structure
   - Create inputs/tech/ structure

4. Materialization Phase
   - Create stages/ directory structure
   - Generate stage_launch.sh for each stage
   - Initialize status.json for each stage
   - Generate pfx_vars.tcl

5. Execution Phase
   - For each stage in pipeline order:
     * Check status.json (skip if complete and not --force)
     * Update status.json with start_time
     * Execute stage_launch.sh
     * Capture exit_code
     * Update status.json with end_time and exit_code
     * Fail fast on non-zero exit code (unless continue flag)
```

## 7. Error Handling Strategy

```cpp
namespace pfx {

// Exception hierarchy
class PFXError : public std::runtime_error {
    using std::runtime_error::runtime_error;
};

class ValidationError : public PFXError {
public:
    ValidationError(const std::string& msg, 
                   const std::filesystem::path& file)
        : PFXError(format("Validation failed in {}: {}", file, msg))
        , file_(file) {}
    
    std::filesystem::path file() const { return file_; }
    
private:
    std::filesystem::path file_;
};

class NormalizationError : public PFXError {
    using PFXError::PFXError;
};

class ExecutionError : public PFXError {
public:
    ExecutionError(const std::string& msg, int exit_code)
        : PFXError(msg), exit_code_(exit_code) {}
    
    int exit_code() const { return exit_code_; }
    
private:
    int exit_code_;
};

} // namespace pfx
```

## 8. File System Abstractions

```cpp
namespace pfx::util {

// Path utilities with PFXFlow-specific logic
class PathResolver {
public:
    static std::filesystem::path resolve_run_root(
        const std::filesystem::path& maybe_run_dir);
    
    static std::filesystem::path resolve_study_root(
        const std::filesystem::path& run_or_study_dir);
    
    // Canonical directory structure queries
    static std::filesystem::path inputs_dir(const std::filesystem::path& run_root);
    static std::filesystem::path stages_dir(const std::filesystem::path& run_root);
    static std::filesystem::path results_dir(const std::filesystem::path& run_root);
    static std::filesystem::path scripts_dir(const std::filesystem::path& run_root);
    
    // Stage-specific paths
    static std::filesystem::path stage_dir(
        const std::filesystem::path& run_root,
        int order,
        const std::string& name);
    
    static std::string stage_dirname(int order, const std::string& name);
};

// File operations with validation
class FileOps {
public:
    // Safe file creation with parent directory creation
    static void create_file(const std::filesystem::path& path,
                           const std::string& content);
    
    // Atomic write (write to temp, then rename)
    static void atomic_write(const std::filesystem::path& path,
                            const std::string& content);
    
    // Check file exists and is readable
    static bool is_readable(const std::filesystem::path& path);
    
    // Create directory structure with validation
    static void create_directories(const std::filesystem::path& path);
};

} // namespace pfx::util
```

## 9. Logging and Diagnostics

```cpp
namespace pfx::util {

enum class LogLevel {
    Debug,
    Info,
    Warning,
    Error,
    Fatal
};

class Logger {
public:
    static Logger& instance();
    
    void set_level(LogLevel level);
    void set_output(std::ostream& os);
    
    void debug(const std::string& msg);
    void info(const std::string& msg);
    void warning(const std::string& msg);
    void error(const std::string& msg);
    void fatal(const std::string& msg);
    
    // Structured logging with context
    void log_stage_start(const std::string& stage_name);
    void log_stage_end(const std::string& stage_name, int exit_code);
    void log_validation_error(const std::string& msg, 
                             const std::filesystem::path& file);
    
private:
    Logger() = default;
    LogLevel level_{LogLevel::Info};
    std::ostream* output_{&std::cerr};
};

// RAII timer for performance tracking
class ScopedTimer {
public:
    explicit ScopedTimer(const std::string& operation);
    ~ScopedTimer();
    
private:
    std::string operation_;
    std::chrono::steady_clock::time_point start_;
};

} // namespace pfx::util
```

## 10. Testing Strategy

```cpp
namespace pfx::test {

// Test fixture for PFXCore testing
class PFXCoreTestFixture {
protected:
    void SetUp() override;
    void TearDown() override;
    
    // Create minimal valid run.toml
    std::filesystem::path create_test_run();
    
    // Create minimal valid pipeline.toml
    std::filesystem::path create_test_pipeline();
    
    // Create complete study structure
    std::filesystem::path create_test_study();
    
    std::filesystem::path temp_dir_;
};

// Example unit tests
TEST_F(PFXCoreTestFixture, ValidateGoodRunConfig) {
    auto run_dir = create_test_run();
    core::Run run(run_dir);
    EXPECT_NO_THROW(run.load());
    EXPECT_TRUE(run.is_valid());
}

TEST_F(PFXCoreTestFixture, RejectInvalidKeyFormat) {
    // Test invalid variable key with spaces
    config::VariableValidator validator;
    EXPECT_FALSE(validator.is_valid_key("bad key"));
    EXPECT_TRUE(validator.is_valid_key("good.key-123"));
}

TEST_F(PFXCoreTestFixture, RejectInvalidValueFormat) {
    config::VariableValidator validator;
    EXPECT_FALSE(validator.is_valid_value("has$dollar"));
    EXPECT_FALSE(validator.is_valid_value("has\"quote"));
    EXPECT_TRUE(validator.is_valid_value("valid_value"));
}

TEST_F(PFXCoreTestFixture, MaterializeStageDirectories) {
    auto run_dir = create_test_run();
    auto pipeline_path = create_test_pipeline();
    
    core::Run run(run_dir);
    run.load();
    
    core::Pipeline pipeline(pipeline_path);
    pipeline.load();
    
    materializer::Materializer mat(run, pipeline);
    EXPECT_NO_THROW(mat.materialize());
    
    // Verify stage directories exist
    EXPECT_TRUE(fs::exists(run_dir / "stages/01_genus"));
    EXPECT_TRUE(fs::exists(run_dir / "stages/02_innovus"));
}

} // namespace pfx::test
```

## 11. Build System (CMake)

```cmake
cmake_minimum_required(VERSION 3.20)
project(PFXCore VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Dependencies
find_package(toml11 REQUIRED)  # TOML parsing
find_package(nlohmann_json REQUIRED)  # JSON for status.json
find_package(GTest REQUIRED)  # Unit testing

# Core library
add_library(pfxcore STATIC
    src/core/Study.cpp
    src/core/Run.cpp
    src/core/Pipeline.cpp
    src/core/Stage.cpp
    src/core/Status.cpp
    src/config/Validator.cpp
    src/config/VariableValidator.cpp
    src/materializer/Materializer.cpp
    src/normalizer/DesignNormalizer.cpp
    src/normalizer/TechNormalizer.cpp
    src/executor/StageRunner.cpp
    src/executor/TclGenerator.cpp
    src/util/PathResolver.cpp
    src/util/FileOps.cpp
    src/util/Logger.cpp
)

target_include_directories(pfxcore
    PUBLIC 
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
)

target_link_libraries(pfxcore
    PUBLIC
        toml11::toml11
        nlohmann_json::nlohmann_json
)

# Main executable
add_executable(pfxcore_main
    src/main.cpp
    src/PFXCore.cpp
)

target_link_libraries(pfxcore_main
    PRIVATE pfxcore
)

# Unit tests
enable_testing()
add_executable(pfxcore_tests
    test/core/RunTest.cpp
    test/core/PipelineTest.cpp
    test/config/ValidatorTest.cpp
    test/materializer/MaterializerTest.cpp
)

target_link_libraries(pfxcore_tests
    PRIVATE
        pfxcore
        GTest::GTest
        GTest::Main
)

gtest_discover_tests(pfxcore_tests)
```

## 12. Dependencies

- **toml11**: Modern C++11 TOML parser (header-only, MIT)
- **nlohmann/json**: JSON for modern C++ (header-only, MIT)
- **{fmt}**: Fast formatting library (consider for string formatting)
- **GTest**: Google Test framework for unit testing
- **Standard Library**: filesystem, string_view, optional, variant (C++17/20)

## 13. Future Considerations

### 13.1 Phase 2 Features
- Hook execution framework
- Harvesting infrastructure
- Template engine integration
- Schema migration support

### 13.2 Performance Optimizations
- Parallel validation of independent stages
- Lazy loading of pipeline definitions
- Caching of normalized inputs

### 13.3 Advanced Error Recovery
- Checkpoint/resume for long-running pipelines
- Partial execution with stage dependencies
- Automatic retry logic for transient failures
