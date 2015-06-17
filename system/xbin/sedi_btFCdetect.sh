#!/system/bin/sh
#############################################################################################################################
#
# Author:   Thomas Fischer (xdajog) <mail@se-di.de>
# Desc:		This code is part of sediROM (http://forum.xda-developers.com/showthread.php?t=2789727)
# Version:  v2.5 (the first digit reflects the sediROM major version when this file has been created/changed/modified)
#
# License:  This code is licensed under the Creative Commons License CC BY-SA 4.0.
#
# DISCLAIMER:
# The following deed highlights only some of the key features and terms of the actual license.
# It is NOT a license and has NO legal value. You should carefully review ALL of the terms and conditions of the actual
# license before using the licensed material.
#
# Please check the following link for details and the full legal content:
# http://creativecommons.org/licenses/by-sa/4.0/legalcode
#
#    You are free to:
#
#       Share — copy and redistribute the material in any medium or format
#       Adapt — remix, transform, and build upon the material
#
#       for any purpose, even commercially.
#       The licensor cannot revoke these freedoms as long as you follow the license terms.
#
#    Under the following terms:
#
#       Attribution:
#          You must give appropriate credit, provide a link to the license, and indicate if changes were made.
#          You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
#
#       ShareAlike:
#          If you remix, transform, or build upon the material, you must distribute your contributions under the same
#          license as the original.
#
#############################################################################################################################

echo "$(date +%D_%T) - sediROM($0): starting. Should be executed by cron." >> /dev/kmsg

# path where the config and log will be saved (may be auto adapted later in this script)
SEDIDIR=/preload/.sediROM/

BTIPATH=$(dirname /data/misc/bluetoothd/*/.)
BTINDI="$BTIPATH/btfix.indicator"

# Indicator file will be added by shutdown script and that requires at least 1 clean shutdown.
IFLAG=$SEDIDIR/.initialized

############################################################
# ensure that /data is not encrypted and if so we wait until it will
# be unlocked by the user
ENCSTATE=$(getprop vold.post_fs_data_done)

# ensure that system has booted completely
BOOTSTATE=$(getprop sys.boot_completed)

while [ ! -f "$IFLAG" ] || [ ! "x$ENCSTATE" == "x1" ] || [ ! "x$BOOTSTATE" == "x1" ];do
    echo "$(date +%D_%T) - sediROM($0): /data (still) locked or sediROM is not fully initialized." >> /dev/kmsg
    RETIFLAG=$(test -f "$IFLAG")
    echo "$(date +%D_%T) - sediROM($0): boot state was: $BOOTSTATE (should be empty or 1)." >> /dev/kmsg
    echo "$(date +%D_%T) - sediROM($0): $IFLAG test was: $RETIFLAG (should be empty or 0)." >> /dev/kmsg
    echo "$(date +%D_%T) - sediROM($0): Encryption test was: $ENCSTATE (should be 1)." >> /dev/kmsg
    sleep 10s
    # re-check states
    ENCSTATE=$(getprop vold.post_fs_data_done)
    BOOTSTATE=$(getprop sys.boot_completed)
    
    # ensure sdcard was initialized
    while [ ! -d "/sdcard/.sediROM" ];do sleep 3s ;done
    
    # if we were not able to use preload as log storage we will use sdcard instead    
    SEDISDDIR=/sdcard/.sediROM # if we cannot mount /preload this is a fallback
    INDIMOVED=$SEDISDDIR/dir-moved-2-preload.txt # indicator file to know if we are using preload or not               
    if [ ! -f "$INDIMOVED" ];then                                                                              
        SEDIDIR=$SEDISDDIR
    fi                                                                                                         
    echo "$(date +%D_%T) - sediROM($0): initflag dir set to $SEDIDIR" >> /dev/kmsg
    IFLAG=$SEDIDIR/.initialized
done

# set working dir according to the above result
WRKDIR=$SEDIDIR/bin
LOG=$WRKDIR/${0##*/}.log

# setup work dir
[ ! -d $WRKDIR ] && mkdir -p $WRKDIR

# check if a force close / soft reboot has taken place
# and if so re-enable bluetooth
if [ ! -f "$BTINDI" ];then
    echo "$(date +%D_%T) - sediROM($0): sediROM fully initialized. Exec 92sediROM_btfix again after FC." >> /dev/kmsg
    echo "$(date) sediROM: starting $0" > $LOG
    sh /etc/init.d/92sediROM_btfix >> $LOG
else
    echo "$(date) sediROM: $0 - BT indicator file is here. nothing to do." > $LOG
fi
echo "$(date +%D_%T) - sediROM($0): finished." >> /dev/kmsg
