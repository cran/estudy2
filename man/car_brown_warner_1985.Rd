% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/car_parametric_tests.R
\name{car_brown_warner_1985}
\alias{car_brown_warner_1985}
\title{Brown and Warner (1985) CAR test.}
\usage{
car_brown_warner_1985(list_of_returns, car_start, car_end, percentage = 90)
}
\arguments{
\item{list_of_returns}{a list of objects of S3 class \code{returns}, each
element of which is treated as a security.}

\item{car_start}{an object of \code{Date} class giving the first date of
the CAR period.}

\item{car_end}{an object of \code{Date} class giving the last date of the
CAR period.}

\item{percentage}{a lowest allowed percentage of non-missing observation
for each day to be incorporated into CAR. The default value is 90 percent.
\itemize{
    \item \code{name}: a name of the test, i.e.
    \code{"car_brown_warner_1985"}
    \item \code{car_start}: the first date of the CAR period
    \item \code{car_end}: the last date of the CAR period
    \item \code{average_percentage}: an average share of non-missing
          observations over the CAR period
    \item \code{car_mean}: an average abnormal return over the CAR period
    \item \code{statistic}: a test's statistic
    \item \code{number_of_days}: the number of days in the CAR period
    \item \code{significance}: a significance of the statistic
}}
}
\description{
A parametric test proposed by Brown and Warner 1995 that examines whether
or not cumulative abnormal return (CAR) significantly differs from zero.
}
\details{
This function performs a test proposed by Brown and Warner 1985 to
investigate whether CAR significantly differs from zero. This tests uses the
variance, specified by Brown and Warner 1985. The advantage of this test is
allowance for correlated cross-sectional returns. However, the test does not
use autocorrelation adjustment. The test statistic is close enough to
statistic, produced by \code{\link{car_lamb}}. The critical values are
standard normal. The significance levels of \eqn{\alpha} are 0.1, 0.05, and
0.01 (marked respectively by *, **, and ***).
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
    car_brown_warner_1985(car_start = as.Date("2020-03-16"),
                          car_end = as.Date("2020-03-20"))
}
## The result of the code above is equivalent to:
data(securities_returns)
car_brown_warner_1985(
    list_of_returns = securities_returns,
    car_start = as.Date("2020-03-16"),
    car_end = as.Date("2020-03-20")
)

}
\references{
Brown S.J., Warner J.B. \emph{Using Daily Stock Returns, The Case
of Event Studies}. Journal of Financial Economics, 14:3-31, 1985.
}
\seealso{
\code{\link{car_lamb}} and
\code{\link{car_parametric_tests}}.
}
