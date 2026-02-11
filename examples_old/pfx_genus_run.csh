#!/bin/csh -f
#
# Usage:
#   pfx_genus_run <run_dir> <stage_name>
#
# Convention:
#   Stage script:  <run_dir>/stages/<order>_<stage>/scripts/<stage>.tcl
#   Outputs:       <run_dir>/stages/<order>_<stage>/outputs/...
#   Log file:      <run_dir>/logs/<order>_<stage>.log
#

# ----------------------------
# Argument checking
# ----------------------------

if ( $#argv != 2 ) then
    echo "ERROR: Usage: pfx_genus_run <run_dir> <stage_name>"
    exit 1
endif

set RUN_DIR    = "$argv[1]"
set STAGE_NAME = "$argv[2]"

if ( ! -d "$RUN_DIR" ) then
    echo "ERROR: Run directory not found: $RUN_DIR"
    exit 1
endif


# ----------------------------
# Locate study root (find pipeline.toml)
# ----------------------------

set CUR = "$RUN_DIR"
set STUDY_ROOT = ""

while ( "$CUR" != "/" )

    if ( -f "$CUR/pipeline.toml" ) then
        set STUDY_ROOT = "$CUR"
        break
    endif

    set CUR = `dirname "$CUR"`

end

if ( "$STUDY_ROOT" == "" ) then
    echo "ERROR: pipeline.toml not found (study root not located)"
    exit 1
endif


# ----------------------------
# Get stage order from pipeline.toml
# (simple awk parsing; assumes [[stages]] blocks)
# ----------------------------

set ORDER = `awk '
  /^\[\[stages\]\]/ { in=0 }
  $1=="name" && $3=="\"'$STAGE_NAME'\"" { in=1 }
  in && $1=="order" { gsub(/=/,""); print $2; exit }
' $STUDY_ROOT/pipeline.toml`

if ( "$ORDER" == "" ) then
    echo "ERROR: Could not find order for stage '$STAGE_NAME'"
    exit 1
endif


# ----------------------------
# Directory layout
# ----------------------------

set STAGE_DIR  = "$RUN_DIR/stages/${ORDER}_${STAGE_NAME}"
set SCRIPT_DIR = "$STAGE_DIR/scripts"
set OUT_DIR    = "$STAGE_DIR/outputs"
set LOG_DIR    = "$RUN_DIR/logs"

set TCL_SCRIPT = "$SCRIPT_DIR/${STAGE_NAME}.tcl"
set LOG_FILE   = "$LOG_DIR/${ORDER}_${STAGE_NAME}.log"


# ----------------------------
# Validate stage script
# ----------------------------

if ( ! -f "$TCL_SCRIPT" ) then
    echo "ERROR: Genus script not found:"
    echo "  $TCL_SCRIPT"
    exit 1
endif

mkdir -p "$OUT_DIR"
mkdir -p "$LOG_DIR"


# ----------------------------
# Environment setup
# ----------------------------

# Optional: source run-local env.sh (may be produced by PFXCore or provided by user)
if ( -f "$RUN_DIR/env.sh" ) then
    echo "Sourcing env.sh"
    source "$RUN_DIR/env.sh"
endif


# ----------------------------
# Move to stage directory
# ----------------------------

cd "$STAGE_DIR"
if ( $status != 0 ) then
    echo "ERROR: Cannot cd to $STAGE_DIR"
    exit 1
endif


# ----------------------------
# Run Genus
# ----------------------------
# Genus doesn't have a -log switch like Innovus in your example, so we capture
# stdout/stderr to the stage log file.

echo "======================================"   >  "$LOG_FILE"
echo "Running Genus stage: $STAGE_NAME"         >> "$LOG_FILE"
echo "Run dir:    $RUN_DIR"                     >> "$LOG_FILE"
echo "Stage dir:  $STAGE_DIR"                   >> "$LOG_FILE"
echo "Script:     $TCL_SCRIPT"                  >> "$LOG_FILE"
echo "======================================"   >> "$LOG_FILE"

genus \
    -abort_on_error \
    -no_gui \
    -batch \
    -files "$TCL_SCRIPT" >>& "$LOG_FILE"

set RC = $status


# ----------------------------
# Error handling
# ----------------------------

if ( $RC != 0 ) then
    echo "ERROR: Genus failed (rc=$RC)" >> "$LOG_FILE"
    echo "ERROR: Genus failed (rc=$RC)"
    exit $RC
endif


# ----------------------------
# Minimal output validation
# ----------------------------
# Your pipeline.toml declares outputs such as:
#   stages/10_synth/outputs/netlist.v
#   stages/10_synth/outputs/constraints.sdc
#
# Here we enforce those conventionally.
#
# If you want stage-specific outputs (e.g. only netlist for synth), you can
# extend this with a per-stage map.

set NETLIST = "$OUT_DIR/netlist.v"
set SDC     = "$OUT_DIR/constraints.sdc"

if ( ! -f "$NETLIST" ) then
    echo "ERROR: Expected netlist not found: $NETLIST" >> "$LOG_FILE"
    echo "ERROR: Expected netlist not found: $NETLIST"
    exit 1
endif

if ( ! -f "$SDC" ) then
    echo "ERROR: Expected SDC not found: $SDC" >> "$LOG_FILE"
    echo "ERROR: Expected SDC not found: $SDC"
    exit 1
endif


# ----------------------------
# Success
# ----------------------------

echo "Stage $STAGE_NAME completed successfully" >> "$LOG_FILE"
echo "Stage $STAGE_NAME completed successfully"

exit 0
