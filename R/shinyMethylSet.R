#' @export
setClass("shinyMethylSet", 
         representation(sampleNames = "character",
                        phenotype = "data.frame",
                        mQuantiles ="list",
                        betaQuantiles = "list",
                        methQuantiles = "list",
                        unmethQuantiles = "list",
                        cnQuantiles = "list",
                        greenControls = "list",
                        redControls = "list",
                        pca = "list",
                        originObject = "character",
                        array = "character")
)



#' @importFrom BiocGenerics rownames
setValidity("shinyMethylSet", function(object){
    msg <- NULL
    
    phenotype <- object@phenotype
    methQuantiles <- object@methQuantiles
    unmethQuantiles <- object@unmethQuantiles
    betaQuantiles <- object@betaQuantiles
    mQuantiles <- object@mQuantiles
    cnQuantiles <- object@cnQuantiles 
    sampleNames <- object@sampleNames
    greenControls <- object@greenControls
    redControls   <- object@redControls
    pca <- object@pca
    n <- length(sampleNames)
    array <- object@array

    # Validity for phenotype
    if (!is.null(phenotype)){
        if (n != nrow(phenotype)){
            msg <- "Phenotype data.frame must have the same length as the sampleNames"
        }

        if (sum(!(sampleNames %in% rownames(phenotype)))>0){
            msg <- "rownames of the phenotype data.frame must correspond to the sampleNames"
        }
    }

    # Validity for the quantiles list
    quantile.names <- c("IGrn", "IRed", "II", "X", "Y")
    if (!all.equal(names(mQuantiles),quantile.names) | !all.equal(names(betaQuantiles),quantile.names) |
      !all.equal(names(cnQuantiles),quantile.names)){
      msg <- "Names of mQuantiles, betaQuantiles and cnQuantiles must be c(\"IGrn\", \"IRed\", \"II\", \"X\", \"Y\")"
    }

    if (object@originObject != "GenomicRatioSet"){
      if (!all.equal(names(methQuantiles),quantile.names) | !all.equal(names(unmethQuantiles),quantile.names)){
         msg <- "Names of methQuantiles and unmethQuantiles must be c(\"IGrn\", \"IRed\", \"II\", \"X\", \"Y\")"
      }
    }

    dim.quantile.validity <- function(quantiles, n.col, quantiles.name){
      n.row.vector <- as.numeric(unlist(lapply(quantiles, FUN=nrow)))
      if (length(unique(n.row.vector)) != 1){
        msg <- paste0("All matrices of the ",quantiles.name, " quantiles list must have the same number of rows")
        return(msg)
      }
      n.col.vector <- as.numeric(unlist(lapply(quantiles, FUN=ncol)))
      if (length(unique(n.col.vector)) != 1){
        msg <- paste0("All matrices of the ",quantiles.name, " quantiles list must have the same number of cols")
        return(msg)
      } else {
        if (unique(n.col.vector) != n.col){
          msg <- paste0("All matrices of the ",quantiles.name, 
            " quantiles list must have the number of columns equal to the length of the sampleNames")
          return(msg)
        }
      }

    }

    msg <- dim.quantile.validity(mQuantiles, n.col = n, "mQuantiles")
    msg <- dim.quantile.validity(betaQuantiles, n.col = n, "betaQuantiles")
    msg <- dim.quantile.validity(cnQuantiles, n.col = n,  "cnQuantiles")


    if (object@originObject != "GenomicRatioSet"){
        msg <- dim.quantile.validity(methQuantiles, n.col=n, "methQuantiles")
        msg <- dim.quantile.validity(unmethQuantiles, n.col=n, "unmethQuantiles")
    }

    # Validity for controls:
    control.names <- c("BISULFITE CONVERSION I",
                       "BISULFITE CONVERSION II",
                       "EXTENSION",
                       "HYBRIDIZATION",
                       "NEGATIVE",
                       "NON-POLYMORPHIC",
                       "NORM_A",
                       "NORM_C",
                       "NORM_G",
                       "NORM_T",
                       "SPECIFICITY I",
                       "SPECIFICITY II",
                       "TARGET REMOVAL",
                       "STAINING")


    if (object@originObject != "GenomicRatioSet"){
        if (length(greenControls) != 14 | length(redControls) != 14){
            msg <- "The greenControls and redControls lists must be of length 14"
        }

        if (!all.equal(control.names,names(greenControls)) | !all.equal(control.names,names(redControls))){
            msg <- "Green controls and red controls names don't match the control probes names defined in shinyMethyl"
        }

       # Validity for PCA

        if (!all.equal(names(pca), c("scores","percs"))){
            msg <- "Names of the pca list must be c(\"scores\",\"percs\")"
        }
        scores <- pca$scores
        percs  <- pca$percs

        if (ncol(scores) !=n | nrow(scores) !=n){
            msg <- "nrow(pca$scores) and ncol(pca$scores) must be equal to the length of sampleNames"
        }

        if (length(percs)!=n){
            msg <- "Length of pca$percs must be equal to the length of sampleNames"
        }

        if (sum(!(rownames(scores) %in% sampleNames))!=0) {
            msg <- "Rownames of pca$scores must be the sampleNames"
        }
    }

    if (is.null(msg)) TRUE else msg
}) 


#' @export
shinyMethylSet <- function(sampleNames = new("character"), 
                           phenotype = new("data.frame"),  
                           mQuantiles = new(vector("list",5)),
                           betaQuantiles = new(vector("list",5)),
                           methQuantiles = new(vector("list",5)),
                           unmethQuantiles = new(vector("list",5)),
                           cnQuantiles = new(vector("list",5)),
                           greenControls = new(vector("list",12)),
                           redControls = new(vector("list",12)),
                           pca = new("list"),
                           originObject = new("character"),
                           array = new("character")
){
    set <- new("shinyMethylSet", 
               sampleNames = sampleNames,
               phenotype = phenotype,
               mQuantiles = mQuantiles,
               betaQuantiles = betaQuantiles,
               methQuantiles = methQuantiles,
               unmethQuantiles = unmethQuantiles,
               cnQuantiles = cnQuantiles,
               greenControls = greenControls,
               redControls = redControls,
               pca = pca,
               originObject = originObject, 
               array = array)
    return(set)
}


#' @export
orderByName <- function(object){
    stopifnot(is(object, "shinyMethylSet"))
    sampleNames    <- object@sampleNames
    slideNames     <- substr(sampleNames,1,10)
    arrayNames     <- substr(sampleNames,12,17)
    plateNames     <- substr(sampleNames,1,6)
    
    designInfo <- data.frame(sampleNames = sampleNames,
                             slideNames  = slideNames,
                             arrayNames  = arrayNames,
                             plateNames  = plateNames)
    designInfo <- designInfo[order(plateNames,slideNames,arrayNames), ]
    o <- match(designInfo$sampleNames, sampleNames)
    for (i in 1:length(object@betaQuantiles)){
        object@betaQuantiles[[i]] <- object@betaQuantiles[[i]][,o]
    }
    for (i in 1:length(object@mQuantiles)){
        object@mQuantiles[[i]] <- object@mQuantiles[[i]][,o]
    }

    for (i in seq_len(length(object@methQuantiles))){
        object@methQuantiles[[i]] <- object@methQuantiles[[i]][,o]
    }
    for (i in seq_len(length(object@unmethQuantiles))){
        object@unmethQuantiles[[i]] <- object@unmethQuantiles[[i]][,o]
    }
    for (i in seq_len(length(object@cnQuantiles))){
        object@cnQuantiles[[i]] <- object@cnQuantiles[[i]][,o]
    }
    
    object@sampleNames <- object@sampleNames[o]
    object@pca$scores  <- object@pca$scores[o,]
    object@pca$percs  <- object@pca$percs[o]
    
    object@phenotype <- object@phenotype[o,]
    
    for (i in seq_len(length(object@greenControls))){
        object@greenControls[[i]] <- object@greenControls[[i]][,o]
        object@redControls[[i]]   <- object@redControls[[i]][,o]
    }
    
    return(object)
}


#' @export
setMethod("show",signature(object="shinyMethylSet"),
          function(object){
              cat(" Object: ",class(object),"\n")
              n <- length(object@sampleNames)
              cat(" Number of samples: ",n, "\n")
              nCovs <- ncol(object@phenotype)
              cat(" Phenotype: ",nCovs, "covariates \n")
              cat(" Origin object: ", object@originObject, "\n")
              cat(" Array: ", object@array, "\n")
})


#' @importFrom minfi getBeta
#' @export
setMethod("getBeta",signature(object="shinyMethylSet"),
          function(object){
    object@betaQuantiles
})

#' @importFrom Biobase pData
#' @export
setMethod("pData",signature(object="shinyMethylSet"),
          function(object){
    object@phenotype
})


#' @importFrom minfi getMeth
#' @export
setMethod("getMeth",signature(object="shinyMethylSet"),
          function(object){
    object@methQuantiles
})

#' @importFrom minfi getUnmeth
#' @export
setMethod("getUnmeth",signature(object="shinyMethylSet"),
          function(object){
    object@unmethQuantiles
})

#' @importFrom minfi getM
#' @export
setMethod("getM",signature(object="shinyMethylSet"),
          function(object){
    object@mQuantiles
})

#' @importFrom minfi getCN
#' @export
setMethod("getCN",signature(object="shinyMethylSet"),
          function(object){
    object@cnQuantiles
})



#' @export
getGreenControls <- function(shinyMethylSet){
      shinyMethylSet@greenControls
}

#' @export
getRedControls <- function(shinyMethylSet){
      shinyMethylSet@redControls
}


#' @export
getPCA <- function(shinyMethylSet){
    shinyMethylSet@pca
}



#' @importFrom Biobase sampleNames
#' @export
setMethod("sampleNames",signature(object="shinyMethylSet"),
          function(object){
    object@sampleNames
})



.checkSex <- function(sex) {
    if(! (is.character(sex) && !any(is.na(sex)) && all(sex %in% c("M", "F"))))
        stop("'sex' seems wrong (needs to be a character, without missing values, of 'M' and 'F'")
    return(sex)
}


#' @importFrom BiocGenerics combine
#' @export
setMethod("combine",
          signature(x="shinyMethylSet",
                    y="shinyMethylSet"),
          function(x,y){
    .shinyCombine(x,y)
})


## Function to combine two shinyMethylSet.
.shinyCombine <- function(shinyMethylSet1,
                          shinyMethylSet2
){
    if (!is(shinyMethylSet1, "shinyMethylSet")){
        stop("First object must be a shinyMethylSet.")
    }
    if (!is(shinyMethylSet2, "shinyMethylSet")){
        stop("Second object must be a shinyMethylSet.")
    }

    c.shinyMethylSet <- new("shinyMethylSet")
    c.shinyMethylSet@sampleNames <- c(shinyMethylSet1@sampleNames,
                                      shinyMethylSet2@sampleNames)
    c.shinyMethylSet@phenotype   <- rbind(shinyMethylSet1@phenotype,
                                          shinyMethylSet2@phenotype)
    
    ## Merging the quantile matrices
    for (i in 1:5){
        c.shinyMethylSet@mQuantiles[[i]] <- cbind(shinyMethylSet1@mQuantiles[[i]],
                                                  shinyMethylSet2@mQuantiles[[i]])
        c.shinyMethylSet@betaQuantiles[[i]] <- cbind(shinyMethylSet1@betaQuantiles[[i]],
                                                     shinyMethylSet2@betaQuantiles[[i]])
        c.shinyMethylSet@methQuantiles[[i]] <- cbind(shinyMethylSet1@methQuantiles[[i]],
                                                     shinyMethylSet2@methQuantiles[[i]])
        c.shinyMethylSet@unmethQuantiles[[i]] <- cbind(shinyMethylSet1@unmethQuantiles[[i]],
                                                       shinyMethylSet2@unmethQuantiles[[i]])
        c.shinyMethylSet@cnQuantiles[[i]] <- cbind(shinyMethylSet1@cnQuantiles[[i]],
                                                   shinyMethylSet2@cnQuantiles[[i]])
    }
    names(c.shinyMethylSet@mQuantiles)      <- names(shinyMethylSet1@mQuantiles)
    names(c.shinyMethylSet@betaQuantiles)   <- names(shinyMethylSet1@mQuantiles)
    names(c.shinyMethylSet@methQuantiles)   <- names(shinyMethylSet1@mQuantiles)
    names(c.shinyMethylSet@unmethQuantiles) <- names(shinyMethylSet1@mQuantiles)
    names(c.shinyMethylSet@cnQuantiles)     <- names(shinyMethylSet1@mQuantiles)
    
    ## Merging the control matrices
    for (i in 1:14){
        c.shinyMethylSet@greenControls[[i]] <- cbind(shinyMethylSet1@greenControls[[i]],
                                                     shinyMethylSet2@greenControls[[i]])
        c.shinyMethylSet@redControls[[i]] <- cbind(shinyMethylSet1@redControls[[i]],
                                                   shinyMethylSet2@redControls[[i]])
    }
    names(c.shinyMethylSet@greenControls) <- names(shinyMethylSet1@greenControls)
    names(c.shinyMethylSet@redControls)   <- names(shinyMethylSet1@redControls)
        
    c.shinyMethylSet@pca <- list() # PCA information is lost. 
    c.shinyMethylSet@originObject <- "Merging"
    return(c.shinyMethylSet)
}

