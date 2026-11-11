# main.R


# Main code for modelling claims related to temperatures and wildfire smoke.


# Project : paper_medication_wildfire_temperature
# Author  : Jeremie Boudreault
# Depends : R [v4.5.1], rjutils [v0.1]
# Imports : See below.
# License : © The authors.



# Librairies -------------------------------------------------------------------


library(data.table)
library(ggplot2)
library(rjutils)
library(mgcv)      
library(splines)   
library(splineplot)  


# Imports ----------------------------------------------------------------------


x <- fread("data/sample.csv")


# Data preparation -------------------------------------------------------------


# Count number of years.
nyears <- length(unique(x$YEAR))

# Convert FSA to factor.
x[, FSA := as.factor(FSA)]

# Convert DOW to factor.
x[, DOW := as.factor(FSA)]

# Convert WFS to factor.
x[, WFS_02 := as.factor(WFS_02)]

# Build formula.
form <- as.formula(paste0(
    "COUNT ~ ", 
    "offset(log(MEMBERS)) + ",
    "s(FSA, bs = 're') + ",
    "s(PM25_02, by = WFS_02) + ",
    "s(T_MEAN_02) +", 
    "DOW + HOL +",
    "s(TIME, k = ", 8 * nyears, ")"
))


# Model fitting ----------------------------------------------------------------


# Fit model.
model <- mgcv::bam(
    formula = form,
    family  = quasipoisson(),
    data    = x
)


# Plot resulting splines -------------------------------------------------------


# Extract splines at median values of PM25 and TMEAN.
coef <- rbindlist(lapply(c("PM25", "T_MEAN"), function(var) {
    
    # Extract interaction splines.
    spl <- as.data.table(splineplot:::extract_spline_interaction(
        fit        = model, 
        data       = x, 
        by_var     = paste0("WFS_02"),
        xvar       = paste0(var, "_02"), 
        model_info = list(type = "gam", family = "quasipoisson", ylabel = "RR"), 
        refx       = median(x[[paste0(var, "_02")]]), 
        log_scale  = TRUE
    ))
    
    # Redo for temperature.
    if (var == "T_MEAN") {
        
        # Extract MMT for WFS 0 and 1.
        mmt_0 <- spl[group == 0 & x > -17.6 & x <= 24.1, ][y == min(y), x]  # Q2 and Q98 of mean temperature
        mmt_1 <- spl[group == 1 & x > -17.6 & x <= 24.1, ][y == min(y), x]  # Q2 and Q98 of mean temperature 
        
        # Extract the whole spline with mmt_0.
        spl_0 <- as.data.table(splineplot:::extract_spline_interaction(
            fit        = model, 
            data       = x, 
            by_var     = paste0("WFS_02"),
            xvar       = paste0(var, "_02"), 
            model_info = list(type = "gam", family = "quasipoisson", ylabel = "RR"), 
            refx       = mmt_0, 
            log_scale  = TRUE
        ))[group == 0, ]
        
        # Extract the whole spline with mmt_1.
        spl_1 <- as.data.table(splineplot:::extract_spline_interaction(
            fit        = model, 
            data       = x, 
            by_var     = paste0("WFS_02"),
            xvar       = paste0(var, "_02"), 
            model_info = list(type = "gam", family = "quasipoisson", ylabel = "RR"), 
            refx       = mmt_1, 
            log_scale  = TRUE
        ))[group == 1, ]
        
        # Combine both results.
        spl <- rbind(spl_0, spl_1)
        
    }

    # Updated columns.
    spl$VAR <- var
    spl[, ylabel := NULL]
    spl[, `:=`(y = exp(y), lcl = exp(lcl), ucl = exp(ucl))]
    names(spl) <- c("X", "RR", "RR_LOW", "RR_HIGH", "WFS", "VAR")
    spl

}))

# Map variable prior to plot.
coef[VAR == "PM25", VAR_F := "a) PM₂.₅"]
coef[VAR == "T_MEAN", VAR_F := "b) Mean temperature"]

# Pal.
pal <- c("blue", "red")

# Plot.
ggplot(coef, aes(x = X, y = RR)) + 
geom_line(aes(col = WFS)) +
geom_hline(yintercept = 1, lwd = 0.4) + 
geom_ribbon(aes(ymin = RR_LOW, ymax = RR_HIGH, fill = WFS), alpha =0.15, show.legend = FALSE) + 
facet_wrap("VAR_F", scales = "free") + 
scale_color_manual(values = pal) + 
scale_fill_manual(values = pal) + 
labs(y = "Rate ratio (RR)", color = "Wildfire smoke:", x = "        PM₂.₅ (µg/m³)                                                        Mean temperature (°C)") + 
jtheme() + 
theme(strip.text = element_text(hjust = 0, size = 11)) + 
guides(color = guide_legend(override.aes = list(fill = "black")), 
       fill = guide_legend(override.aes = list(color = pal)))

