## LERS
predict.LERS <- function(rules, data.test) {
  if(!inherits(rules, "RuleSetRST")) stop("The rule set does not an object from the \'RuleSetRST\' class")
  
  if(!inherits(data.test, "DecisionTable")) stop("Provided data should inherit from the \'DecisionTable\' class.")
  
  method = attr(rules, "method")
  if (!(method %in% c("indiscernibilityBasedRules", "CN2Rules", "MLEM2Rules", "AQRules"))) {
    stop("Unrecognized classification method")
  }
  
  # predict values
  predVec <- vector()
  
  for(ind.obj in 1:nrow(data.test)){
    judges <- vector()
    for(rule in rules){
      idxs <- rule$idx
      values <- rule$values
      judge <- TRUE
      for(ind.idx in 1:length(idxs)){
        # num 
        if(is.numeric(values[[ind.idx]])){
          if(data.test[ind.obj,][idxs[ind.idx]] > values[[ind.idx]][1]&
             data.test[ind.obj,][idxs[ind.idx]] < values[[ind.idx]][2]){ 
            judge <- TRUE
          }else{
            judge <- FALSE
            break
          }
        # nom  
        }else{
          if(data.test[ind.obj,][idxs[ind.idx]] == values[[ind.idx]][1]){
            judge <- TRUE
          }else{
            judge <- FALSE
            break
          }
        }
      }
      judges <- append(judges, judge)
    }
    
    # objにマッチするrule が 1つでもある
    estimatedClass <- NULL
    if(any(judges)){
      # マッチしたルールが1つだけのとき
      if(length(which(judges)) == 1){
        estimatedClass <- list.select(rules[which(judges)], consequent) %>% list.mapv(consequent)
      # マッチしたルールが2つ以上で同じクラスを推定しているとき
      }else if(length(which(judges)) > 1 & length(unique(list.select(rules[which(judges)], consequent))) == 1){
        estimatedClass <- unique(list.select(rules[which(judges)], consequent) %>% list.mapv(consequent))
      # マッチしたルールが2つ以上で別のクラスを推定しているとき
      }else if(length(which(judges)) > 1 & length(unique(list.select(rules[which(judges)], consequent))) > 1){
        support_D <- -1
        for(rule in rules[which(judges)]){
          strength <- length(rule$support)
          specificity <- length(rule$values)
          if((strength * specificity) > support_D){
            estimatedClass <- rule$consequent
          }
        }
      }else{
        stop("LERS doesn't estimate the decision class")
      }
    }
    # rule が objに1つもマッチしない場合は部分一致ルールによる推定
    else{
      p_support <- -1
      for(rule in rules){
        strength <- length(rule$support)
        specificity <- length(rule$values)
        matching_factor <- 0
        idxs <- rule$idx
        values <- rule$values
        for(ind.idx in 1:length(idxs)){
          # num 
          if(is.numeric(values[[ind.idx]])){
            if(data.test[ind.obj,][idxs[ind.idx]] > values[[ind.idx]][1]&
              data.test[ind.obj,][idxs[ind.idx]] < values[[ind.idx]][2]){ 
              matching_factor <- matching_factor + 1
            }
          # nom  
          }else{
            if(data.test[ind.obj,][idxs[ind.idx]] == values[[ind.idx]][1]){
              matching_factor <- matching_factor + 1
            }
          }
        }
        matching_factor <- matching_factor / length(idxs)
        if((matching_factor * strength * specificity) > p_support){
          estimatedClass <- rule$consequent
        }
      }
    }
    predVec <- append(predVec, estimatedClass)
  }
  return(predVec)
}