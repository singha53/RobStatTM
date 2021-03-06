% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/lmrob.MM.R
\name{lmrob.control.neededOnly}
\alias{lmrob.control.neededOnly}
\title{Minimize lmrob control to non-redundant parts}
\usage{
lmrob.control.neededOnly(control)
}
\arguments{
\item{control}{a list, typically the 'control' component of a
\code{\link{lmrob}()} call, or the result of  \code{\link{lmrob.control}()}.}
}
\value{
list: the (typically) modified \code{control}
}
\description{
Modify a \code{\link{lmrob.control}} list to contain only parameters that
were actually used.  Currently used for \code{\link{print}()}ing of lmrob
objects.
}
\author{
Martin Maechler {from Manuel's original code}
}
