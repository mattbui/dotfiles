#!/bin/sh

if [ "$#" -eq 0 ]; then
	printf '%s\n' 'usage: quick-look.sh FILE...' >&2
	exit 1
fi

qlmanage -p "$@" >/dev/null 2>&1 &
preview_pid=$!

osascript - "$preview_pid" <<'APPLESCRIPT' >/dev/null
on run argv
	set previewPid to (item 1 of argv) as integer
	delay 0.1

	repeat 10 times
		tell application "System Events"
			set matchingProcesses to every process whose unix id is previewPid
			if (count of matchingProcesses) > 0 then
				set previewProcess to item 1 of matchingProcesses
				set frontmost of previewProcess to true
				if (count of windows of previewProcess) > 0 then
					perform action "AXRaise" of window 1 of previewProcess
				end if
				return
			end if
		end tell

		delay 0.05
	end repeat
end run
APPLESCRIPT
