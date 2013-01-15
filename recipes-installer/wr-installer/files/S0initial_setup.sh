#!/bin/sh
if [ -f /initial_setup.sh ]
then
        clear 2>/dev/null
        echo "Running /initial_setup.sh"
        echo "Type ^C to abort"
        sh /initial_setup.sh
fi
