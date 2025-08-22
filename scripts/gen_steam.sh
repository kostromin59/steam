#!/bin/bash

PROTO_DIR="proto/steamdatabase/steam"
OUTPUT_DIR="gen"

BLACKLIST=()

mkdir -p $OUTPUT_DIR

EXCLUDE_CONDITION=""
for blacklisted in "${BLACKLIST[@]}"; do
    EXCLUDE_CONDITION="$EXCLUDE_CONDITION -name $blacklisted -o"
done

EXCLUDE_CONDITION=${EXCLUDE_CONDITION% -o}

if [ -n "$EXCLUDE_CONDITION" ]; then
    PROTO_FILES=$(find $PROTO_DIR -name "*.proto" ! \( $EXCLUDE_CONDITION \))
else
    PROTO_FILES=$(find $PROTO_DIR -name "*.proto")
fi

if [ -z "$PROTO_FILES" ]; then
    echo "No proto files found in $PROTO_DIR"
    exit 1
fi

get_dependencies() {
    local proto_file=$1
    local deps=()
    
    while IFS= read -r line; do
        if [[ $line =~ ^import\ \"(.+)\"\; ]]; then
            dep_file="${BASH_REMATCH[1]}"
            dep_filename=$(basename "$dep_file")
            deps+=("$dep_filename")
        fi
    done < "$proto_file"
    
    printf '%s\n' "${deps[@]}" | sort -u
}

# Функция для построения команды protoc с зависимостями
build_protoc_command() {
    local proto_file=$1
    local filename=$(basename "$proto_file")
    local cmd="protoc -I=$PROTO_DIR --go_out=$OUTPUT_DIR"
    
    cmd="$cmd --go_opt=M$filename=go/steampb"
    
    local dependencies=$(get_dependencies "$proto_file")
    
    while IFS= read -r dep; do
        if [ -n "$dep" ]; then
            cmd="$cmd --go_opt=M$dep=go/steampb"
        fi
    done <<< "$dependencies"
    
    cmd="$cmd --go_opt=Menums.proto=go/steampb \
    --go_opt=Mcontenthubs.proto=go/steampb \
    --go_opt=Msteamnetworkingsockets_messages_certs.proto=go/steampb \
    --go_opt=Menums_productinfo.proto=go/steampb \
    proto/steamdatabase/steam/steamnetworkingsockets_messages_certs.proto \
    proto/steamdatabase/steam/contenthubs.proto \
    proto/steamdatabase/steam/enums_productinfo.proto \
    proto/steamdatabase/steam/enums.proto"

    cmd="$cmd $proto_file"
    
    echo "$cmd"
}

for proto_file in $PROTO_FILES; do
    CMD=$(build_protoc_command "$proto_file")
    echo "$CMD"
    echo ""
    eval $CMD
done