#' @title Canopy Structure
#'
#' @description Estimates the canopy structure of a discrete returns scan from different TLS.
#'
#' @param TLS.type A \code{character} describing is the TLS used. It most be one of \code{"single"} return, \code{"multiple"} return, or \code{"fixed.angle"} scanner.
#' @param scan If \code{TLS.type} is equal to \code{"single"} or \code{"fixed.angle"}, a \code{data.table} with three columns describing *XYZ* coordinates of the discrete return. If
#' \code{TLS.type} is equal to \code{"multiple"}, a \code{data.table} with four columns describing *XYZ* coordinates and the target count pulses.
#'
#' @param zenith.range If \code{TLS.type} is equal to \code{"single"} or \code{"multiple"}, a \code{numeric} vector of length two describing the \code{min} and \code{max} range of the zenith angle to use.
#' Theoretically, the \code{max} range should be lower than 90 degrees.
#' @param zenith.rings If \code{TLS.type} is equal to \code{"single"} or \code{"multiple"}, a \code{numeric} vector of length one describing the number of zenith rings to use between \code{zenith.range}.
#' This is used to estimate the frecuency of laser shots from the scanner and returns in \code{scan}. If \code{TLS.type = "fixed.angle"}, \code{zenith.rings = 1} be default.
#' @param azimuth.range A \code{numeric} vector of length two describing the range of the azimuth angle to use. Theoretically, it should be between 0 and 360 degrees.
#' @param vertical.resolution A \code{numeric} vector of length one describing the vertical resolution to use to extract the profiles from *Z*. Low values lead to more variable profiles.
#' The scale used needs to be in congruence with the scale of \code{scan}.
#'
#' @param TLS.resolution If \code{TLS.type} is equal to \code{"single"} or \code{"multiple"}, a \code{numeric} vector of length two describing the horizontal and vertical angle resolution of the scanner.
#' If \code{TLS.type} is equal to \code{"fixed.angle"}, a \code{numeric} vector of length one describing the horizontal angle resolution.
#' @param TLS.frame If \code{TLS.type} is equal to \code{"single"} or \code{"multiple"}, a \code{numeric} vector of length four describing the \code{min} and \code{max} of the zenith and azimuth angle of the scanner frame.
#' If \code{TLS.type = "fixed.angle"}, a \code{numeric} vector of length three describing the fixed zenith angle and the \code{min} and \code{max} of the azimuth angle of the scanner frame.
#' If \code{NULL}, it assumes that a complete hemisphere (\code{c(zenith.min = 0, zenith.max = 90, azimuth.min = 0, azimuth.max = 360)}), or a cone projection (\code{c(zenith = 57.5, azimuth.min = 0, azimuth.max = 360)}) depending on \code{TLS.type}.
#' @param TLS.angles A \code{numeric} vector of length three describing the pitch (*X*), roll (*Y*), and yaw (*Z*) of the TLS during the scan.
#' If \code{NULL}, it assumes that the angles are \code{c(roll = 0, pitch = 0, yaw = 0)}.
#' This needs to be used if \code{TLS.type} is equal to \code{"single"} or \code{"multiple"}, since it assumes that \code{"fixed.angle"} scanner are previously balanced.
#' @param TLS.coordinates A \code{numeric} vector of length three describing the scanner coordinates within \code{scan}.
#' If \code{NULL}, it assumes that the coordinates are \code{c(X = 0, Y = 0, Z = 0)}.
#' @param parallel Logical, if \code{TRUE} it use parallel processing on the estimation of shots and returns. \code{FALSE} as default.
#' @param cores An \code{integer >= 0} describing the number of cores use. This need to be used if \code{parallel = TRUE}.
#'
#' @details Since \code{scan} describes discrete returns measured by the TLS, \code{canopy_structre} first simulates the number of shots emited based on Danson et al. (2007). The simulated shots are
#' created based on the TLS workflow (\code{TLS.resolution, TLS.frame}) assuming that the scanner is perfectly balance. Then these shots are moved and rotated (\code{\link{move_rotate}}) based on the \code{TLS.angles}
#' roll, pitch, and yaw, and \code{TLS.coordintates} to simulate the positioning of the scanner during the \code{scan}. Moved and rotated simulated-shots of interest and \code{scan} returns are then extracted based on the \code{zenith.range}, \code{zenith.rings}, and \code{vertical.resolution}.
#' Using the frecuency of shots and returns the probabiliry of gap (Pgap) is estimated. For \code{TLS.type = "multiple"}, the frecuency of returns is estimated using the sum of 1/target count following Lovell et al. (2011).
#'
#' Using the Pgap estimated per each zenith ring and vertical profile, \code{canopy_structure} then estimates the accumulative L(z) profiles based on the closest
#' zenith ring to 57.5 (hinge region) and, if \code{TLS.type} is equal to \code{"fixed.angle"}, the f(z) or commonly named PAVD based on the ratio of the
#' derivative of L(z) and height (z) following Jupp et al. 2009 (Equation 18). If \code{TLS.type} is equal to \code{"single"} or \code{"multiple"}, \code{canopy_structure} also
#' estimates the normalised average weighted L/LAI, and then PAVD based on the L (hinge angle) at the highest height (LAI) and the ratio between the derivative
#' of L/LAI (average weighted) and the derivative of z (Jupp et al. 2009; Equation 21).
#'
#' Jupp et al. 2009 excludes the zero zenith or fist ring to conduct the average weighted L/LAI estimations, \code{canopy_structre} does not excludes this sections since it depents on the regions of interest of the user.
#' Therefore, user should consider this difference since it may introduce more variability to profile estimations.
#'
#' @references
#'
#' Danson F.M., Hetherington D., Morsdorf F., Koetz B., Allgower B. 2007. Forest canopy gap fraction from terrestrial laser scanning. IEEE Geosci. Remote Sensing Letters 4:157-160. doi: 10.1109/LGRS.2006.887064.
#'
#' Lovell J.L., Jupp D.L.B., van Gorsel E., Jimenez-Berni J., Hopkinson C., Chasmer L. 2011. Foliage profiles from ground based waveform and discrete point LiDAR. In: SilviLaser 2011, Hobart, Australia, 16–20 October 2011.
#'
#' Jupp D.L.B., Culvenor D.S., Lovell J.L., Newnham G.J., Strahler A.H., Woodcock C.E. 2009. Estimating forest LAI profiles and structural parameters using a ground-based laser called “Echidna®”. Tree Physiology 29(2): 171-181. doi: 10.1093/treephys/tpn022.
#'
#' @return For any \code{TLS.type}, it returns a \code{data.table} with the height profiles defined by \code{vertical.resolution}, the gap probability based on the \code{zenith.range} and \code{zenith.rings}, and
#' the accumulative L(z) profiles based on the closest zenith ring to 57.5 degrees (hinge angle). If \code{TLS.type} is equal to \code{"fixed.angle"}, it returns f(z) or commonly named PAVD based on
#' on the ratio of the derivative of L(z) and the derivative of height (z). If \code{TLS.type} is equal to \code{"single"} or \code{"multiple"}, it returns the normalised average weighting L/LAI, and PAVD: based
#' on the L (hinge angle) at the highest height and the ratio between the derivative of L/LAI average weighted and the derivative of z.
#'
#'
#' @author J. Antonio Guzmán Q.
#'
#' @importFrom data.table between
#' @importFrom data.table CJ
#' @importFrom foreach foreach
#' @importFrom foreach %do%
#' @importFrom foreach %dopar%
#' @importFrom parallel makeCluster
#' @importFrom parallel stopCluster
#' @importFrom doSNOW registerDoSNOW
#' @importFrom utils txtProgressBar
#' @importFrom utils setTxtProgressBar
#' @importFrom stats reshape
#' @importFrom stats weighted.mean
#'
#' @examples
#'
#' #Using a multiple return file
#'
#' \dontrun{
#' data(TLS_scan)
#' TLS_scan <- TLS_scan[, 1:4] #Select the four columns required
#'
#' #This will take a while#
#' canopy_structure(TLS.type = "multiple", scan = TLS_scan, zenith.range = c(50,70), zenith.rings = 4,
#'                  azimuth.range = c(0, 360), vertical.resolution = 0.25,
#'                  TLS.resolution = c(0.04, 0.04), TLS.frame = c(30, 130, 0, 360),
#'                  TLS.angles =  c(0.293, -0.835, -150.159))
#'
#' #Using a single return file
#'
#' data(TLS_scan)
#' TLS_scan <- TLS_scan[Target_index == 1, 1:3] #Subset to first return observations
#'
#' #This will take a while#
#' canopy_structure(TLS.type = "single", scan = TLS_scan, zenith.range = c(50,70), zenith.rings = 4,
#'                  azimuth.range = c(0, 360), vertical.resolution = 0.25,
#'                  TLS.resolution = c(0.04, 0.04), TLS.frame = c(30, 130, 0, 360),
#'                  TLS.angles =  c(0.293, -0.835, -150.159))
#' }
#'
#' @export
canopy_structure <- function(TLS.type, scan, zenith.range, zenith.rings, azimuth.range, vertical.resolution, TLS.resolution, TLS.coordinates = NULL, TLS.frame = NULL, TLS.angles = NULL, parallel = FALSE, cores = NULL) {

  if(TLS.type == "multiple") {
    colnames(scan)[1:4] <- c("X", "Y", "Z", "Target_count")
  } else if(TLS.type == "single" | TLS.type == "fixed.angle") {
    colnames(scan)[1:3] <- c("X", "Y", "Z")
  }

  ###Validate assumptions-------------------------------------------------------------------------------------------------------

  if(TLS.type == "single" | TLS.type == "multiple") { ####TLS resolution
    if(length(TLS.resolution) != 2 & is.numeric(TLS.resolution) != TRUE) {
      stop("The TLS.resolution needs to be a numeric vector of length two representing the horizontal and vertical resolution of the scanner")
    }
  } else if(TLS.type == "fixed.angle") {
    if(length(TLS.frame) != 1 & is.numeric(TLS.resolution) != TRUE) {
      stop("The TLS.resolution needs to be a numeric vector of length one representing the horizontal resolution of the scanner")
    }
  }


  if(is.null(TLS.coordinates) == TRUE) { ###TLS coordinates
    TLS.coordintates <- c(X = 0, Y = 0, Z = 0)
  } else if(length(TLS.coordinates) != 3) {
    stop("The length of TLS.coordinates needs to be three representing the *XYZ*")
  }


  if(TLS.type == "single" | TLS.type == "multiple") { ####TLS frame
    if(is.null(TLS.frame) == TRUE) {
      TLS.frame <- c(zenith.min = 0, zenith.max = 90, azimuth.min = 0, azimuth.max = 360)
    } else if(length(TLS.frame) != 4 & is.numeric(TLS.frame) != TRUE) {
      stop("The TLS.frame needs to be a numeric vector of length four representing the min and max of the zenith and azimuth TLS scan")
    }
  } else if(TLS.type == "fixed.angle") {
    if(is.null(TLS.frame) == TRUE) {
      TLS.frame <- c(zenith = 57.5, azimuth.min = 0, azimuth.max = 360)
    } else if(length(TLS.frame) != 3 & is.numeric(TLS.frame) != TRUE) {
      stop("The TLS.frame needs to be a numeric vector of length three representing fixed zenith angle and the the min and max of the azimuth of the scanner")
    }
  }


  if(TLS.type == "single" | TLS.type == "multiple") { ###TLS angles
    if(is.null(TLS.angles) == TRUE) {
      TLS.angles <- c(pitch = 0, roll = 0, azimuth = 0)
    } else if(length(TLS.angles) != 3) {
      stop("The length of the TLS.angles needs to be three representing the pitch, roll, and yaw of the TLS during the scan")
    }
  }


  if(parallel == TRUE & is.null(cores) == TRUE) { ###Data processing
    stop("Select the number of cores to use parallel processing")
  }

  ###Estimates reaturns angles based on the TLS coordinates--------------------------------------------------------------------------------------

  scan <- cbind(scan, cartesian_to_polar(scan[, 1:3], TLS.coordinates, 2)[,1:2])

  if(TLS.type == "multiple") {
    scan[, w := round(1/Target_count, 3),]
  } else if(TLS.type == "single" | TLS.type == "fixed.angle") {
    scan$w <- 1
  }

  if(TLS.type == "multiple" | TLS.type == "single") {
    scan <- scan[between(zenith, zenith.range[1], zenith.range[2]),]
  }

  ###Estimate the number of scanner pulses in a given zenith and azimuth range --------------------------------------------------------------

  if(TLS.type == "multiple" | TLS.type == "single") {  ##Estimate the number per single and multiple
    scanner <- CJ(zenith = seq(TLS.frame[1], TLS.frame[2], TLS.resolution[1]),
                  azimuth = seq(TLS.frame[3], TLS.frame[4], TLS.resolution[2])) #Create grid
    scanner$distance <- 1.000
    scanner <- polar_to_cartesian(scanner, digits = 3) #Get cartesian
    scanner <- move_rotate(scanner, move = NULL, rotate = c(TLS.angles[1], TLS.angles[2], TLS.angles[3])) #Correction of angles
    scanner <- scanner[Z >= 0] #Subset of values
    scanner <- cartesian_to_polar(scanner, NULL, digits = 2) #Get polar
    scanner <- scanner[between(zenith, zenith.range[1], zenith.range[2]) , 1:2]

  } else if(TLS.type == "fixed.angle") { ##Estimate the number per fixed angle
    scanner <- CJ(zenith = TLS.frame[1],
                  azimuth = seq(TLS.frame[2], TLS.frame[3], TLS.resolution[1]))
  }

 #Subset zenith rings

  ###Extraction of the structure metrics------------------------------
  #Set the table for results

  if(TLS.type == "multiple" | TLS.type == "single") {
    mean.bands <- seq((zenith.range[1]+((zenith.range[2]-zenith.range[1])/zenith.rings)/2),
                       zenith.range[2],
                     ((zenith.range[2]-zenith.range[1])/zenith.rings))

    sd.bands <- (zenith.range[2]-zenith.range[1])/zenith.rings/2

    bands <- data.table(rings = seq(1, zenith.rings, 1),
                        mean.zenith = mean.bands)

    frame <- CJ(rings = seq(1, zenith.rings, 1),
                Height = seq(max(scan$Z), 0, -vertical.resolution))

    frame$shots <- NA
    frame$returns_below <- NA
    frame <- merge(bands, frame, by = "rings")

  } else if(TLS.type == "fixed.angle") {
    mean.bands <- TLS.frame[1]

    bands <- data.table(rings = 1,
                        mean.zenith = mean.bands)

    frame <- CJ(rings = 1,
                Height = seq(max(scan$Z), 0, -vertical.resolution))

    frame$shots <- nrow(scanner)
    frame$returns_below <- NA
    frame <- merge(bands, frame, by = "rings")
  }

  #Set the extraction---------------------------------------------------------------------------------------

  if(TLS.type == "multiple" | TLS.type == "single") {   #############If the TLS is multiple or single return
    if(parallel == FALSE) {

      cat(paste("", "Estimating the number of returns and shots", sep = ""))  #Progress bar
      pb <- txtProgressBar(min = 1, max = nrow(frame), style = 3)

      results <- foreach(i = 1:nrow(frame), .inorder = TRUE, .combine= rbind, .packages = c("data.table")) %do% {

        setTxtProgressBar(pb, i)

        frame$shots[i] <- nrow(scanner[between(zenith, frame$mean.zenith[i] - sd.bands, frame$mean.zenith[i] + sd.bands)])
        frame$returns_below[i] <- sum(scan[between(zenith, frame$mean.zenith[i] - sd.bands, frame$mean.zenith[i] + sd.bands) & Z <= frame$Height[i], w])

        return(frame[i])
      }
    }

    if(parallel == TRUE) {

      cat("Estimating the number of returns and shots using parallel processig")
      pb <- txtProgressBar(min = 1, max = nrow(frame), style = 3)
      progress <- function(n) setTxtProgressBar(pb, n)
      opts <- list(progress=progress)

      cl <- makeCluster(cores, outfile="")
      registerDoSNOW(cl)

      results <- foreach(i = 1:nrow(frame), .inorder = TRUE, .combine= rbind, .packages = c("data.table"), .options.snow = opts) %dopar% {

        frame$shots[i] <- nrow(scanner[between(zenith, frame$mean.zenith[i] - sd.bands, frame$mean.zenith[i] + sd.bands)])
        frame$returns_below[i] <- sum(scan[between(zenith, frame$mean.zenith[i] - sd.bands, frame$mean.zenith[i] + sd.bands) & Z <= frame$Height[i], w])

        return(frame[i])
      }

      close(pb)
      stopCluster(cl)
    }

  } else if(TLS.type == "fixed.angle") { #############If the TLS is fixed.angle
    if(parallel == FALSE) {

      cat(paste("", "Estimating the number of returns and shots", sep = ""))  #Progress bar
      pb <- txtProgressBar(min = 1, max = nrow(frame), style = 3)

      results <- foreach(i = 1:nrow(frame), .inorder = TRUE, .combine= rbind, .packages = c("data.table")) %do% {

        setTxtProgressBar(pb, i)

        frame$returns_below[i] <- sum(scan[Z <= frame$Height[i], w])

        return(frame[i])
      }
    }

    if(parallel == TRUE) {

      cat("Estimating the number of returns and shots using parallel processig")
      pb <- txtProgressBar(min = 1, max = nrow(frame), style = 3)
      progress <- function(n) setTxtProgressBar(pb, n)
      opts <- list(progress=progress)

      cl <- makeCluster(cores, outfile="")
      registerDoSNOW(cl)

      results <- foreach(i = 1:nrow(frame), .inorder = TRUE, .combine= rbind, .packages = c("data.table"), .options.snow = opts) %dopar% {

        frame$returns_below[i] <- sum(scan[Z <= frame$Height[i], w])

        return(frame[i])
      }

      close(pb)
      stopCluster(cl)
    }
  }

  #####Estimation of the canopy structure metrics-------------------------------------------------------------------------------------

  results[, Pgap := (1- (returns_below/shots)), by = seq_len(nrow(frame))]

  if(TLS.type == "fixed.angle") {  ###If fixed.angle

    final <- reshape(results[, c("rings" ,"Height", "Pgap")],
                       v.names = "Pgap",
                       idvar = "Height",
                       timevar= "rings",
                       direction= "wide")

    colnames(final) <- c("Height", paste("", "Pgap(", mean.bands, ")", sep = ""))

    col_hinge <- which(abs(mean.bands - 57.5) == min(abs(mean.bands - 57.5)))

    final$'L (hinge)' <- -1.1 * log10(final[, .SD, .SDcols= c(col_hinge+1)])

    for(i in 1:nrow(final)) {

      ld <- final$'L (hinge)'[i+1]-final$L[i]
      final$PAVD[i] <- ld/vertical.resolution

    }
  } else {  ###If multi or single scan

    results[, 'L/LAI' := log10(Pgap)/log10(min(Pgap)), by = rings] #Normalize L/LAI
    results[, 'L/LAI (weighted.mean)' := lapply(.SD, weighted.mean, w = 1:zenith.rings), by = Height, .SDcols=c('L/LAI')] #weighted.mean L/LAI

    final <- reshape(results[, c("rings" ,"Height", "Pgap")],
                       v.names = "Pgap",
                       idvar = "Height",
                       timevar= "rings",
                       direction= "wide")

    colnames(final) <- c("Height", paste("", "Pgap(", mean.bands, ")", sep = ""))

    col_hinge <- which(abs(mean.bands - 57.5) == min(abs(mean.bands - 57.5)))
    subset_results <- subset(results, rings == col_hinge)

    final[, 'L (hinge)' := -1.1 * log10(subset_results$Pgap)] ###Estimates the L close to hinge
    final[, 'L/LAI (weighted mean)' := subset_results$`L/LAI (weighted.mean)`]

    max_LAI <- as.numeric(final[which.max(Height), 'L (hinge)'])

    final$PAVD <- NA

    for(i in 1:nrow(final)) {  ###Estimates PAVD
      ld <- final$'L/LAI (weighted mean)'[i+1]-final$'L/LAI (weighted mean)'[i]
      final$PAVD[i] <- max_LAI*(ld/vertical.resolution)
    }
  }

  return(final)
}
