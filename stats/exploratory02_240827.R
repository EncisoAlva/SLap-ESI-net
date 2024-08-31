library("ggpubr")
library("readxl")
library("tidyverse")
library("plyr")
library("latex2exp")
library("patchwork")

# dataset to analyze
tagname = 'EvalMetrics_evaluation01'

# current directory
script_dir = getwd()

# data path
#setwd('..')
#data_path = paste0( getwd(), '/stats - Copy/' )
data_path = getwd()
setwd( script_dir )

################################################################################

# ALL PROFILES COMBINED
table = read_excel( paste(data_path, tagname, "_ALL.xlsx", sep = "") )
title_text = "All profiles"

# SQUARE PROFILE
table = read_excel( paste(data_path,"/", tagname, "_square.xlsx", sep = "") )
title_text = "Square profile"

# GAUSS PROFILE
table = read_excel( paste(data_path, tagname, "_gauss.xlsx", sep = "") )
title_text = "Gaussian profile"

# EXPONENTIAL PROFILE
table = read_excel( paste(data_path, tagname, "_exp.xlsx", sep = "") )
title_text = "Exponential profile"

# POLYNOMIAL PROFILE
table = read_excel( paste(data_path, tagname, "_circ.xlsx", sep = "") )
title_text = "Polynomial profile"

################################################################################
# FORMATTING

# format (hard-coded for now)
table$SNR = factor(table$SNR, 
                   levels = c( "Inf", "30", "20", "10") 
)
table$HalfMax = table$HalfMax/100

table$Solver = factor(table$Solver, 
                   levels = c( "Tikhonov", "sLORETA",
                     "SLapESInet_EEG", "SLapESInet_SLap", "SLapESInet_WMNE",
                     "SLapESInet_EEG_SLap", "SLapESInet_EEG_WMNE", "SLapESInet_SLap_WMNE") 
)
table$Solver = revalue(table$Solver, 
                      c( "Tikhonov"= "wMNE",
                         "SLapESInet_EEG"="EEG", 
                         "SLapESInet_SLap"="SLap", 
                         "SLapESInet_WMNE"="wMNE*",
                         "SLapESInet_EEG_SLap"="EEG+SLap", 
                         "SLapESInet_EEG_WMNE"="EEG+wMNE", 
                         "SLapESInet_SLap_WMNE"="SLap+wMNE") 
)

table$idx = factor(table$idx)

################################################################################

table %>%
  #drop_na() %>%
  filter( SNR=="30" ) %>%
  ggviolin(x = "Solver",
           y = "DLE1",
           add = "mean_sd") +
  ylab("Distance Localization Eror [mm]") +
  #ggtitle("Noiseless case, SNR = Inf dB") +
  grids() +
  theme_bw()

################################################################################

setwd(paste0( script_dir, "/img/" ))

G1 = table %>%
  #drop_na() %>%
  filter( SNR=="30" ) %>% 
  filter( Solver != "Proposed" ) %>%
  ggboxplot(x = "Solver",
           y = "DLE1") +
  ylab("Distance Localization Eror [mm]") +
  grids() +
  theme_bw()+
  theme(axis.text.x = element_text(angle = 45, hjust=1))

G2 = table %>%
  #drop_na() %>%
  filter( SNR=="30" ) %>%
  filter( Solver != "Proposed" ) %>%
  ggboxplot(x = "Solver",
            y = "SpaDis2") +
  ylab("Spatial Dispersion [mm]") +
  grids() +
  theme_bw()+
  theme(axis.text.x = element_text(angle = 45, hjust=1))

G3 = table %>%
  #drop_na() %>%
  filter( SNR=="30" ) %>%
  filter( Solver != "Proposed" ) %>%
  filter( AUROC_loc_classic>0 ) %>%
  ggboxplot(x = "Solver",
            y = "AUROC_loc_classic") +
  ylab("AUROC (local)") +
  grids() +
  theme_bw()+
  theme(axis.text.x = element_text(angle = 45, hjust=1))

G4 = table %>%
  #drop_na() %>%
  filter( SNR=="30" ) %>%
  filter( Solver != "Proposed" ) %>%
  filter( AP_loc_classic>0 ) %>%
  ggboxplot(x = "Solver",
            y = "AP_loc_classic") +
  ylab("Average Precision (local)") +
  grids() +
  theme_bw()+
  theme(axis.text.x = element_text(angle = 45, hjust=1))

ggarrange( G1, G2, G3, G4,
           ncol = 2, nrow = 2, align = "v", common.legend = TRUE, legend="top") 
ggsave( paste0("plot_",tagname, "ALL", ".pdf"),
        width = 9, height = 6, units = "in")

################################################################################

G1 = table %>%
  #drop_na() %>%
  filter( SNR=="30" ) %>%
  filter( Solver != "Proposed" ) %>%
  filter( Solver == "SISSY" ) %>%
  ggscatter(x = "Depth",
            y = "DLE1", 
            color = "Profile",
            shape = "Profile") +
  ylab("Distance Localisation Error [mm]") +
  xlab("Depth [mm]") +
  grids() +
  theme_bw()

G2 = table %>%
  #drop_na() %>%
  filter( SNR=="30" ) %>%
  filter( Solver != "Proposed" ) %>%
  filter( Solver == "SISSY" ) %>%
  ggscatter(x = "Depth",
            y = "SpaDis2", 
            color = "Profile",
            shape = "Profile") +
  ylab("Spatial Dispersion [mm]") +
  xlab("Depth [mm]") +
  grids() +
  theme_bw()

G3 = table %>%
  #drop_na() %>%
  filter( SNR=="30" ) %>%
  filter( Solver != "Proposed" ) %>%
  filter( Solver == "SISSY" ) %>%
  filter( AUROC_loc>0 ) %>%
  ggscatter(x = "Depth",
            y = "AUROC_loc", 
            color = "Profile",
            shape = "Profile") +
  ylab("AUROC") +
  xlab("Depth [mm]") +
  grids() +
  theme_bw()

G4 = table %>%
  #drop_na() %>%
  filter( SNR=="30" ) %>%
  filter( Solver != "Proposed" ) %>%
  filter( Solver == "SISSY" ) %>%
  filter( AP_loc>0 ) %>%
  ggscatter(x = "Depth",
            y = "AP_loc", 
            color = "Profile",
            shape = "Profile") +
  ylab("Average Precision") +
  xlab("Depth [mm]") +
  grids() +
  theme_bw()

ggarrange( G1, G2, G3, G4,
           ncol = 2, nrow = 2, align = "v", common.legend = TRUE, legend="top")
ggsave( paste0("SISSY_scatter_",tagname, ".pdf"),
        width = 9, height = 6, units = "in")

################################################################################

G1 = table %>%
  #drop_na() %>%
  filter( SNR=="30" ) %>%
  filter( Solver != "Proposed" ) %>%
  filter( Solver == "sLORETA" ) %>%
  ggscatter(x = "Depth",
            y = "DLE1", 
            color = "Profile",
            shape = "Profile") +
  ylab("Distance Localisation Error [mm]") +
  xlab("Depth [mm]") +
  grids() +
  theme_bw()

G2 = table %>%
  #drop_na() %>%
  filter( SNR=="30" ) %>%
  filter( Solver != "Proposed" ) %>%
  filter( Solver == "sLORETA" ) %>%
  ggscatter(x = "Depth",
            y = "SpaDis2", 
            color = "Profile",
            shape = "Profile") +
  ylab("Spatial Dispersion [mm]") +
  xlab("Depth [mm]") +
  grids() +
  theme_bw()

G3 = table %>%
  #drop_na() %>%
  filter( SNR=="30" ) %>%
  filter( Solver != "Proposed" ) %>%
  filter( Solver == "sLORETA" ) %>%
  filter( AUROC_loc>0 ) %>%
  ggscatter(x = "Depth",
            y = "AUROC_loc", 
            color = "Profile",
            shape = "Profile") +
  ylab("AUROC") +
  xlab("Depth [mm]") +
  grids() +
  theme_bw()

G4 = table %>%
  #drop_na() %>%
  filter( SNR=="30" ) %>%
  filter( Solver != "Proposed" ) %>%
  filter( Solver == "sLORETA" ) %>%
  filter( AP_loc>0 ) %>%
  ggscatter(x = "Depth",
            y = "AP_loc", 
            color = "Profile",
            shape = "Profile") +
  ylab("Average Precision") +
  xlab("Depth [mm]") +
  grids() +
  theme_bw()

ggarrange( G1, G2, G3, G4,
           ncol = 2, nrow = 2, align = "v", common.legend = TRUE, legend="top")
ggsave( paste0("sLORETA_scatter_",tagname, ".pdf"),
        width = 9, height = 6, units = "in")


################################################################################
  table %>%
  #drop_na() %>%
  filter( SNR=="30" ) %>%
  filter( Solver != "Proposed" ) %>%
  #filter( Solver == "SISSY" ) %>%
  ggscatter(x = "DLE1",
            y = "SpaDis2", 
            color = "Profile",
            shape = "Profile") +
  xlab("Distance Localisation Error [mm]") +
  ylab("Spatial Dispersion [mm]") +
  #ggtitle("Noiseless case, SNR = Inf dB") +
  #labs(subtitle = ("SNR = 30 [dB]" ) ) +
  #labs(subtitle = expression( paste("SNR =", infinity, "[dB]") ) ) +
  grids() +
  theme_bw()

table %>%
  #drop_na() %>%
  filter( SNR=="30" ) %>%
  filter( Solver != "Proposed" ) %>%
  filter( Solver == "sLORETA" ) %>%
  ggscatter(x = "DLE1",
            y = "SpaDis2", 
            color = "Profile",
            shape = "Profile") +
  xlab("Distance Localisation Error [mm]") +
  ylab("Spatial Dispersion [mm]") +
  #ggtitle("Noiseless case, SNR = Inf dB") +
  #labs(subtitle = ("SNR = 30 [dB]" ) ) +
  #labs(subtitle = expression( paste("SNR =", infinity, "[dB]") ) ) +
  grids() +
  theme_bw()


table %>%
  #drop_na() %>%
  filter( SNR=="30" ) %>%
  filter( Solver != "Proposed" ) %>%
  filter( Solver == "SISSY" ) %>%
  filter( AP_loc>0 ) %>%
  ggscatter(x = "DLE1",
            y = "AP_loc", 
            color = "Profile",
            shape = "Profile") +
  xlab("Distance Localisation Error [mm]") +
  ylab("Spatial Dispersion [mm]") +
  #ggtitle("Noiseless case, SNR = Inf dB") +
  #labs(subtitle = ("SNR = 30 [dB]" ) ) +
  #labs(subtitle = expression( paste("SNR =", infinity, "[dB]") ) ) +
  grids() +
  theme_bw()

table %>%
  #drop_na() %>%
  filter( SNR=="30" ) %>%
  filter( Solver != "Proposed" ) %>%
  filter( AP_loc>0 ) %>%
  filter( Solver == "sLORETA" ) %>%
  ggscatter(x = "DLE1",
            y = "AP_loc", 
            color = "Profile",
            shape = "Profile") +
  xlab("Distance Localisation Error [mm]") +
  ylab("Spatial Dispersion [mm]") +
  #ggtitle("Noiseless case, SNR = Inf dB") +
  #labs(subtitle = ("SNR = 30 [dB]" ) ) +
  #labs(subtitle = expression( paste("SNR =", infinity, "[dB]") ) ) +
  grids() +
  theme_bw()


################################################################################

table %>%
  na.omit() %>%
  filter( Solver != "Proposed" ) %>%
  filter( Solver != "sLORETA" ) %>%
  ggline(., x="SNR", y="DLE1", 
         group=interaction("Profile", "idx"), 
         color = "Solver",
         shape = "Solver",
         add="mean", error.plot = "pointrange")+
  xlab("SNR [dB]") +
  ylab("Distance Localisation Error (mean) [mm]") +
  grids() +
  theme_bw()+
  theme(axis.text.x = element_text(angle = 45, hjust=1))


G1 = table %>%
  filter( Solver != "Proposed" ) %>%
  ggline(., x="SNR", y="DLE1", 
         group=interaction("Profile", "idx"), 
         color = "Solver",
         shape = "Solver",
         add="mean", error.plot = "pointrange")+
  xlab("SNR [dB]") +
  ylab("Distance Localisation Error (mean) [mm]") +
  grids() +
  theme_bw()+
  theme(axis.text.x = element_text(angle = 45, hjust=1))

G2 = table %>%
  filter( Solver != "Proposed" ) %>%
  ggline(., x="SNR", y="SpaDis2", 
         group=interaction("Profile", "idx"), 
         color = "Solver",
         shape = "Solver",
         add="mean", error.plot = "pointrange")+
  xlab("SNR [dB]") +
  ylab("Spatial Dispersion [mm]") +
  grids() +
  theme_bw()+
  theme(axis.text.x = element_text(angle = 45, hjust=1))

G3 = table %>%
  filter( Solver != "Proposed" ) %>%
  filter( AUROC_loc_classic>0 ) %>%
  ggline(., x="SNR", y="AUROC_loc_classic", 
         group=interaction("Profile", "idx"), 
         color = "Solver",
         shape = "Solver",
         add="mean", error.plot = "pointrange")+
  xlab("SNR [dB]") +
  ylab("AUROC") +
  grids() +
  theme_bw()

G4 = table %>%
  filter( Solver != "Proposed" ) %>%
  filter( AP_loc_classic>0 ) %>%
  ggline(., x="SNR", y="AP_loc_classic", 
         group=interaction("Profile", "idx"), 
         color = "Solver",
         shape = "Solver",
         add="mean", error.plot = "pointrange")+
  xlab("SNR [dB]") +
  ylab("Average Precision") +
  grids() +
  theme_bw()+
  theme(axis.text.x = element_text(angle = 45, hjust=1))

ggarrange( G1, G2, G3, G4,
           ncol = 2, nrow = 2, align = "v", common.legend = TRUE, legend="top")
ggsave( paste0("SNRdegradation_",tagname, ".pdf"),
        width = 9, height = 6, units = "in")

################################################################################

currMethod = "EEG"
currMethod = "wMNE*"

G1 = table %>%
  na.omit() %>%
  filter( Solver == currMethod ) %>%
  filter( SNR == "30" ) %>%
  ggscatter(., x="Depth", y="DLE1" 
         #group=interaction("Profile", "idx"), 
         #color = "Solver",
         #shape = "Solver",
         #add="mean", error.plot = "pointrange"
         )+
  xlab("Depth [mm]") +
  ylab("Distance Localisation Error [mm]") +
  grids() +
  theme_bw()+
  theme(axis.text.x = element_text(angle = 45, hjust=1))

G2 = table %>%
  na.omit() %>%
  filter( Solver == currMethod ) %>%
  filter( SNR == "30" ) %>%
  ggscatter(., x="Depth", y="SpaDis2" 
            #group=interaction("Profile", "idx"), 
            #color = "Solver",
            #shape = "Solver",
            #add="mean", error.plot = "pointrange"
  )+
  xlab("Depth [mm]") +
  ylab("Spatial Dispersion [mm]") +
  grids() +
  theme_bw()+
  theme(axis.text.x = element_text(angle = 45, hjust=1))

G3 = table %>%
  na.omit() %>%
  filter( Solver == currMethod ) %>%
  filter( SNR == "30" ) %>%
  ggscatter(., x="Depth", y="AUROC_loc_classic" 
            #group=interaction("Profile", "idx"), 
            #color = "Solver",
            #shape = "Solver",
            #add="mean", error.plot = "pointrange"
  )+
  xlab("Depth [mm]") +
  ylab("AUROC") +
  grids() +
  theme_bw()+
  theme(axis.text.x = element_text(angle = 45, hjust=1))

G4 = table %>%
  na.omit() %>%
  filter( Solver == currMethod ) %>%
  filter( SNR == "30" ) %>%
  ggscatter(., x="Depth", y="AP_loc_classic" 
            #group=interaction("Profile", "idx"), 
            #color = "Solver",
            #shape = "Solver",
            #add="mean", error.plot = "pointrange"
  )+
  xlab("Depth [mm]") +
  ylab("Average Precision") +
  grids() +
  theme_bw()+
  theme(axis.text.x = element_text(angle = 45, hjust=1))

ggarrange( G1, G2, G3, G4,
           ncol = 2, nrow = 2, align = "v", common.legend = TRUE, legend="top")
ggsave( paste0("CORR_depth_", currMethod, "_",tagname, ".pdf"),
        width = 9, height = 6, units = "in")


################################################################################

setwd(paste0( script_dir, "/img/" ))

G1 = table %>%
  drop_na() %>%
  filter( SNR=="30" ) %>% 
  filter( Solver == "SISSY" ) %>%
  ggboxplot(x = "Solver",
            y = "DLE1", fill="Profile") +
  ylab("Distance Localization Eror [mm]") +
  grids() +
  theme_bw() +
  theme(axis.title.x=element_blank())

G2 = table %>%
  drop_na() %>%
  filter( SNR=="30" ) %>%
  filter( Solver == "SISSY" ) %>%
  ggboxplot(x = "Solver",
            y = "SpaDis2", fill="Profile") +
  ylab("Spatial Dispersion [mm]") +
  grids() +
  theme_bw()+
  theme(axis.title.x=element_blank())

G3 = table %>%
  filter( SNR=="30" ) %>%
  filter( Solver == "SISSY" ) %>%
  filter( AUROC_loc>0 ) %>%
  drop_na() %>%
  ggboxplot(x = "Solver",
            y = "AUROC_loc", fill="Profile") +
  ylab("AUROC (local)") +
  grids() +
  theme_bw()+
  theme(axis.title.x=element_blank())

G4 = table %>%
  drop_na() %>%
  filter( SNR=="30" ) %>%
  filter( Solver == "SISSY" ) %>%
  filter( AP_loc>0 ) %>%
  ggboxplot(x = "Solver",
            y = "AP_loc", fill="Profile") +
  ylab("Average Precision (local)") +
  grids() +
  theme_bw()+
  theme(axis.title.x=element_blank())

ggarrange( G1, G2, G3, G4,
           ncol = 2, nrow = 2, align = "v", common.legend = TRUE, legend="top")
ggsave( paste0("shape_",tagname, "ALL", ".pdf"),
        width = 9, height = 6, units = "in")

################################################################################

vars_cor = table %>%
  drop_na() %>%
  filter( SNR=="30" ) %>%
  filter( Solver == "SLap" ) %>%
  select( "DLE1", "SpaDis2", "AUROC_loc", "AP_loc", "Depth" ) %>%
  correlate()

calc_ttest_p_value <- function(vec_a, vec_b){
  t.test(vec_a, vec_b)$p.value
}

vars_cor_p = table %>%
  drop_na() %>%
  filter( SNR=="20" ) %>%
  select( "DLE1", "SpaDis2", "AUROC_loc", "AP_loc", "Depth" ) %>%
  colpair_map(., calc_ttest_p_value)

