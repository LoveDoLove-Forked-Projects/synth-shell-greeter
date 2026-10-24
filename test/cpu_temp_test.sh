#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
# shellcheck source=test/support/testlib.sh
source "$SCRIPT_DIR/support/testlib.sh"

test_root="$(createTestRoot cpu-temp)"
mkdir -p "$test_root/bin"
# shellcheck disable=SC2016
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$SENSORS_OUTPUT"\n' >"$test_root/bin/sensors"
printf '#!/usr/bin/env bash\nIFS= read -r _ || :\nprintf "1\\n"\n' >"$test_root/bin/bc"
chmod +x "$test_root/bin/sensors" "$test_root/bin/bc"
PATH="$test_root/bin:$PATH"
export SENSORS_OUTPUT

set +u
# shellcheck disable=SC1091
source "$PROJECT_ROOT/synth-shell-greeter/info.sh"
set -u

printInfoLine() {
	INFO_RESULT="$1|$2|${3:-}"
}

printResourceMonitor() {
	MONITOR_RESULT="$1|$2|$3|$4|$5|$6"
}

assertEqual() {
	local expected="$1"
	local actual="$2"

	[[ "$actual" == "$expected" ]] || die "expected '$expected', got '$actual'"
}

SENSORS_OUTPUT=$'temp1:        +32.0°C\nPackage id 0:  +34.0°C  (high = +88.0°C, crit = +98.0°C)'
printInfoCPUTemp
assertEqual 'CPU temp|34.0°C|nominal' "$INFO_RESULT"

SENSORS_OUTPUT='Tdie:          +42.0°C'
printInfoCPUTemp
assertEqual 'CPU temp|42.0°C|nominal' "$INFO_RESULT"

SENSORS_OUTPUT='Tctl:          +43.0°C'
printInfoCPUTemp
assertEqual 'CPU temp|43.0°C|nominal' "$INFO_RESULT"

SENSORS_OUTPUT='Core 0:         +44.0°C'
printInfoCPUTemp
assertEqual 'CPU temp|44.0°C|nominal' "$INFO_RESULT"

SENSORS_OUTPUT=$'temp1:        +32.0°C  (high = +80.0°C, crit = +90.0°C)\nAdapter: NIC'
printInfoCPUTemp
assertEqual 'CPU temp|unavailable|' "$INFO_RESULT"

SENSORS_OUTPUT=$'temp1:        +32.0°C\nPackage id 0:  +34.0°C  (high = +88.0°C, crit = +98.0°C)'
printMonitorCPUTemp
assertEqual 'CPU temp|34.0|98.0|°C|a/b|1' "$MONITOR_RESULT"

SENSORS_OUTPUT='Tdie:          +42.0°C'
printMonitorCPUTemp
assertEqual 'CPU temp|unavailable|' "$INFO_RESULT"

printf 'PASS: CPU temperature sensor selection\n'
