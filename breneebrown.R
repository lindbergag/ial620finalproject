#Check whether necessary libraries are installed. If not, install them. Otherwise, load the libraries
if (!require("rvest")) install.packages("rvest")
library(rvest)
if (!require("tidyverse")) install.packages("tidyverse")
library(tidyverse)
if (!require("RSelenium")) install.packages("RSelenium")
library(RSelenium)

#Primary Source content
main.url <- read_html("https://brenebrown.com/dtl-podcast/")

#Run an RSelenium Server (using Docker)
remDr <- remoteDriver(
  remoteServerAddr = "localhost",
  port = 4445L
)
remDr$open()

#Open the webpage of interest
remDr$navigate("https://brenebrown.com/dtl-podcast/")

#Locate the load More button
loadmorebutton <- remDr$findElement(using = 'css selector', ".alm-load-more-btn.more")

#Click the Load More Button
loadmorebutton$clickElement()

#Click the Load More Button, again
loadmorebutton$clickElement()

#Get the page HTML
page.source <- remDr$getPageSource()


#Generate the urls for all of the transcript links on the website
main.url <- read_html(page.source[[1]])

scrape.list <- html_nodes(main.url, "a.podcast-image") %>%
  html_attr("href")

#This gets everything except the newest podcast
#Unfortunately, that episode doesn't have a transcript, yet. COmmenting out the code to add it
##newest <- html_nodes(main.url, "a.left") %>%
##  html_attr("href")
#Add the newest
##scrape.list<- c(scrape.list, newest)


#Close the browser session
remDr$close()

#The url for Brene's Transcripts is /transcript instead of /podcast. Fix that
for (i in seq_along(scrape.list)) {
  scrape.list[i] <- str_replace(scrape.list[i], "https://brenebrown.com/podcast/", "https://brenebrown.com/transcript/")
}

#The url for the episode with Aiko Bethea doesn't follow the model

scrape.list[28] <- "https://brenebrown.com/transcript/brene-with-aiko-bethea/"

# Create empty vectors that will be filled data by the 'for loop' below
page.title <- vector()
page.text <- vector()
page.date <- vector()

# The for loop visits each URL in scrape.list and then collects the text content from each page, creating a new list
for (i in seq_along(scrape.list)) {
  new.url <- read_html(scrape.list[i])
  
  #Collects title content from pages
  title.add <- html_nodes(new.url, xpath='//*[@id="single-meta"]/h3') %>%
    html_text()
  
  #Collects text content from pages
  text.add <- html_nodes(new.url, xpath='//*[@class ="normal-content"]') %>%
    html_text()
  
  #Collapses all the separate <p> text content into one string of text
  text.add <- paste(text.add, collapse=" ")
  
  #Collects the date from pages
  date.add <- html_nodes(new.url, xpath='*//span[@class = "post-time"]') %>%
    html_text()
  
  page.title <- c(page.title, title.add)
  page.text <- c(page.text, text.add)
  page.date <- c(page.date, date.add)
  
  #Put a 3 second delay in between page scrapes
  Sys.sleep(3)
}


# Using tibble, the list of URLs is combined with the text scraped from each URL to create a dataframe for our combined dataset
scrape.data <- tibble('title' = page.title, 'url'=scrape.list, 'date'=page.date, 'text'=page.text)


# Save dataframe as an RDS file
saveRDS(scrape.data, 'breneebrown.rds')