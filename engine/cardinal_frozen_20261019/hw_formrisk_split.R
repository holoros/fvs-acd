# Record-split of predicted hardwood form/risk using Smith Table A.9 distributions.
.a9 <- data.frame(
  sp=c("AB","PB","QA","RM","RO","SM","WA","YB","OH"),
  R1=c(42,423,352,1311,629,577,77,625,206), R2=c(52,168,91,1132,975,269,35,352,159),
  R3=c(124,32,26,370,87,144,14,149,49), R4=c(51,32,31,212,37,65,3,66,24),
  F1=c(133,293,316,1075,667,750,53,584,188), F2=c(59,221,134,534,589,166,58,248,162),
  F3=c(10,14,0,26,6,36,1,76,1), F4=c(34,6,1,13,0,5,0,49,2),
  F5=c(13,19,4,178,94,15,3,60,25), F6=c(6,23,4,51,119,26,2,25,34),
  F7=c(7,10,0,87,60,31,5,44,7), F8=c(7,69,41,1061,193,26,7,106,19), stringsAsFactors=FALSE)
HW_SPP <- .a9$sp[.a9$sp!="OH"]
.fc<-paste0("F",1:8); .rc<-paste0("R",1:4)
.pform<-as.matrix(.a9[,.fc]/rowSums(.a9[,.fc])); rownames(.pform)<-.a9$sp
.prisk<-as.matrix(.a9[,.rc]/rowSums(.a9[,.rc])); rownames(.prisk)<-.a9$sp
split_formrisk <- function(tree, prune=0.03) {
  is_hw <- toupper(tree$sp) %in% .a9$sp
  out<-list()
  pt<-tree[!is_hw,,drop=FALSE]
  if(nrow(pt)){ if(!"form"%in%names(pt)) pt$form<-NA_character_; if(!"risk"%in%names(pt)) pt$risk<-NA_character_; out[[1]]<-pt }
  hw<-tree[is_hw,,drop=FALSE]
  if(nrow(hw)){
    maxid<-suppressWarnings(max(tree$tree,na.rm=TRUE)); if(!is.finite(maxid)) maxid<-0
    subs<-list(); ctr<-0L
    for(r in seq_len(nrow(hw))){
      sp<-toupper(hw$sp[r]); key<-if(sp%in%HW_SPP) sp else "OH"
      J<-outer(.pform[key,], .prisk[key,]); J[J<prune]<-0
      if(sum(J)==0) J<-outer(.pform[key,], .prisk[key,]); J<-J/sum(J)
      idx<-which(J>0, arr.ind=TRUE)
      for(q in seq_len(nrow(idx))){
        ctr<-ctr+1L; row<-hw[r,,drop=FALSE]
        row$expf<-hw$expf[r]*J[idx[q,1],idx[q,2]]
        row$form<-paste0("F",idx[q,1]); row$risk<-paste0("R",idx[q,2]); row$tree<-maxid+ctr
        subs[[length(subs)+1]]<-row } }
    if(length(subs)) out[[length(out)+1]]<-do.call(rbind,subs) }
  res<-do.call(rbind,out); rownames(res)<-NULL; res }
if(!exists(".SPLIT_QUIET")){
  td<-data.frame(plot=1L,tree=1:4,sp=c("RM","RO","BF","WA"),dbh=c(20,35,25,40),ht=c(18,22,20,24),expf=c(50,40,60,30),stringsAsFactors=FALSE)
  s<-split_formrisk(td,prune=0.03)
  cat("input rows:",nrow(td)," -> split rows:",nrow(s),"\n")
  cat("stems conserved by species:\n"); print(aggregate(expf~sp,data=s,sum))
  cat("\nRM sub-records:\n"); print(s[toupper(s$sp)=="RM",c("sp","expf","form","risk")],row.names=FALSE)
  cat("BF passthrough:\n"); print(s[toupper(s$sp)=="BF",c("sp","expf","form","risk")],row.names=FALSE) }
