#!/bin/bash
##----------------------------------------------------------------------------------------------
## Calculates disk usage and emails HTML report with color
## Hua Huang 02/06/2026
##----------------------------------------------------------------------------------------------

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "USAGE: bash storage_usage.sh USERNAME EMAIL_ADDRESS"
    exit 0
fi

USER="$1"
EMAIL="$2"

REPORT_DIR=/home/"$USER"/storage_usage_reports
mkdir -p "$REPORT_DIR"

OUTPUT_FILE="$REPORT_DIR/Storage_Usage_Report_$(date +%Y%m%d).html"

if [ -e "$OUTPUT_FILE" ]; then
    echo "Can't overwrite $OUTPUT_FILE"
    exit 0
fi

cat > "$OUTPUT_FILE" <<EOF
To: $EMAIL
Subject: HPC Storage Usage Report
MIME-Version: 1.0
Content-Type: text/html; charset=UTF-8

<html>
<body>
<h4>HPC Storage Usage Report</h4>
<p>Report Date: $(date)</p>
<pre style="font-family: monospace; font-size: 11px; line-height: 1.2;">
EOF

total=0

for folder in $(find /project/wherrylab/ -mindepth 2 -maxdepth 2 -type d -user "$USER") $(find /home/"$USER" -mindepth 2 -maxdepth 2 -type d)
    do
    if [ -d "$folder" ]; then
        usage=$(du -s "$folder" | cut -f1)
        total=$((total + usage))
        gigabytes=$(echo "scale=4;$usage/1000000" | bc)

        if (( $(echo "$gigabytes > 100" | bc -l) )); then
            printf "%s\t<span style=\"color:red;font-weight:bold;\">%s GB</span>\n" \
                "$folder" "$gigabytes" >> "$OUTPUT_FILE"
        else
            printf "%s\t%s GB\n" "$folder" "$gigabytes" >> "$OUTPUT_FILE"
        fi
    fi
done

terabytes=$(echo "scale=4;$total/1000000000" | bc)
cost=$(printf "%.2f" "$(echo "scale=8;$total*0.000000055" | bc)")

cat >> "$OUTPUT_FILE" <<EOF
</pre>
<p><b>Total TB:</b> $terabytes</p>
<p><b>Total Monthly Cost:</b> \$$cost</p>
</body>
</html>
EOF

/usr/sbin/sendmail -v "$EMAIL" < "$OUTPUT_FILE"
rm "$OUTPUT_FILE"
