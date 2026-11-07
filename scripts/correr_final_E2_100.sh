#!/bin/bash
# Candidato final: E2, semilla primigenia 770503, semillerio de 100 modelos.
# Reutiliza la grilla y los 30 modelos del semillerio-30 (las primeras 30 semillas son las mismas).
cd "$(dirname "$0")"
BASE=/content/buckets/b1/exp/GrupoB/Final
ORIG="$BASE/F_E2_S770503_semillerio30"
DEST="$BASE/F_E2_S770503_semillerio100"
mkdir -p "$DEST/modelos"
cp -n "$ORIG/tb_grid_parcial.txt" "$DEST/tb_grid_parcial.txt"
cp -n "$ORIG"/modelos/modelo_*.txt "$DEST/modelos/"
echo "$(date -u '+%F %T') inicio F_E2_S770503_semillerio100 (modelos reutilizados: $(ls $DEST/modelos | wc -l))"
jupyter nbconvert --to notebook --execute --ExecutePreprocessor.timeout=-1 \
  05_Final_Kaggle_GrupoB_E2_S770503_semillerio100.ipynb \
  --output salida_E2_S770503_semillerio100.ipynb > salida_E2_S770503_semillerio100.log 2>&1
echo "$(date -u '+%F %T') fin (codigo $?)"
