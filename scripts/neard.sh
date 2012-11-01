#! /bin/sh

neard=/usr/bin/neard

test -x "$neard" || exit 0

case "$1" in
  start)
    echo -n "Starting neard nfc stack"
    modprobe nfcwilink
    start-stop-daemon --start --quiet --exec $neard &
    /usr/share/nfc-test-scripts/enable-adapter nfc0
    echo "."
    ;;
  stop)
    echo -n "Stopping neard nfc stack"
    start-stop-daemon --stop --quiet --pidfile /var/run/neard.pid
    echo "."
    ;;
  *)
    echo "Usage: /etc/init.d/neard.sh {start|stop}"
    exit 1
esac

exit 0

