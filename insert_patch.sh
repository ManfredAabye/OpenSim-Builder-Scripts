#!/bin/bash

###############################################################################
# OpenSimulator Patch Applicator
# Applies git patches to the OpenSimulator repository
###############################################################################

# Verwendungsbeispiele:
# # Patch anwenden
# bash insert_patch.sh BulletS-crossing.patch

# # Zunächst testen (empfohlen)
# bash insert_patch.sh --dry-run BulletS-crossing.patch

# # Patch rückgängig machen
# bash insert_patch.sh --revert BulletS-crossing.patch

# # Mit ausführlicher Ausgabe
# bash insert_patch.sh --verbose BulletS-crossing.patch

# # Hilfe anzeigen
# bash insert_patch.sh --help

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}/opensim"
PATCH_DIR="${SCRIPT_DIR}/patch"

###############################################################################
# Functions
###############################################################################

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] <patch-file>

Apply a git patch to the OpenSimulator repository.

OPTIONS:
    -h, --help              Show this help message
    -d, --dry-run           Show what would be applied without actually applying
    -v, --verbose           Show verbose output
    -r, --revert            Revert the patch instead of applying it
    --force-fallback        Try fallback patch methods if git apply fails

EXAMPLES:
    # Apply a patch
    $0 BulletS-crossing.patch

    # Do a dry run
    $0 --dry-run BulletS-crossing.patch

    # Revert a patch
    $0 --revert BulletS-crossing.patch

    # Linux layout under /opt (recommended sequence)
    cd /opt
    bash insert_patch.sh --dry-run BulletS-crossing.patch
    bash insert_patch.sh --verbose BulletS-crossing.patch
    bash insert_patch.sh --verbose --force-fallback BulletS-crossing.patch

EOF
    exit 1
}

check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v git &> /dev/null; then
        print_error "git is not installed"
        exit 1
    fi
    
    if [ ! -d "$REPO_ROOT" ]; then
        print_error "Repository directory not found: $REPO_ROOT"
        exit 1
    fi
    
    if [ ! -d "$PATCH_DIR" ]; then
        print_error "Patch directory not found: $PATCH_DIR"
        exit 1
    fi
    
    print_success "Prerequisites OK"
}

validate_patch_file() {
    local patch_file="$1"
    local full_path="${PATCH_DIR}/${patch_file}"
    
    if [ ! -f "$full_path" ]; then
        print_error "Patch file not found: $full_path"
        echo "Available patches:"
        ls -la "$PATCH_DIR"/*.patch 2>/dev/null || echo "  (no patches found)"
        exit 1
    fi
    
    echo "$full_path"
}

apply_patch() {
    local patch_file="$1"
    local dry_run="$2"
    local verbose="$3"
    local revert="$4"
    local force_fallback="$5"
    local work_patch_file="$patch_file"
    local temp_patch_file=""
    
    print_info "Patch file: $(basename "$patch_file")"
    print_info "Repository: $REPO_ROOT"
    
    cd "$REPO_ROOT"

    # Normalize Windows CRLF patch files to LF for maximum compatibility.
    if grep -q $'\r' "$patch_file" 2>/dev/null; then
        temp_patch_file="$(mktemp)"
        tr -d '\r' < "$patch_file" > "$temp_patch_file"
        work_patch_file="$temp_patch_file"
        [ "$verbose" = "true" ] && print_info "Normalized CRLF line endings in patch file"
    fi

    # If reverse check succeeds, this patch is likely already applied.
    if [ "$revert" = "false" ] && git apply --reverse --check "$work_patch_file" >/dev/null 2>&1; then
        print_success "Patch appears to be already applied"
        [ -n "$temp_patch_file" ] && rm -f "$temp_patch_file"
        return 0
    fi
    
    # Build git apply command arrays to preserve quoting safely.
    local cmd=(git apply)
    [ "$revert" = "true" ] && cmd+=(--reverse)
    [ "$dry_run" = "true" ] && cmd+=(--check)
    [ "$verbose" = "true" ] && cmd+=(-v)
    cmd+=("$work_patch_file")

    local cmd_ws=(git apply --ignore-space-change --ignore-whitespace)
    [ "$revert" = "true" ] && cmd_ws+=(--reverse)
    [ "$dry_run" = "true" ] && cmd_ws+=(--check)
    [ "$verbose" = "true" ] && cmd_ws+=(-v)
    cmd_ws+=("$work_patch_file")

    local cmd_3way=(git apply --3way)
    [ "$revert" = "true" ] && cmd_3way+=(--reverse)
    [ "$dry_run" = "true" ] && cmd_3way+=(--check)
    [ "$verbose" = "true" ] && cmd_3way+=(-v)
    cmd_3way+=("$work_patch_file")

    local cmd_reject=(git apply --reject --recount)
    [ "$revert" = "true" ] && cmd_reject+=(--reverse)
    [ "$dry_run" = "true" ] && cmd_reject+=(--check)
    [ "$verbose" = "true" ] && cmd_reject+=(-v)
    cmd_reject+=("$work_patch_file")
    
    if [ "$dry_run" = "true" ]; then
        print_info "DRY RUN: Testing patch application..."
    elif [ "$revert" = "true" ]; then
        print_info "REVERT: Attempting to revert patch..."
    else
        print_info "APPLY: Applying patch..."
    fi
    
    if [ "$verbose" = "true" ]; then
        print_info "Executing: ${cmd[*]}"
    fi
    
    # Execute the command
    if "${cmd[@]}"; then
        if [ "$dry_run" = "true" ]; then
            print_success "Patch would apply cleanly (dry-run mode)"
        elif [ "$revert" = "true" ]; then
            print_success "Patch reverted successfully"
        else
            print_success "Patch applied successfully"
        fi
        [ -n "$temp_patch_file" ] && rm -f "$temp_patch_file"
        return 0
    else
        print_warn "Primary method failed: git apply"

        # For dry-run and revert we avoid destructive fallback methods.
        if [ "$dry_run" = "true" ] || [ "$revert" = "true" ]; then
            print_error "Failed to apply patch"
            print_warn "Likely source mismatch between patch and repository state"
            [ -n "$temp_patch_file" ] && rm -f "$temp_patch_file"
            return 1
        fi

        print_info "Trying fallback #1: git apply --ignore-whitespace"
        if "${cmd_ws[@]}"; then
            print_success "Patch applied successfully with whitespace-tolerant mode"
            print_warn "Please review result: git status ; git diff"
            [ -n "$temp_patch_file" ] && rm -f "$temp_patch_file"
            return 0
        fi

        print_info "Trying fallback #2: git apply --3way"
        if "${cmd_3way[@]}"; then
            print_success "Patch applied successfully with 3-way merge"
            print_warn "Please review merged result: git status ; git diff"
            [ -n "$temp_patch_file" ] && rm -f "$temp_patch_file"
            return 0
        fi

        print_info "Trying fallback #3: git apply --reject --recount"
        if "${cmd_reject[@]}"; then
            print_success "Patch partially applied with reject mode"
            print_warn "Review any *.rej files and resolve remaining hunks manually"
            print_warn "Then verify: git status ; git diff"
            [ -n "$temp_patch_file" ] && rm -f "$temp_patch_file"
            return 0
        fi

        if [ "$force_fallback" = "true" ]; then
            print_info "Trying fallback #4: patch -p1 --forward --fuzz=3"
            if command -v patch >/dev/null 2>&1; then
                if patch -p1 --forward --fuzz=3 --input="$work_patch_file"; then
                    print_success "Patch applied using 'patch -p1' fallback"
                    print_warn "Please review result carefully: git status ; git diff"
                    [ -n "$temp_patch_file" ] && rm -f "$temp_patch_file"
                    return 0
                fi
            else
                print_warn "'patch' command not available; skipping fallback #4"
            fi
        fi

        print_error "Failed to apply patch"
        print_warn "Likely source mismatch between patch and repository state"
        print_warn "Try one of these options:"
        print_warn "  1) Update source to matching commit/version"
        print_warn "  2) Recreate patch from your current source tree"
        print_warn "  3) Run with --force-fallback to try GNU patch fuzz mode"
        print_warn "  4) Compare target file against patch context and regenerate"
        print_warn "  5) Run with --verbose for detailed diagnostics"
        [ -n "$temp_patch_file" ] && rm -f "$temp_patch_file"
        return 1
    fi
}

###############################################################################
# Main
###############################################################################

# Default values
DRY_RUN="false"
VERBOSE="false"
REVERT="false"
PATCH_FILE=""
FORCE_FALLBACK="false"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            ;;
        -d|--dry-run)
            DRY_RUN="true"
            shift
            ;;
        -v|--verbose)
            VERBOSE="true"
            shift
            ;;
        -r|--revert)
            REVERT="true"
            shift
            ;;
        --force-fallback)
            FORCE_FALLBACK="true"
            shift
            ;;
        -*)
            print_error "Unknown option: $1"
            show_usage
            ;;
        *)
            if [ -z "$PATCH_FILE" ]; then
                PATCH_FILE="$1"
            else
                print_error "Multiple patch files specified"
                show_usage
            fi
            shift
            ;;
    esac
done

# Validate we have a patch file
if [ -z "$PATCH_FILE" ]; then
    print_error "No patch file specified"
    show_usage
fi

# Run the process
print_info "OpenSimulator Patch Applicator"
print_info "=============================="

check_prerequisites

FULL_PATCH_PATH=$(validate_patch_file "$PATCH_FILE")

echo ""

if ! apply_patch "$FULL_PATCH_PATH" "$DRY_RUN" "$VERBOSE" "$REVERT" "$FORCE_FALLBACK"; then
    exit 1
fi

echo ""
print_success "Done!"

exit 0
