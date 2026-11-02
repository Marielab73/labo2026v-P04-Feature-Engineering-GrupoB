# =====================================================================
# Analisis estadistico - Problema 4 FE historico - Grupo B
#
# Entrada : resultados/consolidado_resultados.csv
#           (columnas: id, cfg, semilla, gan, envios, minutos)
# Salidas : resultados/resumen_estadistico.csv
#           evidencias/grafico_comparativo.png
#           evidencias/grafico_ganancia_vs_tiempo.png
#           evidencias/grafico_test_wilcoxon.png
#
# Replica lo que hace la celda 4 de la maestra:
# Wilcoxon pareado por semilla contra E0 y ajuste de Holm.
# =====================================================================

args <- commandArgs(trailingOnly = TRUE)
f_consolidado <- if (length(args) >= 1) args[1] else "resultados/consolidado_resultados.csv"
dir_resultados <- if (length(args) >= 2) args[2] else "resultados"
dir_evidencias <- if (length(args) >= 3) args[3] else "evidencias"

BASELINE <- "E0"
# Familia de comparaciones contra el baseline sobre la que se aplica Holm
# (las del diseno aprobado). Otras configuraciones, como E5, se reportan
# con su p crudo, sin entrar en la familia.
FAMILIA_HOLM <- c("E1", "E2", "E3", "E4")
MIN_PARES <- 6     # con menos pares no se calcula el test
ALFA <- 0.05

dir.create(dir_resultados, showWarnings = FALSE, recursive = TRUE)
dir.create(dir_evidencias, showWarnings = FALSE, recursive = TRUE)

tb <- read.csv(f_consolidado, stringsAsFactors = FALSE)
stopifnot(all(c("cfg", "semilla", "gan") %in% names(tb)))
if (!("minutos" %in% names(tb))) tb$minutos <- NA_real_

# configuraciones en orden natural (E0, E1, ...)
cfgs <- sort(unique(tb$cfg))
stopifnot(BASELINE %in% cfgs)

base <- tb[tb$cfg == BASELINE, ]

# ---- resumen por configuracion y test contra el baseline ------------
filas <- lapply(cfgs, function(cf) {
  x <- tb[tb$cfg == cf, ]
  r <- data.frame(
    cfg = cf,
    n = nrow(x),
    gan_media = mean(x$gan),
    gan_sd = if (nrow(x) > 1) sd(x$gan) else NA_real_,
    gan_mediana = median(x$gan),
    min_medio = mean(x$minutos),
    dif_media_vs_E0 = NA_real_,
    pct_vs_E0 = NA_real_,
    semillas_que_superan_E0 = NA_integer_,
    n_pares = NA_integer_,
    p_crudo = NA_real_,
    stringsAsFactors = FALSE
  )
  if (cf != BASELINE) {
    m <- merge(x[, c("semilla", "gan")], base[, c("semilla", "gan")],
               by = "semilla", suffixes = c("", "_E0"))
    r$n_pares <- nrow(m)
    r$dif_media_vs_E0 <- mean(x$gan) - mean(base$gan)
    r$pct_vs_E0 <- 100 * r$dif_media_vs_E0 / mean(base$gan)
    r$semillas_que_superan_E0 <- sum(m$gan > m$gan_E0)
    if (nrow(m) >= MIN_PARES) {
      r$p_crudo <- suppressWarnings(
        wilcox.test(m$gan, m$gan_E0, paired = TRUE, exact = TRUE)$p.value
      )
    }
  }
  r
})
res <- do.call(rbind, filas)

# ---- ajuste de Holm sobre las comparaciones con p calculado ---------
res$p_holm <- NA_real_
ok <- !is.na(res$p_crudo) & res$cfg %in% FAMILIA_HOLM
res$p_holm[ok] <- p.adjust(res$p_crudo[ok], method = "holm")
res$significativo_5pct <- ifelse(is.na(res$p_holm), NA, res$p_holm < ALFA)
res$comparaciones_en_holm <- sum(ok)
res$en_familia_holm <- res$cfg %in% FAMILIA_HOLM

write.csv(res, file.path(dir_resultados, "resumen_estadistico.csv"),
          row.names = FALSE)
print(res, digits = 4)

# ---- comparaciones directas entre configuraciones (exploratorias) ----
# Responden si combinar (E4) rinde mas que cada familia por separado, y si
# unas familias rinden mas que otras. No son parte del diseno original:
# Holm se aplica solo dentro de este grupo.
cand <- intersect(c("E1", "E2", "E3", "E4"), cfgs)
pares <- if (length(cand) >= 2) t(combn(cand, 2)) else NULL
if (!is.null(pares)) {
  dir <- lapply(seq_len(nrow(pares)), function(i) {
    a <- tb[tb$cfg == pares[i, 2], ]; b <- tb[tb$cfg == pares[i, 1], ]
    m <- merge(a[, c("semilla", "gan")], b[, c("semilla", "gan")],
               by = "semilla", suffixes = c("_a", "_b"))
    data.frame(comparacion = paste(pares[i, 2], "vs", pares[i, 1]),
               n_pares = nrow(m),
               dif_media = mean(m$gan_a - m$gan_b),
               semillas_a_favor = sum(m$gan_a > m$gan_b),
               p_crudo = if (nrow(m) >= MIN_PARES) suppressWarnings(
                 wilcox.test(m$gan_a, m$gan_b, paired = TRUE, exact = TRUE)$p.value)
               else NA_real_)
  })
  dir <- do.call(rbind, dir)
  dir$p_holm_exploratorio <- NA_real_
  okd <- !is.na(dir$p_crudo)
  dir$p_holm_exploratorio[okd] <- p.adjust(dir$p_crudo[okd], method = "holm")
  write.csv(dir, file.path(dir_resultados, "comparaciones_directas.csv"),
            row.names = FALSE)
  cat("\nComparaciones directas (exploratorias):\n")
  print(dir, digits = 4)
}

# ---- grafico comparativo --------------------------------------------
colores <- c(E0 = "#1B2540", E1 = "#F2682A", E2 = "#17695F",
             E3 = "#5B4B9A", E4 = "#B3541E", E5 = "#6B7390")
col_cfg <- function(cf) ifelse(cf %in% names(colores), colores[cf], "#444444")

png(file.path(dir_evidencias, "grafico_comparativo.png"),
    width = 1600, height = 900, res = 150)
par(mar = c(5, 5, 4, 2))
rango <- range(tb$gan)
plot(NA, xlim = c(0.5, length(cfgs) + 0.5),
     ylim = c(rango[1] - 1, rango[2] + 2.5),
     xaxt = "n", xlab = "Configuracion", ylab = "Ganancia (media de la meseta)",
     main = "Ganancia por semilla en cada configuracion (futuro 202107)")
axis(1, at = seq_along(cfgs), labels = cfgs)
grid(nx = NA, ny = NULL)
set.seed(1)
for (i in seq_along(cfgs)) {
  x <- tb[tb$cfg == cfgs[i], ]
  points(i + runif(nrow(x), -0.12, 0.12), x$gan, pch = 19,
         col = adjustcolor(col_cfg(cfgs[i]), 0.55), cex = 1.6)
  segments(i - 0.3, mean(x$gan), i + 0.3, mean(x$gan), lwd = 4, col = "#1B2540")
  text(i, mean(x$gan), sprintf("%.1f", mean(x$gan)), pos = 3, offset = 0.8,
       font = 2, cex = 0.9)
  ph <- res$p_holm[res$cfg == cfgs[i]]
  etiqueta <- if (cfgs[i] == BASELINE) "baseline" else
    if (is.na(ph)) sprintf("n=%d", nrow(x)) else sprintf("p Holm=%.3f", ph)
  mtext(etiqueta, side = 3, at = i, line = 0, cex = 0.8, col = "#4A5370")
}
legend("topleft", bty = "n", cex = 0.85,
       legend = c("cada punto = una semilla", "linea oscura = media",
                  "p: Wilcoxon pareado vs E0 con ajuste de Holm"))
dev.off()

# ---- grafico ganancia vs costo computacional ------------------------
# Cada configuracion es un punto: tiempo medio por corrida (eje x) y
# ganancia media (eje y), con +/- 1 desvio entre semillas. Las
# configuraciones con pocas corridas (n < MIN_PARES) se dibujan huecas.
res$completa <- res$n >= MIN_PARES
png(file.path(dir_evidencias, "grafico_ganancia_vs_tiempo.png"),
    width = 1600, height = 900, res = 150)
par(mar = c(5, 5, 4, 2))
xr <- range(res$min_medio, na.rm = TRUE)
yr <- range(c(res$gan_media - ifelse(is.na(res$gan_sd), 0, res$gan_sd),
              res$gan_media + ifelse(is.na(res$gan_sd), 0, res$gan_sd)))
plot(NA, xlim = c(xr[1] - 8, xr[2] + 0.4 * diff(xr)), ylim = c(yr[1] - 1, yr[2] + 1),
     xlab = "Tiempo medio por corrida (minutos)",
     ylab = "Ganancia media (media de la meseta)",
     main = "Ganancia contra costo computacional")
grid()
b <- res[res$cfg == BASELINE, ]
abline(h = b$gan_media, lty = 2, col = "#6B7390")
abline(v = b$min_medio, lty = 2, col = "#6B7390")
for (i in seq_len(nrow(res))) {
  r <- res[i, ]
  col <- col_cfg(r$cfg)
  if (!is.na(r$gan_sd))
    segments(r$min_medio, r$gan_media - r$gan_sd,
             r$min_medio, r$gan_media + r$gan_sd, lwd = 3, col = col)
  points(r$min_medio, r$gan_media, pch = if (r$completa) 19 else 1,
         cex = 2.6, col = col, lwd = 3)
  etq <- if (r$cfg == BASELINE) r$cfg else
    sprintf("%s (%+.1f pts, %+.0f min)", r$cfg,
            r$dif_media_vs_E0, r$min_medio - b$min_medio)
  if (!r$completa) etq <- paste0(etq, " [n=", r$n, "]")
  text(r$min_medio, r$gan_media, etq, pos = 4, offset = 1.1,
       font = 2, cex = 0.85, col = col)
}
legend("bottomright", bty = "n", cex = 0.85,
       legend = c("punto = media de las semillas, barra = +/- 1 desvio",
                  "punto hueco = pocas corridas, provisorio",
                  "lineas punteadas = baseline E0"))
dev.off()

# ---- grafico del test: p de Holm de cada configuracion vs el baseline ----
# Barra a la izquierda de la linea de alfa = diferencia significativa.
# Holm para la familia de comparaciones del diseno; el resto, p crudo.
res$p_plot <- ifelse(is.na(res$p_holm), res$p_crudo, res$p_holm)
pt <- res[!is.na(res$p_plot), ]
if (nrow(pt) > 0) {
  pt <- pt[order(pt$cfg, decreasing = TRUE), ]   # E1 arriba
  png(file.path(dir_evidencias, "grafico_test_wilcoxon.png"),
      width = 1600, height = 700, res = 150)
  par(mar = c(5, 6, 4, 2))
  colb <- ifelse(pt$p_plot < ALFA, col_cfg(pt$cfg), "#B0B5C3")
  bp <- barplot(pt$p_plot, horiz = TRUE, names.arg = pt$cfg, las = 1,
                xlim = c(0, 1), col = colb, border = NA,
                xlab = "p-valor de Wilcoxon con ajuste de Holm",
                main = sprintf("Wilcoxon pareado contra %s, alfa = %.2f",
                               BASELINE, ALFA))
  abline(v = ALFA, lty = 2, lwd = 2)
  dentro <- pt$p_plot > 0.5
  etq_p <- paste0(sprintf("%.3f", pt$p_plot), ifelse(is.na(pt$p_holm), " (crudo)", ""))
  text(ifelse(dentro, pt$p_plot - 0.01, pmax(pt$p_plot, ALFA) + 0.01), bp,
       etq_p, pos = ifelse(dentro, 2, 4),
       font = 2, cex = 0.9)
  legend("topright", bty = "n", cex = 0.85,
         legend = c("color: significativa (p de Holm < alfa)",
                    "gris: no significativa",
                    "linea punteada: alfa"))
  dev.off()
}

cat("\nListo: resumen_estadistico.csv y los tres graficos generados.\n")
