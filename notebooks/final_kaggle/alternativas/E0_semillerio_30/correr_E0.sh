#!/bin/bash
# Corre el baseline (E0) con semillerio de 30 en las 5 semillas primigenias, mismo protocolo que E2 y E4.
# La primera (770503) calcula su propia grilla; las demas la reutilizan.
# Si se corta, se relanza igual: salta las corridas ya terminadas.
cd "$(dirname "$0")"
BASE=/content/buckets/b1/exp/GrupoB/Final
GRILLA="$BASE/F_E0_S770503_semillerio30/tb_grid_parcial.txt"
for S in 770503 216751 126233 877577 388403; do
  ID="F_E0_S${S}_semillerio30"; DEST="$BASE/$ID"
  if [ -f "$DEST/kaggle_puntajes.csv" ]; then echo "$(date -u '+%F %T') $ID ya terminada, salto"; continue; fi
  mkdir -p "$DEST"
  if [ "$S" != "770503" ]; then
    if [ ! -f "$GRILLA" ]; then echo "$(date -u '+%F %T') FALTA la grilla de 770503, salto $ID"; continue; fi
    cp -n "$GRILLA" "$DEST/tb_grid_parcial.txt"
  fi
  echo "$(date -u '+%F %T') inicio $ID"
  jupyter nbconvert --to notebook --execute --ExecutePreprocessor.timeout=-1 \
    "05_Final_Kaggle_GrupoB_semillerio_E0_S${S}.ipynb" --output "salida_E0_S${S}.ipynb" > "salida_E0_S${S}.log" 2>&1
  echo "$(date -u '+%F %T') fin $ID (codigo $?)"
done
echo "$(date -u '+%F %T') TODO TERMINADO"
