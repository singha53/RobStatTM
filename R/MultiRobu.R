#' Robust multivariate location and scatter estimators
#'
#' This function computes robust estimators for multivariate location and scatter.
#'
#' This function computes robust estimators for multivariate location and scatter.
#'
#' @param X a data matrix with observations in rows.
#' @param type a string indicating which estimator to compute. Valid options
#' are "Rocke" for Rocke's S-estimator, "MM" for an MM-estimator with a 
#' SHR rho function, or "auto" (default) which selects "Rocke" if the number 
#' of variables is greater than or equal to 10, and "MM" otherwise.  
#'
#' @return A list with the following components:
#' \item{mu}{The location estimator}
#' \item{V}{The scatter matrix estimator, scaled for consistency at the normal distribution}
#' \item{dist}{Robust Mahalanobis distances}
#' 
#' @author Ricardo Maronna, \email{rmaronna@retina.ar}
#'
#' @references \url{http://thebook}
#'
#' @export
MultiRobu<-function(X,type="auto")  {
if (type=="auto") {
  p=dim(X)[2]
  if (p<10) {type="MM"
  } else {type="Rocke"}
}  
  
 if (type=="Rocke") {
   resu=RockeMulti(X)
 } else {resu=MMultiSHR(X)  #MM
 }
  mu=resu$mu; V=resu$V
  return(list(mu=mu, V=V, dist=mahalanobis(X,mu,V)))
}

########
#Rocke S-estimator
RockeMulti <- function(X, initial='K', maxsteps=5, propmin=2, qs=2, maxit=50, tol=1e-4)
{
  d <- dim(X)
  n <- d[1]
  p <- d[2]


  gamma0 <- consRocke(p=p, n=n, initial )$gamma # tuning constant
  if(initial=='K')
{  out=KurtSDNew(X)
   mu0=out$center; V0=out$cova
   V0=V0/(det(V0)^(1/p))
dista0=mahalanobis(X,mu0,V0)
dista=dista0}

if(initial=='mve')
{out=fastmve(X)

mu0=out$center
    V0=out$cov
   V0=V0/(det(V0)^(1/p))
dista0=mahalanobis(X,mu0,V0)
dista=dista0}
 

  delta <- (1-p/n)/2 # max breakdown
  #gamma0 <- consRocke(p,n,'K')$gamma
  sig <- MScalRocke(x=dista, gamma=gamma0, q=qs, delta=delta) #Inicializar
  # %Buscar gama que asegure que al menos p*propmin elementos tengan w>0
  didi <- dista / sig
  dife <- sort( abs( didi - 1) )
  gg <- min( dife[ (1:n) >= (propmin*p) ] )
  gamma <- max(gg, gamma0)
#print(gamma)
  sig0 <- MScalRocke(x=dista, gamma=gamma, delta=delta, q=qs)
  
  iter <- 0
  difpar <- difsig <- +Inf
  while( ( ( (difsig > tol) | (difpar > tol) ) & 
           (iter < maxit) ) & (difsig > 0) ) {
    iter <- iter + 1
    w <- WRoTru(tt=dista/sig, gamma=gamma, q=qs)
    mu <- colMeans( X * w ) / mean(w) # as.vector( t(w) %*% X ) / sum(w)
    Xcen <- scale(X, center=mu, scale=FALSE)
    V <- t(Xcen) %*% (Xcen * w) / n;
    V <- V / ( det(V)^(1/p) )
    dista <- mahalanobis(x=X, center=mu, cov=V)

    sig <- MScalRocke(x=dista, gamma=gamma, delta=delta, q=qs)
    # %Si no desciende, hacer Line search
    step <- 0
    delgrad <- 1
    while( (sig > sig0) & (step < maxsteps) ) {
      delgrad <- delgrad / 2
      step <- step + 1
      mu <- delgrad * mu + (1 - delgrad)*mu0
      V <- delgrad*V + (1-delgrad)*V0
      V <- V / ( det(V)^(1/p) )
      dista <- mahalanobis(x=X, center=mu, cov=V)

      sig <- MScalRocke(x=dista, gamma=gamma, delta=delta, q=qs)
    }
    dif1 <- as.vector( t(mu - mu0) %*% solve(V0, mu-mu0) ) / p
    dif2 <- max(abs(solve(V0, V)-diag(p)))
    difpar <- max(dif1, dif2)
    difsig <- 1 - sig/sig0
    mu0 <- mu
    V0 <- V
    sig0 <- sig
  }
  tmp <- scalemat(V0=V0, dis=dista, weight='X')
  V <- tmp$V
  ff <- tmp$ff
  dista <- dista/ff
  return(list(mu=mu, V=V, sig=sig, dista=dista, w=w, gamma=gamma))
}

consRocke <- function(p, n, initial) {
  if(initial=='M') {
    beta <- c(-5.4358, -0.50303, 0.4214)
  } else { 
    beta <- c(-6.1357, -1.0078, 0.81564)
  }
  if( p >= 15 ) {
    a <- c(1, log(p), log(n))
    alpha <- exp( sum( beta*a ) )
    gamma <- qchisq(1-alpha, df=p)/p - 1
    gamma <- min(gamma, 1)
  } else {
    gamma <- 1
    alpha <- 1e-6
  }
  return(list(gamma=gamma, alpha=alpha))
}


WRoTru <- function(tt, gamma, q) {
  ss <- (tt - 1) / gamma
  w <- 1 - ss^q
  w[ abs(ss) > 1 ] <- 0
  return(w)
}


rhorotru <- function(tt, gamma, q) {
  u <- (tt - 1) / gamma
  y <- ( (u/(2*q)*(q+1-u^q) +0.5) )
  y[ u >= 1 ] <- 1
  y[ u < (-1) ] <- 0
  return(y)
}



MScalRocke <- function(x, gamma, q, delta = 0.5, tol=1e-5) 
{
  # sigma= solucion de ave{rhorocke1(x/sigma)}=delta
  n <- length(x) 
  y <- sort(abs(x))
  n1 <- floor(n * (1-delta) )
  n2 <- ceiling(n * (1 - delta) / (1 - delta/2) )
  qq <- y[c(n1, n2)]
  u <- 1 + gamma*(delta-1)/2 #asegura rho(u)<delta/2
  sigin <- c(qq[1]/(1+gamma), qq[2]/u)
  if( qq[1] >= 1) { 
    tolera <- tol 
  } else { 
    tolera <- tol * qq[1] 
  }
  if( mean(x==0) > (1-delta) ) { 
    sig <- 0 
  } else {
    sig <- uniroot(f=averho, interval=sigin, x=x, 
                   gamma=gamma, delta=delta, q=q, tol=tolera)$root
  } # solucion de ave{rhorocke1(x/sigma)}=delta
  return(sig)
}

averho <- function(sig, x, gamma, delta, q)
  return( mean( rhorotru(x/sig, gamma, q) ) - delta )


scalemat <- function(V0, dis, weight='X')
{
  p <- dim(V0)[1]
  if( weight == 'M') {
    sig <- M_Scale(x=sqrt(dis), normz=0)^2
    cc <- 4.8421*p-2.5786 #ajuste empirico
  } else {
    sig <- median(dis)
    cc <- qchisq(0.5, df=p)
  }    
  ff <- sig/cc
  return(list(ff=ff, V=V0*ff))
}


M_Scale <- function(x, normz=1, delta=0.5, tol=1e-5)
{
  n <- length(x)
  y <- sort(abs(x))
  n1 <- floor(n*(1-delta))
  n2 <- ceiling(n*(1-delta)/(1-delta/2));
  qq <- y[c(n1, n2)] 
  u <- rhoinv(delta/2)
  sigin <- c(qq[1],  qq[2]/u) # intervalo inicial
  if (qq[1]>=1) {
    tolera=tol
  } else { 
    tolera = tol * qq[1]
  }
  #tol. relativa o absol. si sigma> o < 1
  if( mean(x==0) >= (1-delta) ) {
    sig <- 0
  } else {
    sig <- uniroot(f=averho.uni, interval=sigin, x=x, 
                   delta=delta, tol=tolera)$root
  }
  if( normz > 0) sig <- sig / 1.56
  return(sig)
}



rhobisq <- function(x) {
  r <- 1 - (1-x^2)^3
  r[ abs(x) > 1 ] <- 1
  return(r)
}

averho.uni <- function(sig, x, delta) 
  return( mean( rhobisq(x/sig) ) - delta )

rhoinv <- function(x) 
  return(sqrt(1-(1-x)^(1/3)))

############################
# Multivariate MM estimator with SHR rho
MMultiSHR <- function(X, maxit=50, tolpar=1e-4) {
  d <- dim(X)
  n <- d[1]; p <- d[2]
  delta <- 0.5*(1-p/n) #max. breakdown
  cc <- consMMKur(p,n)
  const <- cc[1]
  out=KurtSDNew(X)
  mu0=out$center; V0=out$cova
  V0=V0/(det(V0)^(1/p))
  distin=mahalanobis(X,mu0,V0)

  sigma <- MscalSHR(t=distin, delta=delta)*const;
  iter <- 0
  difpar <- +Inf
  V0 <- diag(p)
  mu0 <- rep(0, p)
  dista <- distin
  while ((difpar>tolpar) & (iter<maxit)) {
    iter <- iter+1
    w <- weightsSHR(dista/sigma)
    mu <- colMeans(X * w) / mean(w) # mean(repmat(w,1,p).*X)/mean(w)
    Xcen <- scale(X, center=mu, scale=FALSE)
    V <- t(Xcen) %*% (Xcen * w) # Xcen'*(repmat(w,1,p).*Xcen);
    V <- V/(det(V)^(1/p)) # set det=1
    # V0in <- solve(V0);
    dista <- mahalanobis(x=X,center=mu, cov=V) # %rdis=sqrt(dista);
    dif1 <- t(mu - mu0) %*% solve(V0, mu-mu0) # (mu-mu0)*V0in*(mu-mu0)' 
    dif2 <-  max(abs(c(solve(V0, V) - diag(p)))) # max(abs(V0in*V-eye(p)));
    difpar <- max(c(dif1, dif2)) #errores relativos de parametros
    mu0 <- mu
    V0 <- V
  }
  tmp <- scalemat(V0=V0, dis=dista, weight='X'); 
  dista <- dista/tmp$ff
  return(list(V=tmp$V, mu=mu0, dista=dista, w=w))
}


MscalSHR <- function(t, delta=0.5, sig0=median(t), niter=50, tol=1e-4) { 
  if(mean(t<1e-16) >= 0.5) { sig <- 0
  } else { # fixed point
    sig1 <- sig0
    y1 <- meanrhoSHR(sig1, t, delta)
    # make meanrho(sig11, t) <= sig1
    while( (y1 > sig1) & ( (sig1/sig0) < 1000) ) {
      sig1 <- 2*sig1
      y1 <- meanrhoSHR(sig1, t, delta) 
    }
    if( (sig1/sig0) >= 1000) { warning('non-convex function') 
      sig <- sig0 } else {
        iter <- 0
        sig2 <- y1
        while( iter <= niter) {
          iter <- iter+1
          y2 <- meanrhoSHR(sig2, t, delta) 
          den <- sig2-y2+y1-sig1 # secante
          if( abs(den) < tol*sig1) {
            sig3 <- sig2
            iter <- niter+1 } else {
              sig3 <- (y1*sig2-sig1*y2)/den
            }
          sig1 <- sig2
          sig2 <- sig3
          y1 <- y2
        }
        sig <- sig2
      }  
  }
  return(sig)
}


meanrhoSHR <- function(sig, d, delta) {
  return( sig * mean( rhoSHR( d/sig )) /delta )
}

rhoSHR <- function(d)  { # SHR # Optima, squared distances (d=x^2)
  G1 <- (-1.944)
  G2 <- 1.728
  G3 <- (-0.312)
  G4 <- 0.016 
  u <- (d > 9.0) 
  v <- (d < 4)
  w <- (1-u)*(1-v)
  z <- v*d/2 + w*((G4/8)*(d^4) + (G3/6)*(d^3) + 
                    (G2/4)*(d^2)+ (G1/2)*d + 1.792) + 3.25*u
  z <- z/3.25
  return(z)
}


weightsSHR <- function(d){ # derivative of SHR rho
  G1 <- (-1.944)
  G2 <- 1.728
  G3 <- (-0.312)
  G4 <- 0.016
  u <- (d > 9.0)
  v <- (d < 4)
  w <- (1-u)*(1-v)
  z <- v/2+ w*((G4/2)*(d^3) + (G3/2)*(d^2) +(G2/2)*d+ (G1/2));
  w <- z/3.25
  return(w)
}

consMMKur <- function(p, n) {
  # Constante para eficiewncia 90% de MM, partiendo de KSD (Pe?a-Prieto)
  # cc(1): rho "SHR" ("Optima"), cc(2): Bisquare
  x <- c(1/p, p/n, 1)
  beta <- c(4.5041, -1.1117, 0.61161, 2.5724, -0.7855, 0.716)
  beta <- matrix(beta, byrow=TRUE, ncol=3)
  return( t(x) %*% t(beta) )
}




mahdist <- function(x, center=c(0,0), cov) 
{
x <- as.matrix(x)
if(any(is.na(cov)))
	stop("Missing values in covariance matrix not allowed")
if(any(is.na(center)))
	stop("Missing values in center vector not allowed")
dx <- dim(x)
p <- dx[2]
if(length(center) != p)
	stop("center is the wrong length")
# produce the inverse of the covariance matrix
if(!is.qr(cov)) cov <- qr(cov)
dc <- dim(cov$qr)
if(p != dc[1] || p != dc[2])
	stop("Covariance matrix is the wrong size")
rank.cov <- cov$rank
flag.rank <- (rank.cov < p)
mahdist <- NA
if(!flag.rank)  {
	#cov.inv <- rep(c(1, rep(0, p)), length = p * p)
	#dim(cov.inv) <- c(p, p)
	#cov.inv <- qr.coef(cov, cov.inv)
	n <- dx[1]
 	mahdist <- mahalanobis(x, center=center, cov=cov)
 	if(length(dn <- dimnames(x)[[1]]))
  		names(mahdist) <- dn
}
ans <- list(mahdist,flag.rank)
names(ans) <- c("mahdist","flag.rank")
ans
}
##############################3
desceRocke <- function(X, gamma0, muini, Vini, 
                       maxsteps=5, propmin=2, 
                       qs=2, maxit=50, tol=1e-4)
## Iterations to minimize Rocke's scale strting from initial vector muini and matrix Vini  
{
  d <- dim(X)
  n <- d[1]
  p <- d[2]
  delta <- (1-p/n)/2 # max breakdown
  mu0 <- muini
  V0 <- Vini
  dista <- dista0 <- mahalanobis(x=X,center=mu0,cov=V0);
  gamma0 <- consRocke(p,n,'K')$gamma
  sig <- MScalRocke(x=dista, gamma=gamma0, q=qs, delta=delta) #Inicializar
  # %Buscar gama que asegure que al menos p*propmin elementos tengan w>0
  didi <- dista / sig
  dife <- sort( abs( didi - 1) )
  gg <- min( dife[ (1:n) >= (propmin*p) ] )
  gamma <- max(gg, gamma0)
  sig0 <- MScalRocke(x=dista, gamma=gamma, delta=delta, q=qs)
  
  iter <- 0
  difpar <- difsig <- +Inf
  while( ( ( (difsig > tol) | (difpar > tol) ) & 
           (iter < maxit) ) & (difsig > 0) ) {
    iter <- iter + 1
    w <- WRoTru(tt=dista/sig, gamma=gamma, q=qs)
    mu <- colMeans( X * w ) / mean(w) # as.vector( t(w) %*% X ) / sum(w)
    Xcen <- scale(X, center=mu, scale=FALSE)
    V <- t(Xcen) %*% (Xcen * w) / n;
    V <- V / ( det(V)^(1/p) )
    dista <- mahalanobis(x=X, center=mu, cov=V)
    sig <- MScalRocke(x=dista, gamma=gamma, delta=delta, q=qs)
    # %Si no desciende, hacer Line search
    step <- 0
    delgrad <- 1
    while( (sig > sig0) & (step < maxsteps) ) {
      delgrad <- delgrad / 2
      step <- step + 1
      mu <- delgrad * mu + (1 - delgrad)*mu0
      V <- delgrad*V + (1-delgrad)*V0
      V <- V / ( det(V)^(1/p) )
      dista <- mahalanobis(x=X, center=mu, cov=V)
      sig <- MScalRocke(x=dista, gamma=gamma, delta=delta, q=qs)
    }
    dif1 <- as.vector( t(mu - mu0) %*% solve(V0, mu-mu0) ) / p
    dif2 <- max(abs(solve(V0, V)-diag(p)))
    difpar <- max(dif1, dif2)
    difsig <- 1 - sig/sig0
    mu0 <- mu
    V0 <- V
    sig0 <- sig
  }
  tmp <- scalemat(V0=V0, dis=dista, weight='M')
  V <- tmp$V
  ff <- tmp$ff
  dista <- dista/ff
  return(list(mu=mu, V=V, sig=sig, dista=dista, w=w, gamma=gamma))
}



consRocke <- function(p, n, initial) {
  if(initial=='M') {
    beta <- c(-5.4358, -0.50303, 0.4214)
  } else { 
    beta <- c(-6.1357, -1.0078, 0.81564)
  }
  if( p >= 15 ) {
    a <- c(1, log(p), log(n))
    alpha <- exp( sum( beta*a ) )
    gamma <- qchisq(1-alpha, df=p)/p - 1
    gamma <- min(gamma, 1)
  } else {
    gamma <- 1
    alpha <- 1e-6
  }
  return(list(gamma=gamma, alpha=alpha))
}


WRoTru <- function(tt, gamma, q) {
  ss <- (tt - 1) / gamma
  w <- 1 - ss^q
  w[ abs(ss) > 1 ] <- 0
  return(w)
}


rhorotru <- function(tt, gamma, q) {
  u <- (tt - 1) / gamma
  y <- ( (u/(2*q)*(q+1-u^q) +0.5) )
  y[ u >= 1 ] <- 1
  y[ u < (-1) ] <- 0
  return(y)
}



MScalRocke <- function(x, gamma, q, delta = 0.5, tol=1e-5) 
{
  # sigma= solucion de ave{rhorocke1(x/sigma)}=delta
  n <- length(x) 
  y <- sort(abs(x))
  n1 <- floor(n * (1-delta) )
  n2 <- ceiling(n * (1 - delta) / (1 - delta/2) )
  qq <- y[c(n1, n2)]
  u <- 1 + gamma*(delta-1)/2 #asegura rho(u)<delta/2
  sigin <- c(qq[1]/(1+gamma), qq[2]/u)
  if( qq[1] >= 1) { 
    tolera <- tol 
  } else { 
    tolera <- tol * qq[1] 
  }
  if( mean(x==0) > (1-delta) ) { 
    sig <- 0 
  } else {
    sig <- uniroot(f=averho, interval=sigin, x=x, 
                   gamma=gamma, delta=delta, q=q, tol=tolera)$root
  } # solucion de ave{rhorocke1(x/sigma)}=delta
  return(sig)
}

averho <- function(sig, x, gamma, delta, q)
  return( mean( rhorotru(x/sig, gamma, q) ) - delta )


scalemat <- function(V0, dis, weight='M')
{
  p <- dim(V0)[1]
  if( weight == 'M') {
    sig <- M_Scale(x=sqrt(dis), normz=0)^2
    cc <- 4.8421*p-2.5786 #ajuste empirico
  } else {
    sig <- median(dis)
    cc <- qchisq(0.5, df=p)
  }    
  ff <- sig/cc
  return(list(ff=ff, V=V0*ff))
}


M_Scale <- function(x, normz=1, delta=0.5, tol=1e-5)
{
  n <- length(x)
  y <- sort(abs(x))
  n1 <- floor(n*(1-delta))
  n2 <- ceiling(n*(1-delta)/(1-delta/2));
  qq <- y[c(n1, n2)] 
  u <- rhoinv(delta/2)
  sigin <- c(qq[1],  qq[2]/u) # intervalo inicial
  if (qq[1]>=1) {
    tolera=tol
  } else { 
    tolera = tol * qq[1]
  }
  #tol. relativa o absol. si sigma> o < 1
  if( mean(x==0) >= (1-delta) ) {
    sig <- 0
  } else {
    sig <- uniroot(f=averho.uni, interval=sigin, x=x, 
                   delta=delta, tol=tolera)$root
  }
  if( normz > 0) sig <- sig / 1.56
  return(sig)
}



rhobisq <- function(x) {
  r <- 1 - (1-x^2)^3
  r[ abs(x) > 1 ] <- 1
  return(r)
}

averho.uni <- function(sig, x, delta) 
  return( mean( rhobisq(x/sig) ) - delta )

rhoinv <- function(x) 
  return(sqrt(1-(1-x)^(1/3)))


