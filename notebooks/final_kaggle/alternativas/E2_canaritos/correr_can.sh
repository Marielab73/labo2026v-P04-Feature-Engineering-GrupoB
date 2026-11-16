#!/bin/bash
# E2 con seleccion de variables por canaritos, semillerio de 30, 5 semillas primigenias.
# Espera a que la cuota diaria de Kaggle se reinicie (00:00 UTC = 21:00 Argentina) antes de empezar.
# La grilla (solo aporta las iteraciones) se reutiliza la de E2 semilla 770503, igual que en las otras pruebas.
# Si se corta, se relanza igual: salta las corridas ya terminadas.
cd "$(dirname "$0")"
FECHA_MIN="${1:-2026-11-15}"   # primer dia UTC en que se puede empezar
while [[ "$(date -u +%F)" < "$FECHA_MIN" ]]; do sleep 60; done
BASE=/content/buckets/b1/exp/GrupoB/Final
GRILLA="$BASE/F_E2_S770503_semillerio30/tb_grid_parcial.txt"
if [ ! -f "$GRILLA" ]; then echo "FALTA la grilla $GRILLA"; exit 1; fi
for S in 770503 216751 126233 877577 388403; do
  ID="F_E2_S${S}_semillerio30_can"; DEST="$BASE/$ID"
  if [ -f "$DEST/kaggle_puntajes.csv" ]; then echo "$(date -u '+%F %T') $ID ya terminada, salto"; continue; fi
  mkdir -p "$DEST"; cp -n "$GRILLA" "$DEST/tb_grid_parcial.txt"
  echo "$(date -u '+%F %T') inicio $ID"
  jupyter nbconvert --to notebook --execute --ExecutePreprocessor.timeout=-1 \
    "05_Final_Kaggle_GrupoB_semillerio_E2_can_S${S}.ipynb" --output "salida_E2_can_S${S}.ipynb" > "salida_E2_can_S${S}.log" 2>&1
  echo "$(date -u '+%F %T') fin $ID"
done
echo "$(date -u '+%F %T') TODO TERMINADO"
