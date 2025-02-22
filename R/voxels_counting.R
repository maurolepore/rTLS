#' @title Voxels Counting
#'
#' @description Creates voxels of different size on a point cloud using the \code{\link{voxels}} function, and then return a \code{\link{summary_voxels}} of their features.
#'
#' @param cloud A \code{data.table} with xyz coordinates of the point clouds in the first three columns.
#' @param voxel.sizes A positive \code{numeric} vector describing the different voxel size to perform. If \code{NULL}, it use 10 voxel sizes by defaul based on the largest range of XYZ.
#' @param min.size A positive \code{numeric} vector of length 1 describing the minimum voxel size to perform. This is required if \code{voxel.sizes = NULL}.
#' @param length.out A positive \code{interger} of length 1 indicating the number of different voxel sizes to use. This is required if \code{voxel.sizes = NULL}.
#' @param bootstrap Logical. If \code{TRUE}, it computes a bootstrap on the H index calculations. \code{FALSE} as default.
#' @param R A positive \code{integer} of length 1 indicating the number of bootstrap replicates. This need to be used if \code{bootstrap = TRUE}.
#' @param progress Logical, if \code{TRUE} displays a graphical progress bar. \code{TRUE} as default.
#' @param parallel Logical, if \code{TRUE} it uses a parallel processing for the voxelization. \code{FALSE} as default.
#' @param cores An \code{integer} >= 0 describing the number of cores to use. This need to be used if \code{parallel = TRUE}.
#'
#' @importFrom parallel makeCluster
#' @importFrom parallel stopCluster
#' @importFrom doSNOW registerDoSNOW
#' @importFrom foreach foreach
#' @importFrom foreach %dopar%
#' @importFrom foreach %do%
#'
#' @seealso \code{\link{voxels}}, \code{\link{summary_voxels}}, \code{\link{plot_voxels}}
#'
#' @return A \code{data.table} with the summary of the voxels created with their features.
#' @author J. Antonio Guzmán Q.
#' @examples
#'
#' data(pc_tree)
#'
#' #Applying voxels counting.
#' voxels_counting(pc_tree, min.size = 0.05)
#'
#' #Voxels counting using boostrap on the H indixes with 1000 repetitions.
#' voxels_counting(pc_tree, min.size = 0.05, bootstrap = TRUE, R = 1000)
#'
#' \dontrun{
#' #Voxels counting using bootstrap on the H indices and using parallel processing.
#' voxels_counting(pc_tree, min.size = 0.05, bootstrap = TRUE, R = 1000, parallel = TRUE, cores = 4)
#' }
#'
#' @export
voxels_counting <- function(cloud, voxel.sizes = NULL, min.size, length.out = 10, bootstrap = FALSE, R = NULL, progress = TRUE, parallel = FALSE, cores = NULL) {

  colnames(cloud) <- c("X", "Y", "Z")

  if(is.null(voxel.sizes) == TRUE) { ###Default voxel.sizes
    ranges <- c(max(cloud[,1]) - min(cloud[,1]), max(cloud[,2]) - min(cloud[,2]), max(cloud[,3]) - min(cloud[,3]))
    max.range <- ranges[which.max(ranges)] + 0.001
    voxel.sizes <- seq(from = log10(c(max.range)), to = log10(min.size), length.out = length.out)
    voxel.sizes <- 10^voxel.sizes
  }

  cloud_touse <- cloud


  if(parallel == TRUE) { ###If parallel is true

    cl <- makeCluster(cores, outfile="") #Make clusters
    registerDoSNOW(cl)

    if(progress == TRUE) {
      print("Creating voxels in parallel")  #Progress bar
      pb <- txtProgressBar(min = 0, max = length(voxel.sizes), style = 3)
      progress <- function(n) setTxtProgressBar(pb, n)
      opts <- list(progress=progress)

    } else {
      opts <- NULL
    }

    #Run in parallel
    results <- foreach(i = 1:length(voxel.sizes), .inorder = FALSE, .combine= rbind, .packages = c("data.table", "rTLS"), .options.snow = opts) %dopar% {
      vox <- voxels(cloud_touse, voxel.size = voxel.sizes[i], obj.voxels = FALSE)
      summary <- summary_voxels(vox, voxel.size = voxel.sizes[i], bootstrap = bootstrap, R = R)
      return(summary)
    }

    results <- results[order(Voxel.size)]

    stopCluster(cl)

  } else if(parallel == FALSE) { ###If parallel is false

    if(progress == TRUE) {
      print("Creating voxels")
      pb <- txtProgressBar(min = 0, max = length(voxel.sizes), style = 3) #Progress bar
    }

    #Run without using parallel
    results <- foreach(i = 1:length(voxel.sizes), .inorder = FALSE, .combine= rbind) %do% {

      if(progress == TRUE) {
        setTxtProgressBar(pb, i)
      }

      vox <- voxels(cloud_touse, voxel.size = voxel.sizes[i], obj.voxels = FALSE)
      summary <- summary_voxels(vox, voxel.size = voxel.sizes[i], bootstrap = bootstrap, R = R)
      return(summary)
    }

    if(progress == TRUE) {
      close(pb) #Close clusters
    }

    results <- results[order(Voxel.size)]
  }
  return(results)
}

decimals <- function(x) {
  n <- 0
  while (!isTRUE(all.equal(floor(x),x)) & n <= 1e6) { x <- x*10; n <- n+1 }
  return (n)
}

