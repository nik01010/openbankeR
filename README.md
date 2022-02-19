# openbankeR

<a href="https://nik01010.wordpress.com/" target="_blank">Blog</a> 
| <a href="https://nik01010.wordpress.com/contact/" target="_blank">Contact</a>
| <a href="https://openbankinguk.github.io/opendata-api-docs-pub/" target="_blank">Full API Spec</a>
<br> 

An R package for querying the UK Open Banking (Open Data) API.


<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/openbankeR)](https://CRAN.R-project.org/package=openbankeR)
[![R build status](https://github.com/nik01010/openbankeR/workflows/R-CMD-check/badge.svg)](https://github.com/nik01010/openbankeR/actions)
[![Codecov test coverage](https://codecov.io/gh/nik01010/openbankeR/branch/master/graph/badge.svg)](https://codecov.io/gh/nik01010/openbankeR?branch=master)
[![Stability: Active](https://masterminds.github.io/stability/active.svg)](https://masterminds.github.io/stability/active.html)
<!-- badges: end -->


## Features
- Create an R client for the OpenBanking (OpenData) API

- Extract raw data from the API using convenient functions


## Installation
From CRAN:
```R
install.packages("openbankeR")
```

From GitHub:
```R
library(devtools)
install_github("nik01010/openbankeR")
```


## Functions

| Function       | Description                | Input | Output             |
| ------------- |----------------------|----------------------|-------------------|
| CreateOpenBankingClient | Creates a client for calling the API | Optional user-defined settings | OpenBankingClient object with query functions |


## Create an API client
Create a new client for querying the API
```R
library(openbankeR)

openBankingClient <- openbankeR::CreateOpenBankingClient()
```


## Available banks
Get a list of banks that report the API
```R
availableBanks <- openBankingClient$GetAvailableBanks()

availableBanks
```


## Available instruments
Get a list of instruments reported via the API
```R
availableInstruments <- openBankingClient$GetAvailableInstruments()

availableInstruments
```


## Extract raw data
Get raw data using the API for a given bank and instrument
```R
bankName <- "HSBC Group"
instrument <- "branches"

rawData <- openBankingClient$GetRawData(
  bankName = bankName,
  instrument = instrument
)

rawData
```


## Note
Raw data provided by the API can be a nested structure and may need to be unnested for some types of analysis.
