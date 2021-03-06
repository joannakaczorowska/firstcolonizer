#### All R scripts for the paper Early-life colonization by Beta- and Gammatorquevirus in infants

### LOAD PACKAGES
library("tidyverse")
library("dplyr")
library("reshape2")
library("ggpubr")
library("svglite")
library("survival")
library("scales")
library("epitools")
library("ggsignif")
library("broom")
library("rstatix")
library("grid")

#preparation of the dataset - melting

read.csv("new_det_limit.csv") -> qPCR_new_det

qPCR_new_det <- melt(qPCR_new_det)
write.csv(qPCR_new_det, "qPCR_new_det_melt.csv")

### After the melting process I added the Months column manually in Excel.

### MILK
### SCATTERPLOT - to show whether the AV prevalence changes depending on the moment of breastmilk collection.

read.csv("new_det_limit_m.csv") -> qPCR_new_det_m
qPCR_milk <- subset(qPCR_new_det_m, Number > 114)

qPCR_milk %>% mutate(Sample = fct_reorder(Sample, Number)) %>% ### sorting the samples according to the sample number
  ggplot(aes(x = Sample, y = value)) +
  geom_point(size = 6, aes(shape = variable, fill = variable, colour = variable)) +
  labs(x = "Samples", y = "DNA copies per mL breastmilk") +
  scale_y_log10(breaks= c(1000, 100000, 10000000, 1000000000, 100000000000),
                labels=trans_format('log10', math_format(10^.x)), limits = c(100, 100000000000)) +
  theme(legend.position = "none", legend.title = element_blank(), legend.text = element_text(size = 16), 
        axis.title.x = element_blank(), axis.title.y = element_text(size=20),
        axis.text.x = element_text(size = 15, angle = 90, vjust = 0.5), axis.text.y = element_text(size = 18), 
        panel.background = element_rect(fill="white", colour = "grey50"), 
        panel.grid.major = element_line(colour = "grey50", linetype = "dashed"),
        strip.text.y = element_text(size = 20)) +
  geom_hline(yintercept=1456, linetype='solid', lwd=0.5) +
  scale_colour_manual(values = c("#000000", "#000000", "#FFFFFF"))+
  scale_fill_manual(values=c( "#FFFFFF", "gray70", "#000000")) +
  scale_shape_manual(values=c(21, 21, 21))

ggsave("scatter_milk_new_det.svg", width = 18, height = 8)
ggsave("scatter_milk_new_det.png", width = 18, height = 8)

### PERCENTAGE POSITIVE
# How many positive?
# TTV
qPCR_milk_TTV <- subset(qPCR_milk, variable == "TTV")
table(qPCR_milk_TTV$value)
## 62 negative values, 11 positive values.

# TTMV
qPCR_milk_TTMV <- subset(qPCR_milk, variable == "TTMV")
table(qPCR_milk_TTMV$value)
## 61 negative values, 12 positive values.

# TTMV + TTMDV
qPCR_milk_TTMDV <- subset(qPCR_milk, variable == "TTMV_TTMDV")
table(qPCR_milk_TTMDV$value)
## 47 negative values, 26 positive values.

positive_samples <- c(11, 12, 26)
total_samples <- c(73, 73, 73)
qPCR <- c("TTV", "TTMV", "TTMV_TTMDV")
prop_pos <- positive_samples / total_samples
perc_pos <- prop_pos * 100

pos_milk <- data.frame(qPCR, positive_samples, total_samples, prop_pos, perc_pos)
pos_milk$perc_pos

### mcnemar of these values - milk
qPCR_new_det_m$pos <- factor(
  qPCR_new_det_m$pos, levels = c(1, 0),
  labels = c("positive", "negative")
)
qPCR_milk <- subset(qPCR_new_det_m, Number > 114)

xtabs(~pos + variable, qPCR_milk)
stat_all_milk <- pairwise_mcnemar_test(qPCR_milk, pos ~ variable|Sample)
write.csv(stat_all_milk, "stat_mcnemar_milk.csv")

### Are there significant differences in anello prevalence between early and late milk?
# early milk - let's set it up 0-6 months. late milk 6 - max (around 13 months)
# first I have to make sure to remove all NA's

qPCR_milk_noNA <- subset(qPCR_milk, Number < 176)

# then, subset of young milk
qPCR_milk_early <- subset(qPCR_milk_noNA, Number < 169)

# late milk
qPCR_milk_late <- subset(qPCR_milk_noNA, Number > 169)
#there are only 6 samples. Maybe it's better to compare the 0-2 months and 2 - 13 months?

# 0 - 2 months
qPCR_milk_02 <- subset(qPCR_milk_noNA, Number < 150)
xtabs(~pos + variable, qPCR_milk_02)
stat_milk_02 <- pairwise_mcnemar_test(qPCR_milk_02, pos ~ variable|Sample)
write.csv(stat_milk_02, "stat_milk_02.csv")

#variable
#pos TTMV TTMV_TTMDV TTV
#0   31         26  31
#1    4          9   4

# more than 2 months
qPCR_milk_213 <- subset(qPCR_milk_noNA, Number > 150)
xtabs(~pos + variable, qPCR_milk_213)
stat_milk_213 <- pairwise_mcnemar_test(qPCR_milk_213, pos ~ variable|Sample)
write.csv(stat_milk_213, "stat_milk_213.csv")

#variable
#pos TTMV TTMV_TTMDV TTV
#0   19         15  23
#1    6         10   2

#"middle" breastmilk (2 - 6 months)

qPCR_milk_26 <- subset(qPCR_milk_213, Number < 169)
xtabs(~pos + variable, qPCR_milk_26)
stat_milk_26 <- pairwise_mcnemar_test(qPCR_milk_26, pos ~ variable|Sample)
write.csv(stat_milk_26, "stat_milk_26.csv")

# Chisquare to compare the number of samples positive for AV in early and late breastmilk samples
read.csv("chisq.csv") -> milk_chi
print(chisq.test(milk_chi))

### KIDS
### SCATTERPLOT
qPCR_kids <- subset(qPCR_new_det_m, Number < 115)
qPCR_kids_012 <- subset(qPCR_kids, Months < 12)

qPCR_kids_012 %>% mutate(Sample = fct_reorder(Sample, Months)) %>% 
  ggplot(aes(x = Sample, y = value)) +
  geom_point(size = 6, aes(shape = variable, fill = variable, colour = variable)) +
  labs(x = "Samples", y = "DNA copies per mL serum") +
  scale_y_log10(breaks= c(1000, 100000, 10000000, 1000000000, 100000000000),
                labels=trans_format('log10', math_format(10^.x)), limits = c(100, 100000000000)) +
  theme(legend.position = "none", legend.title = element_blank(), legend.text = element_text(size = 16), 
        axis.title.x = element_blank(), axis.title.y = element_text(size=20),
        axis.text.x = element_text(size = 15, angle = 90, vjust = 0.5), axis.text.y = element_text(size = 18), 
        panel.background = element_rect(fill="white", colour = "grey50"), 
        panel.grid.major = element_line(colour = "grey50", linetype = "dashed"),
        strip.text.y = element_text(size = 20)) +
  geom_hline(yintercept=1456, linetype='solid', lwd=0.5) +
  scale_colour_manual(values = c("#000000", "#000000", "#FFFFFF"))+
  scale_fill_manual(values=c( "#FFFFFF", "gray70", "#000000")) +
  scale_shape_manual(values=c(21, 21, 21))

ggsave("scatter_012_new_det.svg", width = 18, height = 8)
ggsave("scatter_012_new_det.png", width = 18, height = 8)

qPCR_kids_old12 <- subset(qPCR_kids, Months > 12)

qPCR_kids_old12 %>% mutate(Sample = fct_reorder(Sample, Months)) %>% 
  ggplot(aes(x = Sample, y = value)) +
  geom_point(size = 6, aes(shape = variable, fill = variable, colour = variable)) +
  labs(x = "Samples", y = "DNA copies per mL serum") +
  scale_y_log10(breaks= c(1000, 100000, 10000000, 1000000000, 100000000000),
                labels=trans_format('log10', math_format(10^.x)), limits = c(100, 100000000000)) +
  theme(legend.position = "none", legend.title = element_blank(), legend.text = element_text(size = 16), 
        axis.title.x = element_blank(), axis.title.y = element_text(size=20),
        axis.text.x = element_text(size = 15, angle = 90, vjust = 0.5), axis.text.y = element_text(size = 18), 
        panel.background = element_rect(fill="white", colour = "grey50"), 
        panel.grid.major = element_line(colour = "grey50", linetype = "dashed"),
        strip.text.y = element_text(size = 20)) +
  geom_hline(yintercept=1456, linetype='solid', lwd=0.5) +
  scale_colour_manual(values = c("#000000", "#000000", "#FFFFFF"))+
  scale_fill_manual(values=c( "#FFFFFF", "gray70", "#000000")) +
  scale_shape_manual(values=c(21, 21, 21))

ggsave("scatter_old12_new_det.svg", width = 18, height = 8)
ggsave("scatter_old12_new_det.png", width = 18, height = 8)

## mcnemar test
# all kids

xtabs(~pos + variable, qPCR_kids)
stat_all_kids <- pairwise_mcnemar_test(qPCR_kids, pos ~ variable|Sample)
write.csv(stat_all_kids, "stat_mcnemar_all_kids.csv")

# kids 0-12 months

xtabs(~pos + variable, qPCR_kids_012)
stat_012_kids <- pairwise_mcnemar_test(qPCR_kids_012, pos ~ variable|Sample)
write.csv(stat_012_kids, "stat_mcnemar_012_kids.csv")

# kids 12-64 months

xtabs(~pos + variable, qPCR_kids_old12)
stat_old12_kids <- pairwise_mcnemar_test(qPCR_kids_old12, pos ~ variable|Sample)
write.csv(stat_old12_kids, "stat_mcnemar_old12_kids.csv")

#kids 0 - 6 months
qPCR_kids_06 <- subset(qPCR_kids, Months < 6)
xtabs(~pos + variable, qPCR_kids_06)
stat_06_kids <- pairwise_mcnemar_test(qPCR_kids_06, pos ~ variable|Sample)
write.csv(stat_06_kids, "stat_mcnemar_06_kids.csv")

#### Supplementary figures
## Kids - concentration in time

qPCR_kids$Months <- cut(qPCR_kids$Months, breaks = c(0.36, 2, 6, 12, 18, 24, 30, 65), right = FALSE)
View(qPCR_kids)


### Select just positive samples
qPCR_kids_noneg <- subset(qPCR_kids, pos == "positive")
View(qPCR_kids_noneg)

qPCR_kids_noneg <- qPCR_kids_noneg %>% mutate(variable = fct_relevel(variable, 
                                                                 "TTV",
                                                                 "TTMV", 
                                                                 "TTMV_TTMDV"))

qPCR_kids_noneg <- qPCR_kids_noneg %>% mutate(Months = fct_relevel(Months, 
                                                                   "[0.36,2)",
                                                                   "[2,6)", 
                                                                   "[6,12)", 
                                                                   "[12,18)", 
                                                                   "[18,24)", 
                                                                   "[24,30)",
                                                                   "[30,65)"))

ggplot(qPCR_kids_noneg, mapping = aes(fill = variable, x = Months, y = value)) +
  geom_boxplot(outlier.shape = NA) +
  scale_fill_brewer(palette="Set2") +
  labs(x = "Age (months)", y = "DNA copies per mL serum") +
  scale_y_log10(breaks=trans_breaks('log10', function(x) 10^x),
                labels=trans_format('log10', math_format(10^.x)), limits = c(0.1, 100000000000)) +
  theme(legend.title = element_blank(), legend.text = element_text(size = 16), 
        axis.title.y = element_text(size=20), axis.title.x = element_text(size =20), 
        axis.text.x = element_text(size=16), axis.text.y = element_text(size = 18), 
        panel.background = element_rect(fill="white", colour = "grey50"), 
        panel.grid.major = element_line(colour = "grey50", linetype = "dashed"))

ggsave("kids_conc_in_time_new_det.svg")
ggsave("kids_conc_in_time_new_det.png")

# STATISTICS FOR THIS ONE

kids_months_noneg <- qPCR_kids_noneg %>%
  wilcox_test(value ~ Months) %>%
  adjust_pvalue(method = "bonferroni") %>%
  add_significance("p.adj")
kids_months_noneg
View(kids_months_noneg)
write.csv(kids_months_noneg, "kids_months_stat_noneg.csv")

kids_genera_noneg <- qPCR_kids_noneg %>%
  group_by(Months) %>% 
  wilcox_test(value ~ variable) %>%
  adjust_pvalue(method = "bonferroni") %>%
  add_significance("p.adj")
kids_genera_noneg
View(kids_genera_noneg)
write.csv(kids_genera_noneg, "kids_genera_stat_noneg.csv")

xtabs(~pos + variable, qPCR_kids)

kids_02 <- subset(qPCR_kids, Months == "[0.36,2)")
xtabs(~pos + variable, kids_02)

kids_26 <- subset(qPCR_kids, Months == "[2,6)")
xtabs(~pos + variable, kids_26)

kids_612 <- subset(qPCR_kids, Months == "[6,12)")
xtabs(~pos + variable, kids_612)

kids_1218 <- subset(qPCR_kids, Months == "[12,18)")
xtabs(~pos + variable, kids_1218)

kids_1824 <- subset(qPCR_kids, Months == "[18,24)")
xtabs(~pos + variable, kids_1824)

kids_2430 <- subset(qPCR_kids, Months == "[24,30)")
xtabs(~pos + variable, kids_2430)

kids_3065 <- subset(qPCR_kids, Months == "[30,65)")
xtabs(~pos + variable, kids_3065)

Months <- c("[0.36,2)",
            "[2,6)", 
            "[6,12)", 
            "[12,18)", 
            "[18,24)", 
            "[24,30)",
            "[30,65)")

TTV_pos <- c(0, 4, 7, 13, 13, 10, 11)
TTMV_pos <- c(3, 6, 11, 13, 8, 7, 8)
TTMDV_pos <- c(4, 9, 13, 15, 14, 12, 16)
total <- c(15, 20, 16, 15, 17, 13, 18)
prop_TTV <- TTV_pos / total
prop_TTMV <- TTMV_pos / total
prop_TTMDV <- TTMDV_pos / total
proc_TTV <- prop_TTV * 100
proc_TTMV <- prop_TTMV * 100
proc_TTMDV <- prop_TTMDV * 100

proc_kids <- data.frame(Months, proc_TTV, proc_TTMV, proc_TTMDV)
proc_kids <- melt(proc_kids)

proc_kids <- proc_kids %>% mutate(Months = fct_relevel(Months, 
                                                               "[0.36,2)",
                                                               "[2,6)", 
                                                               "[6,12)", 
                                                               "[12,18)", 
                                                               "[18,24)", 
                                                               "[24,30)",
                                                               "[30,65)"))

ggplot(proc_kids, aes(x = Months, y = value, fill = variable)) +
  geom_col(position = "dodge") +
  scale_fill_brewer(palette="Set2") +
  labs(x = "Age (months)", y = "% positive samples") +
  scale_y_continuous(limits = c(0, 100)) +
  theme(legend.position = "none", axis.title.x = element_text(size = 20), axis.title.y = element_text(size=20), 
        axis.text.x = element_text(size=16), axis.text.y = element_text(size = 18), panel.background = element_rect(fill="white", colour = "grey50"), 
        panel.grid.major = element_line(colour = "grey50", linetype = "dashed"))

ggsave("prop_pos_kids_new_det.svg")
ggsave("prop_pos_kids_new_det.png")

### Comparison HIV positive samples and HIV negative samples
read.csv("new_det_limit_HIV.csv") -> kids_vs_milk
kids_vs_milk_noneg <- subset(kids_vs_milk, pos == 1)

kids_vs_milk_noneg <- kids_vs_milk_noneg %>% mutate(variable = fct_relevel(variable, 
                                                                       "TTV",
                                                                       "TTMV", 
                                                                       "TTMV_TTMDV",
                                                                       "TTV HIV-1 pos",
                                                                       "TTMV HIV-1 pos",
                                                                       "TTMV_TTMDV HIV-1 pos",
                                                                       "TTV BM", 
                                                                       "TTMV BM",
                                                                       "TTMV_TTMDV BM",
                                                                       "TTV BM HIV-1 pos", 
                                                                       "TTMV BM HIV-1 pos",
                                                                       "TTMV_TTMDV BM HIV-1 pos"))

ggplot(data = kids_vs_milk_noneg, aes(x = variable, y = value, fill = variable)) +
  geom_boxplot() +
  geom_jitter(shape=16, position=position_jitter(0.1)) +
  labs(x = "", y = "DNA copies per mL sample") +
  scale_y_log10(breaks= c(1, 100, 10000, 1000000, 100000000, 10000000000),
                labels=trans_format('log10', math_format(10^.x)), limits = c(1, 100000000000)) +
  theme(legend.position = "none",
        axis.title.y = element_text(size=20), axis.text.x = element_blank(), 
        axis.text.y = element_text(size = 18), panel.background = element_rect(fill="white", colour = "grey50"), 
        panel.grid.major = element_line(colour = "grey50", linetype = "dashed")) +
  scale_fill_manual(values = c("#67C4A6", "#F68D64", "#8CA0CC", "#67C4A6", "#F68D64", "#8CA0CC",
                               "#67C4A6", "#F68D64", "#8CA0CC", "#67C4A6", "#F68D64", "#8CA0CC",
                               "#67C4A6", "#F68D64", "#8CA0CC", "#67C4A6", "#F68D64", "#8CA0CC"))

ggsave("compare_HIV_new_det.svg")
ggsave("compare_HIV_new_det.png")

milk_kids_stat_noneg <- kids_vs_milk_noneg %>%
  wilcox_test(value ~ variable) %>%
  adjust_pvalue(method = "bonferroni") %>%
  add_significance("p.adj")
milk_kids_stat_noneg
View(milk_kids_stat_noneg)
write.csv(milk_kids_stat_noneg, "compare_HIV.csv")
