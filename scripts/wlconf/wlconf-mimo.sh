wlconf_path=/usr/sbin/wlconf
wlconf_scripts_path=/home/root/scripts/wlconf
wl18xx_conf_bin=/lib/firmware/ti-connectivity/wl18xx-conf.bin

rmmod wl18xx
./testing_set_wlcore.sh mimo rdl2_rdl4
cd ${wlconf_path}
./wlconf -i ${wl18xx_conf_bin} -o ${wl18xx_conf_bin} --set core.conn.sta_sleep_auth=0
cd ${wlconf_scripts_path}
./wlconf-modify-default-params.sh
modprobe wl18xx
