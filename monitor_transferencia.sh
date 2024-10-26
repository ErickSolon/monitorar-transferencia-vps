#!/bin/bash

# Define o limite de 100 MB (em bytes)
LIMITE=104857600 
UPLOAD_LOG="/var/log/upload.log"
DOWNLOAD_LOG="/var/log/download.log"
TOTAL_LOG="/var/log/total_transferencia.log"
DESLIGAMENTO_LOG="/var/log/desligamento.log"

for LOG_FILE in "$UPLOAD_LOG" "$DOWNLOAD_LOG" "$TOTAL_LOG"; do
    if [ ! -f "$LOG_FILE" ]; then
        touch "$LOG_FILE"
    fi
done

USO_ANTERIOR=0
TOTAL_UPLOAD=0
TOTAL_DOWNLOAD=0

while true; do
    
    USO_ATUAL=$(ifstat -S 1 1 | awk 'NR==3 {print $1 + $2}' | awk '{print int($1 * 1024)}')

    if ! [[ "$USO_ATUAL" =~ ^[0-9]+$ ]]; then
        echo "Erro: Não foi possível obter o uso de dados."
        exit 1
    fi
    
    TRANSFERENCIA_INCREMENTAL=$((USO_ATUAL - USO_ANTERIOR))
   
    if [ "$TRANSFERENCIA_INCREMENTAL" -gt 0 ]; then
        UPLOAD=$(ifstat -S 1 1 | awk 'NR==3 {print $1 * 1024}' | awk '{print int($1)}')
        DOWNLOAD=$(ifstat -S 1 1 | awk 'NR==3 {print $2 * 1024}' | awk '{print int($1)}')

        TOTAL_UPLOAD=$((TOTAL_UPLOAD + UPLOAD))
        TOTAL_DOWNLOAD=$((TOTAL_DOWNLOAD + DOWNLOAD))

        echo "$(date '+%Y-%m-%d %H:%M:%S') - Upload: $UPLOAD bytes" >> "$UPLOAD_LOG"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Download: $DOWNLOAD bytes" >> "$DOWNLOAD_LOG"
    fi

    USO_ANTERIOR=$USO_ATUAL

    TOTAL_TRANSFERIDO=$((TOTAL_UPLOAD + TOTAL_DOWNLOAD))
    if [ "$TOTAL_TRANSFERIDO" -ge "$LIMITE" ]; then
        # Grava a data e hora no log de desligamento
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Limite de transferência atingido. Desligando o sistema..." >> "$DESLIGAMENTO_LOG"
        echo "Desligando o sistema..."
        shutdown now
    fi

    if (( $(date +%s) % 60 == 0 )); then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Total Upload: $TOTAL_UPLOAD bytes, Total Download: $TOTAL_DOWNLOAD bytes" >> "$TOTAL_LOG"
    fi

    sleep 1
done
