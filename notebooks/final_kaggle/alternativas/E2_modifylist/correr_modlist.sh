#!/bin/bash
# E2 con modifyList (los mejores hiperparametros de la grilla se usan en el modelo final).
# La grilla no cambia: se reutiliza la de E2 semilla 770503. Los modelos si se entrenan de nuevo (otros parametros).
# Si se corta, se relanza igual: salta las corridas ya terminadas.
cd "$(dirname "$0")"
BASE=/content/buckets/b1/exp/GrupoB/Final
GRILLA="$BASE/F_E2_S770503_semillerio30/tb_grid_parcial.txt"
if [ ! -f "$GRILLA" ]; then echo "FALTA la grilla $GRILLA"; exit 1; fi
for S in 770503 216751 126233 877577 388403; do
  ID="F_E2_S${S}_semillerio30_modlist"; DEST="$BASE/$ID"
  if [ -f "$DEST/kaggle_puntajes.csv" ]; then echo "$(date -u '+%F %T') $ID ya terminada, salto"; continue; fi
  mkdir -p "$DEST"; cp -n "$GRILLA" "$DEST/tb_grid_parcial.txt"
  echo "$(date -u '+%F %T') inicio $ID"
  jupyter nbconvert --to notebook --execute --ExecutePreprocessor.timeout=-1 \
    "05_Final_Kaggle_GrupoB_semillerio_E2_modlist_S${S}.ipynb" --output "salida_E2_modlist_S${S}.ipynb" > "salida_E2_modlist_S${S}.log" 2>&1
  echo "$(date -u '+%F %T') fin $ID (codigo $?)"
done
echo "$(date -u '+%F %T') TODO TERMINADO"
