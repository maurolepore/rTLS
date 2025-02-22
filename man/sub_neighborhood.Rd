% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sub_neighborhood.R
\name{sub_neighborhood}
\alias{sub_neighborhood}
\title{Subsample Neighboring Points}
\usage{
sub_neighborhood(neig.obj, method, new_radius, new_k)
}
\arguments{
\item{neig.obj}{An object of class \code{"neighborhood"}.}

\item{method}{A \code{character} string specifying the method to subsample the neighboring points. It most be one of \code{"sphere"} or \code{"knn"}.}

\item{new_radius}{A \code{numeric} vector of a length 1 representing the new radius to consider. This will be used if \code{method = "sphere"}. To be functional, \code{"new_radius"} most be lower than \code{"radius"} used in \code{\link{neighborhood}}.}

\item{new_k}{An integer of a length 1 representing the new number of neighbors to consider. This will be used if \code{method = "knn"}. To be functional, \code{"new_k"} most be lower than \code{"k"} used in \code{\link{neighborhood}}.}
}
\value{
An object of class \code{\link{neighborhood}} with a list per point of the neighboring points.
}
\description{
Subsample the neighboring points based in a radius of a shpere or knn.
}
\examples{
data("pc_tree")

#Calculate the neighborhood of a sample using the sphere method and a 0.2 of radius.
cloud.random <- pc_tree[sample(nrow(pc_tree), 1000), ]
dist <- neighborhood(cloud.random, pc_tree, method = "sphere", radius = 0.2)

#Subset neighboring points from a 0.2 of radius to 0.1.
sub_neighborhood(dist, method = "sphere", new_radius = 0.1)

}
\seealso{
\code{\link{knn_neighbors}}, \code{\link{sphere_neighbors}}, \code{\link{neighborhood}}
}
\author{
J. Antonio Guzmán  Q.
}
