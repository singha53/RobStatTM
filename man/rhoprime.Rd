% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/psiFuns.R
\name{rhoprime}
\alias{rhoprime}
\title{The first derivative of the rho function}
\usage{
rhoprime(u, family, cc, standardize = FALSE)
}
\arguments{
\item{u}{point or vector at which rho is to be evaluated}

\item{family}{family string specifying the name of the family of loss function to be used (current valid
options are "bisquare", "optimal" and "modified.optimal").}

\item{cc}{tuning parameters to be computed according to efficiency and / or breakdown
considerations. See \link{lmrobdet.control}, \link{bisquare}, \link{modified.optimal}
and \link{optimal}.}

\item{standardize}{logical value determining whether the rho function is to be
standardized so that its maximum value is 1. See \link{Mpsi}.}
}
\value{
The value of the first derivative \code{rho} evaluated at \code{u}
}
\description{
The first derivative of the rho function
}
\author{
Matias Salibian-Barrera, \email{matias@stat.ubc.ca}
}
