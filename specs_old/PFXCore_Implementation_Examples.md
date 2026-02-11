# PFXCore Implementation Details and Examples

## 1. Concrete Implementation Examples

### 1.1 Run Class Implementation

```cpp
// include/pfx/core/Run.hpp
#pragma once

#include <filesystem>
#include <map>
#include <optional>
#include <string>
#include <variant>
#include <vector>

namespace fs = std::filesystem;

namespace pfx::core {

// Type aliases for clarity
using DoeValue = std::variant<double, int64_t, std::string, bool>;
using VariableStore = std::map<std::string, std::string>;

struct RunMetadata {
    std::string run_id;
    std::string study_name;
    std::string semantic_path;
};

struct DoeParameters {
    std::map<std::string, DoeValue> params;
    
    // Type-safe accessors
    template<typename T>
    std::optional<T> get(const std::string& key) const {
        auto it = params.find(key);
        if (it == params.end()) return std::nullopt;
        if (auto* val = std::get_if<T>(&it->second)) {
            return *val;
        }
        return std::nullopt;
    }
};

struct DesignConfig {
    std::string top;
    std::string rtl_type;
    fs::path filelist;  // Relative to study root or absolute
    std::vector<fs::path> include_dirs;
    std::vector<std::string> defines;
    std::vector<fs::path> sdc_files;
    
    // Validation helpers
    bool has_filelist() const noexcept { return !filelist.empty(); }
    bool has_sdc() const noexcept { return !sdc_files.empty(); }
};

struct TechnologyConfig {
    std::string bundle;
    std::string corner;
    double voltage;
    int temperature;
    
    // Convenience
    std::string corner_key() const {
        return bundle + "_" + corner;
    }
};

class Run {
public:
    explicit Run(fs::path run_dir);
    
    // Disable copy (move is fine)
    Run(const Run&) = delete;
    Run& operator=(const Run&) = delete;
    Run(Run&&) noexcept = default;
    Run& operator=(Run&&) noexcept = default;
    
    // Load and validate run.toml
    void load();
    
    // Accessors (const-correct, noexcept where possible)
    const RunMetadata& metadata() const noexcept { return metadata_; }
    const DoeParameters& doe() const noexcept { return doe_; }
    const DesignConfig& design() const noexcept { return design_; }
    const TechnologyConfig& technology() const noexcept { return tech_; }
    const VariableStore& variables() const noexcept { return vars_; }
    
    // Get tool-specific variables (e.g., [genus] table)
    std::optional<VariableStore> tool_variables(const std::string& tool) const;
    
    // Directory structure (canonical paths)
    fs::path root() const noexcept { return run_dir_; }
    fs::path run_toml() const { return run_dir_ / "run.toml"; }
    fs::path env_sh() const { return run_dir_ / "env.sh"; }
    fs::path inputs_dir() const { return run_dir_ / "inputs"; }
    fs::path stages_dir() const { return run_dir_ / "stages"; }
    fs::path results_dir() const { return run_dir_ / "results"; }
    fs::path scripts_dir() const { return run_dir_ / "scripts"; }
    
    // Validation state
    bool is_valid() const noexcept { return validated_; }
    
    // Debugging
    std::string dump() const;
    
private:
    fs::path run_dir_;
    RunMetadata metadata_;
    DoeParameters doe_;
    DesignConfig design_;
    TechnologyConfig tech_;
    VariableStore vars_;
    
    // Tool-specific configuration (e.g., [genus], [innovus])
    std::map<std::string, VariableStore> tool_configs_;
    
    bool validated_{false};
    
    // Implementation helpers
    void parse_run_toml();
    void validate_structure();
    void check_required_paths();
};

} // namespace pfx::core
```

### 1.2 Run Class Implementation (.cpp)

```cpp
// src/core/Run.cpp
#include "pfx/core/Run.hpp"
#include "pfx/config/Validator.hpp"
#include "pfx/util/Logger.hpp"
#include <toml.hpp>
#include <stdexcept>

namespace pfx::core {

Run::Run(fs::path run_dir)
    : run_dir_(std::move(run_dir))
{
    if (!fs::exists(run_dir_)) {
        throw std::runtime_error("Run directory does not exist: " + 
                               run_dir_.string());
    }
}

void Run::load() {
    using namespace util;
    
    Logger::instance().info("Loading run from: " + run_dir_.string());
    
    // Parse TOML
    parse_run_toml();
    
    // Validate structure and semantics
    validate_structure();
    
    // Check required filesystem paths
    check_required_paths();
    
    validated_ = true;
    Logger::instance().info("Run loaded successfully: " + metadata_.run_id);
}

void Run::parse_run_toml() {
    const auto toml_path = run_toml();
    
    if (!fs::exists(toml_path)) {
        throw std::runtime_error("run.toml not found: " + toml_path.string());
    }
    
    const auto data = toml::parse(toml_path.string());
    
    // Parse [run] table (required)
    const auto& run_table = toml::find(data, "run");
    metadata_.run_id = toml::find<std::string>(run_table, "run_id");
    metadata_.study_name = toml::find<std::string>(run_table, "study_name");
    metadata_.semantic_path = toml::find<std::string>(run_table, "semantic_path");
    
    // Parse [doe] table (required)
    const auto& doe_table = toml::find(data, "doe");
    for (const auto& [key, value] : doe_table.as_table()) {
        if (value.is_floating()) {
            doe_.params[key] = value.as_floating();
        } else if (value.is_integer()) {
            doe_.params[key] = value.as_integer();
        } else if (value.is_string()) {
            doe_.params[key] = value.as_string();
        } else if (value.is_boolean()) {
            doe_.params[key] = value.as_boolean();
        }
    }
    
    // Parse [design] table (required)
    const auto& design_table = toml::find(data, "design");
    design_.top = toml::find<std::string>(design_table, "top");
    design_.rtl_type = toml::find<std::string>(design_table, "rtl_type");
    design_.filelist = toml::find<std::string>(design_table, "filelist");
    
    if (design_table.contains("include_dirs")) {
        const auto& dirs = toml::find(design_table, "include_dirs");
        for (const auto& dir : dirs.as_array()) {
            design_.include_dirs.push_back(dir.as_string());
        }
    }
    
    if (design_table.contains("defines")) {
        const auto& defs = toml::find(design_table, "defines");
        for (const auto& def : defs.as_array()) {
            design_.defines.push_back(def.as_string());
        }
    }
    
    if (design_table.contains("sdc_files")) {
        const auto& sdcs = toml::find(design_table, "sdc_files");
        for (const auto& sdc : sdcs.as_array()) {
            design_.sdc_files.push_back(sdc.as_string());
        }
    }
    
    // Parse [technology] table (required)
    const auto& tech_table = toml::find(data, "technology");
    tech_.bundle = toml::find<std::string>(tech_table, "bundle");
    tech_.corner = toml::find<std::string>(tech_table, "corner");
    tech_.voltage = toml::find<double>(tech_table, "voltage");
    tech_.temperature = toml::find<int>(tech_table, "temperature");
    
    // Parse [vars] table (optional)
    if (data.contains("vars")) {
        const auto& vars_table = toml::find(data, "vars");
        for (const auto& [key, value] : vars_table.as_table()) {
            // All variables must be strings or convertible to strings
            vars_[key] = value.is_string() ? value.as_string() 
                                           : toml::format(value);
        }
    }
    
    // Parse tool-specific tables (e.g., [genus], [innovus])
    for (const auto& [table_name, table] : data.as_table()) {
        if (table_name == "run" || table_name == "doe" || 
            table_name == "design" || table_name == "technology" || 
            table_name == "vars") {
            continue;  // Skip standard tables
        }
        
        // Tool-specific table
        VariableStore tool_vars;
        for (const auto& [key, value] : table.as_table()) {
            tool_vars[key] = value.is_string() ? value.as_string() 
                                                : toml::format(value);
        }
        tool_configs_[table_name] = std::move(tool_vars);
    }
}

void Run::validate_structure() {
    using namespace config;
    
    // Validate variable keys and values
    VariableValidator::validate_store(vars_);
    
    for (const auto& [tool, tool_vars] : tool_configs_) {
        VariableValidator::validate_store(tool_vars);
    }
    
    // Check required fields are non-empty
    if (metadata_.run_id.empty()) {
        throw std::runtime_error("run_id cannot be empty");
    }
    if (metadata_.study_name.empty()) {
        throw std::runtime_error("study_name cannot be empty");
    }
    if (design_.top.empty()) {
        throw std::runtime_error("design.top cannot be empty");
    }
    if (tech_.bundle.empty()) {
        throw std::runtime_error("technology.bundle cannot be empty");
    }
}

void Run::check_required_paths() {
    // env.sh must exist (generated by PFXStudy)
    if (!fs::exists(env_sh())) {
        throw std::runtime_error("Required env.sh not found: " + 
                               env_sh().string());
    }
}

std::optional<VariableStore> Run::tool_variables(const std::string& tool) const {
    auto it = tool_configs_.find(tool);
    if (it != tool_configs_.end()) {
        return it->second;
    }
    return std::nullopt;
}

std::string Run::dump() const {
    std::ostringstream oss;
    oss << "Run: " << metadata_.run_id << "\n"
        << "  Study: " << metadata_.study_name << "\n"
        << "  Path: " << metadata_.semantic_path << "\n"
        << "  Design: " << design_.top << " (" << design_.rtl_type << ")\n"
        << "  Tech: " << tech_.bundle << " @ " << tech_.corner << "\n"
        << "  DOE params: " << doe_.params.size() << "\n"
        << "  Variables: " << vars_.size() << "\n";
    return oss.str();
}

} // namespace pfx::core
```

### 1.3 Pipeline Class Implementation

```cpp
// include/pfx/core/Pipeline.hpp
#pragma once

#include <filesystem>
#include <map>
#include <optional>
#include <string>
#include <vector>

namespace fs = std::filesystem;

namespace pfx::core {

struct ExecConfig {
    std::vector<std::string> argv;
    std::string working_dir_policy{"stage"};  // Default per spec
    
    bool is_valid() const noexcept {
        return !argv.empty();
    }
};

struct StageConfig {
    std::string name;
    int order;  // NN in stages/NN_<name>/
    
    ExecConfig exec;
    
    // Optional stage-specific variable overrides
    std::map<std::string, std::string> vars;
    
    // Future: hooks
    std::vector<std::string> pre_hooks;
    std::vector<std::string> post_hooks;
    
    // Validation
    bool is_valid() const noexcept {
        return !name.empty() && order >= 0 && exec.is_valid();
    }
    
    // Formatted stage directory name
    std::string stage_dirname() const {
        return std::format("{:02d}_{}", order, name);
    }
};

class Pipeline {
public:
    explicit Pipeline(fs::path pipeline_toml);
    
    // Load and validate pipeline definition
    void load();
    
    // Access stages in execution order
    const std::vector<StageConfig>& stages() const noexcept { 
        return stages_; 
    }
    
    // Query specific stage by name
    std::optional<StageConfig> find_stage(const std::string& name) const;
    
    // Query by order
    std::optional<StageConfig> find_stage_by_order(int order) const;
    
    // Validation state
    bool is_valid() const noexcept { return validated_; }
    
    // Number of stages
    size_t size() const noexcept { return stages_.size(); }
    
    // Debugging
    std::string dump() const;
    
private:
    fs::path path_;
    std::vector<StageConfig> stages_;
    std::map<std::string, size_t> name_index_;  // name -> stages_ index
    bool validated_{false};
    
    void parse_pipeline_toml();
    void validate_ordering();
    void validate_unique_names();
    void build_index();
};

} // namespace pfx::core
```

```cpp
// src/core/Pipeline.cpp
#include "pfx/core/Pipeline.hpp"
#include "pfx/util/Logger.hpp"
#include <toml.hpp>
#include <algorithm>
#include <stdexcept>

namespace pfx::core {

Pipeline::Pipeline(fs::path pipeline_toml)
    : path_(std::move(pipeline_toml))
{
    if (!fs::exists(path_)) {
        throw std::runtime_error("pipeline.toml not found: " + 
                               path_.string());
    }
}

void Pipeline::load() {
    using namespace util;
    
    Logger::instance().info("Loading pipeline from: " + path_.string());
    
    parse_pipeline_toml();
    validate_ordering();
    validate_unique_names();
    build_index();
    
    validated_ = true;
    Logger::instance().info("Pipeline loaded: " + std::to_string(stages_.size()) + 
                          " stages");
}

void Pipeline::parse_pipeline_toml() {
    const auto data = toml::parse(path_.string());
    
    // Pipeline should have a [stages] table or array of [[stage]] entries
    if (!data.contains("stage")) {
        throw std::runtime_error("pipeline.toml must contain [[stage]] entries");
    }
    
    const auto& stage_array = toml::find(data, "stage");
    
    for (const auto& stage_entry : stage_array.as_array()) {
        StageConfig stage;
        
        stage.name = toml::find<std::string>(stage_entry, "name");
        stage.order = toml::find<int>(stage_entry, "order");
        
        // Parse [stage.exec]
        if (stage_entry.contains("exec")) {
            const auto& exec_table = toml::find(stage_entry, "exec");
            
            if (exec_table.contains("argv")) {
                const auto& argv = toml::find(exec_table, "argv");
                for (const auto& arg : argv.as_array()) {
                    stage.exec.argv.push_back(arg.as_string());
                }
            }
            
            if (exec_table.contains("working_dir_policy")) {
                stage.exec.working_dir_policy = 
                    toml::find<std::string>(exec_table, "working_dir_policy");
            }
        }
        
        // Parse optional [stage.vars]
        if (stage_entry.contains("vars")) {
            const auto& vars_table = toml::find(stage_entry, "vars");
            for (const auto& [key, value] : vars_table.as_table()) {
                stage.vars[key] = value.is_string() ? value.as_string() 
                                                    : toml::format(value);
            }
        }
        
        if (!stage.is_valid()) {
            throw std::runtime_error("Invalid stage configuration: " + stage.name);
        }
        
        stages_.push_back(std::move(stage));
    }
    
    if (stages_.empty()) {
        throw std::runtime_error("Pipeline must contain at least one stage");
    }
}

void Pipeline::validate_ordering() {
    // Stages must be ordered by 'order' field
    for (size_t i = 1; i < stages_.size(); ++i) {
        if (stages_[i].order <= stages_[i-1].order) {
            throw std::runtime_error(
                "Stage ordering violation: stage '" + stages_[i].name + 
                "' (order=" + std::to_string(stages_[i].order) + 
                ") must come after '" + stages_[i-1].name + 
                "' (order=" + std::to_string(stages_[i-1].order) + ")");
        }
    }
    
    // Optional: warn if orders are not sequential
    for (size_t i = 0; i < stages_.size(); ++i) {
        int expected = static_cast<int>(i) + 1;
        if (stages_[i].order != expected) {
            util::Logger::instance().warning(
                "Stage '" + stages_[i].name + "' has order " + 
                std::to_string(stages_[i].order) + ", expected " + 
                std::to_string(expected));
        }
    }
}

void Pipeline::validate_unique_names() {
    std::set<std::string> seen;
    for (const auto& stage : stages_) {
        if (seen.contains(stage.name)) {
            throw std::runtime_error("Duplicate stage name: " + stage.name);
        }
        seen.insert(stage.name);
    }
}

void Pipeline::build_index() {
    name_index_.clear();
    for (size_t i = 0; i < stages_.size(); ++i) {
        name_index_[stages_[i].name] = i;
    }
}

std::optional<StageConfig> Pipeline::find_stage(const std::string& name) const {
    auto it = name_index_.find(name);
    if (it != name_index_.end()) {
        return stages_[it->second];
    }
    return std::nullopt;
}

std::optional<StageConfig> Pipeline::find_stage_by_order(int order) const {
    auto it = std::find_if(stages_.begin(), stages_.end(),
                          [order](const StageConfig& s) { 
                              return s.order == order; 
                          });
    if (it != stages_.end()) {
        return *it;
    }
    return std::nullopt;
}

std::string Pipeline::dump() const {
    std::ostringstream oss;
    oss << "Pipeline: " << stages_.size() << " stages\n";
    for (const auto& stage : stages_) {
        oss << "  [" << stage.order << "] " << stage.name;
        if (!stage.exec.argv.empty()) {
            oss << " -> " << stage.exec.argv[0];
        }
        oss << "\n";
    }
    return oss.str();
}

} // namespace pfx::core
```

### 1.4 Variable Validator Implementation

```cpp
// include/pfx/config/VariableValidator.hpp
#pragma once

#include <map>
#include <string>

namespace pfx::config {

class VariableValidator {
public:
    // Section 3.12.1: Keys may contain only letters, digits, dots (.), dashes (-)
    static bool is_valid_key(const std::string& key);
    
    // Section 3.12.2: Values MUST NOT contain: $, quotes, newlines, backslashes
    static bool is_valid_value(const std::string& value);
    
    // Validate entire variable store (throws on first error)
    static void validate_store(const std::map<std::string, std::string>& vars);
    
    // Get descriptive error message
    static std::string get_key_error(const std::string& key);
    static std::string get_value_error(const std::string& value);
};

} // namespace pfx::config
```

```cpp
// src/config/VariableValidator.cpp
#include "pfx/config/VariableValidator.hpp"
#include <algorithm>
#include <cctype>
#include <stdexcept>

namespace pfx::config {

bool VariableValidator::is_valid_key(const std::string& key) {
    if (key.empty()) return false;
    
    return std::all_of(key.begin(), key.end(), [](char c) {
        return std::isalnum(static_cast<unsigned char>(c)) || 
               c == '.' || c == '-';
    });
}

bool VariableValidator::is_valid_value(const std::string& value) {
    return std::none_of(value.begin(), value.end(), [](char c) {
        return c == '$' || c == '"' || c == '\'' || 
               c == '\n' || c == '\r' || c == '\\';
    });
}

void VariableValidator::validate_store(
    const std::map<std::string, std::string>& vars)
{
    for (const auto& [key, value] : vars) {
        if (!is_valid_key(key)) {
            throw std::runtime_error(
                "Invalid variable key: " + get_key_error(key));
        }
        if (!is_valid_value(value)) {
            throw std::runtime_error(
                "Invalid variable value for key '" + key + "': " + 
                get_value_error(value));
        }
    }
}

std::string VariableValidator::get_key_error(const std::string& key) {
    if (key.empty()) {
        return "Key cannot be empty";
    }
    
    // Find first invalid character
    for (size_t i = 0; i < key.size(); ++i) {
        char c = key[i];
        if (!std::isalnum(static_cast<unsigned char>(c)) && 
            c != '.' && c != '-') {
            return "'" + key + "' contains invalid character '" + 
                   std::string(1, c) + "' at position " + std::to_string(i) +
                   ". Only letters, digits, dots (.), and dashes (-) allowed.";
        }
    }
    
    return "'" + key + "' is invalid";
}

std::string VariableValidator::get_value_error(const std::string& value) {
    // Find first forbidden character
    for (size_t i = 0; i < value.size(); ++i) {
        char c = value[i];
        if (c == '$') {
            return "Value contains forbidden dollar sign ($) at position " + 
                   std::to_string(i);
        }
        if (c == '"' || c == '\'') {
            return "Value contains forbidden quote (" + 
                   std::string(1, c) + ") at position " + std::to_string(i);
        }
        if (c == '\n' || c == '\r') {
            return "Value contains forbidden newline at position " + 
                   std::to_string(i);
        }
        if (c == '\\') {
            return "Value contains forbidden backslash (\\) at position " + 
                   std::to_string(i);
        }
    }
    
    return "Value is invalid";
}

} // namespace pfx::config
```

### 1.5 Tcl Generator Implementation

```cpp
// include/pfx/executor/TclGenerator.hpp
#pragma once

#include "pfx/core/Run.hpp"
#include "pfx/core/Stage.hpp"
#include <filesystem>
#include <map>
#include <string>

namespace pfx::executor {

class TclGenerator {
public:
    TclGenerator(const core::Run& run, const core::Stage& stage);
    
    // Generate pfx_vars.tcl in stage directory
    void generate_vars_file();
    
    // Get path to generated pfx_vars.tcl
    std::filesystem::path vars_file_path() const;
    
private:
    const core::Run& run_;
    const core::Stage& stage_;
    
    // Collect all variables (run + stage overrides)
    std::map<std::string, std::string> collect_variables() const;
    
    // Emit single variable in canonical Tcl form (Section 3.12.3)
    std::string emit_tcl_variable(const std::string& key, 
                                  const std::string& value) const;
    
    // Generate complete pfx_vars.tcl content
    std::string generate_tcl_content() const;
};

} // namespace pfx::executor
```

```cpp
// src/executor/TclGenerator.cpp
#include "pfx/executor/TclGenerator.hpp"
#include "pfx/util/FileOps.hpp"
#include "pfx/util/Logger.hpp"
#include <sstream>

namespace pfx::executor {

TclGenerator::TclGenerator(const core::Run& run, const core::Stage& stage)
    : run_(run), stage_(stage)
{
}

std::filesystem::path TclGenerator::vars_file_path() const {
    return stage_.dir() / "pfx_vars.tcl";
}

std::map<std::string, std::string> TclGenerator::collect_variables() const {
    std::map<std::string, std::string> result;
    
    // Start with run-level [vars]
    result = run_.variables();
    
    // Add/override with stage-specific vars
    for (const auto& [key, value] : stage_.config().vars) {
        result[key] = value;
    }
    
    // Add DOE parameters as variables
    for (const auto& [key, value] : run_.doe().params) {
        std::string str_value;
        std::visit([&str_value](const auto& v) {
            std::ostringstream oss;
            oss << v;
            str_value = oss.str();
        }, value);
        result["doe." + key] = str_value;
    }
    
    // Add metadata as variables
    result["run.id"] = run_.metadata().run_id;
    result["run.study"] = run_.metadata().study_name;
    result["run.semantic_path"] = run_.metadata().semantic_path;
    
    // Add design info
    result["design.top"] = run_.design().top;
    result["design.rtl_type"] = run_.design().rtl_type;
    
    // Add technology info
    result["tech.bundle"] = run_.technology().bundle;
    result["tech.corner"] = run_.technology().corner;
    result["tech.voltage"] = std::to_string(run_.technology().voltage);
    result["tech.temperature"] = std::to_string(run_.technology().temperature);
    
    // Add stage info
    result["stage.name"] = stage_.name();
    result["stage.order"] = std::to_string(stage_.order());
    
    return result;
}

std::string TclGenerator::emit_tcl_variable(const std::string& key,
                                           const std::string& value) const {
    // Section 3.12.3: Canonical form is: set pfx(key) {value}
    return "set pfx(" + key + ") {" + value + "}\n";
}

std::string TclGenerator::generate_tcl_content() const {
    std::ostringstream oss;
    
    // Header comment
    oss << "# PFXFlow Variable Export\n";
    oss << "# Generated by PFXCore for stage: " << stage_.name() << "\n";
    oss << "# Run: " << run_.metadata().run_id << "\n";
    oss << "#\n";
    oss << "# All variables are exported in the pfx() array\n";
    oss << "# Access as: $pfx(key)\n\n";
    
    // Emit all variables
    const auto vars = collect_variables();
    for (const auto& [key, value] : vars) {
        oss << emit_tcl_variable(key, value);
    }
    
    return oss.str();
}

void TclGenerator::generate_vars_file() {
    using namespace util;
    
    const auto path = vars_file_path();
    const auto content = generate_tcl_content();
    
    Logger::instance().debug("Generating pfx_vars.tcl: " + path.string());
    
    FileOps::create_file(path, content);
    
    Logger::instance().debug("pfx_vars.tcl generated successfully");
}

} // namespace pfx::executor
```

## 2. Example Usage Patterns

### 2.1 Loading and Executing a Complete Run

```cpp
#include "pfx/PFXCore.hpp"
#include <iostream>

int main(int argc, char* argv[]) {
    try {
        // Initialize PFXCore
        pfx::PFXCore core;
        
        // Set up execution options
        pfx::ExecutionOptions opts;
        opts.force = false;        // Skip completed stages
        opts.verbose = true;
        
        // Execute complete run
        const auto run_dir = std::filesystem::path("/path/to/run_0127");
        const int exit_code = core.execute_run(run_dir, opts);
        
        if (exit_code == 0) {
            std::cout << "Run completed successfully\n";
        } else {
            std::cerr << "Run failed with exit code: " << exit_code << "\n";
        }
        
        return exit_code;
        
    } catch (const pfx::ValidationError& e) {
        std::cerr << "Validation failed: " << e.what() << "\n";
        std::cerr << "File: " << e.file() << "\n";
        return 1;
        
    } catch (const pfx::PFXError& e) {
        std::cerr << "PFXCore error: " << e.what() << "\n";
        return 1;
        
    } catch (const std::exception& e) {
        std::cerr << "Unexpected error: " << e.what() << "\n";
        return 2;
    }
}
```

### 2.2 Executing a Single Stage

```cpp
#include "pfx/PFXCore.hpp"

void debug_single_stage(const std::filesystem::path& run_dir,
                       const std::string& stage_name) {
    pfx::PFXCore core;
    
    pfx::ExecutionOptions opts;
    opts.stage_name = stage_name;
    opts.force = true;  // Re-execute even if complete
    opts.verbose = true;
    
    const int result = core.execute_stage(run_dir, stage_name, opts);
    
    if (result == 0) {
        std::cout << "Stage '" << stage_name << "' completed successfully\n";
    } else {
        std::cerr << "Stage '" << stage_name << "' failed\n";
    }
}
```

### 2.3 Validation-Only Mode

```cpp
#include "pfx/PFXCore.hpp"

bool validate_run_configuration(const std::filesystem::path& run_dir) {
    try {
        pfx::PFXCore core;
        
        pfx::ExecutionOptions opts;
        opts.validate_only = true;  // Stop after validation
        
        core.execute_run(run_dir, opts);
        
        std::cout << "Configuration is valid\n";
        return true;
        
    } catch (const pfx::ValidationError& e) {
        std::cerr << "Validation failed: " << e.what() << "\n";
        return false;
    }
}
```

## 3. Testing Examples

### 3.1 Unit Test for Variable Validator

```cpp
#include <gtest/gtest.h>
#include "pfx/config/VariableValidator.hpp"

using pfx::config::VariableValidator;

TEST(VariableValidatorTest, ValidKeys) {
    EXPECT_TRUE(VariableValidator::is_valid_key("simple"));
    EXPECT_TRUE(VariableValidator::is_valid_key("with.dots"));
    EXPECT_TRUE(VariableValidator::is_valid_key("with-dashes"));
    EXPECT_TRUE(VariableValidator::is_valid_key("key123"));
    EXPECT_TRUE(VariableValidator::is_valid_key("very.long-key.123"));
}

TEST(VariableValidatorTest, InvalidKeys) {
    EXPECT_FALSE(VariableValidator::is_valid_key(""));
    EXPECT_FALSE(VariableValidator::is_valid_key("has space"));
    EXPECT_FALSE(VariableValidator::is_valid_key("has$dollar"));
    EXPECT_FALSE(VariableValidator::is_valid_key("has/slash"));
    EXPECT_FALSE(VariableValidator::is_valid_key("has@symbol"));
}

TEST(VariableValidatorTest, ValidValues) {
    EXPECT_TRUE(VariableValidator::is_valid_value("simple"));
    EXPECT_TRUE(VariableValidator::is_valid_value("with spaces"));
    EXPECT_TRUE(VariableValidator::is_valid_value("123.456"));
    EXPECT_TRUE(VariableValidator::is_valid_value("/path/to/file"));
}

TEST(VariableValidatorTest, InvalidValues) {
    EXPECT_FALSE(VariableValidator::is_valid_value("has$dollar"));
    EXPECT_FALSE(VariableValidator::is_valid_value("has\"quote"));
    EXPECT_FALSE(VariableValidator::is_valid_value("has'apostrophe"));
    EXPECT_FALSE(VariableValidator::is_valid_value("has\\backslash"));
    EXPECT_FALSE(VariableValidator::is_valid_value("has\nnewline"));
}

TEST(VariableValidatorTest, ValidateStore) {
    std::map<std::string, std::string> good = {
        {"key1", "value1"},
        {"key.2", "value with spaces"},
        {"key-3", "123"}
    };
    EXPECT_NO_THROW(VariableValidator::validate_store(good));
    
    std::map<std::string, std::string> bad_key = {
        {"bad key", "value"}
    };
    EXPECT_THROW(VariableValidator::validate_store(bad_key), std::runtime_error);
    
    std::map<std::string, std::string> bad_value = {
        {"key", "bad$value"}
    };
    EXPECT_THROW(VariableValidator::validate_store(bad_value), std::runtime_error);
}
```

### 3.2 Integration Test for Run Loading

```cpp
#include <gtest/gtest.h>
#include "pfx/core/Run.hpp"
#include <filesystem>
#include <fstream>

class RunLoadTest : public ::testing::Test {
protected:
    void SetUp() override {
        // Create temporary test directory
        temp_dir_ = std::filesystem::temp_directory_path() / "pfx_test";
        std::filesystem::create_directories(temp_dir_);
        
        // Create minimal run.toml
        create_test_run_toml();
        create_test_env_sh();
    }
    
    void TearDown() override {
        std::filesystem::remove_all(temp_dir_);
    }
    
    void create_test_run_toml() {
        std::ofstream f(temp_dir_ / "run.toml");
        f << R"(
[run]
run_id = "test_run_001"
study_name = "test_study"
semantic_path = "test/path"

[doe]
param1 = 1.5
param2 = 100

[design]
top = "test_top"
rtl_type = "verilog"
filelist = "files.f"
defines = ["TEST"]

[technology]
bundle = "TEST_TECH"
corner = "tt"
voltage = 0.8
temperature = 25

[vars]
custom_var = "custom_value"
)";
    }
    
    void create_test_env_sh() {
        std::ofstream f(temp_dir_ / "env.sh");
        f << "#!/bin/bash\n";
        f << "# Test environment\n";
    }
    
    std::filesystem::path temp_dir_;
};

TEST_F(RunLoadTest, LoadValidRun) {
    pfx::core::Run run(temp_dir_);
    EXPECT_NO_THROW(run.load());
    EXPECT_TRUE(run.is_valid());
    
    EXPECT_EQ(run.metadata().run_id, "test_run_001");
    EXPECT_EQ(run.metadata().study_name, "test_study");
    EXPECT_EQ(run.design().top, "test_top");
    EXPECT_EQ(run.technology().bundle, "TEST_TECH");
}

TEST_F(RunLoadTest, AccessDoeParameters) {
    pfx::core::Run run(temp_dir_);
    run.load();
    
    auto param1 = run.doe().get<double>("param1");
    ASSERT_TRUE(param1.has_value());
    EXPECT_DOUBLE_EQ(*param1, 1.5);
    
    auto param2 = run.doe().get<int64_t>("param2");
    ASSERT_TRUE(param2.has_value());
    EXPECT_EQ(*param2, 100);
}

TEST_F(RunLoadTest, AccessVariables) {
    pfx::core::Run run(temp_dir_);
    run.load();
    
    const auto& vars = run.variables();
    ASSERT_EQ(vars.size(), 1);
    EXPECT_EQ(vars.at("custom_var"), "custom_value");
}
```

## 4. Key Implementation Notes

### 4.1 Memory Management
- Use RAII throughout - no manual memory management
- Prefer `std::unique_ptr` for ownership
- Use `const&` for read-only access to avoid copies
- Move semantics for transferring ownership

### 4.2 Error Handling Philosophy
- Exceptions for truly exceptional cases (file not found, parse errors)
- Return codes for expected failures (tool exit codes)
- Clear exception types for different error categories
- Rich error messages with context (file path, line number, etc.)

### 4.3 Performance Considerations
- Parse TOML files once and cache
- Build indices for O(1) lookups (stage name -> stage config)
- Use string_view for read-only string operations where appropriate
- Lazy initialization where possible

### 4.4 Thread Safety
- PFXCore is not thread-safe for same-directory concurrent execution (per spec)
- Use const methods wherever possible for clarity
- Document any mutable state clearly

### 4.5 Filesystem Operations
- Always use `std::filesystem::path` for paths
- Canonicalize paths early to avoid confusion
- Check file existence before operations
- Provide clear error messages for missing files
