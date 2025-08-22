#!/bin/bash

PROTO_DIR="proto/steamdatabase/webui"
OUTPUT_DIR="gen"

BLACKLIST=(
    "common.proto"
    "common_base.proto"
    "service_steamvrvoicechat.proto"
    "service_steamvrwebrtc.proto"
)

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

CMD="protoc -I=$PROTO_DIR --go_out=$OUTPUT_DIR"

for proto_file in $PROTO_FILES; do
    filename=$(basename $proto_file)
    CUR_CMD="protoc -I=$PROTO_DIR --go_out=$OUTPUT_DIR --go_opt=M$filename=go/webui  --go_opt=Mcommon.proto=go/webui --go_opt=Mcommon_base.proto=go/webui proto/steamdatabase/webui/common.proto proto/steamdatabase/webui/common_base.proto $proto_file"
    echo "$CUR_CMD"
    eval $CUR_CMD
done