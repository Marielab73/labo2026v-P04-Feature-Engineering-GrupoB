# Problema 4: Feature Engineering Histórico Épico (Grupo B)

Experimentos Colaborativos · Laboratorio de Implementación 1 · Universidad Austral · 2026

Modalidad Junior · futuro = 202107 · ganancia calculada en la notebook (sin Kaggle) · Grupo B

## Qué se hizo

Se mide cuánto aporta a la ganancia agregar historia de cada cliente al dataset de la modalidad Junior. Se comparan configuraciones de Feature Engineering histórico contra el baseline del workflow de la cátedra (que ya incluye lag1, lag2 y sus deltas), manteniendo constante todo lo demás.

| Config | Qué agrega sobre el baseline | Columnas (con clase) |
|---|---|---|
| E0 | Nada: baseline de la cátedra (lag1, lag2, delta1, delta2) | 273 |
| E1 | lag3 y lag4 | 381 |
| E2 | variación a 3 meses, cantidad de caídas y pendiente sobre 4 meses | 426 |
| E3 | media móvil de 3 y 6 meses y desvío móvil de 3 meses | 426 |
| E4 | E1 + E2 + E3 | 687 |
| E5 (referencia, aparte) | Sin historia: se quitan también lag1, lag2 y sus deltas | ~57 (estimado) |

E2, E3 y E4 se aplican a 51 variables numéricas (todas las lagueables menos `cliente_edad`, `cliente_antiguedad` y `kmes`). Las variables nuevas usan solo el mes actual y meses anteriores del mismo cliente.

## Diseño experimental

- Cada configuración se corre con las mismas 10 semillas: 770503, 216751, 126233, 877577, 388403, 308563, 344785, 618973, 245039, 552707.
- Cada semilla ejecuta el workflow completo, grilla de hiperparámetros incluida.
- La ganancia de cada corrida es el máximo de la media móvil centrada (ancho 400) de la ganancia acumulada en el futuro 202107 ("media de la meseta"). Ganancia: +0,975 por BAJA+2 y −0,025 por el resto.
- Resultado por configuración: un vector de 10 ganancias.
- Comparación de cada configuración contra E0 con Wilcoxon pareado por semilla (exacto, al 5%) y ajuste de Holm sobre la familia E1 a E4 (4 comparaciones).
- Se registran tiempos de ejecución, hiperparámetros y salidas de cada corrida.
- Entrenamiento 201901–202103, validación 202105, entrenamiento final 201901–202105, futuro 202107.
- Máquina: 8 vCPU y 64 GB de RAM.

## Contenido del repositorio

```
P04/
├── README.md
├── notebooks/
│   ├── 02_WorkFlow_GrupoB.ipynb                 workflow de la cátedra con el FE de E0 a E4
│   ├── 03_Maestra_Experimentos.ipynb            corre E0 a E4, consolida y analiza
│   ├── 02_WorkFlow_GrupoB_SinFE.ipynb           workflow de E5 (sin historia)
│   ├── 03_Maestra_Experimentos_SinFE.ipynb   maestra de E5
│   ├── 04_Analisis_Estadistico.R                análisis independiente (Wilcoxon, Holm y gráficos)
│   ├── 05_Final_Kaggle_GrupoB.ipynb             validación final de la configuración ganadora
│   └── final_kaggle/                            modelo final de la competencia (semillerio)
│       ├── 05_Final_Kaggle_semillerio_E2.ipynb      semillerio de 30 modelos, configuración E2
│       ├── 05_Final_Kaggle_semillerio_E4.ipynb      ídem, configuración E4
│       └── 05_Final_Kaggle_E2_S770503_semillerio100.ipynb   semillerio de 100 modelos (envío final)
├── scripts/
│   ├── correr_semillas.sh                       corre E2 y E4 con las 4 semillas primigenias restantes
│   └── correr_final_E2_100.sh                   corre el semillerio de 100 reutilizando modelos y grilla
├── resultados/
│   ├── consolidado_resultados.csv               una fila por corrida (config, semilla, ganancia, envíos, minutos)
│   ├── consolidado_E5_referencia.csv            corridas de E5 (referencia, fuera del experimento aprobado)
│   ├── tiempos_corridas.csv                     registro de tiempos y estado de cada corrida
│   ├── resumen_estadistico.csv                  medias, desvíos, p crudo y p de Holm por configuración
│   ├── comparaciones_directas.csv               comparaciones entre configuraciones (exploratorias)
│   ├── kaggle_puntajes_E2.csv                   70 puntajes públicos de Kaggle (10 semillas × 7 cortes)
│   ├── kaggle_semillerio30_E2_E4.csv            puntajes públicos del semillerio de 30 (E2 y E4, 5 semillas primigenias)
│   └── kaggle_semillerio100_E2_S770503.csv      puntajes públicos del semillerio de 100 (envío final)
├── evidencias/
│   ├── grafico_comparativo.png                  ganancia por semilla de todas las corridas
│   ├── grafico_ganancia_vs_tiempo.png           ganancia media contra costo computacional
│   ├── grafico_test_wilcoxon.png                p de Holm de cada configuración contra E0
│   ├── parametros/                              PARAM.yml de cada corrida (E0_S770503_PARAM.yml, ...)
│   └── grillas/                                 tb_grid_search_01.txt de cada corrida

```

No se incluyen el dataset de la competencia, los modelos guardados (`modelo.txt`), las predicciones (`prediccion.txt`) ni los notebooks ejecutados, por tamaño.

## Cómo replicarlo

Requisitos: R con kernel de Jupyter (`ir`), `jupyter nbconvert`, y los paquetes `data.table`, `R.utils`, `mice`, `lightgbm` y `yaml`. El dataset `analistajr_competencia_2026.csv.gz` debe estar en `/content/datasets/`.

1. Ubicar `02_WorkFlow_GrupoB.ipynb` y `03_Maestra_Experimentos.ipynb` en la carpeta `ExpColaborativos/P04_FEhistorico_GrupoB` de los buckets.
2. Abrir la maestra con kernel R. En la celda 1 definir:
   - `CONFIGS`: las configuraciones a correr, por ejemplo `c("E3")`.
   - `N_SEMILLAS`: cuántas semillas usar (1 a 10, tomadas en el orden de la lista anterior).
   - `BASE`: carpeta de resultados (`/content/buckets/b1/exp/GrupoB`).
3. Ejecutar las celdas en orden:
   - Celda 2: ubica el workflow y crea una copia congelada (`..._CONGELADO.ipynb`), para que la edición del original no afecte corridas en curso. No editar ni regenerar la copia mientras corre el loop.
   - Celda 3: loop de corridas. Para cada semilla y configuración guarda los parámetros en un `.rds` dentro de `params/`, lanza el workflow con `jupyter nbconvert --execute` y pasa la ruta del `.rds` en la variable de entorno `GRUPOB_PARAMETROS`. Una corrida ya terminada (existe su `PARAM.yml`) se saltea, por lo que el loop se puede reanudar. Si hay dos fallos seguidos, se detiene.
   - Celda 4: consolida los `PARAM.yml` y los tiempos en `consolidado_resultados.csv`, resume por configuración y calcula Wilcoxon pareado contra E0 con ajuste de Holm.
4. Análisis fuera de la maestra: desde la raíz del repositorio, `Rscript notebooks/04_Analisis_Estadistico.R`. Lee `resultados/consolidado_resultados.csv` y genera `resultados/resumen_estadistico.csv`, `resultados/comparaciones_directas.csv` y los tres gráficos de `evidencias/`. La familia de Holm es E1 a E4; E5, si está en el consolidado, se reporta aparte con su p crudo.
5. Cada corrida de E0 tarda unos 52 minutos, E1 unos 80, E2 unos 83, E3 unos 86 y E4 unos 135 (corrida completa del notebook, incluido el arranque y el Feature Engineering).
6. E5: se corre con `02_WorkFlow_GrupoB_SinFE.ipynb` y `03_Maestra_Experimentos_SinFE_v3.ipynb` (mismo procedimiento, `CONFIGS <- c("E5")`). Los resultados se guardan en una carpeta separada de E0 a E4 y no se mezclan con el consolidado aprobado; el script los lee desde `consolidado_E5_referencia.csv`.

## Qué se modificó del workflow de la cátedra

Se tomó el workflow genérico de la cátedra (`z621_WorkFlow_01_junior_grupoB.ipynb`) sin tocar el código de modelado. Cambian cuatro celdas de 100:

1. Parámetros: lee la configuración y la semilla desde `GRUPOB_PARAMETROS`.
2. Carpeta del experimento: escribe en `GrupoB/<config>/<config>_S<semilla>`.
3. Feature Engineering histórico: agrega las variables de E1 a E4 según la configuración.
4. Verificación: resume las variables creadas. No altera los datos.

Los cambios 1 y 2 solo permiten automatizar las corridas, y el 3 es el objeto del experimento. En el workflow de E5 el bloque de lags del baseline se omite cuando la configuración es E5.

## Aclaraciones sobre el workflow de la cátedra

- **Hiperparámetros:** el modelo final se entrena con los parámetros fijos del workflow (`num_leaves` 64, `min_data_in_leaf` 128, `feature_fraction` 0,5). La grilla se ejecuta y se registra, pero de ella solo se usa el número de iteraciones: `param_final <- c(fijos, mejores_hiperparametros)` conserva los valores fijos cuando un parámetro figura en ambos grupos. Se verificó en los modelos guardados de tres corridas. Es igual en todas las configuraciones.
- **Curva de ganancia:** el PDF que genera el workflow fija el eje vertical en 0 a 15.000.000, por lo que con las ganancias de esta modalidad la curva queda aplanada. Por eso no se incluye. La ganancia de cada corrida está en `PARAM.yml` (`resultado.ganancia_suavizada_max`).
- **Variables del modelo:** el modelo incluye `numero_de_cliente` y `foto_mes` entre sus variables, igual que el workflow original, en todas las configuraciones.

## Resultados

Diez semillas por configuración (50 corridas). Ganancia en las unidades del workflow. Detalle en `resultados/`.

| Config | Ganancia media | Desvío | Minutos por corrida | Dif. vs E0 | Semillas que superan a E0 | p crudo | p Holm |
|---|---|---|---|---|---|---|---|
| E0 | 92,21 | 2,30 | 51,8 | baseline | | | |
| E1 | 94,71 | 2,42 | 79,6 | +2,50 | 9 de 10 | 0,0039 | 0,0117 |
| E2 | 96,39 | 2,15 | 83,0 | +4,18 | 8 de 10 | 0,0098 | 0,0195 |
| E3 | 92,32 | 2,17 | 85,7 | +0,11 | 4 de 10 | 1,000 | 1,000 |
| E4 | 95,62 | 1,66 | 135,2 | +3,42 | 10 de 10 | 0,0020 | 0,0078 |

- E1, E2 y E4 superan a E0 con significancia al 5% después del ajuste de Holm (familia de 4 comparaciones). E3 no aporta.
- E2 tiene la media más alta, pero su diferencia con E1 no es significativa (p = 0,105, exploratorio). E4 no supera a E2 (−0,76 puntos; p = 0,32, exploratorio).
- E4 es la más consistente (menor desvío, mejora a E0 en las 10 semillas) pero cuesta un 161% más de tiempo que E0.
- Las comparaciones entre configuraciones distintas de E0 son exploratorias y están en `comparaciones_directas.csv`.

### Referencia sin historia (E5)

E5 quita también lag1, lag2 y sus deltas, para medir cuánto aporta la historia que ya trae el baseline. Se corrió por separado, en otra carpeta, para no mezclarlo con el experimento aprobado (E0 a E4); sus datos están en `resultados/consolidado_E5_referencia.csv` y no entran en el consolidado principal ni en la familia de Holm.

| Config | Ganancia media | Desvío | Minutos por corrida | Dif. vs E0 | Semillas que superan a E0 | p crudo vs E0 |
|---|---|---|---|---|---|---|
| E5 | 90,54 | 1,22 | 16,7 | −1,67 | 2 de 10 | 0,105 |

Sin historia la ganancia media es 1,67 puntos menor que la del baseline, pero la diferencia no llega a ser significativa con 10 semillas (p crudo = 0,105, sin ajuste). Es consistente con que la historia ayuda, aunque este experimento no lo demuestra por sí solo. Corre en un tercio del tiempo de E0.

Contra E5, exploratorio y con p crudo: E1, E2 y E4 le ganan en las 10 semillas (+4,17, +5,85 y +5,08 puntos; p = 0,002 cada una), E3 en 7 de 10 (+1,78; p = 0,049) y E0 en 8 de 10 (+1,67; p = 0,105). Lo que más separa a las configuraciones de E5 es el Feature Engineering que agregan E1, E2 y E4.


## Modelo final para la competencia de Kaggle

Esta parte es independiente del experimento (E0 a E4), que quedó cerrado y es lo que se presenta. Sirve para armar el envío final a la competencia (Labo 1 Virtual 2026, analista Jr). Se parte de la notebook Junior con el Feature Engineering de E2 y se usa un **semillerio**: K modelos LightGBM con distintas semillas cuyas probabilidades se promedian. Esto sube la media y baja la variabilidad del puntaje. El número de envíos (corte) es la cantidad de clientes con mayor probabilidad que se marcan como 1.

### Criterio de selección

Siguiendo el documento de la cátedra sobre cómo elegir el mejor modelo, el puntaje se trata como una variable aleatoria: cada semillerio construido con una semilla primigenia distinta es una observación. El valor de cada observación es el máximo del puntaje público entre sus cortes, sin promediar envíos. Para comparar configuraciones se usa Wilcoxon exacto pareado por semilla primigenia. No se usa el ranking público como criterio de elección.

### E2 contra E4 con 5 semillas primigenias (semillerio de 30)

Semillas primigenias: 770503, 216751, 126233, 877577, 388403. Cortes de 1.200 a 2.000 cada 100 (E4 de la semilla 770503 se corrió además cada 50; para comparar se usan los mismos cortes).

| Semilla primigenia | E2 (mejor corte) | E4 (mejor corte) |
|---|---|---|
| 770503 | 92,13 | 86,15 |
| 216751 | 91,96 | 87,48 |
| 126233 | 92,46 | 88,97 |
| 877577 | 92,05 | 87,06 |
| 388403 | 94,29 | 86,15 |

E2 supera a E4 en las 5 primigenias. Wilcoxon exacto pareado: p = 0,031 a una cola y 0,0625 a dos colas, que es el mínimo posible con n = 5 y no llega a p < 0,05 a dos colas. Se eligió E2 (más simple y más barata: un modelo tarda unos 23 s contra 58 s en E4).

Media por corte entre las 5 primigenias (puntaje público):

| Corte | 1200 | 1300 | 1400 | 1500 | 1600 | 1700 | 1800 | 1900 | 2000 |
|---|---|---|---|---|---|---|---|---|---|
| E2 | 82,87 | 88,56 | 91,11 | **92,21** | 89,95 | 86,96 | 84,09 | 81,54 | 79,14 |
| E4 | 84,30 | 84,47 | 82,79 | 84,88 | 86,16 | 85,60 | 84,60 | 83,09 | 81,71 |

E2 tiene una meseta estable alrededor de 1.500 envíos (desvío entre primigenias de 0,24 en ese corte) y cae de forma regular hacia los extremos. E4 es plana y más ruidosa. Los cortes de 1.500 a 1.600 son la zona de interés.

### Semillerio de 100 modelos (envío final)

Configuración E2, semilla primigenia 770503, 100 modelos (los 30 del semillerio anterior se reutilizan), cortes de 1.400 a 1.600 cada 25.

| Corte | 1400 | 1425 | 1450 | 1475 | 1500 | 1525 | 1550 | 1575 | 1600 |
|---|---|---|---|---|---|---|---|---|---|
| Puntaje público | 88,058 | 90,799 | **93,458** | 93,042 | 92,211 | 91,713 | 90,716 | 90,135 | 89,636 |

**Corte elegido: 1.475 envíos.** No se elige el máximo (1.450) porque queda justo en el borde donde la curva sube con más pendiente: un corrimiento chico del corte óptimo en el privado cuesta mucho. El corte 1.475 queda pegado al pico y apoyado en la zona estable de 1.475 a 1.525, y es consistente con la meseta de 1.500 de las otras primigenias. La diferencia entre 1.475 y 1.500 (0,8 puntos) está dentro del ruido del puntaje público, que es una parte del test. El envío es `KA9301_1475.csv` (mensaje `envios=1475 semilla=770503 semillerio=100 cfg=E2`).


### Hiperparámetros del modelo final

Igual que en el experimento, el modelo final usa los valores fijos del workflow (`num_leaves` 64, `min_data_in_leaf` 128, `feature_fraction` 0,5, `max_bin` 31, tasa de aprendizaje 0,03) y de la grilla de 50 combinaciones solo toma el número de iteraciones (95 en E2). Probar los hiperparámetros ganadores de la grilla, o una optimización bayesiana, queda como trabajo futuro: no se evaluó para no sobreajustar al puntaje público.

### Cómo replicarlo

1. `notebooks/final_kaggle/05_Final_Kaggle_semillerio_E2.ipynb` (semilla 770503, 30 modelos). La grilla es reanudable y escribe `tb_grid_parcial.txt`.
2. `scripts/correr_semillas.sh` corre E2 y E4 con las otras cuatro primigenias (ver los notebooks de cada semilla; cambia solo `PARAM$semilla_primigenia`).
3. `scripts/correr_final_E2_100.sh` copia la grilla y los modelos del semillerio de 30 a la carpeta nueva y ejecuta `05_Final_Kaggle_E2_S770503_semillerio100.ipynb`, que entrena los 70 modelos restantes y envía los 9 cortes a Kaggle.
4. Los modelos se guardan en `modelos/modelo_<semilla>.txt` y se omiten si ya existen.

## Limitaciones

- Un solo futuro (202107) y una sola validación (202105).
- Las semillas solo cambian el azar del modelo, no los datos.
- Con 10 pares, el p exacto mínimo de Wilcoxon es cercano a 0,002.
- Hiperparámetros fijos del workflow, elegidos por AUC y no por ganancia.
- Las transformaciones se aplican a todas las variables, por lo que no se separa el aporte de cada una ni se controla si la mejora viene de la información o de sumar columnas.
- Dataset Junior con pocas variables originales.
- Modelo final de Kaggle: el puntaje público es una parte del test y el corte se eligió mirándolo; el puntaje privado puede diferir. La comparación E2 contra E4 usa solo 5 primigenias (p mínimo posible).

El detalle está en el documento del trabajo y en la presentación.
