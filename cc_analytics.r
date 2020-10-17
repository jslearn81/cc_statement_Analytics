require(tabulizer)
require(data.table)
require(openxlsx)
require(readxl)
require(ggplot2)

extract_dbs_pdf_cc_table<-function(dbs_pdf,table_extraction=F){
  #Will not be able to extract outstanding balance
  #currency ?
  
  if (!table_extraction){
    temp<-tabulizer::extract_text(dbs_pdf)
    temp<-str_extract_all(temp,"[0-9][0-9] [A-Z]{3} .*? ((.|\\n|\\r)*?)[0-9]([0-9|,]?)\\.[0-9]{2}[\\s](CR)?")
    
    dates<-str_extract_all(as.character(temp[[1]]),"([0-9][0-9] [A-Z]{3})",simplify = T)
    amtx<-str_extract_all(as.character(temp[[1]]),"[0-9]([0-9|,]*)\\.[0-9]{2}[\\s](CR)?",simplify = T)
    item<-substr(temp[[1]],7,10000)
    
    
    tbl<-data.table(
      date=as.Date(dates,"%d %b"),
      acct="dbs",
      item=trimws(substr(item,1,str_length(item)-str_length(amtx))),
      amt=suppressWarnings({as.numeric(amtx)})
    )
    
    
    return(tbl[!grepl("CR",amtx)]) #Excludes credit amount
    
  }
  
  
  
  dbs_content<-tabulizer::extract_tables(dbs_pdf,method = "stream")
  
  dbs_content<-lapply(dbs_content,function(mat){
    if(any(grepl("[0-9][0-9] [A-Z]{3}",mat[,1]))){
      
      mat<-data.table(mat)
      mat<-mat[grepl("[0-9][0-9] [A-Z]{3}",V1)]
      #Handle subcard formating
      mat[!grepl("[0-9][0-9] [A-Z]{3}$",V1),V2:=paste0("SUBCARD - ",stringr::str_extract(V1,"(?<=[0-9][0-9] [A-Z]{3}).*?$"))]
      mat[,V1:=stringr::str_extract(V1,"[0-9][0-9] [A-Z]{3}")]
      
      
      
      return(
        data.table(date=as.Date(mat[[1]],"%d %b"),
                   acct="dbs",
                   item=apply(mat[,-c(1,ncol(mat)),with=F],1,paste0,collapse=""),
                   amt=as.numeric(ifelse(grepl("CR",mat[[ncol(mat)]]),paste0("-",gsub(" CR","",mat[[ncol(mat)]])),mat[[ncol(mat)]])))
      )
      
    }
    return(NULL)
  })
  
  
  return(rbindlist(dbs_content)[order(date,item)])
  
}
extract_uob_pdf_cc_table<-function(uob_xls){
  #currency ?
  
  data<-data.table(readxl::read_excel(uob_xls))
  acct_number<-data[4,][,2,with=F][[1]]
  data<-data.table(readxl::read_excel(uob_xls,skip = 9))
  return(data[,.(date=as.Date(`Posting Date`,"%d %b %Y"),acct=paste0("UOB ",acct_number),item=Description,amt=`Transaction Amount(Local)`)])
}
extract_amex_csv_cc_table<-function(amex_csv){
  #currency ?
  
  data<-read.csv(amex_csv,header=F)
  data.table(data)[,.(date=as.Date(V1,"%d/%m/%Y"),acct='AMEX',item=V4,amt=V3)]
}



tag_spending<-function(data){

#This code needs to be cleaned up further

  restaurants_dict<-c("GOODWOODPARK",
                      "YA KUN",
                      "BREADTALK",
                      "HUGGS",
                      "MCDONALD",
                      "WHEAT",
                      "BENGAWAN SOLO",
                      "KAMIKAZE ASIA",
                      "VIIO GASTROPUB PTE LTD",
                      "DIAN XIAO ER",
                      "IZAKAYA",
                      "STARBUCKS",
                      "THE BEEF STATION",
                      "THE MARMALADE PANTRY",
                      "KFC",
                      "TONKATSU BY MA MAISON",
                      "KOUFU PTE LTD",
                      'ORCHID LIVE SEAFOOD',
                      'IRON 2 NORI PTE LTD',
                      'PHO STOP PTE. LTD',
                      'PONGGOL NASI LEMAK CAFE',
                      'CHEERS - 500 TOA PAYOH',
                      'A&W - AMK',
                      'KAKI - AMK',
                      'SOUPERSTAR - TANJONG PAGA',
                      'GEORGES@THE COVE',
                      'JEWEL COFFEE',
                      'HAKATA IKKOUSHA',
                      'KORYO MART MARINE PARADE',
                      'FOC Sentosa Pte Ltd',
                      'GEORGES@THE COVE',
                      'KEI MARINA SQUARE')
  
  discretionary_spending<-c(
    "IKEA",
    "APPLE.COM",
    "APPLE ONLINE",
    "M & S",
    "THE ART FACULTY LTD",
    "DECATHLON"
  )
  
  groceries_spending<-c(
    "PRIME NOW SG",
    "FINEST",
    "FAIRPRICE",
    "HAO MART",
    "NTUC",
    "COLD STORAGE",
    "7-ELEVEN",
    "DON DON DONKI",
    "GUARDIAN",
    "SHENGSIONG",
    "CHEERS",
    "SHENG SIONG"
  )
  
  ecommerce<-c('LAZADA',
               'SHOPEE',
               'AMAZON RETAIL',
               'PAYPAL',
               'YOUTRIP',
               'AMAZON')
  
  lifestyle_spending<-c(
    "ACTIVESG"
  )
  
  travel_sightseeing_holiday<-c('SINGAPORE ZOO','RIVER SAFARI')
  
  religion<-c('ODB MINISTRIES SG')
  
  
  data[grepl("GIGA|LIBERTY WIRELESS|SPOTIFY ",item),TAG:="BILL"]
  data[grepl("BUS/MRT",item),TAG:="TRANSPORT/BUSMRT"]
  data[grepl("GRAB",item),TAG:="TRANSPORT/GRAB"]
  data[grepl("BLUESG",item),TAG:="TRANSPORT/BLUESG"]
  data[grepl("COMFORT/CITYCAB TAXI",item),TAG:="TRANSPORT/COMFORT"]
  data[grepl(paste0(ecommerce,collapse = "|"),item),TAG:="RETAIL/ECOMMERCE"]
  data[grepl(paste0(groceries_spending,collapse = "|"),item),TAG:="RETAIL/GROCERY"]
  data[grepl("DELIVEROO.COM|DELIVEROO|FOODPANDA",item),TAG:="FOOD/ONLINE"]
  data[grepl("RAFFLES HOSPITAL|NSC|SURGERY CENTRE|INTERNAL MEDICINE CENTRE",item),TAG:="HEALTH/HOSPITAL"]
  data[grepl("NATIONAL UNIVERSITY OF SINGAPORE|COURSRA|POPULAR BOOK COMPANY",item),TAG:="EDUCATION"]
  data[grepl(paste0(discretionary_spending,collapse = "|"),item),TAG:="RETAIL/DISCRETIONARY"]
  data[grepl(paste0(restaurants_dict,collapse = "|"),item),TAG:="FOOD/RESTAURANT"]
  data[grepl(paste0(travel_sightseeing_holiday,collapse = "|"),item),TAG:="LEISURE/SIGHTSEEING"]
  data[grepl(paste0(lifestyle_spending,collapse = "|"),item),TAG:="LEISURE/SPORTS"]
  data[grepl(paste0(religion,collapse = "|"),item),TAG:="RELIGION/GIVING"]
  
  
  return(data)
  
}
