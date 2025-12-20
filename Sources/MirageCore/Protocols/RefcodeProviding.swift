//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// Types providing reference code, i.e., HTTP Status Codes.

public protocol RefcodeProviding {
    var refcode: String { get }
}

//
// #!/usr/bin/env bash
//
// CHARS='ABCDEFGHJKMNPQRSTUVWXY23456789'
// CHAR_COUNT=${#CHARS}
//
// id=$(openssl rand 4 \
//  | xxd -p \
//  | fold -w2 \
//  | while read -r byte; do
//      idx=$((16#$byte % CHAR_COUNT))
//      printf '%s' "${CHARS:idx:1}"
//    done \
//  | head -c 4)
//
// printf '%s' "$id" | pbcopy
// echo "$id"
//
