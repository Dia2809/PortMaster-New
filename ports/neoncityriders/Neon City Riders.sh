#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

export controlfolder

source $controlfolder/control.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

# Variables
GAMEDIR="/$directory/ports/neoncityriders"

# CD and set up logging
cd $GAMEDIR
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

# Exports
export LD_LIBRARY_PATH="$GAMEDIR/lib:$LD_LIBRARY_PATH"
$ESUDO chmod +x "$GAMEDIR/gmloadernext.aarch64"

# Check if the patching needs to be applied
if [ ! -f "$GAMEDIR/patchlog.txt" ] && [ -f "$GAMEDIR/assets/data.win" ]; then
	if [ -f "$controlfolder/utils/patcher.txt" ]; then
		set -o pipefail
			
		# Setup mono environment variables
		DOTNETDIR="$HOME/mono"
		DOTNETFILE="$controlfolder/libs/dotnet-8.0.12.squashfs"
		$ESUDO mkdir -p "$DOTNETDIR"
		$ESUDO umount "$DOTNETFILE" || true
		$ESUDO mount "$DOTNETFILE" "$DOTNETDIR"
		export PATH="$DOTNETDIR":"$PATH"
		
		# Setup and execute the Portmaster Patcher utility with our patch file
		export ESUDO
		export PATCHER_FILE="$GAMEDIR/tools/patchscript"
		export PATCHER_GAME="$(basename "${0%.*}")"
		export PATCHER_TIME="10-15 minutes"
		source "$controlfolder/utils/patcher.txt"
		$ESUDO umount "$DOTNETDIR"
	else
		pm_message "This port requires the latest version of PortMaster."
		pm_finish
		exit 1
	fi
fi

# Assign gptokeyb and load the game
$GPTOKEYB "gmloadernext.aarch64" &
pm_platform_helper "$GAMEDIR/gmloadernext.aarch64" >/dev/null
./gmloadernext.aarch64 -c gmloader.json

# Kill processes
pm_finish
