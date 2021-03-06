% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/MultiRobu.R
\name{MultiRobu}
\alias{MultiRobu}
\title{Robust multivariate location and scatter estimators}
\usage{
MultiRobu(X, type = "auto")
}
\arguments{
\item{X}{a data matrix with observations in rows.}

\item{type}{a string indicating which estimator to compute. Valid options
are "Rocke" for Rocke's S-estimator, "MM" for an MM-estimator with a 
SHR rho function, or "auto" (default) which selects "Rocke" if the number 
of variables is greater than or equal to 10, and "MM" otherwise.}
}
\value{
A list with the following components:
\item{mu}{The location estimator}
\item{V}{The scatter matrix estimator, scaled for consistency at the normal distribution}
\item{dist}{Robust Mahalanobis distances}
}
\description{
This function computes robust estimators for multivariate location and scatter.
}
\details{
This function computes robust estimators for multivariate location and scatter.
}
\references{
\url{http://thebook}
}
\author{
Ricardo Maronna, \email{rmaronna@retina.ar}
}
