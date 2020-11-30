#!/bin/bash
set -e
echo "TYPE= $TYPE"
case $TYPE in
    master)
        tail -f /dev/null
        ;;
    slave)
        $JMETER_HOME/bin/jmeter-server \
            -Dserver.rmi.localport=50000 \
            -Dserver_port=1099 \
            -Jserver.rmi.ssl.disable=true
        ;;
    *)
        echo "Sorry, this option doesn't exist!"
        ;;
esac

exec "$@"