
<!-- README.md is generated from README.Rmd. Please edit that file -->

# tweetbotornot2 <img src="man/figures/logo.png" width="160px" align="right" />

<!-- badges: start -->

[![Travis build
status](https://travis-ci.org/mkearney/tweetbotornot2.svg?branch=master)](https://travis-ci.org/mkearney/tweetbotornot2)
[![CRAN
status](https://www.r-pkg.org/badges/version/tweetbotornot2)](https://CRAN.R-project.org/package=tweetbotornot2)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![Codecov test
coverage](https://codecov.io/gh/mkearney/tweetbotornot2/branch/master/graph/badge.svg)](https://codecov.io/gh/mkearney/tweetbotornot2?branch=master)
<!-- badges: end -->

{tweetbotornot2} provides an out-of-the-box classifier for detecting
Twitter bots that is easy to use, volume-friendly (classify over two
hundred thousands accounts per day), accurate (see paper), robust and
customizable (update the model with new or user-defined training data),
and explainable (view feature contributions behind each estimated
probability).

## Installation

You can install the released version of tweetbotornot2 from
[CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("tweetbotornot2")
```

## Predict

### Use `predict_bot()` to use the built-in bot classifier

Enter screen names of Twitter users of interest and `predict_bot()`
returns the estimated probability that one or more Twitter accounts is a
bot.

``` r
## pass screen names to predict function
predict_bot(c("MagicRealismBot", "netflix_bot", "rdpeng", "hspter"))
#>       user_id     screen_name   prob_bot
#> 1: 1203840834     netflix_bot 0.99986231
#> 2:   24228154          hspter 0.00016590
#> 3: 3701125272 MagicRealismBot 0.99996889
#> 4:    9308212          rdpeng 0.00042064
```

`predict_bot()` also accepts previously collected Twitter data (e.g.,
data returned by `rtweet::get_timelines()`)

``` r
## estimate bot probabilities
twtdat <- rtweet::get_timelines(
  c(
    ## (these ones should be bots)
    "American__Voter",
    "MagicRealismBot", 
    "mitchhedbot",
    "rstats4ds", 
    "thinkpiecebot", 
    "tidyversetweets", 
    "newstarsbot",
    ## (these ones should be Nots)
    "AOC", 
    "kearneymw", 
    "kumailn", 
    "mindykaling", 
    "NateSilver538", 
    "realDonaldTrump", 
    "hspter",
    "rdpeng"),
  n = 200, check = FALSE)

## view output (order most likely to least like bot)
predict_bot(twtdat)[order(-prob_bot), ]
#>                 user_id     screen_name     prob_bot
#>  1:  935569091678691328 tidyversetweets 0.9999926090
#>  2:  780707721209188352     newstarsbot 0.9999874830
#>  3:  829792389925597184 American__Voter 0.9999735355
#>  4:          3701125272 MagicRealismBot 0.9999688864
#>  5:          3325527710   thinkpiecebot 0.9999618530
#>  6:           214244836     mitchhedbot 0.9998689890
#>  7: 1075011651366199297       rstats4ds 0.9998586178
#>  8:          2973406683       kearneymw 0.0312312841
#>  9:             9308212          rdpeng 0.0004206400
#> 10:            25073877 realDonaldTrump 0.0002082884
#> 11:            24228154          hspter 0.0001659000
#> 12:            16017475   NateSilver538 0.0001259984
#> 13:            23544596     mindykaling 0.0000552008
#> 14:           138203134             AOC 0.0000382137
#> 15:            28406270         kumailn 0.0000097915
```

## Explain

### Use `explain_bot()` to see the contributions made by each feature in the model

Examine prediction contributions for features in the model

``` r
## view top features in predictions of each user
explain_bot(twtdat)[feature %in% feature[1:10], .SD, on = "feature"][1:30, -1]
#>         screen_name    prob_bot   feature      value                feature_description
#>  1:             AOC 0.000038214 twt_srctw -4.9941258 Tweet source of Twitter (official)
#>  2:             AOC 0.000038214 twt_srcna -1.0472798            Tweet source of unknown
#>  3:             AOC 0.000038214 usr_fllws -0.7423525                     User followers
#>  4:             AOC 0.000038214 twt_quots -0.6206971                   Tweet via quotes
#>  5:             AOC 0.000038214      BIAS  0.6181790             Intercept (y when x=0)
#>  6:             AOC 0.000038214 twt_atsmn -0.5708530                     Tweet mentions
#>  7:             AOC 0.000038214 usr_actyr -0.5174876                   User account age
#>  8:             AOC 0.000038214 twt_srcts -0.4900279                 Tweet source types
#>  9:             AOC 0.000038214 twt_rtwts -0.4330552                 Tweet via retweets
#> 10:             AOC 0.000038214 twt_wdtsd -0.4117078     Tweet display widht variatiojn
#> 11: American__Voter 0.999973536 twt_srctw  5.2209139 Tweet source of Twitter (official)
#> 12: American__Voter 0.999973536 usr_actyr  1.2841703                   User account age
#> 13: American__Voter 0.999973536 twt_srcna  1.1032038            Tweet source of unknown
#> 14: American__Voter 0.999973536      BIAS  0.6181790             Intercept (y when x=0)
#> 15: American__Voter 0.999973536 twt_atsmn  0.3782851                     Tweet mentions
#> 16: American__Voter 0.999973536 twt_wdtsd  0.3500980     Tweet display widht variatiojn
#> 17: American__Voter 0.999973536 twt_rtwts  0.3150270                 Tweet via retweets
#> 18: American__Voter 0.999973536 twt_srcts -0.2297356                 Tweet source types
#> 19: American__Voter 0.999973536 twt_quots  0.0765267                   Tweet via quotes
#> 20: American__Voter 0.999973536 usr_fllws  0.0046947                     User followers
#> 21: MagicRealismBot 0.999968886 twt_srctw  5.2880497 Tweet source of Twitter (official)
#> 22: MagicRealismBot 0.999968886 usr_actyr  1.3091636                   User account age
#> 23: MagicRealismBot 0.999968886 twt_srcna  1.0801283            Tweet source of unknown
#> 24: MagicRealismBot 0.999968886      BIAS  0.6181790             Intercept (y when x=0)
#> 25: MagicRealismBot 0.999968886 usr_fllws -0.5370702                     User followers
#> 26: MagicRealismBot 0.999968886 twt_atsmn  0.3796347                     Tweet mentions
#> 27: MagicRealismBot 0.999968886 twt_rtwts  0.3240635                 Tweet via retweets
#> 28: MagicRealismBot 0.999968886 twt_wdtsd  0.2360608     Tweet display widht variatiojn
#> 29: MagicRealismBot 0.999968886 twt_srcts -0.2314501                 Tweet source types
#> 30: MagicRealismBot 0.999968886 twt_quots  0.0731127                   Tweet via quotes
#>         screen_name    prob_bot   feature      value                feature_description
```

## Update

### Use `sample_via_twitter_lists()` to gather new users

`sample_via_twitter_lists()` leverages Twitter lists to snowball sample
from a few users (input) to hundreds or even thousands of users
(output). Use it to find and label “bot” and “not” (bot) Twitter
accounts via snowball sampling

``` r
## find up to 10,000 accounts similar to these well-known Twitter bots
bots <- sample_via_twitter_lists(c("netflix_bot", "American__Voter", "UTLEGtracker", 
  "JVLast", "EndlessJeopardy", "PossumEveryHour", "MagicRealismBot", "factbot1"), 
  n = 10000)

## retrieve user and timeline information for each user
bots_tmls <- tweetbotornot_collect(bots)
```

### Use `preprocess_bot()` to prepare user timeline data for modeling

Extract and transform numeric features from the data

``` r
## wrangle, munge, aggregate data for modelling
bots_tmls <- preprocess_bot(twtdat)
```

### Use `tweetbotornot_update` to train the model on new data

``` r
## train model
new_model <- tweetbotornot_update(newdata)

## use updated model to get new predictions
predict_bot(new_model, c("netflix_bot", "mindykaling"))
```

## About Model

### Feature importance

The most influential features in the classifier

![](man/figures/README-import.png)

### Feature contributions

How features contributed to predictions in the original training data:

![](man/figures/README-shap.png)
