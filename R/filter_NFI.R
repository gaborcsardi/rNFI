#' read_NFI()
#'
#' read_NFI() is a function that reads Korean National Forest Inventory.
#' Loads the annual National Forest Inventory file downloaded from "https://kfss.forest.go.kr/stat/ " from the local computer.
#' And change the data to an easy-to-analyze format and perform integrity verification.
#' @param data : data
#' @param expr_texts : a logical value indicating whether to load a standing tree survey table.
#' @param hier : a logical value indicating whether to load a standing tree survey table.
#' @return dataframe
#' @export


filter_NFI <- function(data, expr_texts, hier=T){
  
  matches <- regmatches(expr_texts, gregexpr("\\w+(?=\\$)", expr_texts, perl=TRUE))
  matches_chek <- sapply(matches, function(x) length(unique(x)) == 1)
  
  if (any(matches_chek == FALSE)) {
    
    stop(paste0("param 'expr_texts' requires separate expressions for each item in ", deparse(substitute(data)), ". For example: c('plot$LAND_USECD == 1', 'tree$WDY_PLNTS_TYP_CD == 1 & tree$SUBPTYP ==0')"))
    
    
  }

  
  for(expr_text in expr_texts){
    
    modified_text <- gsub("\\w+\\$", "", expr_text)
    modified_expressions <- rlang::parse_exprs(modified_text)
    
    name <- regmatches(expr_text, gregexpr("\\w+(?=\\$)", expr_text, perl=TRUE))[[1]][1]

    if(grepl("plot\\$", expr_text)){
      
      
      filter_plot <- data$plot %>%
        filter(!!!modified_expressions)
      
      plot_all <- unique(filter_plot$SUB_PLOT)
      
      results <- lapply(data[-1], function(df) {
        df_filtered <- df[df$SUB_PLOT %in% plot_all, ]
        return(df_filtered)
      })
      
      data <- c(list(plot = filter_plot), results)
      
    }else{
      
      
      if(hier){
        
        data[[name]] <- data[[name]] %>%
          filter(!!!modified_expressions)
        
      }else{
        
        filter_plot <- data[[name]] %>%
          filter(!!!modified_expressions)
        
        
        plot_all <- unique(filter_plot$SUB_PLOT)
        
        results <- lapply(data, function(df) {
          df_filtered <- df[df$SUB_PLOT %in% plot_all, ]
          return(df_filtered)
        })
        
        results[[name]] <- results[[name]] %>% 
          filter(!!!modified_expressions)
        
        
        data <- results
        
      }
    }
  }
    
  return(data)
  
}

