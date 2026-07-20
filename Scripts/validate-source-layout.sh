#!/bin/bash
set -euo pipefail

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_directory/.." && pwd)
cd "$repo_root"

failed=0

report_failure() {
    echo "$1" >&2
    failed=1
}

maintained_roots=(
    Sources/SwiftWebUI
    Sources/SwiftWebUIStatic
    Sources/SwiftWebUIRuntime
    Sources/SwiftWebUIEmbeddedDemo
    Tests/SwiftWebUITests
    Tests/SwiftWebUIRuntimeTests
    Examples/RuntimeCounter/Sources
)

duplicate_suffixes=$(find Sources Tests Examples Documentation -type f \( \
    -name '* 2.swift' -o \
    -name '* 3.swift' -o \
    -name '* copy.swift' -o \
    -name '* new.swift' -o \
    -name '* old.swift' -o \
    -name '* backup.swift' \
\) -print)
if [[ -n "$duplicate_suffixes" ]]; then
    report_failure "Duplicate-suffixed Swift files found:"
    printf '%s\n' "$duplicate_suffixes" >&2
fi

for target_root in "${maintained_roots[@]}"; do
    [[ -d "$target_root" ]] || continue
    duplicate_basenames=$(find "$target_root" -type f -name '*.swift' -print \
        | awk -F/ '{ print $NF }' \
        | sort \
        | uniq -d)
    if [[ -n "$duplicate_basenames" ]]; then
        report_failure "Duplicate Swift basenames found in $target_root:"
        printf '%s\n' "$duplicate_basenames" >&2
    fi
done

key_declarations=(
    ViewNode
    WebNode
    WebElementNode
    WebAttribute
    WebStyleDeclaration
    ViewNodeToWebNodeLowerer
    Font
    View
    ModifiedView
    Binding
    State
    Button
    Text
    VStack
    HStack
)

for declaration in "${key_declarations[@]}"; do
    matches=$(rg --no-heading --glob '*.swift' \
        "^(public |package |internal |private |fileprivate )?(indirect )?(struct|enum|class|protocol|typealias) ${declaration}\\b" \
        Sources/SwiftWebUI || true)
    if [[ -z "$matches" ]]; then
        count=0
    else
        count=$(printf '%s\n' "$matches" | wc -l | tr -d '[:space:]')
    fi
    if [[ $count -ne 1 ]]; then
        report_failure "Expected one $declaration declaration in SwiftWebUI; found $count."
        [[ -z "$matches" ]] || printf '%s\n' "$matches" >&2
    fi
done

top_level_declarations=$(rg --no-heading --no-filename --glob '*.swift' \
    '^(public |package |internal |private |fileprivate )?(indirect )?(struct|enum|class|protocol|typealias) [A-Za-z_][A-Za-z0-9_]*' \
    Sources/SwiftWebUI \
    | sed -E 's/^(public |package |internal |private |fileprivate )?(indirect )?(struct|enum|class|protocol|typealias) ([A-Za-z_][A-Za-z0-9_]*).*/\4/' \
    | sort \
    | uniq -d)
if [[ -n "$top_level_declarations" ]]; then
    report_failure "Duplicate top-level declarations found in SwiftWebUI:"
    printf '%s\n' "$top_level_declarations" >&2
fi

for target_root in "${maintained_roots[@]}"; do
    [[ -d "$target_root" ]] || continue
    while IFS= read -r -d '' file; do
        filename=${file##*/}
        line1=$(sed -n '1p' "$file")
        line2=$(sed -n '2p' "$file")
        line3=$(sed -n '3p' "$file")
        line4=$(sed -n '4p' "$file")
        line5=$(sed -n '5p' "$file")
        line6=$(sed -n '6p' "$file")
        line7=$(sed -n '7p' "$file")

        valid_header=true
        [[ $line1 == '//' ]] || valid_header=false
        [[ $line2 == "//  $filename" ]] || valid_header=false
        [[ $line3 == '//  swift-web-ui' ]] || valid_header=false
        [[ $line4 == '//' ]] || valid_header=false
        [[ $line5 == '//  Created by '*' on '*'.' ]] || valid_header=false
        [[ $line6 == '//' ]] || valid_header=false
        [[ -z $line7 ]] || valid_header=false

        if [[ $valid_header != true ]]; then
            report_failure "Missing or malformed standard Swift header: $file"
        fi
    done < <(find "$target_root" -type f -name '*.swift' -print0)
done

if [[ -d Sources/SwiftWebUI/Core ]]; then
    report_failure "Obsolete SwiftWebUI Core source directory still exists."
fi

if rg -n 'sources:.*Core' Package.swift >/dev/null; then
    report_failure "Package.swift still references the obsolete Core source directory."
fi

if [[ $failed -ne 0 ]]; then
    exit 1
fi

echo "Swift source layout validation passed"
