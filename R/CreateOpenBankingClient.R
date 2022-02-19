#' @title CreateOpenBankingClient
#' 
#' @description Creates a new Open Banking (Open Data) API client with convenient queries
#'
#' @section Available client fields:
#' \itemize{
#'   \item \strong{BankDetails}: The default table of bank details used to query the API.
#' }
#' 
#' @section Available client queries:
#' \itemize{
#'   \item \strong{GetAvailableBanks}: Get a list of banks that report the API.
#'   \item \strong{GetAvailableInstruments}: Get a list of instruments reported via the API.
#'   \item \strong{GetRawData}: Get raw data using the API for a given bank and instrument.
#' }
#' 
#' @param bankDetails optional. Bank details list to use. When set to "default", the
#' bank details will be taken from the below URL:
#' https://github.com/OpenBankingUK/opendata-api-spec-compiled/blob/master/participant_store.json
#' 
#' Otherwise, the user can provide a custom list of bank details.
#' 
#' @param version optional. Which version of the API to use. Defaults to "latest".
#' When set to "latest", the version used will be the latest available for the selected bank and instrument. 
#' The latest available version information will be derived from the bank details table above.
#' Alternatively, the user can supply a manually set version such as "v2.3"
#' 
#' @param timeOutSeconds optional. Number of seconds before a request times out. Defaults to 15 seconds
#'
#' @return Object of type OpenBankingClient with methods for querying the API
#' 
#' @examples
#' \donttest{
#' library(openbankeR)
#'
#' openBankingClient <- openbankeR::CreateOpenBankingClient()
#' 
#' bankDetails <- openBankingClient$BankDetails
#'    
#' availableBanks <- openBankingClient$GetAvailableBanks()
#' availableInstruments <- openBankingClient$GetAvailableInstruments()
#' 
#' bankName <- "HSBC Group"
#' instrument <- "branches"
#' 
#' rawData <- openBankingClient$GetRawData(
#'   bankName = bankName,
#'   instrument = instrument
#' )
#' }
#' 
#' @export
CreateOpenBankingClient <- function(bankDetails = "default", version = "latest", timeOutSeconds = 15) {
  openBankingClient <- .openBankingClient$new(
    bankDetails = bankDetails, 
    version = version, 
    timeOutSeconds = timeOutSeconds
  )
  
  return(openBankingClient)
}


#' @keywords internal
.openBankingClient <- R6::R6Class(
  classname = "OpenBankingClient",
  cloneable = FALSE,
  
  public = list(
    
    #' @field BankDetails Details for available banks that support the API
    BankDetails = NULL,
    
    
    #' @title initialize
    #' 
    #' @description Initialize a new API client
    #' 
    #' @param bankDetails optional. Bank details list to use. When set to "default", the
    #' bank details will be taken from the below URL:
    #' https://github.com/OpenBankingUK/opendata-api-spec-compiled/blob/master/participant_store.json
    #' Otherwise, the user can provide a custom list of bank details.
    #' 
    #' @param version optional. Which version of the API to use. Defaults to "latest.
    #' When set to "latest", the version used will be the latest available for 
    #' the selected bank and instrument. This information will be derived from the bank details table above.
    #' Alternatively, the user can supply a manually set version such as "v2.3"
    #' 
    #' @param timeOutSeconds optional. Number of seconds before a request times out. Defaults to 15 seconds
    #' 
    #' @return Object of type OpenBankingClient with methods for querying the API
    #' 
    initialize = function(bankDetails = "default", version = "latest", timeOutSeconds = 15) {
      private$.version <- version
      
      private$.timeOutSeconds <- timeOutSeconds
      message(glue::glue("A timeout of {timeOutSeconds} seconds is being used."))
      message("Any individual request that takes longer than this will be stopped.")
      
      bankDetailsProvided <- (bankDetails != "default")
      if (!bankDetailsProvided) {
        bankDetails <- private$.getBankDetails()
      }
      
      private$.validateBankDetails(bankDetails = bankDetails)
      
      self$BankDetails <- bankDetails
    },
    
    
    #' @description Get available banks that support the API
    #' 
    #' @return character list. Names of available banks
    #' 
    GetAvailableBanks = function() {
      bankList <- unique(self$BankDetails$name)
      
      return(bankList)
    },
    
    
    #' @description Get available instruments for the API
    #' 
    #' @return character list. Names of available instruments
    #' 
    GetAvailableInstruments = function() {
      columnNames <- colnames(self$BankDetails)
      
      excludedColumns <- c("name", "brands", "baseUrl")
      
      instrumentList <- columnNames[!(columnNames %in% excludedColumns)]
      
      return(instrumentList)
    },
    
    
    #' @description Get raw data for a specified bank and instrument
    #' 
    #' @param bankName character. Name of the bank to get data for. See GetAvailableBanks()
    #' 
    #' @param instrument character. Instrument to get data for. See GetAvailableInstruments()
    #' 
    #' @return list. Raw data for the requested bank and instrument
    #' 
    GetRawData = function(bankName, instrument) {
      bankDetails <- private$.getDetailsForBank(bankName = bankName)
      requestUrl <- private$.buildUrlForRequest(bankDetails = bankDetails, instrument = instrument)
      
      requestIsInvalid <- is.null(requestUrl)
      if (requestIsInvalid) {
        return(NULL)
      }
      
      rawDataList <- private$.downloadDataForUrl(requestUrl = requestUrl)
      
      return(rawDataList)
    }
    
  ),
  
  private = list(
    
    .version = NULL,
    
    .timeOutSeconds = NULL,
    
    .bankDetailsUrl = file.path(
      "https://raw.githubusercontent.com/OpenBankingUK/opendata-api-spec-compiled/master",
      "participant_store.json"
    ),
    
    
    .buildUrlForRequest = function(bankDetails, instrument) {
      bankName <- bankDetails$name
      baseUrlForBank <- bankDetails$baseUrl
      supportedVersionForBank <- bankDetails[instrument][1]
      
      # Bank-specific corrections
      if (bankName == "Nationwide Building Society" && instrument == "branches") {
        baseUrlForBank <- "https://locations.nationwidebranches.co.uk/open-banking"
      }
      
      instrumentNotSupported <- is.na(supportedVersionForBank)
      if (instrumentNotSupported) {
        warningMessage <- glue::glue("Bank '{bankName}' does not support instrument '{instrument}'")
        warning(warningMessage)
        return(NULL)
      }
      
      overrideApiVersion <- (private$.version != "latest")
      if (overrideApiVersion) {
        supportedVersionForBank <- private$.version
      }
      
      urlForRequest <- glue::glue("{baseUrlForBank}/{supportedVersionForBank}/{instrument}")
      
      return(urlForRequest)
    },
    
    
    .handleHttpResponse = function(responseStatusCode) {
      if (responseStatusCode == 200) {
        return(TRUE)
      }
      
      statusCodeDetail <- httpcode::http_code(code = responseStatusCode)
      statusMessage <- statusCodeDetail$message
      statusDescription <- statusCodeDetail$explanation
      
      warningMessage <- glue::glue(
        "Problem with HTTP response code {responseStatusCode}.
        Status message: {statusMessage}.
        Status description: {statusDescription}"
      )
      warning(warningMessage)
      
      return(FALSE)
    },
    
    
    .getBankDetails = function() {
      requestUrl <- private$.bankDetailsUrl
      bankDetailsList <- private$.downloadDataForUrl(requestUrl = requestUrl)
      
      bankDetailsNestedTable <- jsonlite::flatten(x = bankDetailsList$data)
      
      bankDetails <- bankDetailsNestedTable %>%
        dplyr::select(-`supportedAPIs.fca-service-metrics`) %>%
        tidyr::unnest(cols = "brands", keep_empty = TRUE) %>%
        tidyr::unnest(cols = "supportedAPIs.business-current-accounts", keep_empty = TRUE) %>%
        tidyr::unnest(cols = "supportedAPIs.personal-current-accounts", keep_empty = TRUE) %>%
        tidyr::unnest(cols = "supportedAPIs.unsecured-sme-loans", keep_empty = TRUE) %>%
        tidyr::unnest(cols = "supportedAPIs.atms", keep_empty = TRUE) %>%
        tidyr::unnest(cols = "supportedAPIs.branches", keep_empty = TRUE) %>%
        tidyr::unnest(cols = "supportedAPIs.commercial-credit-cards", keep_empty = TRUE)
      
      colnames(bankDetails) <- gsub(pattern = "supportedAPIs.", replacement = "", x = colnames(bankDetails))
      
      bankDetails <- bankDetails %>%
        dplyr::select(
          name, brands, baseUrl, `business-current-accounts`, `personal-current-accounts`,
          `unsecured-sme-loans`, atms, branches, `commercial-credit-cards`
        )
      
      return(bankDetails)
    },
    
    
    .validateBankDetails = function(bankDetails) {
      expectedColumns <- c(
        "name", "brands", "baseUrl", "business-current-accounts", "personal-current-accounts",
        "unsecured-sme-loans", "atms", "branches", "commercial-credit-cards"
      )
      
      columnsAreValid <- all(expectedColumns %in% colnames(bankDetails))
      if (!columnsAreValid) {
        expectedColumnList <- paste0(expectedColumns, collapse = ", ")
        errorMessage <- glue::glue(
          "The bank details table has invalid columns. Expected columns: {expectedColumnList}"
        )
        stop(errorMessage)
      }
    },
    
    
    .getDetailsForBank = function(bankName) {
      detailsForBank <- self$BankDetails %>%
        dplyr::filter(name == bankName)
      
      return(detailsForBank)
    },
    
    
    .downloadDataForUrl = function(requestUrl) {
      print(glue::glue("Downloading from URL: {requestUrl}"))
      
      responseData <- httr::GET(url = requestUrl, httr::timeout(seconds = private$.timeOutSeconds))
      
      responseStatusCode <- responseData$status_code
      responseIsValid <- private$.handleHttpResponse(responseStatusCode = responseStatusCode)
      if (responseIsValid == FALSE) {
        return(NULL)
      }
      
      rawDataJson <- httr::content(x = responseData, as = "text", encoding = "UTF-8")
      rawDataList <- jsonlite::fromJSON(txt = rawDataJson)
      
      return(rawDataList)
    }
    
  )
  
)
