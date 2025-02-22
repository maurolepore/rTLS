% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/basic_metrics.R
\name{basic_metrics}
\alias{basic_metrics}
\title{Basic Metrics of the Neighboring Points.}
\usage{
basic_metrics(space, radius = NULL)
}
\arguments{
\item{space}{A \code{data.table} with *XYZ* coordinates of the neighboring points in the first three columns and a four column with their distance to the target point.}

\item{radius}{A \code{numeric} vector of a length 1 representing the radius of the sphere that was used. If \code{NULL}, it uses the maximum distance of \code{space} (\code{max(space[,4])}). \code{NULL} as default.}
}
\value{
A \code{data.table} with four columns, which represent metrics: i) the number of neighboring points, ii) the volume occupied by neighbors, iii) volume of the sphere used, and iv) density of points based on the sphere size. If \code{NULL}, the volume occupied by neighbors and the volume of the sphere is the same.
}
\description{
It estimates basic metrics of the surrounding neighboring points created based on a target point.
}
\examples{
data("pc_tree")
neig <- neighborhood(pc_tree[50,], pc_tree, method = "sphere", radius = 0.2)
basic_metrics(neig$neighborhood[, 2:5], radius = neig$parameter)

}
\seealso{
\code{\link{distribution}}, \code{\link{dimensionality}}, \code{\link{cloud_metrics}}, \code{\link{neighborhood}}
}
\author{
J. Antonio Guzman Q. and Ronny Hernandez
}
