#!/bin/bash
INPUT_FILE=${1:-"access.log"}

FILTER_CONDITION='"query": "[^"]*uuid=[^"]*"'
TMP_FILE="stats_tmp_file"
TMP_DURATIONS_FILE="stats_tmp_duration_file"

grep -E "$FILTER_CONDITION" ${INPUT_FILE} > $TMP_FILE

cat $TMP_FILE | awk -F'"time_firstbyte": "' '{print $2}' |  awk -F'"' '{print $1}' | sort -n > $TMP_DURATIONS_FILE

TOTAL_MATCHED=$(wc -l $TMP_FILE | awk '{print $1}')
UNIQUE_REQUESTS=$(cat $TMP_FILE | awk -F '"host": "' '{print $2}' | awk -F ', "hitmiss":' '{print $1}' | sort -u | wc -l)
UNIQUE_PERCENTAGE=$(awk "BEGIN {printf \"%.2f\", ($UNIQUE_REQUESTS/$TOTAL_MATCHED)*100}")
MAX_THEORTICAL_HIT_RATIO=$(awk "BEGIN {printf \"%.2f\", (($TOTAL_MATCHED-$UNIQUE_REQUESTS)/$TOTAL_MATCHED)*100}")

TIME_PERCENTILE() {
    local p=$1
    local index=$(( $TOTAL_MATCHED * $p / 100   )) # Could be off by 1 index?, not sure and not important
    echo $(sed "${index}q;d" $TMP_DURATIONS_FILE)
}

HIT_COUNT=$(grep -Ec '"hitmiss": "hit"' $TMP_FILE)

if [ "$TOTAL_MATCHED" -gt 0 ]; then
        HIT_PERCENTAGE=$(awk "BEGIN {printf \"%.2f\", ($HIT_COUNT/$TOTAL_MATCHED)*100}")
        MISS_PERCENTAGE=$(awk "BEGIN {printf \"%.2f\", (100 - $HIT_PERCENTAGE)}")
else
        HIT_PERCENTAGE=0
        MISS_PERCENTAGE=0
fi

echo -e "File: \t\t\t\t\t$INPUT_FILE"
echo -e "Total Matched: \t\t\t\t$TOTAL_MATCHED"
echo -e "Unique Requests: \t\t\t$UNIQUE_REQUESTS"
echo -e "Unique Percentage: \t\t\t$UNIQUE_PERCENTAGE%"
echo -e "Hit Count: \t\t\t\t$HIT_COUNT"
echo -e "Hit Percentage: \t\t\t$HIT_PERCENTAGE%"
echo -e "Repeated Requests:\t\t\t$MAX_THEORTICAL_HIT_RATIO%"
echo -e "Miss Percentage: \t\t\t$MISS_PERCENTAGE%"
echo -e "P50: \t\t\t\t\t$(TIME_PERCENTILE 50)s (# Requests slower: $(( ${TOTAL_MATCHED} * 50 / 100 )))"
echo -e "P90: \t\t\t\t\t$(TIME_PERCENTILE 90)s (# Requests slower: $(( ${TOTAL_MATCHED} * 10 / 100 )))"
echo -e "P95: \t\t\t\t\t$(TIME_PERCENTILE 95)s (# Requests slower: $(( ${TOTAL_MATCHED} * 5 / 100 )))"
echo -e "P99: \t\t\t\t\t$(TIME_PERCENTILE 99)s (# Requests slower: $(( ${TOTAL_MATCHED} * 1 / 100 )))"
echo -e "Slowest request: \t\t\t$(tail -n1 $TMP_DURATIONS_FILE)s"
echo -e "--------------------"

rm $TMP_FILE
rm $TMP_DURATIONS_FILE
