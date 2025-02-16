
#' bm_df() Function
#'
#' This function 
#' @param data : data
 
## biomass 구하기--------------------------------------------------------------
## 수종 ~ 추정간재적*(목재기본밀도)*(바이오매스 확장계수)(1+뿌리함량비)-----------------
bm_df <- function(data){
  
  
  output <- data  %>% mutate(species_bm = case_when(
    
    ## bio_coeff = 국가고유배출계수, 
    ## 출처 : "탄소배출계수를 활용한 국가 온실가스 통계 작성", 
    ## "NIFoS 산림정책이슈 제129호 : 주요 산림수종의 표준 탄소흡수량(ver.1.2)"
    
    ## 강원지방소나무--------------------------------------------------------------
    (SPCD =="14994" & ( SGG_CD == 47210 |  SGG_CD == 47920 |  SGG_CD == 47930 | SGG_CD == 47760 | SIDO_CD == 42 )) 
    ~ "14994_GW" , 
    
    ##강원지방소나무 영주시, 봉화군, 울진군, 영양군, 강원도 #
    
    ## 수종별--------------------------------------------------------------
    SPCD =="14994" ~ "14994", #중부지방소나무
    SPCD =="14964" ~ "14964" , #일본잎갈나무
    SPCD =="14987" ~ "14987", #리기다
    SPCD =="15003" ~ "15003", #곰솔
    SPCD =="14973" ~ "14973", #잣나무
    SPCD =="15014" ~ "15014" , #삼나무
    SPCD =="14973" ~ "14973" , #편백
    SPCD =="6617" ~ "6617" , #굴참나무
    SPCD =="6556" ~ "6556" , #신갈나무
    SPCD =="6512" ~ "6512" , #상수리나무
    SPCD =="6591" ~ "6591" , #졸참나무
    SPCD =="6505" ~ "6505" , #붉가시나무
    SPCD =="1959" ~ "1959" , #아까시나무
    SPCD =="895" ~ "895" , #자작나무
    SPCD =="11588" ~ "11588" , #백합나무
    SPCD =="19592" ~ "19592" , #현사시? 은사시?
    SPCD =="6476" ~ "6476" , #밤나무
    
    ## 기타 활엽수 및 기타 침엽수--------------------------------------------------------------
    (DECEVER_CD == 1) ~ "EVERDEC" ,
    (CONDEC_CLASS_CD ==1) ~ "OTHER_DEC" ,
    (CONDEC_CLASS_CD ==0) ~ "OTHER_CON",
    TRUE ~ as.character(NA)
    
  ))
  
  ## bio_coeff = 국가고유배출계수, 
  ## 출처 : "탄소배출계수를 활용한 국가 온실가스 통계 작성", 
  ## "NIFoS 산림정책이슈 제129호 : 주요 산림수종의 표준 탄소흡수량(ver.1.2)"
  output <- left_join(output, bio_coeff, by= c("species_bm" ="SPCD") )
  
  ## 지상부 biomass 구하기--------------------------------------------------------------
  ## 수종 ~ 추정간재적*(목재기본밀도)*(바이오매스 확장계수)-------------------------------
  output$AG_biomass <- (output$VOL_EST)*(output$wood_density)*(output$biomass_expan)
  ## biomass 구하기--------------------------------------------------------------
  ## 수종 ~ 추정간재적*(목재기본밀도)*(바이오매스 확장계수)(1+뿌리함량비)-----------------
  output$T_biomass <- output$AG_biomass*(1+output$root_shoot_ratio)
  ## 탄소흡수량 구하기-----------------------------------------------
  ## 수종 ~ 추정간재적*(목재기본밀도)*(바이오매스 확장계수)(1+뿌리함량비)*(0.51(침) or 0.48(활))-----------------------
  output$CF <- ifelse(output$CONDEC_CLASS_CD ==1, 0.48, 0.51 ) ##탄소전환계수
  output$carbon_stock <- output$T_biomass*output$CF
  ## 이산탄소흡수량 구하기--------------------------------------------------------------
  ## 수종 ~ 추정간재적*(목재기본밀도)*(바이오매스 확장계수)(1+뿌리함량비)*(0.51(침) or 0.48(활))*(44/12)--------------------
  output$co2_stock = output$carbon_stock*(44/12)
  
  
  return(output)
  
}







#' biomass_NFI() Function
#'
#' This function 
#' @param data : data
#' @param byplot : byplot
#' @param grpby : grpby
#' @param grpby2 : grpby
#' @param strat : 흉고단면적/개체수
#' @param clusterplot : byplot TRUE 집락
#' @param largetreearea : 대경목조사원
#' @param Stockedland : 임목지
#' @param talltree : 교목
#' @keywords biomass
#' @return biomass
#' @export 


biomass_NFI <- function(data, byplot= FALSE, grpby=NULL, grpby2= NULL, strat="FORTYP_SUB", clusterplot=FALSE, largetreearea=TRUE, Stockedland=TRUE, talltree=TRUE){
  
  
  # 경고 
  required_names <- c("plot", "tree")
  
  if (!all(required_names %in% names(data))) {
    missing_dfs <- required_names[!required_names %in% names(data)]
    stop("Missing required data frames in the list: ", paste(missing_dfs, collapse = ", "), call. = FALSE)
  }
  
  
  if (!is.null(grpby)){
    if(grpby==strat){
      stop("param 'grpby' is the same as param 'strat'")
    }
    if(!is.character(grpby)) {
      stop("param 'grpby' must be 'character'")
    }
    #if(byplot){
    #  warning("param 'grpby' has priority over param 'byplot'")
    #}
    
  }
  
  if (!is.null(grpby2)){
    
    if(!is.character(grpby2)) {
      stop("param 'grpby' must be 'character'")
    }
    
  }
  
  if (!is.null(strat)){
    if(!is.character(strat)) {
      stop("param 'strat' must be 'character'")
    }
    if(byplot){
      warning("param 'byplot' has priority over param 'strat'")
    }
    
  }
  
  
  # 전처리
  if (Stockedland){ #임목지
    data <- filter_NFI(data, c("plot$LAND_USECD == 1"))
  }
  
  if(talltree){#수목형태구분
    data$tree <- data$tree %>% filter(WDY_PLNTS_TYP_CD == 1)
  }
  
   
  df <- left_join(data$tree[,c('CLST_PLOT', 'SUB_PLOT',"CYCLE", 'WDY_PLNTS_TYP_CD','SP', 'SPCD',
                                'CONDEC_CLASS_CD', 'DECEVER_CD', 'DBH', 'VOL_EST',  'LARGEP_TREE', grpby2)], 
                  data$plot[,c('CLST_PLOT', 'SUB_PLOT', "CYCLE", 'INVYR', "LAND_USE", "LAND_USECD",
                               'NONFR_INCL_AREA_SUBP', 'NONFR_INCL_AREA_LARGEP', "SGG_CD", 'SIDO_CD', strat, grpby)],
                  by = c("CLST_PLOT", "SUB_PLOT", "CYCLE"))

  if (!is.numeric(df$VOL_EST)){
    df$VOL_EST <- as.numeric(df$VOL_EST)
  } 
  
  
  
  if(!largetreearea){ #대경목조사원내존재여부
    df <- df %>% filter(df$LARGEP_TREE == 0)
  }else{
    df$largetree <- ifelse(df$DBH>=30, 1, 0)
    df$largetree_area <- 0.08 - ((df$NONFR_INCL_AREA_LARGEP*10)/10000) # 단위 m2/10
  }
  
  df$tree_area <- 0.04 - ((df$NONFR_INCL_AREA_SUBP*10)/10000)
  
  df <- bm_df(df)
  
  if(clusterplot){
    plot_id <- c('CLST_PLOT')
  }else{
    plot_id <- c('SUB_PLOT')
  }
  
  plot_id  <- rlang::sym(plot_id)
  grpby  <- rlang::syms(grpby)
  strat<- rlang::sym(strat)
  grpby2  <- rlang::syms(grpby2)
  
  if(!largetreearea){
    largetree <- NULL
  }
  if(byplot){
    strat <- NULL
  }
  
  
  # 집락 또는 부표본점별 생물량 계산
  if(clusterplot){ # 집락표본점별 생물량 계산
    
    plot_area <- df[-which(duplicated(df[c('SUB_PLOT', 'CYCLE')])),c('CYCLE', 'INVYR', 'CLST_PLOT', 'SUB_PLOT', 'largetree_area', 'tree_area')]
    
    plot_area <- plot_area %>%
      group_by(CYCLE, !!plot_id, INVYR) %>%
      summarise(largetree_area = sum(largetree_area, na.rm=TRUE),
                tree_area= sum(tree_area, na.rm=TRUE),.groups = 'drop')
    
    bm_temp <- df %>% 
      group_by(CYCLE, !!plot_id, INVYR, largetree, !!!grpby, !!!grpby2, !!strat) %>% 
      summarise(volume_m3 = sum(VOL_EST, na.rm=TRUE),
                biomass_ton = sum(T_biomass, na.rm=TRUE),
                AG_biomass_ton = sum(AG_biomass, na.rm=TRUE),
                carbon_stock_tC = sum(carbon_stock, na.rm=TRUE),
                co2_stock_tCO2 = sum(co2_stock, na.rm=TRUE),.groups = 'drop')
    
    bm_temp <- full_join(bm_temp, plot_area, by=c('CYCLE', 'INVYR', quo_name(plot_id)))
    
    condition <- (names(bm_temp) %in% c("volume_m3","biomass_ton","AG_biomass_ton","carbon_stock_tC","co2_stock_tCO2"))
    
    
    if(!largetreearea){ # 대경목조사원 미포함 집락표본점별 생물량 계산 
      
      condition_ha <- c("volume_m3_ha","biomass_ton_ha","AG_biomass_ton_ha","carbon_stock_tC_ha","co2_stock_tCO2_ha")
      bm_temp[condition_ha] <-  NA
      bm_temp <- as.data.frame(bm_temp)
      
      condition_ha <- (names(bm_temp) %in% c("volume_m3_ha","biomass_ton_ha","AG_biomass_ton_ha","carbon_stock_tC_ha","co2_stock_tCO2_ha"))
      
      bm_temp[condition_ha] <- 
        lapply(bm_temp[condition], function(x) (x/bm_temp$tree_area))
      
      condition <- (names(bm_temp) %in% c("volume_m3","biomass_ton","AG_biomass_ton","carbon_stock_tC","co2_stock_tCO2"))
      
      
      bm_temp[condition] <- NULL
      bm_temp$tree_area <- NULL
      bm_temp$largetreearea <- NULL
      
      
    }else{ # 대경목조사원 포함 집락표본점별 생물량 계산 
      
      bm_temp[condition] <- 
        lapply(bm_temp[condition], function(x) ifelse(bm_temp$largetree == 1, 
                                                      x/(bm_temp$largetree_area),
                                                      x/(bm_temp$tree_area)))
      
      bm_temp <- bm_temp %>% 
        group_by(CYCLE, INVYR, !!plot_id, !!!grpby, !!!grpby2, !!strat) %>% 
        summarise(volume_m3_ha = sum(volume_m3, na.rm=TRUE),
                  biomass_ton_ha = sum(biomass_ton, na.rm=TRUE),
                  AG_biomass_ton_ha = sum(AG_biomass_ton, na.rm=TRUE),
                  carbon_stock_tC_ha = sum(carbon_stock_tC, na.rm=TRUE),
                  co2_stock_tCO2_ha = sum(co2_stock_tCO2, na.rm=TRUE),.groups = 'drop')
    }
    
    
    
    
    
    
  }else{ # 부표본점별 생물량 계산  
    
    
    bm_temp <- df %>% 
      group_by(CYCLE, !!plot_id, INVYR, !!strat, largetree, !!!grpby, !!!grpby2, largetree_area, tree_area) %>% 
      summarise(volume_m3 = sum(VOL_EST, na.rm=TRUE),
                biomass_ton = sum(T_biomass, na.rm=TRUE),
                AG_biomass_ton = sum(AG_biomass, na.rm=TRUE),
                carbon_stock_tC = sum(carbon_stock, na.rm=TRUE),
                co2_stock_tCO2 = sum(co2_stock, na.rm=TRUE),.groups = 'drop')
    

    condition <- (names(bm_temp) %in% c("volume_m3","biomass_ton","AG_biomass_ton","carbon_stock_tC","co2_stock_tCO2"))
    
    if(!largetreearea){ # 대경목조사원 미포함 부표본점별 생물량 계산  
      
      condition_ha <- c("volume_m3_ha","biomass_ton_ha","AG_biomass_ton_ha","carbon_stock_tC_ha","co2_stock_tCO2_ha")
      bm_temp[condition_ha] <-  NA
      bm_temp <- as.data.frame(bm_temp)
      
      condition_ha <- (names(bm_temp) %in% c("volume_m3_ha","biomass_ton_ha","AG_biomass_ton_ha","carbon_stock_tC_ha","co2_stock_tCO2_ha"))
      
      bm_temp[condition_ha] <- 
        lapply(bm_temp[condition], function(x) (x/bm_temp$tree_area))
      
      condition <- (names(bm_temp) %in% c("volume_m3","biomass_ton","AG_biomass_ton","carbon_stock_tC","co2_stock_tCO2"))
      
      
      bm_temp[condition] <- NULL
      bm_temp$tree_area <- NULL
      bm_temp$largetreearea <- NULL
      
      
      
    }else{ # 대경목조사원 포함 부표본점별 생물량 계산  
      
      bm_temp[condition] <- 
        lapply(bm_temp[condition], function(x) ifelse(bm_temp$largetree == 1, 
                                                      x/(bm_temp$largetree_area),
                                                      x/(bm_temp$tree_area)))
      
      bm_temp <- bm_temp %>% 
        group_by(CYCLE, INVYR, !!plot_id, !!!grpby, !!!grpby2, !!strat) %>% 
        summarise(volume_m3_ha = sum(volume_m3, na.rm=TRUE),
                  biomass_ton_ha = sum(biomass_ton, na.rm=TRUE),
                  AG_biomass_ton_ha = sum(AG_biomass_ton, na.rm=TRUE),
                  carbon_stock_tC_ha = sum(carbon_stock_tC, na.rm=TRUE),
                  co2_stock_tCO2_ha = sum(co2_stock_tCO2, na.rm=TRUE),.groups = 'drop')
    }
  }
  
  if(!byplot){ # 사후층화이중추출법 및 가중이동평균 생물량 계산
    
    # Double sampling for post-strat(forest stand)
    weight_grpby <- data$plot %>% 
      group_by(CYCLE, !!!grpby) %>% 
      summarise(plot_num_all = n(),.groups = 'drop')
    
    
    weight_year <- data$plot %>% 
      group_by(CYCLE, INVYR, !!!grpby) %>% 
      summarise(plot_num_year = n(),.groups = 'drop')
    
    
    weight_stand <- data$plot %>% 
      group_by(CYCLE, INVYR, !!strat, !!!grpby) %>% 
      summarise(plot_num_stand = n(),.groups = 'drop')
    
    
    weight_DSS <- full_join(weight_stand, weight_year, by =c("CYCLE", "INVYR", as.character(unlist(lapply(grpby, quo_name)))))
    weight_DSS$weight_DSS <- weight_DSS$plot_num_stand/weight_DSS$plot_num_year
    

    # plot to stand 생물량 계산
    bm_temp_DSS <- bm_temp %>% 
      group_by(CYCLE, INVYR, !!strat, !!!grpby, !!!grpby2) %>% 
      summarise(var_volume_m3_ha =  var(volume_m3_ha, na.rm=TRUE),
                volume_m3_ha = sum(volume_m3_ha, na.rm=TRUE),
                var_biomass_ton_ha =  var(biomass_ton_ha, na.rm=TRUE),
                biomass_ton_ha = sum(biomass_ton_ha, na.rm=TRUE),
                var_AG_biomass_ton_ha =  var(AG_biomass_ton_ha, na.rm=TRUE),
                AG_biomass_ton_ha = sum(AG_biomass_ton_ha, na.rm=TRUE),
                var_carbon_stock_tC_ha =  var(carbon_stock_tC_ha, na.rm=TRUE),
                carbon_stock_tC_ha = sum(carbon_stock_tC_ha, na.rm=TRUE),
                var_co2_stock_tCO2_ha =  var(co2_stock_tCO2_ha, na.rm=TRUE),
                co2_stock_tCO2_ha = sum(co2_stock_tCO2_ha, na.rm=TRUE), .groups = 'drop')
    
    
    bm_temp_DSS <- full_join(bm_temp_DSS, weight_DSS, by =c("CYCLE", "INVYR", quo_name(strat), as.character(unlist(lapply(grpby, quo_name)))))
    
    
    condition_DSS <- c("w_volume_m3_ha","w_biomass_ton_ha","w_AG_biomass_ton_ha","w_carbon_stock_tC_ha","w_co2_stock_tCO2_ha")
    bm_temp_DSS[condition_DSS] <-  NA
    bm_temp_DSS <- as.data.frame(bm_temp_DSS)
    
    condition <- (names(bm_temp_DSS) %in% c("volume_m3_ha","biomass_ton_ha","AG_biomass_ton_ha","carbon_stock_tC_ha","co2_stock_tCO2_ha"))
    
    bm_temp_DSS[condition] <- 
      lapply(bm_temp_DSS[condition], function(x) ((x/bm_temp_DSS$plot_num_stand)))
    
    condition_DSS <- (names(bm_temp_DSS) %in% c("w_volume_m3_ha","w_biomass_ton_ha","w_AG_biomass_ton_ha","w_carbon_stock_tC_ha","w_co2_stock_tCO2_ha"))
    bm_temp_DSS[condition_DSS] <- 
      lapply(bm_temp_DSS[condition], function(x) (x*bm_temp_DSS$weight_DSS))
    
    
    condition_var <- (names(bm_temp_DSS) %in% c("var_volume_m3_ha","var_biomass_ton_ha","var_AG_biomass_ton_ha","var_carbon_stock_tC_ha","var_co2_stock_tCO2_ha"))
    bm_temp_DSS[condition_var] <- 
      lapply(bm_temp_DSS[condition_var], function(x) ((bm_temp_DSS$weight_DSS)^2*(x/bm_temp_DSS$plot_num_stand)))
    
    
    bm_temp_WMA <- bm_temp_DSS %>% 
      group_by(CYCLE, INVYR, !!!grpby, !!!grpby2) %>% 
      summarise(w_volume_m3_ha = sum(w_volume_m3_ha, na.rm=TRUE),
                w_biomass_ton_ha = sum(w_biomass_ton_ha, na.rm=TRUE),
                w_AG_biomass_ton_ha = sum(w_AG_biomass_ton_ha, na.rm=TRUE),
                w_carbon_stock_tC_ha = sum(w_carbon_stock_tC_ha, na.rm=TRUE),
                w_co2_stock_tCO2_ha = sum(w_co2_stock_tCO2_ha, na.rm=TRUE), .groups = 'drop')
    
    
    # stand to study area 생물량 계산
    bm_temp_DSS[condition_DSS] <-  NULL
    bm_temp_DSS <- left_join(bm_temp_DSS, bm_temp_WMA, by =c("CYCLE", "INVYR", as.character(unlist(lapply(grpby, quo_name))),
                                                             as.character(unlist(lapply(grpby2, quo_name)))))
    
    bm_temp_DSS$var_volume_m3_ha <- bm_temp_DSS$var_volume_m3_ha + (bm_temp_DSS$weight_DSS*(bm_temp_DSS$volume_m3_ha-bm_temp_DSS$w_volume_m3_ha)^2/bm_temp_DSS$plot_num_year)
    bm_temp_DSS$var_biomass_ton_ha <- bm_temp_DSS$var_biomass_ton_ha + (bm_temp_DSS$weight_DSS*(bm_temp_DSS$biomass_ton_ha-bm_temp_DSS$w_biomass_ton_ha)^2/bm_temp_DSS$plot_num_year)
    bm_temp_DSS$var_AG_biomass_ton_ha <- bm_temp_DSS$var_AG_biomass_ton_ha + (bm_temp_DSS$weight_DSS*(bm_temp_DSS$AG_biomass_ton_ha-bm_temp_DSS$w_AG_biomass_ton_ha)^2/bm_temp_DSS$plot_num_year)
    bm_temp_DSS$var_carbon_stock_tC_ha <- bm_temp_DSS$var_carbon_stock_tC_ha + (bm_temp_DSS$weight_DSS*(bm_temp_DSS$carbon_stock_tC_ha-bm_temp_DSS$w_carbon_stock_tC_ha)^2/bm_temp_DSS$plot_num_year)
    bm_temp_DSS$var_co2_stock_tCO2_ha <- bm_temp_DSS$var_co2_stock_tCO2_ha + (bm_temp_DSS$weight_DSS*(bm_temp_DSS$co2_stock_tCO2_ha-bm_temp_DSS$w_co2_stock_tCO2_ha)^2/bm_temp_DSS$plot_num_year)
    
    bm_temp_DSS[condition_DSS] <- 
      lapply(bm_temp_DSS[condition], function(x) (x*bm_temp_DSS$weight_DSS))
    
    bm_temp_WMA <- bm_temp_DSS %>% 
      group_by(CYCLE, INVYR, !!!grpby, !!!grpby2) %>% 
      summarise(volume_m3_ha = sum(w_volume_m3_ha, na.rm=TRUE),
                var_volume_m3_ha = sum(var_volume_m3_ha, na.rm=TRUE),
                biomass_ton_ha = sum(w_biomass_ton_ha, na.rm=TRUE),
                var_biomass_ton_ha = sum(var_biomass_ton_ha, na.rm=TRUE),
                AG_biomass_ton_ha = sum(w_AG_biomass_ton_ha, na.rm=TRUE),
                var_AG_biomass_ton_ha = sum(var_AG_biomass_ton_ha, na.rm=TRUE),
                carbon_stock_tC_ha = sum(w_carbon_stock_tC_ha, na.rm=TRUE),
                var_carbon_stock_tC_ha = sum(var_carbon_stock_tC_ha, na.rm=TRUE),
                co2_stock_tCO2_ha = sum(w_co2_stock_tCO2_ha, na.rm=TRUE),
                var_co2_stock_tCO2_ha = sum(var_co2_stock_tCO2_ha, na.rm=TRUE),.groups = 'drop')
    
    
    # Weighted Moving Average(to combine annual inventory field data)
    weight_WMA <- full_join(weight_year, weight_grpby, by =c("CYCLE", as.character(unlist(lapply(grpby, quo_name)))))
    weight_WMA$weight_WMA <- weight_WMA$plot_num_year/weight_WMA$plot_num_all
    
    
    bm_temp_WMA <- full_join(bm_temp_WMA, weight_WMA, by =c("CYCLE","INVYR", as.character(unlist(lapply(grpby, quo_name)))))
    
    condition <- (names(bm_temp_WMA) %in% c("volume_m3_ha","biomass_ton_ha","AG_biomass_ton_ha","carbon_stock_tC_ha","co2_stock_tCO2_ha"))
    
    
    bm_temp_WMA[condition] <- 
      lapply(bm_temp_WMA[condition], function(x) (x*bm_temp_WMA$weight_WMA))
    
    
    bm <- bm_temp_WMA %>% 
      group_by(CYCLE, !!!grpby, !!!grpby2) %>% 
      summarise(volume_m3_ha = sum(volume_m3_ha, na.rm=TRUE),
                var_volume_m3_ha = sum(weight_WMA^2*var_volume_m3_ha, na.rm=TRUE),
                se_volume_m3_ha = sqrt(var_volume_m3_ha),
                rse_volume_m3_ha = se_volume_m3_ha/volume_m3_ha*100,
                biomass_ton_ha = sum(biomass_ton_ha, na.rm=TRUE),
                var_biomass_ton_ha = sum(weight_WMA^2*var_biomass_ton_ha, na.rm=TRUE),
                se_biomass_ton_ha = sqrt(var_biomass_ton_ha),
                rse_biomass_ton_ha = se_biomass_ton_ha/biomass_ton_ha*100,
                AG_biomass_ton_ha = sum(AG_biomass_ton_ha, na.rm=TRUE),
                var_AG_biomass_ton_ha = sum(weight_WMA^2*var_AG_biomass_ton_ha, na.rm=TRUE),
                se_AG_biomass_ton_ha = sqrt(var_AG_biomass_ton_ha),
                rse_AG_biomass_ton_ha = se_AG_biomass_ton_ha/AG_biomass_ton_ha*100,
                carbon_stock_tC_ha = sum(carbon_stock_tC_ha, na.rm=TRUE),
                var_carbon_stock_tC_ha = sum(weight_WMA^2*var_carbon_stock_tC_ha, na.rm=TRUE),
                se_carbon_stock_tC_ha = sqrt(var_carbon_stock_tC_ha),
                rse_carbon_stock_tC_ha = se_carbon_stock_tC_ha/carbon_stock_tC_ha*100,
                co2_stock_tCO2_ha = sum(co2_stock_tCO2_ha, na.rm=TRUE),
                var_co2_stock_tCO2_ha = sum(weight_WMA^2*var_co2_stock_tCO2_ha, na.rm=TRUE),
                se_co2_stock_tCO2_ha = sqrt(var_co2_stock_tCO2_ha),
                rse_co2_stock_tCO2_ha = se_co2_stock_tCO2_ha/co2_stock_tCO2_ha*100,.groups = 'drop')
    
    
    
    
    
  }else{ # 표본점별 생물량 계산
    
    bm <- bm_temp
    
  }
  
  
  
  
  
  
  
  return(bm)
  
}



#' biomass_tsvis() Function
#'
#' This function 
#' @param data : data
#' @param grpby : grpby
#' @param grpby2 : grpby
#' @param strat : 흉고단면적/개체수
#' @param clusterplot : byplot TRUE 집락
#' @param largetreearea : 대경목조사원
#' @param Stockedland : 임목지
#' @param talltree : 교목
#' @keywords biomass


biomass_tsvis <- function(data, grpby=NULL, grpby2=NULL, strat="FORTYP_SUB", clusterplot=FALSE, largetreearea=TRUE, Stockedland=TRUE, talltree=TRUE){
  
  #경고 
  required_names <- c("plot", "tree")
  
  if (!all(required_names %in% names(data))) {
    missing_dfs <- required_names[!required_names %in% names(data)]
    stop("Missing required data frames in the list: ", paste(missing_dfs, collapse = ", "), call. = FALSE)
  }
  
  if (!is.null(grpby)){
    if(grpby==strat){
      stop("param 'grpby' is the same as param 'strat'")
    }
    if(!is.character(grpby)) {
      stop("param 'grpby' must be 'character'")
    }
    
  }
  
  
  if (!is.null(grpby2)){
    
    if(!is.character(grpby2)) {
      stop("param 'grpby' must be 'character'")
    }
    
  }
  
  if (!is.null(strat)){
    if(!is.character(strat)) {
      stop("param 'strat' must be 'character'")
    }
    
  }
  
  
  
  # 전처리
  
  if (Stockedland){ #임목지
    data <- filter_NFI(data, c("plot$LAND_USECD == 1"))
  }
  
  if(talltree){#수목형태구분
    data$tree <- data$tree %>% filter(WDY_PLNTS_TYP_CD == 1)
  }
  
  df <- left_join(data$tree[,c('CLST_PLOT', 'SUB_PLOT',"CYCLE", 'WDY_PLNTS_TYP_CD','SP', 'SPCD',
                               'CONDEC_CLASS_CD', 'DECEVER_CD', 'DBH', 'VOL_EST',  'LARGEP_TREE', grpby2 )], 
                  data$plot[,c('CLST_PLOT', 'SUB_PLOT', "CYCLE", 'INVYR', "LAND_USE", "LAND_USECD",
                               'NONFR_INCL_AREA_SUBP', 'NONFR_INCL_AREA_LARGEP', "SGG_CD", 'SIDO_CD', strat, grpby)],
                  by = c("CLST_PLOT", "SUB_PLOT", "CYCLE"))
  

  if (!is.numeric(df$VOL_EST)){
    df$VOL_EST <- as.numeric(df$VOL_EST)
  } 
  
  if(!largetreearea){ #대경목조사원내존재여부
    df <- df %>% filter(df$LARGEP_TREE == 0)
  }else{
    df$largetree <- ifelse(df$DBH>=30, 1, 0)
    df$largetree_area <- 0.08 - ((df$NONFR_INCL_AREA_LARGEP*10)/10000) # 단위 m2/10
  }
  
  
  df$tree_area <- 0.04 - ((df$NONFR_INCL_AREA_SUBP*10)/10000)
  
  df <- bm_df(df)
  
  if(clusterplot){
    plot_id <- c('CLST_PLOT')
  }else{
    plot_id <- c('SUB_PLOT')
  }
  
  plot_id  <- rlang::sym(plot_id)
  grpby  <- rlang::syms(grpby)
  grpby2  <- rlang::syms(grpby2)
  strat<- rlang::sym(strat)
  
  if(!largetreearea){
    largetree <- NULL
  }
  
  
  # 집락 또는 부표본점별 생물량 계산
  if(clusterplot){ # 집락표본점별 생물량 계산
    
    plot_area <- df[-which(duplicated(df[c('SUB_PLOT', 'CYCLE')])),c('CYCLE', 'INVYR', 'CLST_PLOT', 'SUB_PLOT', 'largetree_area', 'tree_area')]

    
    plot_area <- plot_area %>%
      group_by(CYCLE, !!plot_id,  INVYR) %>%
      summarise(largetree_area = sum(largetree_area, na.rm=TRUE),
                tree_area= sum(tree_area, na.rm=TRUE),.groups = 'drop')
    
 
    bm_temp <- df %>% 
      group_by(CYCLE, !!plot_id, INVYR, largetree, !!!grpby, !!!grpby2, !!strat) %>% 
      summarise(volume_m3 = sum(VOL_EST, na.rm=TRUE),
                biomass_ton = sum(T_biomass, na.rm=TRUE),
                AG_biomass_ton = sum(AG_biomass, na.rm=TRUE),
                carbon_stock_tC = sum(carbon_stock, na.rm=TRUE),
                co2_stock_tCO2 = sum(co2_stock, na.rm=TRUE),.groups = 'drop')
    
    
    bm_temp <- full_join(bm_temp, plot_area, by=c('CYCLE', 'INVYR', quo_name(plot_id)))
    
    condition <- (names(bm_temp) %in% c("volume_m3","biomass_ton","AG_biomass_ton","carbon_stock_tC","co2_stock_tCO2"))
    
    
    if(!largetreearea){ # 대경목조사원 미포함 집락표본점별 생물량 계산
      
      condition_ha <- c("volume_m3_ha","biomass_ton_ha","AG_biomass_ton_ha","carbon_stock_tC_ha","co2_stock_tCO2_ha")
      bm_temp[condition_ha] <-  NA
      bm_temp <- as.data.frame(bm_temp)
      
      condition_ha <- (names(bm_temp) %in% c("volume_m3_ha","biomass_ton_ha","AG_biomass_ton_ha","carbon_stock_tC_ha","co2_stock_tCO2_ha"))
      
      bm_temp[condition_ha] <- 
        lapply(bm_temp[condition], function(x) (x/bm_temp$tree_area))
      
      condition <- (names(bm_temp) %in% c("volume_m3","biomass_ton","AG_biomass_ton","carbon_stock_tC","co2_stock_tCO2"))
      
      
      bm_temp[condition] <- NULL
      bm_temp$tree_area <- NULL
      bm_temp$largetreearea <- NULL
      
      
    }else{ # 대경목조사원 포함 집락표본점별 생물량 계산
      
      bm_temp[condition] <- 
        lapply(bm_temp[condition], function(x) ifelse(bm_temp$largetree == 1, 
                                                      x/(bm_temp$largetree_area),
                                                      x/(bm_temp$tree_area)))
      
      bm_temp <- bm_temp %>% 
        group_by(CYCLE, INVYR, !!plot_id, !!!grpby, !!!grpby2, !!strat) %>% 
        summarise(volume_m3_ha = sum(volume_m3, na.rm=TRUE),
                  biomass_ton_ha = sum(biomass_ton, na.rm=TRUE),
                  AG_biomass_ton_ha = sum(AG_biomass_ton, na.rm=TRUE),
                  carbon_stock_tC_ha = sum(carbon_stock_tC, na.rm=TRUE),
                  co2_stock_tCO2_ha = sum(co2_stock_tCO2, na.rm=TRUE),.groups = 'drop')
    }
    
    
    
    
    
    
  }else{ # 부표본점별 생물량 계산
    
    bm_temp <- df %>% 
      group_by(CYCLE, !!plot_id, INVYR, !!strat, largetree, !!!grpby, !!!grpby2, largetree_area, tree_area) %>% 
      summarise(volume_m3 = sum(VOL_EST, na.rm=TRUE),
                biomass_ton = sum(T_biomass, na.rm=TRUE),
                AG_biomass_ton = sum(AG_biomass, na.rm=TRUE),
                carbon_stock_tC = sum(carbon_stock, na.rm=TRUE),
                co2_stock_tCO2 = sum(co2_stock, na.rm=TRUE),.groups = 'drop')
    
    
    condition <- (names(bm_temp) %in% c("volume_m3","biomass_ton","AG_biomass_ton","carbon_stock_tC","co2_stock_tCO2"))
    
    if(!largetreearea){ # 대경목조사원 미포함 부표본점별 생물량 계산
      
      condition_ha <- c("volume_m3_ha","biomass_ton_ha","AG_biomass_ton_ha","carbon_stock_tC_ha","co2_stock_tCO2_ha")
      bm_temp[condition_ha] <-  NA
      bm_temp <- as.data.frame(bm_temp)
      
      condition_ha <- (names(bm_temp) %in% c("volume_m3_ha","biomass_ton_ha","AG_biomass_ton_ha","carbon_stock_tC_ha","co2_stock_tCO2_ha"))
      
      bm_temp[condition_ha] <- 
        lapply(bm_temp[condition], function(x) (x/bm_temp$tree_area))
      
      
      condition <- (names(bm_temp) %in% c("volume_m3","biomass_ton","AG_biomass_ton","carbon_stock_tC","co2_stock_tCO2"))
      
      
      bm_temp[condition] <- NULL
      bm_temp$tree_area <- NULL
      bm_temp$largetreearea <- NULL
      
      
    }else{ # 대경목조사원 포함 부표본점별 생물량 계산
      
      bm_temp[condition] <- 
        lapply(bm_temp[condition], function(x) ifelse(bm_temp$largetree == 1, 
                                                      x/(bm_temp$largetree_area),
                                                      x/(bm_temp$tree_area)))
      
      bm_temp <- bm_temp %>% 
        group_by(CYCLE, INVYR, !!plot_id, !!!grpby, !!!grpby2, !!strat) %>% 
        summarise(volume_m3_ha = sum(volume_m3, na.rm=TRUE),
                  biomass_ton_ha = sum(biomass_ton, na.rm=TRUE),
                  AG_biomass_ton_ha = sum(AG_biomass_ton, na.rm=TRUE),
                  carbon_stock_tC_ha = sum(carbon_stock_tC, na.rm=TRUE),
                  co2_stock_tCO2_ha = sum(co2_stock_tCO2, na.rm=TRUE),.groups = 'drop')
    }
  }
  
  
  
  # Double sampling for post-strat(forest stand)
  weight_grpby <- data$plot %>% 
    group_by(!!!grpby) %>% 
    summarise(plot_num_all = n(),.groups = 'drop')
  
  
  weight_year <- data$plot %>% 
    group_by(CYCLE, INVYR, !!!grpby) %>% 
    summarise(plot_num_year = n(),.groups = 'drop')
  
  
  weight_stand <- data$plot %>% 
    group_by(CYCLE, INVYR, !!strat, !!!grpby) %>% 
    summarise(plot_num_stand = n(),.groups = 'drop')
  
  
  weight_DSS <- full_join(weight_stand, weight_year, by =c("CYCLE", "INVYR", as.character(unlist(lapply(grpby, quo_name)))))
  weight_DSS$weight_DSS <- weight_DSS$plot_num_stand/weight_DSS$plot_num_year
  
  
  # plot to stand 생물량 계산
  bm_temp_DSS <- bm_temp %>% 
    group_by(CYCLE, INVYR, !!strat, !!!grpby, !!!grpby2) %>% 
    summarise(var_volume_m3_ha =  var(volume_m3_ha, na.rm=TRUE),
              volume_m3_ha = sum(volume_m3_ha, na.rm=TRUE),
              var_biomass_ton_ha =  var(biomass_ton_ha, na.rm=TRUE),
              biomass_ton_ha = sum(biomass_ton_ha, na.rm=TRUE),
              var_AG_biomass_ton_ha =  var(AG_biomass_ton_ha, na.rm=TRUE),
              AG_biomass_ton_ha = sum(AG_biomass_ton_ha, na.rm=TRUE),
              var_carbon_stock_tC_ha =  var(carbon_stock_tC_ha, na.rm=TRUE),
              carbon_stock_tC_ha = sum(carbon_stock_tC_ha, na.rm=TRUE),
              var_co2_stock_tCO2_ha =  var(co2_stock_tCO2_ha, na.rm=TRUE),
              co2_stock_tCO2_ha = sum(co2_stock_tCO2_ha, na.rm=TRUE), .groups = 'drop')
  
  
  bm_temp_DSS <- full_join(bm_temp_DSS, weight_DSS, by =c("CYCLE", "INVYR", quo_name(strat), as.character(unlist(lapply(grpby, quo_name)))))
  
  
  condition_DSS <- c("w_volume_m3_ha","w_biomass_ton_ha","w_AG_biomass_ton_ha","w_carbon_stock_tC_ha","w_co2_stock_tCO2_ha")
  bm_temp_DSS[condition_DSS] <-  NA
  bm_temp_DSS <- as.data.frame(bm_temp_DSS)
  
  condition <- (names(bm_temp_DSS) %in% c("volume_m3_ha","biomass_ton_ha","AG_biomass_ton_ha","carbon_stock_tC_ha","co2_stock_tCO2_ha"))
  
  bm_temp_DSS[condition] <- 
    lapply(bm_temp_DSS[condition], function(x) ((x/bm_temp_DSS$plot_num_stand)))
  
  condition_DSS <- (names(bm_temp_DSS) %in% c("w_volume_m3_ha","w_biomass_ton_ha","w_AG_biomass_ton_ha","w_carbon_stock_tC_ha","w_co2_stock_tCO2_ha"))
  bm_temp_DSS[condition_DSS] <- 
    lapply(bm_temp_DSS[condition], function(x) (x*bm_temp_DSS$weight_DSS))
  
  
  condition_var <- (names(bm_temp_DSS) %in% c("var_volume_m3_ha","var_biomass_ton_ha","var_AG_biomass_ton_ha","var_carbon_stock_tC_ha","var_co2_stock_tCO2_ha"))
  bm_temp_DSS[condition_var] <- 
    lapply(bm_temp_DSS[condition_var], function(x) ((bm_temp_DSS$weight_DSS)^2*(x/bm_temp_DSS$plot_num_stand)))
  
  
  bm_temp_WMA <- bm_temp_DSS %>% 
    group_by(CYCLE, INVYR, !!!grpby, !!!grpby2) %>% 
    summarise(w_volume_m3_ha = sum(w_volume_m3_ha, na.rm=TRUE),
              w_biomass_ton_ha = sum(w_biomass_ton_ha, na.rm=TRUE),
              w_AG_biomass_ton_ha = sum(w_AG_biomass_ton_ha, na.rm=TRUE),
              w_carbon_stock_tC_ha = sum(w_carbon_stock_tC_ha, na.rm=TRUE),
              w_co2_stock_tCO2_ha = sum(w_co2_stock_tCO2_ha, na.rm=TRUE), .groups = 'drop')
  
  
  # stand to study area 생물량 계산
  bm_temp_DSS[condition_DSS] <-  NULL
  bm_temp_DSS <- left_join(bm_temp_DSS, bm_temp_WMA, by =c("CYCLE", "INVYR", as.character(unlist(lapply(grpby, quo_name))),
                                                           as.character(unlist(lapply(grpby2, quo_name)))))
  
  bm_temp_DSS$var_volume_m3_ha <- bm_temp_DSS$var_volume_m3_ha + (bm_temp_DSS$weight_DSS*(bm_temp_DSS$volume_m3_ha-bm_temp_DSS$w_volume_m3_ha)^2/bm_temp_DSS$plot_num_year)
  bm_temp_DSS$var_biomass_ton_ha <- bm_temp_DSS$var_biomass_ton_ha + (bm_temp_DSS$weight_DSS*(bm_temp_DSS$biomass_ton_ha-bm_temp_DSS$w_biomass_ton_ha)^2/bm_temp_DSS$plot_num_year)
  bm_temp_DSS$var_AG_biomass_ton_ha <- bm_temp_DSS$var_AG_biomass_ton_ha + (bm_temp_DSS$weight_DSS*(bm_temp_DSS$AG_biomass_ton_ha-bm_temp_DSS$w_AG_biomass_ton_ha)^2/bm_temp_DSS$plot_num_year)
  bm_temp_DSS$var_carbon_stock_tC_ha <- bm_temp_DSS$var_carbon_stock_tC_ha + (bm_temp_DSS$weight_DSS*(bm_temp_DSS$carbon_stock_tC_ha-bm_temp_DSS$w_carbon_stock_tC_ha)^2/bm_temp_DSS$plot_num_year)
  bm_temp_DSS$var_co2_stock_tCO2_ha <- bm_temp_DSS$var_co2_stock_tCO2_ha + (bm_temp_DSS$weight_DSS*(bm_temp_DSS$co2_stock_tCO2_ha-bm_temp_DSS$w_co2_stock_tCO2_ha)^2/bm_temp_DSS$plot_num_year)
  
  bm_temp_DSS[condition_DSS] <- 
    lapply(bm_temp_DSS[condition], function(x) (x*bm_temp_DSS$weight_DSS))
  
  
  bm_temp_WMA <- bm_temp_DSS %>% 
    group_by(CYCLE, INVYR, !!!grpby, !!!grpby2) %>% 
    summarise(volume_m3_ha = sum(w_volume_m3_ha, na.rm=TRUE),
              var_volume_m3_ha = sum(var_volume_m3_ha, na.rm=TRUE),
              biomass_ton_ha = sum(w_biomass_ton_ha, na.rm=TRUE),
              var_biomass_ton_ha = sum(var_biomass_ton_ha, na.rm=TRUE),
              AG_biomass_ton_ha = sum(w_AG_biomass_ton_ha, na.rm=TRUE),
              var_AG_biomass_ton_ha = sum(var_AG_biomass_ton_ha, na.rm=TRUE),
              carbon_stock_tC_ha = sum(w_carbon_stock_tC_ha, na.rm=TRUE),
              var_carbon_stock_tC_ha = sum(var_carbon_stock_tC_ha, na.rm=TRUE),
              co2_stock_tCO2_ha = sum(w_co2_stock_tCO2_ha, na.rm=TRUE),
              var_co2_stock_tCO2_ha = sum(var_co2_stock_tCO2_ha, na.rm=TRUE),.groups = 'drop')
  
  
  # var2_volume_m3_ha = sum(weight_DSS*(volume_m3_ha-w_volume_m3_ha)^2/plot_num_year),
  
  
  # Weighted Moving Average(to combine annual inventory field data)
  weight_WMA <- full_join(weight_year, weight_grpby, by =c(as.character(unlist(lapply(grpby, quo_name)))))
  weight_WMA$weight_WMA <- weight_WMA$plot_num_year/weight_WMA$plot_num_all
  
  
  bm_temp_WMA <- full_join(bm_temp_WMA, weight_WMA, by =c("CYCLE","INVYR", as.character(unlist(lapply(grpby, quo_name)))))
  
  condition <- (names(bm_temp_WMA) %in% c("volume_m3_ha","biomass_ton_ha","AG_biomass_ton_ha","carbon_stock_tC_ha","co2_stock_tCO2_ha"))
  
  
  bm_temp_WMA[condition] <- 
    lapply(bm_temp_WMA[condition], function(x) (x*bm_temp_WMA$weight_WMA))
  
  
  bm <- bm_temp_WMA %>% 
    group_by(!!!grpby, !!!grpby2) %>% 
    summarise(volume_m3_ha = sum(volume_m3_ha, na.rm=TRUE),
              var_volume_m3_ha = sum(weight_WMA^2*var_volume_m3_ha, na.rm=TRUE),
              se_volume_m3_ha = sqrt(var_volume_m3_ha),
              rse_volume_m3_ha = se_volume_m3_ha/volume_m3_ha*100,
              biomass_ton_ha = sum(biomass_ton_ha, na.rm=TRUE),
              var_biomass_ton_ha = sum(weight_WMA^2*var_biomass_ton_ha, na.rm=TRUE),
              se_biomass_ton_ha = sqrt(var_biomass_ton_ha),
              rse_biomass_ton_ha = se_biomass_ton_ha/biomass_ton_ha*100,
              AG_biomass_ton_ha = sum(AG_biomass_ton_ha, na.rm=TRUE),
              var_AG_biomass_ton_ha = sum(weight_WMA^2*var_AG_biomass_ton_ha, na.rm=TRUE),
              se_AG_biomass_ton_ha = sqrt(var_AG_biomass_ton_ha),
              rse_AG_biomass_ton_ha = se_AG_biomass_ton_ha/AG_biomass_ton_ha*100,
              carbon_stock_tC_ha = sum(carbon_stock_tC_ha, na.rm=TRUE),
              var_carbon_stock_tC_ha = sum(weight_WMA^2*var_carbon_stock_tC_ha, na.rm=TRUE),
              se_carbon_stock_tC_ha = sqrt(var_carbon_stock_tC_ha),
              rse_carbon_stock_tC_ha = se_carbon_stock_tC_ha/carbon_stock_tC_ha*100,
              co2_stock_tCO2_ha = sum(co2_stock_tCO2_ha, na.rm=TRUE),
              var_co2_stock_tCO2_ha = sum(weight_WMA^2*var_co2_stock_tCO2_ha, na.rm=TRUE),
              se_co2_stock_tCO2_ha = sqrt(var_co2_stock_tCO2_ha),
              rse_co2_stock_tCO2_ha = se_co2_stock_tCO2_ha/co2_stock_tCO2_ha*100,.groups = 'drop')
  
  
  
  
  return(bm)
  
}


