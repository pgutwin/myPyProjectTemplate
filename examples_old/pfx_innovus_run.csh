#!/bin/csh -f
#
# Usage:
#   pfx_innovus_run <run_dir> <stage_name>
#

# ----------------------------
# Argument checking
# ----------------------------

if ( $#argv != 2 ) then
    echo "ERROR: Usage: pfx_innovus_run <run_dir> <stage_name>"
    exit 1
endif

set RUN_DIR    = "$argv[1]"
set STAGE_NAME = "$argv[2]"

if ( ! -d "$RUN_DIR" ) then
    echo "ERROR: Run directory not found: $RUN_DIR"
    exit 1
endif


# ----------------------------
# Locate study root
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
# (simple grep/sed parsing for v1)
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

set STAGE_DIR = "$RUN_DIR/stages/${ORDER}_${STAGE_NAME}"
set SCRIPT_DIR = "$STAGE_DIR/scripts"
set OUT_DIR    = "$STAGE_DIR/outputs"
set LOG_DIR    = "$RUN_DIR/logs"

set TCL_SCRIPT = "$SCRIPT_DIR/${STAGE_NAME}.tcl"
set LOG_FILE   = "$LOG_DIR/${ORDER}_${STAGE_NAME}.log"


# ----------------------------
# Validate inputs
# ----------------------------

if ( ! -f "$TCL_SCRIPT" ) then
    echo "ERROR: Innovus script not found:"
    echo "  $TCL_SCRIPT"
    exit 1
endif

mkdir -p "$OUT_DIR"
mkdir -p "$LOG_DIR"


# ----------------------------
# Environment setup
# ----------------------------

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
# Run Innovus
# ----------------------------

echo "======================================"
echo "Running Innovus stage: $STAGE_NAME"
echo "Run dir:    $RUN_DIR"
echo "Stage dir:  $STAGE_DIR"
echo "Script:     $TCL_SCRIPT"
echo "Log:        $LOG_FILE"
echo "======================================"

innovus \
    -stylus \
    -64 \
    -init "$TCL_SCRIPT" \
    -log  "$LOG_FILE"

set RC = $status


# ----------------------------
# Error handling
# ----------------------------

if ( $RC != 0 ) then
    echo "ERROR: Innovus failed (rc=$RC)"
    exit $RC
endif


# ----------------------------
# Minimal output validation
# (example: design.enc must exist)
# ----------------------------

set CHECKPOINT = "$OUT_DIR/design.enc"

if ( ! -f "$CHECKPOINT" ) then
    echo "ERROR: Expected checkpoint not found:"
    echo "  $CHECKPOINT"
    exit 1
endif


# ----------------------------
# Success
# ----------------------------

echo "Stage $STAGE_NAME completed successfully"

exit 0
