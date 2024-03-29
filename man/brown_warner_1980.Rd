% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/parametric_tests.R
\name{brown_warner_1980}
\alias{brown_warner_1980}
\title{Brown and Warner parametric test (1980).}
\usage{
brown_warner_1980(list_of_returns, event_start, event_end)
}
\arguments{
\item{list_of_returns}{a list of objects of S3 class \code{returns}, each
element of which is treated as a security.}

\item{event_start}{an object of \code{Date} class giving the first date of
the event period.}

\item{event_end}{an object of \code{Date} class giving the last date of the
event period.}
}
\value{
A data frame of the following columns:
\itemize{
    \item \code{date}: a calendar date
    \item \code{weekday}: a day of the week
    \item \code{percentage}: a share of non-missing observations for a given
          day
    \item \code{mean}: an average abnormal return
    \item \code{bw_1980_stat}: a Brown and Warner (1980) test statistic
    \item \code{bw_1980_signif}: a significance of the statistic
}
}
\description{
An event study parametric test described in Brown and Warner 1980.
}
\details{
Performs a parametric test for the event study, which is described in
Brown and Warner 1980. The test assumes a cross-sectional independence
and an insignificance of event-induced variance. The test examines the
hypothesis whether the theoretical cross-sectional expected value for a given
day is equal to zero. The standard deviation in statistics is calculated as
the cross-sectional mean of companies' variances, estimated on the estimation
period. It calculates statistics even if the event window and the estimation
period are overlapped (intersect). The critical values are Student's
t-distributed (no approximation in limit). The significance levels of
\eqn{\alpha} are 0.1, 0.05, and 0.01 (marked respectively by *, **, and ***).
It was designed to measure monthly data: for daily data look at Brown and
Warner 1985 and \code{brown_warner_1985}.
}
\examples{
\dontrun{
library("magrittr")
rates_indx <- get_prices_from_tickers("^GSPC",
                                      start = as.Date("2019-04-01"),
                                      end = as.Date("2020-04-01"),
                                      quote = "Close",
                                      retclass = "zoo") \%>\%
    get_rates_from_prices(quote = "Close",
                          multi_day = TRUE,
                          compounding = "continuous")
tickers <- c("AMZN", "ZM", "UBER", "NFLX", "SHOP", "FB", "UPWK")
get_prices_from_tickers(tickers,
                        start = as.Date("2019-04-01"),
                        end = as.Date("2020-04-01"),
                        quote = "Close",
                        retclass = "zoo") \%>\%
    get_rates_from_prices(quote = "Close",
                          multi_day = TRUE,
                          compounding = "continuous") \%>\%
    apply_market_model(regressor = rates_indx,
                       same_regressor_for_all = TRUE,
                       market_model = "sim",
                       estimation_method = "ols",
                       estimation_start = as.Date("2019-04-01"),
                       estimation_end = as.Date("2020-03-13")) \%>\%
    brown_warner_1980(event_start = as.Date("2020-03-16"),
                      event_end = as.Date("2020-03-20"))
}
## The result of the code above is equivalent to:
data(securities_returns)
brown_warner_1980(list_of_returns = securities_returns,
                  event_start = as.Date("2020-03-16"),
                  event_end = as.Date("2020-03-20"))

}
\references{
Brown S.J., Warner J.B. \emph{Measuring security price
performance}. Journal of Financial Economics, 8:205-258, 1980.
}
\seealso{
\code{\link{parametric_tests}}, \code{\link{brown_warner_1985}},
\code{\link{t_test}}, \code{\link{patell}}, \code{\link{boehmer}}, and
\code{\link{lamb}}.
}
