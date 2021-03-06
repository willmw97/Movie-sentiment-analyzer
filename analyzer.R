  library(syuzhet)
library(stringr)
library(tm)
library(wordcloud)
library(ggplot2)
library(xtable)
library(dplyr)

###--------- Choices -------------------------------
# Action movies:
#   Rambo
#   Predator
#   Die Hard
#   Machete
#   The last dragon
#   
# Chick Flicks:
#   When Harry Met Sally
#   Bridget Jones
#   Breakfast at Tiffany's
#   Casablanca
#   Notting Hill

###--------- Load in -------------------------------
pathF <- "./Movie scripts/"
pathO <- "./web/Output/"
filesList = list.files(pathF)

## Initialize stuff
generalStats <- data.frame(0,0,0)
names(generalStats) <- c("Words","Length","Rate")
iii<-0
naam.list <-NULL

## ... and Goooooo!
for (i in 1:length(filesList)){
  
  ###--------------- CALCULATE STUFF ------------
  naam <- gsub(".txt","",filesList[i])
  naam.list <-rbind(naam.list,naam)
  iii <- iii+1 
  ## fix name for tifanie
  if (naam=="Breakfast at Tiffanys") naam <- "Breakfast at Tiffany's"
  
  ## Read in
  sentences.df <- get_sentences(get_text_as_string(
    paste(pathF,filesList[i],sep="/")))
    
  ## Sentiment analysis 
  feelings.df <- get_sentiment(sentences.df, method="bing")
  
  
  ###--------------- PLOT STUFF ------------
  ###-------- Basic stats
  Werds <- str_count(get_text_as_string(
    paste(pathF,filesList[i],sep="/"))," ")
  Sentences <- length(sentences.df)
#   Length <- ggplot2::movies$length[naam==ggplot2::movies$title]
## hell with this, neither this nor grep work.. movie names are too weird
## what with the ellipsis and quotes and subtext... forget it! Cheat mode:
  moobieLengths=c(115,97,102,131,107,124,107,92,109,96)
  Length=moobieLengths[i]
  WordRate <- Werds/Length
  generalStats[iii,] <- data.frame(Sentences,Length,WordRate)
  

  ###--------- Wordclouds -------------------------------
  ## hrmmmm.... don't remove stopwords
  # ou <- tm_map(Corpus(VectorSource(sentences.df)), removeWords, stopwords("SMART"))
  ou <- sentences.df
  png(width=250, height=250, file=paste(pathO,naam,"-wordcloud.png", sep=""))
    wordcloud(ou, scale=c(3,0.5), max.words=50, colors=brewer.pal(8,"Set2"))
  dev.off()
  
  ## ---- Plot Line -----------------------------------------------------
  percent_vals <- get_percentage_values(feelings.df,bins=moobieLengths[i])
  png(width=725, height=725, file=paste(pathO,naam,"-perc.png", sep=""))
  plot(
    percent_vals, 
    type="l", 
    ylim=c(-1.1,1.1),
    main="Plot trajectory by minute", 
    xlab = "Narrative Time (min)", 
    ylab= "Emotional Valence", 
    col="red"
  )
  abline(h=0,col="black")
   dev.off()
  
  ## ---- Transformed -----------------------------------------------------
  ft_values <- get_transformed_values(
    feelings.df, 
    low_pass_size = 3, 
    x_reverse_len = moobieLengths[i],
    scale_vals = TRUE,
    scale_range = FALSE
  )
  png(width=725, height=725, file=paste(pathO,naam,"-tran.png", sep=""))
  plot(
    ft_values, 
    type ="h", 
    main =" using Transformed Values", 
    xlab = "Narrative Time (min)s", 
    ylab = "Emotional Valence", 
    col = "red"
  )
  dev.off()
  
  ## ---- Feelings-------------------------------------------------------
  
  nrc_data <- get_nrc_sentiment(sentences.df)
  colors <- c("red", "blue", "khaki", "yellow",
              "purple","black","orange", "white")
  feelings.v = colSums(prop.table(nrc_data[, 1:8]))
  colors <- colors[order(feelings.v)]
  feelings.v <- feelings.v[order(feelings.v)]
  feelings.v <- feelings.v *100
  fff = data.frame(feelings=rownames(data.frame(feelings.v)),
                   value=as.vector(feelings.v))
    
  ggplot(fff,aes(x=feelings,y=value)) +
    geom_bar(stat="identity", color="black",
             fill=c("red", "blue", "khaki", "yellow",
                    "purple","black","orange", "white")) + 
    coord_flip()  + theme(axis.text = element_text(size = rel(1.5))) + 
    ggtitle(paste("Prevailing emotions for",naam))+ylab("%")
    
    ggsave(filename=paste(pathO,naam,"-feelings.png", sep=""))

  ####---------- Sentence Drawings -------------------
  all <- data.frame(sentance=sentences.df, sentiment=feelings.df,length=nchar(sentences.df))
  df<- data.frame(x=0,y=0)
  a <- 0
  
  for (ii in 2:nrow(all)){
    if (a==4) a=0
    if (a==0){
      df[ii,1]=df[ii-1,1]+all$length[ii]
      df[ii,2]=df[ii-1,2]
    } else if (a==1){
      df[ii,1]=df[ii-1,1]
      df[ii,2]=df[ii-1,2]+all$length[ii]
    } else if (a==2){
      df[ii,1]=df[ii-1,1]-all$length[ii]
      df[ii,2]=df[ii-1,2]
    } else if (a==3){
      df[ii,1]=df[ii-1,1]
      df[ii,2]=df[ii-1,2]-all$length[ii]
    }
      a=a+1
  }
  
  ####### -------- Add color
  ### Try fancie coloring if you want... but it don't really work.
  # x=c(0,0,3,4)
  # y=C(0,1,1,4)
  # z=c("red","grey", "blue", "red")
  
  ## Select colors
  # library(choosecolor)
  # MyPal <- palette.picker(n=2)
  # color.df <- data.frame(val=sort(unique(feelings.df)),
  #                        color=Mypal(length(unique(feelings.df))),stringsAsFactors =FALSE)
  # color.df[color.df$val==0,2] <- "grey"
  # for (i in 1:nrow(all)){
  #   all$colors[i] <- as.character(color.df[match(all$sentiment[i],color.df$val),2])
  # }
  
  all$colors <- all$sentiment
  all$colors <- gsub("-.+","red",all$colors)
  all$colors <- gsub("0","grey",all$colors)
  all$colors <- gsub("\\d+","green",all$colors)
  
  ## construct final df
  df <- data.frame(x=df$x,y=df$y,col=all$colors)

  ## plot!

  xlim=c(min(df$x)-5,max(df$x)+5)
  ylim=c(min(df$y)-5,max(df$y)+5)
  png(width=725, height=725, file=paste(pathO,naam,"-sDrawing.png", sep=""))  
    plot(xlim,ylim,type="n",xlab="",ylab="",yaxt="n",xaxt="n")
    for (j in 1:nrow(df)){
      lines(df[c(j,j+1),1],df[c(j,j+1),2],col=as.character(df[j+1,3]))
    }
    points(0,0,pch=20)    
    points(x=df[nrow(df),1],y=df[nrow(df),2],pch=20, col="blue")
  dev.off()


  ###------------ Emo Mo --------------------
  ## take into consideration the prior emotional valence.
  
  df.momentum<- data.frame(x=0,y=0)
  
  # For each sentence, add to plot:
  #   TO X: 5
  #   TO Y: sentence length * Sentiment (Or just the sentiment)
  # Yeah, I miss the last sentance... oh boohoo... ;)
  for (ii in 2:nrow(all)){
    df.momentum[ii,1] <- df.momentum[ii-1,1] + 5
    df.momentum[ii,2] <- df.momentum[ii-1,2] + 
#       all$length[ii] * all$sentiment[ii]  
      all$sentiment[ii] # or each line is just the sentiment
  }
  
  ## construct final df
  df.mom <- data.frame(x=df.momentum$x,y=df.momentum$y,col=all$colors)
  
  ## plot!
  xlim=c(min(df.mom$x)-5,max(df.mom$x)+5)
  ylim=c(min(df.mom$y)-5,max(df.mom$y)+5)
  png(width=725, height=725, file=paste(pathO,naam,"-emoMo.png", sep=""))  
  plot(xlim,ylim,type="n",ylab="Emotional valence",xlab="Sentence number")
  for (j in 1:nrow(df.mom)){
    lines(df.mom[c(j,j+1),1],df.mom[c(j,j+1),2],col=as.character(df.mom[j+1,3]))
  }
  points(0,0,pch=20)
  points(x=df.mom[nrow(df.mom),1],y=df.mom[nrow(df.mom),2],pch=20, col="blue")
  dev.off()

  ##---- Overall general plot -----
  if (iii==10){
    generalStats$gender <- c("female","female","female","male","male","female","male","male","male","female")
    generalStats$Name <- naam.list
    generalStats <- cbind(ID= 1:10,
                          generalStats,
                          s="Each movie")
    generalStats %>%
      group_by(gender)%>%
      summarize(mean(Words),mean(Length),mean(Rate)) -> sumG
    sumG <- cbind(ID=c(11,12),
                  sumG[,c(2:4)],
                  gender=c("female","male"),
                  name=c("Female mean","Male mean"),
                  s="Gender overall")    
    names(sumG) <- names(generalStats)
    boff <- bind_rows(generalStats,sumG)
    ggplot(boff,aes(x=Words,shape =s,y=Length,size=Rate,
                            label=Name,color=factor(gender))) +
      geom_point() + 
      labs(title="Movie length vs # words",
           x="Number of words (used spaces as proxy)",
           y="Movie length (min)",
           color="COLOR= Movie genre",
           size="SIZE = Speech rate (words/min)",
           shape="SHAPE = each movie or aggregate") +
      geom_text(aes(label=Name),vjust=-.5)+ 
      scale_size(range=c(2,7))
    ggsave(filename=paste(pathO,"Movie pace.png", sep=""))
  }
} 

#-------------------------------- loop end

