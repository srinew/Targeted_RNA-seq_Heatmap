server <- function(input, output) {
  plotInput <- function(){
    inFile <- input$file
    file1 <- read.csv(inFile$datapath, header = T)
    # file1 <- read.csv("/Users/srnallan/Desktop/Heatmap Shiny/test shiny.csv", header = T)
    mainfile <- as.data.frame(file1[4:nrow(file1), c(1,4:ncol(file1))])
    rownames(mainfile) <- mainfile[,1]
    mainfile <- mainfile[,-1]
    
    for( i in 1:ncol(mainfile)){
      mainfile[,i] <- as.character(mainfile[,i])
      mainfile[,i] <- as.integer(mainfile[,i])
    }
    mainfile <- as.matrix(mainfile)
    
    colanno <- data.frame(t(file1[2:3, 4:ncol(file1)]))
    colnames(colanno)[[1]] <- as.character(file1[2,3])
    colnames(colanno)[[2]] <- as.character(file1[3,3])
    
    file2 <- data.frame(t(file1[1,4:ncol(file1)]))
    file2$Sample <- rownames(file2)
    file2 <- file2[,c(2,1)]
    colnames(file2) <- c("Sample", "Total.reads")
    file2$Lib.size <- colSums(mainfile)
    file2$Total.reads <- as.character(file2$Total.reads)
    file2$Total.reads <- as.integer(file2$Total.reads)
    file2$Percentage.reads.mapped <- file2$Lib.size/file2$Total.reads
    
    file3 <- file1[4:nrow(file1), 1:3]
    rownames(file3) <- file3[,1]
    
    # file1 <- file1[-(1:3),-(2:3)]
    # rownames(file1) <- file1[,1]
    # file1 <- file1[,-1]
    
    if(all(colnames(mainfile) != rownames(file2))) return("Please check the sample names")
    if(all(rownames(mainfile) != rownames(file3))) return("Please check the sample names")
    
    # Create the expression set
    pd <- new("AnnotatedDataFrame", data = file2, varMetadata = data.frame(cbind(colnames(file2), rep("stuff", length(colnames(file2))))))
    fd <- new("AnnotatedDataFrame", data = file3, varMetadata = data.frame(cbind(colnames(file3), rep("stuff", length(colnames(file3))))))
    
    hdat.eset <- new("ExpressionSet", phenoData = pd, exprs = as.matrix(mainfile),featureData = fd)
    Counts <- exprs(hdat.eset)
    dim(Counts)
    
    tmr <- 500000
    e2e <- 0.6
    
    hdat.eset <- hdat.eset[,hdat.eset$Lib.size > tmr & hdat.eset$Percentage.reads.mapped > e2e]
    hdat.eset  #9 samples 137 genes
    
    #### Create DGEList
    y   <- DGEList(count = exprs(hdat.eset), genes= file3, remove.zeros=T, lib.size = colSums(exprs(hdat.eset)))
    # tapply(y$samples$lib.siz, INDEX= y$samples$group, summary)
    # vv <- y$samples[,1:2]
    # y$counts <- y$counts+10
    
    ######## Filtering Removing absolute zero counts
    # y <- y[!y[[3]][,3]=="Fusion",]
    selr <- rowSums(cpm(y)>1) >= ncol(y) #Filter low expression tags: keep genes with at least 5 CPM in at least X, where X is the number of samples in the smallest group
    selc <- colSums(y$counts)>=500000  #Filter samples based on library size
    
    y <- y[selr,selc, keep.lib.sizes=F]
    dim(y)
    # Traditional EdgeR library normalization
    y$samples$lib.size <- colSums(y$counts)
    y.reg <- calcNormFactors(y, method = c("TMM"))
    
    # Custom Normalization for targeted gene panel
    housekeeping <- as.character(y[[3]][y[[3]][,3]=="Housekeeping",1])
    counts <- as.matrix(y$counts)
    counts <- t(counts)
    
    NormalizeMxRNASeq <- function(counts,housekeeping) {
      stopifnot(class(counts)=="matrix")
      stopifnot(class(housekeeping)=="character")
      stopifnot(housekeeping %in% colnames(counts))
      
      log2Counts <- log2(counts+1)
      log2Housekeeping <- log2Counts[,housekeeping]
      housekeepingMeans <- apply(log2Housekeeping,1,mean)
      log2Normalized <- log2Counts-housekeepingMeans
      log2Normalized <- t(log2Normalized)
      return(log2Normalized)
    }
    
    y.new <- NormalizeMxRNASeq(counts, housekeeping)
    
    y.new.med <- rowMedians(y.new)
    y.new.1 <- y.new-y.new.med
    HKnorm <- data.frame(y.new.1)
    HKnorm$Comparison <- "Housekeeping normalization"
    
    ################### Heatmap norm no DE Trad edgeR CPM
    e <- cpm(y.reg, normalized.lib.sizes = T, prior.count = 0.25, log=TRUE)
    med.e <- rowMedians(e)
    e.med <- e-med.e
    edgernorm <- data.frame(e.med)
    edgernorm$Comparison <- "edgeR TMM normalization"
    
    df <- data.frame(rbind(HKnorm, edgernorm))
    # df.x <- as.matrix(droplevels(df[df$Comparison %in% c("Housekeeping normalization"), c(1:(ncol(df)-1))]))
    df.x <- as.matrix(droplevels(df[df$Comparison %in% input$select_class, c(1:(ncol(df)-1))]))
    rownames(df.x) <- rownames(y$genes)
    
    rowanno <- data.frame(y[[3]][,c(2,3)])
    rowanno.1 <- data.frame(rowanno[,2])
    colnames(rowanno.1)[[1]] <- "Function"
    rownames(rowanno.1) <- rownames(rowanno)
    
    colanno <- colanno[rownames(colanno) %in% rownames(y[[2]]),]
    if(all(rownames(y[[2]]) != rownames(colanno))) return("Please check the sample row names")
    colanno[,1] <- factor(colanno[,1])
    colanno[,2] <- factor(colanno[,2])
    
    colors.hm <- colorRampPalette(c("blue","white","red"))(100)
    heat.brks <- seq(from=-max(abs(df.x)), to=max(abs(df.x)),length= 101)
    
    # pheatmap(e.med ,color=colors.hm, labels_row = y$genes$Gene,fontsize_row = 5,
    #          # cluster_cols = ifelse(input$select_class_1=="Yes", T, F),
    #          annotation_row = rowanno.1)
    
    pheatmap(df.x ,color=colors.hm, breaks=heat.brks, labels_row = y[[3]][,2], main=paste0(input$select_class),fontsize_row = 10,
             cluster_cols = ifelse(input$select_class_1=="Yes", T, F), annotation_row = rowanno.1, annotation_col = colanno,
             clustering_method = input$select_class_2)
                  
  }

  output$distPlot <- renderPlot({
    # input$file1 will be NULL initially. After the user selects
    # and uploads a file, it will be a data frame with 'name',
    # 'size', 'type', and 'datapath' columns. The 'datapath'
    # column will contain the local filenames where the data can
    # be found.
    inFile <- input$file
    if (is.null(inFile))
      return(NULL)
    # read.csv(inFile$datapath, header = input$header)
    plotInput()

  },height= 950)
  
  output$export <- downloadHandler(
    filename = function() { paste(gsub(".csv","",input$file), " Clustering- ", input$select_class_2,' normalized heatmap.pdf', sep='') },
    content = function(file) {
      ggsave(file, plot = plotInput(), device = "pdf", width=20,height = 20)
    }
  )
}

# Run the application 
shinyApp(ui = ui, server = server)
