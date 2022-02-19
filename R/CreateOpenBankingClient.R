#' @title CreateOpenBankingClient
#' @description Creates a new Open Banking (Open Data) API client with convenient queries
#'
#' @section Available client queries:
#' \itemize{
#'   \item \strong{GetBankDetails}: Get default table of bank details used to query the API.
#'   \item \strong{GetAvailableBanks}: Get a list of banks that report the API.
#'   \item \strong{GetAvailableInstruments}: Get a list of instruments reported via the API.
#'   \item \strong{GetRawData}: Get raw data using the API for a given bank and instrument.
#' }
#' @param bankName character. Name of the bank to get data for. See GetAvailableBanks()
#' @param instrument character. Instrument to get data for. See GetAvailableInstruments()
#' @param bankDetails optional. Bank details list to use. When set to "default", the
#' bank details will be taken from the below URL:
#' https://github.com/OpenBankingUK/opendata-api-spec-compiled/blob/master/participant_store.json
#' Otherwise, the user can provide a custom list of bank details.
#' @param version optional. Which version of the API to use. When set to "latest", the
#' version used will be the latest available for the selected bank and instrument. This information
#' will be derived from the bank details table above.
#'
#' @return list. Raw data for the requested bank name and instrument
#' @examples
#' \donttest{
#' library(openbankeR)
#'
#' openBankingClient <- openbankeR::CreateOpenBankingClient()
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
#' @export
CreateOpenBankingClient <- function(bankName, instrument, bankDetails = "default", version = "latest") {
  
}


#' @keywords internal
.openBankingClient <- R6::R6Class(
  
)
