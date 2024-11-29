# Load necessary libraries
library(readxl)  # For reading Excel files
library(dplyr)   # For data manipulation
library(ggplot2) # For data visualization
library(cluster) # For clustering
library(factoextra) # For visualization of clustering
library(scales)  # For scaling data
library(shiny)  # For Deploying application
library(shinythemes)

# Load the data from the Excel file
data <- read_excel("onlineretail.xlsx")

head(data)

# Exploratory Data Analysis (EDA)
# Check for missing values
missing_values <- colSums(is.na(data))
print(missing_values)

# Drop rows with missing CustomerID
data <- data %>% filter(!is.na(CustomerID))

# Convert 'InvoiceDate' to datetime format and 'CustomerID' to character
data$InvoiceDate <- as.POSIXct(data$InvoiceDate, format="%Y-%m-%d %H:%M:%S")
data$CustomerID <- as.character(data$CustomerID)

# Create a new column for Total Amount Paid per transaction
data <- data %>% mutate(TotalAmtPaid = Quantity * UnitPrice)

# Remove rows with negative quantities
data <- data %>% filter(Quantity > 0)

# Identify categorical columns
categorical_cols <- c("InvoiceNo", "StockCode", "Description", "CustomerID", "Country")
data[categorical_cols] <- lapply(data[categorical_cols], as.factor)

# Recency, Frequency, Monetary (RFM) computation
# Compute Recency
date_max <- max(data$InvoiceDate)
recency <- data %>% group_by(CustomerID) %>% 
  summarize(Recency = as.numeric(difftime(date_max, max(InvoiceDate), units="days")))

# Compute Frequency
frequency <- data %>% group_by(CustomerID) %>% 
  summarize(Frequency = n())

# Compute Monetary
monetary <- data %>% group_by(CustomerID) %>%
 summarize(Monetary = sum(TotalAmtPaid))

# Merge RFM metrics
rfm_table <- recency %>% 
  inner_join(frequency, by="CustomerID") %>% 
  inner_join(monetary, by="CustomerID")

# Remove outliers using IQR
for (col in c("Recency", "Frequency", "Monetary")) {
  Q1 <- quantile(rfm_table[[col]], 0.25)
  Q3 <- quantile(rfm_table[[col]], 0.75)
  IQR <- Q3 - Q1
  rfm_table <- rfm_table %>% filter(
    rfm_table[[col]] >= (Q1 - 1.5 * IQR) & 
    rfm_table[[col]] <= (Q3 + 1.5 * IQR))
}

# Scale RFM data
rfm_scaled <- as.data.frame(scale(rfm_table[, c("Recency", "Frequency", "Monetary")])) # nolint

# K-Means Clustering
# Determine optimal number of clusters using the elbow method
wss <- sapply(1:10, function(k) {
  kmeans(rfm_scaled, centers = k, nstart = 20)$tot.withinss
})

plot(1:10, wss, type="b", pch=19, frame=FALSE,
     xlab="Number of Clusters", ylab="Total Within-Cluster Sum of Squares",
     main="Elbow Method for Optimal Clusters")

# Based on the elbow plot, assume optimal clusters = 3
set.seed(42)
kmeans_model <- kmeans(rfm_scaled, centers = 3, nstart = 20)
rfm_table$Cluster <- as.factor(kmeans_model$cluster)

# Visualize Clusters
fviz_cluster(kmeans_model, data = rfm_scaled, geom = "point")

# Explore RFM metrics by cluster
print(rfm_table %>% group_by(Cluster) %>% summarize(
  Recency = mean(Recency),
  Frequency = mean(Frequency),
  Monetary = mean(Monetary)
))

# Deploying the Software
# Best option: Deploy the clustering solution using R Shiny for interactive web applications

# Update Shiny app to use data inputs directly
# Extract unique values for dropdown menus
invoice_no_choices <- unique(data$InvoiceNo)
stock_code_choices <- unique(data$StockCode)
description_choices <- unique(data$Description)
customer_id_choices <- unique(data$CustomerID)
country_choices <- unique(data$Country)

# UI
ui <- fluidPage(
  theme = shinytheme("darkly"),
  tags$head(
    tags$style(HTML("
      .container-fluid {
        background-color: #1A0266;
        color: #ffffff;
      }
      .well {
        background-color: #2a2a2a;
        border: 4px solid #444;
      }
      h1, h2, h3, h4 {
        color: #f39c12;
      }
      .btn {
        background-color: #f39c12;
        color: #ffffff;
      }
      .btn:hover {
        background-color: #e67e22;
      }
    "))
  ),
  titlePanel("Customer Segmentation - Interactive Analysis"),
  sidebarLayout(
    sidebarPanel(
      h3("Input Data"),
      selectInput("invoiceNo", "Invoice No:", choices = invoice_no_choices),
      selectInput("stockCode", "Stock Code:", choices = stock_code_choices),
      selectInput("description", "Description:", choices = description_choices),
      selectInput("customerID", "Customer ID:", choices = customer_id_choices),
      selectInput("country", "Country:", choices = country_choices),
      numericInput("quantity", "Quantity:", value = 10, min = 0),
      numericInput("unitPrice", "Unit Price:", value = 1.5, min = 0),
      dateInput("invoiceDate", "Invoice Date:"),
      actionButton("run", "Run Clustering"),
      width = 6
    ),
    mainPanel(
      tabsetPanel(
        tabPanel(
          "Cluster Plot",
          plotOutput("clusterPlot", height = "500px")
        ),
        tabPanel(
          "Cluster Summary",
          tableOutput("clusterSummary")
        )
      ),
      width = 6
    )
  )
)

# Server
server <- function(input, output, session) {
  observeEvent(input$run, {
    # Create a new data frame with the user inputs
    new_data <- data.frame(
      InvoiceNo = as.character(input$invoiceNo),
      StockCode = as.character(input$stockCode),
      Description = as.character(input$description),
      Quantity = input$quantity,
      InvoiceDate = as.POSIXct(input$invoiceDate),
      UnitPrice = input$unitPrice,
      CustomerID = as.character(input$customerID),
      Country = as.character(input$country)
    )
    
    # Combine with the existing dataset
    combined_data <- bind_rows(data, new_data)
    
    # Preprocess combined data for clustering
    date_max <- max(combined_data$InvoiceDate, na.rm = TRUE)
    combined_rfm <- combined_data %>%
      group_by(CustomerID) %>%
      summarize(
        Recency = as.numeric(difftime(date_max, max(InvoiceDate), units = "days")),
        Frequency = n(),
        Monetary = sum(Quantity * UnitPrice, na.rm = TRUE)
      ) %>%
      filter(!is.na(Recency) & !is.na(Frequency) & !is.na(Monetary))
    
    # Scale RFM metrics
    scaled_combined_rfm <- as.data.frame(scale(combined_rfm[, c("Recency", "Frequency", "Monetary")]))
    
    # Perform clustering
    kmeans_model <- kmeans(scaled_combined_rfm, centers = 3, nstart = 20)
    combined_rfm$Cluster <- as.factor(kmeans_model$cluster)
    
    # Render cluster plot
    output$clusterPlot <- renderPlot({
      fviz_cluster(kmeans_model, data = scaled_combined_rfm, geom = "point",
                   palette = c("#e74c3c", "#3498db", "#2ecc71"),
                   ggtheme = theme_minimal() + theme(plot.background = element_rect(fill = "#ffffff")))
    })
    
    # Render cluster summary
    output$clusterSummary <- renderTable({
      combined_rfm %>% group_by(Cluster) %>% summarize(
        Recency = mean(Recency),
        Frequency = mean(Frequency),
        Monetary = mean(Monetary)
      )
    })
  })
}

# Run the app
shinyApp(ui, server)