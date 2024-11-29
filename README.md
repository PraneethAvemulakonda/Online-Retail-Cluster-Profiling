Online Retail Cluster Profiling & Analysis

This project analyzes an online retail dataset to uncover customer purchasing behaviors and patterns. It utilizes R for data manipulation, visualization, and clustering, and deploys an interactive Shiny application for user engagement.


Table of Contents
-----------------

1.  Features
2.  Technologies Used
3.  Requirements
4.  Installation
5.  Usage
6.  License
7.  Contact


Features
--------

-   Data Loading: Imports data from Excel files using readxl.

-   Data Manipulation: Cleans and transforms data with dplyr.

-   Visualization: Generates insightful plots using ggplot2.

-   Clustering Analysis: Performs customer segmentation with cluster and visualizes results using factoextra.

-   Interactive Application: Provides a user-friendly interface through a Shiny app, enhanced with shinythemes.


Technologies Used
-------------------

1.  R version 4.0.0 or higher. [Download from https://cran.r-project.org/bin/windows/base/]

2.  RStudio latest version. [Download from https://posit.co/download/rstudio-desktop/]

3.  R packages:

-   readxl
-   dplyr
-   ggplot2
-   cluster
-   factoextra
-   scales
-   shiny
-   shinythemes


Requirements
------------

Ensure the following R packages are installed:

    install.packages(c("readxl", "dplyr", "ggplot2", "cluster", "factoextra", "scales", "shiny", "shinythemes"))

If R is not installed, download it from CRAN.


Installation
------------

1.  Clone the Repository:

        git clone https://github.com/PraneethAvemulakonda/Online-Retail-Cluster-Profiling.git

2.  Navigate to the Project Directory:

        cd Online-Retail-Cluster-Profiling

3.  Open R or RStudio.


Usage
-----

1.  Load the Script: Open online_retail.r in your R editor.

2.  Set Data Path: Ensure the Excel file (onlineretail.xlsx) is in the project directory or update the path in the script accordingly.

3.  Run the Script: Execute the code to perform data analysis, generate visualizations and launching Shiny App.


License
-------

This project is licensed under the MIT License. See the LICENSE file for details.

This project is created by [Praneeth Avemulakonda], MSc Applied Data Science, Teesside University as part of professional internship for the ThinkPacific Foundation (https://thinkpacific.com/).
Project was created during the period of [ 23-September-2024 | 13-December-2024 ].

Contact
-------

For questions or feedback, please contact praneethsai6196@gmail.com.
