#!/bin/bash

# GVM Credentials
GVM_USERNAME="admin"
GVM_PASSWORD="admin"

# Path to GVM's socket - This is the value for CentOS 7
SOCKET_PATH="/var/run/gvmd.sock"

#############
# VARIABLES #
#############

# Set our path, just in case
PATH=${PATH}:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

# Get the name of the script
APP_NAME=$(basename "${0}")

#############
# FUNCTIONS #
#############

usage () {
  if [ "${1}" == "formats" ]
  then
    echo "Supported report formats are:"
    echo "anon-xml"
    echo "arf"
    echo "cpe"
    echo "csv-hosts"
    echo "csv-results"
    echo "html"
    echo "itg"
    echo "nbe"
    echo "pdf"
    echo "topo-svg - Topology SVG"
    echo "txt"
    echo "vern-ism - Verinice ISM"
    echo "vern-itg - Verinice ITG"
    echo "xml"
    exit 1
  elif [ "${1}" == "scan-types" ]
  then
    echo "Supported scan types are:"
    echo "discovery"
    echo "empty"
    echo "full-and-fast"
    echo "full-and-fast-ult"
    echo "full-and-deep"
    echo "full-and-deep-ult"
    echo "host-discovery"
    echo "system-discovery"
    exit 1
  else
    echo "Usage: ${APP_NAME} --ip <IP_ADDRESS> --scan-name <NAME> --format <FORMAT_TYPE> --scan-type <SCAN_TYPE>"
    exit 1
  fi
}

###############
# SCRIPT BODY #
###############

# Evaluate all of our options
# Options can be in any order in the command
if [ ${#} -eq 0 ]
# If there are no options
then
  usage
else
  while [ ${#} -gt 0 ]
  # If there are some options
  do
    case "${1}" in
      --ip)
        IP=${2}
        shift
        ;;
      --scan-name)
        SCAN_NAME=${2}
        shift
        ;;
      --format)
        REPORT_FORMAT=${2}
        shift
        ;;
      --scan-type)
        SCAN_TYPE=${2}
        shift
        ;;
      *)
        usage
        ;;
      esac
      shift
  done
fi

# Build out an XML structure we can use to authenticate with GMP
AUTH_XML="<authenticate>\
            <credentials>\
              <username>${GVM_USERNAME}</username>\
              <password>${GVM_PASSWORD}</password>\
            </credentials>\
          </authenticate>"


# Create a target
TARGET_ID=$(
  gvm-cli \
    socket \
    --socketpath ${SOCKET_PATH} \
    --xml "<commands>\
            ${AUTH_XML}\
            <create_target>\
              <name>${SCAN_NAME}</name>\
              <hosts>${IP}</hosts>\
            </create_target>\
          </commands>"
)

# Get the response code out of the result
TARGET_RESPONSE_CODE=$(
  echo "${TARGET_ID}" \
  | grep -oE "create_target_response status=.*" \
  | cut -d "\"" -f2
)

# If we didn't get a 2xx
if [[ ${TARGET_RESPONSE_CODE:0:1} -ne 2 ]]
then
  echo "Failed to create target, quitting..."
  exit 1
fi

# Finds the word (meaning: a string with spaces on either side) with the ID in it
# Gets everything between the quotes (the actual ID)
TARGET_ID=$(
  echo "${TARGET_ID}" \
  | grep -oE "id.*" \
  | cut -d "\"" -f2
)

echo "Target ID is ${TARGET_ID}"

# Create a task using our target created above and one of the scan configs, given below
case ${SCAN_TYPE} in
  discovery)
    SCAN_CONFIG_ID="8715c877-47a0-438d-98a3-27c7a6ab2196" # Discovery
    ;;
  empty)
    SCAN_CONFIG_ID="085569ce-73ed-11df-83c3-002264764cea" # empty
    ;;
  full-and-fast)
    SCAN_CONFIG_ID="daba56c8-73ec-11df-a475-002264764cea" # Full and fast
    ;;
  full-and-fast-ult)
    SCAN_CONFIG_ID="698f691e-7489-11df-9d8c-002264764cea" # Full and fast ultimate
    ;;
  full-and-deep)
    SCAN_CONFIG_ID="708f25c4-7489-11df-8094-002264764cea" # Full and very deep
    ;;
  full-and-deep-ult)
    SCAN_CONFIG_ID="74db13d6-7489-11df-91b9-002264764cea" # Full and very deep ultimate
    ;;
  host-discovery)
    SCAN_CONFIG_ID="2d3f051c-55ba-11e3-bf43-406186ea4fc5" # Host Discovery
    ;;
  system-discovery)
    SCAN_CONFIG_ID="bbca7412-a950-11e3-9109-406186ea4fc5" # System Discovery
    ;;
  *)
    echo "Unknown scan type..."
    usage scan-types
esac

# Create the task
TASK_ID=$(
  gvm-cli \
    socket \
    --socketpath ${SOCKET_PATH} \
    --xml "<commands>\
            ${AUTH_XML}\
            <create_task>\
              <name>${SCAN_NAME}</name>\
              <Comment>Full and Fast Scan on ${IP}</Comment>\
              <target id='${TARGET_ID}'/>\
              <config id='${SCAN_CONFIG_ID}'/>\
            </create_task>
          </commands>"
)

# Get the response code out of the result
TASK_RESPONSE_CODE=$(
  echo "${TASK_ID}" \
  | grep -oE "create_task_response status=.*" \
  | cut -d "\"" -f2
)

# If we didn't get a 2xx
if [[ ${TASK_RESPONSE_CODE:0:1} -ne 2 ]]
then
  echo "Failed to create task, quitting..."
  exit 1
fi

# Get the task ID out of the response
TASK_ID=$(
  echo "${TASK_ID}" \
  | grep -oE "id.*" \
  | cut -d "\"" -f2
)
echo "Task ID is ${TASK_ID}"

# Run the newly created task
REPORT_ID=$(
  gvm-cli \
    socket \
    --socketpath ${SOCKET_PATH} \
    --xml "<commands>\
            ${AUTH_XML}\
            <start_task task_id='${TASK_ID}'/>
          </commands>"
)

# Get the report ID out of the response
REPORT_ID=$(
  echo "${REPORT_ID}" \
  | grep -o "<report_id>.*" \
  | cut -d "<" -f2 \
  | cut -d ">" -f2
)

echo "Report ID is ${REPORT_ID}"

# Initialize our variable
SCAN_COMPLETE=0
# Loop till we get a "Done" status for the scan
while [ "${SCAN_COMPLETE}" -ne "1" ]
do
  sleep 2

  # Describe the task
  TASK_STATUS=$(
    gvm-cli \
      socket \
      --socketpath ${SOCKET_PATH} \
      --xml "<commands>\
              ${AUTH_XML}\
              <get_tasks task_id='${TASK_ID}'/>
            </commands>"
  )

  # Get the status out of the response
  TASK_STATUS=$(
    echo "${TASK_STATUS}" \
    | grep -o "<status>.*" \
    | cut -d "<" -f2 \
    | cut -d ">" -f2
  )

  # Evaluate the status
  case ${TASK_STATUS} in
    Requested)
      echo "Task ${TASK_ID} is pending execution..."
      ;;
    Running)
      echo "Task ${TASK_ID} is still running. Waiting 1 minute for next check..."
      sleep 60
      ;;
    Done)
      echo "Task ${TASK_ID} is complete!"
      SCAN_COMPLETE=1
      ;;
    *)
      echo "Unknown status for task ${TASK_ID}: ${TASK_STATUS}"
      ;;
  esac
done

# Evaluate our report format and get a format ID from our list
case ${REPORT_FORMAT} in
  anon-xml)
    FORMAT_ID="5057e5cc-b825-11e4-9d0e-28d24461215b" # Anonymous XML
    ;;
  arf)
    FORMAT_ID="910200ca-dc05-11e1-954f-406186ea4fc5" # ARF
    ;;
  cpe)
    FORMAT_ID="5ceff8ba-1f62-11e1-ab9f-406186ea4fc5" # CPE
    ;;
  csv-hosts)
    FORMAT_ID="9087b18c-626c-11e3-8892-406186ea4fc5" # CSV Hosts
    ;;
  csv-results)
    FORMAT_ID="c1645568-627a-11e3-a660-406186ea4fc5" # CSV Results
    ;;
  html)
    FORMAT_ID="6c248850-1f62-11e1-b082-406186ea4fc5" # HTML
    ;;
  itg)
    FORMAT_ID="77bd6c4a-1f62-11e1-abf0-406186ea4fc5" # ITG
    ;;
  latex)
    FORMAT_ID="a684c02c-b531-11e1-bdc2-406186ea4fc5" # LaTeX
    ;;
  nbe)
    FORMAT_ID="9ca6fe72-1f62-11e1-9e7c-406186ea4fc5" # NBE
    ;;
  pdf)
    FORMAT_ID="c402cc3e-b531-11e1-9163-406186ea4fc5" # PDF
    ;;
  topo-svg)
    FORMAT_ID="9e5e5deb-879e-4ecc-8be6-a71cd0875cdd" # Topology SVG
    ;;
  txt)
    FORMAT_ID="a3810a62-1f62-11e1-9219-406186ea4fc5" # TXT
    ;;
  vern-ism)
    FORMAT_ID="c15ad349-bd8d-457a-880a-c7056532ee15" # Verinice ISM
    ;;
  vern-itg)
    FORMAT_ID="50c9950a-f326-11e4-800c-28d24461215b" # Verinice ITG
    ;;
  xml)
    FORMAT_ID="a994b278-1f62-11e1-96ac-406186ea4fc5" # XML
    ;;
  *)
    echo "Unknown format type..."
    usage formats
esac

# Get the report
REPORT=$(
  gvm-cli \
    socket \
    --socketpath ${SOCKET_PATH} \
    --xml "<commands>\
            ${AUTH_XML}\
            <get_reports report_id='${REPORT_ID}' format_id='${FORMAT_ID}'/>
          </commands>"
)

# Convert to PDF and write to the root of the container
echo "${REPORT}" \
| grep -o "</report_format>.*" \
| cut -d "<" -f2 \
| cut -d ">" -f2 \
| base64 -d > /report.pdf
