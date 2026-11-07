#!/bin/bash
# Corre una atras de otra las corridas E2 y E4 de las semillas restantes.
# Reutiliza la grilla de la semilla 770503 (mismos hiperparametros, cambia solo la semilla).
# Si se corta, se relanza igual: salta las corridas ya terminadas.
cd "$(dirname "$0")"
BASE=/content/buckets/b1/exp/GrupoB/Final
SEMILLAS="216751 126233 877577 388403"

for S in $SEMILLAS; do
  for CFG in E2 E4; do
    ID="F_${CFG}_S${S}_semillerio30"
    DEST="$BASE/$ID"
    GRILLA="$BASE/F_${CFG}_S770503_semillerio30/tb_grid_parcial.txt"
    if [ -f "$DEST/kaggle_puntajes.csv" ]; then
      echo "$(date -u '+%F %T') $ID ya terminada, salto"; continue
    fi
    if [ ! -f "$GRILLA" ]; then
      echo "$(date -u '+%F %T') FALTA la grilla $GRILLA, salto $ID"; continue
    fi
    mkdir -p "$DEST"
    cp -n "$GRILLA" "$DEST/tb_grid_parcial.txt"
    echo "$(date -u '+%F %T') inicio $ID"
    jupyter nbconvert --to notebook --execute --ExecutePreprocessor.timeout=-1 \
      "05_Final_Kaggle_GrupoB_semillerio_${CFG}_S${S}.ipynb" \
      --output "salida_${CFG}_S${S}.ipynb" > "salida_${CFG}_S${S}.log" 2>&1
    echo "$(date -u '+%F %T') fin $ID (codigo $?)"
  done
done
echo "$(date -u '+%F %T') TODO TERMINADO"
