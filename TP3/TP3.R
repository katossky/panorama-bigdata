# Va contenir les données inférieures à la médiane courante
min_heap <- c()
max_min_heap <- NA
#Va contenir les données supérieures à la médiane courante
max_heap <-c()
min_max_heap <- NA


#Combien d'élément
size_min_heap <- 0
size_max_heap <- 0

update_mediane <- function(new_element, min_heap, max_heap ) {
  if (new_element <= max_min_heap) {
    # On est plus petit que le max des min alors on va dans les min
    append(min_heap, new_element)
    size_min_heap <<- size_min_heap + 1
  } else {
    append(max_heap, new_element)
    size_max_heap <<- size_max_heap + 1
  }
  
  #Si différence des tailles > 1, besoin d'un rééquilibrage
  if(size_min_heap - size_max_heap > 1){
    #Il manque des éléments dans max_heap
    
    
  }
}