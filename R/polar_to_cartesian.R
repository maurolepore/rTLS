#' @title Polar to Cartesian Coordinates
#'
#' @description Convert from polar to cartesian coordinates.
#'
#' @param polar A \code{data.table} with three columns describing the zenith, azimuth, and distance of a point.
#' @param digits A \code{numeric} vector of length 1 describing the decimal numbers to \code{\link{round}} the cartesian coordinates. If \code{NULL}, \code{\link{round}} does not apply. \code{NULL} as default.
#'
#' @return A \code{data.table} with three columns describing the *XYZ* of the cartesian coordinates.
#'
#' @author J. Antonio Guzmán Q.
#'
#' @seealso \code{\link{cartesian_to_polar}}
#'
#' @examples
#'
#' #Creates a hemisphere of points each 2 degrees
#'
#' zenith <- seq(0, 90, 2)
#' azimuth <- seq(0, 360, 2)
#' hemi <- CJ(zenith, azimuth)
#' hemi$distance <- 1
#' hemicloud <- polar_to_cartesian(hemi)
#' rgl::plot3d(hemicloud)
#'
#' @export
polar_to_cartesian <- function(polar, digits = NULL) {

  colnames(polar)[1:3] <- c("zenith", "azimuth", "distance")

  polar[ , c("X", "Y", "Z") := list((distance * (cos((azimuth*pi)/180) * sin((zenith*pi)/180))),
                                    (distance * (sin((azimuth*pi)/180) * sin((zenith*pi)/180))),
                                    (distance * cos((zenith*pi)/180))), by = seq_len(nrow(polar))]


  if(is.null(digits) != TRUE) {
    polar <- polar[, c("X", "Y", "Z") := round(.SD, digits), .SDcols= c("X", "Y", "Z")]
  }

  return(polar[ , 4:6])
}

