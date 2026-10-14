#!/bin/bash

# This script explains why the COBOTTA robot has no Chrony service to restart, as 'RESTART-CHRONY-SERVICE.bash' calls it when 'cobotta' is the active platform.
# It runs with every 'OPENROSDE_*' variable exported by 'scripts/load-openrosde-env.bash'.
#
# Usage: bash ./scripts/cobotta/restart-chrony-service.bash

################################################################################

# Explain why the COBOTTA has no clock to resync.
echo "COBOTTA Chrony restart is not applicable. The COBOTTA connects over USB and has no integrated PC."
