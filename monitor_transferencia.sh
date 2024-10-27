#!/bin/bash

# Configurações
LIMIT=15
FILE='/var/log/limite_transferencia.log'

if [ ! -e "$FILE" ]; then
    touch "$FILE"
fi

echo "" > "$FILE"
rm -f /var/lib/vnstat/vnstat.db
/etc/init.d/vnstat stop
/etc/init.d/vnstat start

while true; do
    OUTPUT=$(vnstat --alert 1 1 d total $LIMIT MB -i eth0 | grep 'Alert limit exceeded!' | sed 's/ //g')
    DATA_HORA=$(date +'%d/%m/%Y %H:%M:%S')
    /etc/init.d/vnstat stop
    /etc/init.d/vnstat start

    if echo "$OUTPUT" | grep -q "Alertlimitexceeded!"; then
        echo "$DATA_HORA - Limite de $LIMIT MB atingido. Desligando a máquina..." >> "$FILE"
        sudo shutdown now
        break
    fi

    sleep 5
done
