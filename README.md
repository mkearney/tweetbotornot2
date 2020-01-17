
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
#>       user_id     screen_name prob_bot
#> 1: 3701125272 MagicRealismBot 0.978815
#> 2: 1203840834     netflix_bot 0.977786
#> 3:    9308212          rdpeng 0.027967
#> 4:   24228154          hspter 0.023199
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
#>                 user_id     screen_name prob_bot
#>  1:  935569091678691328 tidyversetweets 0.979425
#>  2:  780707721209188352     newstarsbot 0.979408
#>  3:  829792389925597184 American__Voter 0.979399
#>  4:          3325527710   thinkpiecebot 0.979319
#>  5:          3701125272 MagicRealismBot 0.978815
#>  6:           214244836     mitchhedbot 0.976384
#>  7: 1075011651366199297       rstats4ds 0.973782
#>  8:          2973406683       kearneymw 0.038251
#>  9:             9308212          rdpeng 0.027967
#> 10:            25073877 realDonaldTrump 0.024500
#> 11:            23544596     mindykaling 0.023267
#> 12:            16017475   NateSilver538 0.023230
#> 13:            24228154          hspter 0.023199
#> 14:           138203134             AOC 0.023083
#> 15:            28406270         kumailn 0.022726
```

## Explain

### Use `explain_bot()` to see the contributions made by each feature in the model

View prediction contributions from top five features (for each user) in
the model

``` r
## view top features in predictions of each user
explain_bot(twtdat)[order(screen_name, 
  -abs(value)), ][feature %in% feature[1:5], 
    .SD, on = "feature"][1:50, -1]
#>         screen_name prob_bot   feature     value                feature_description
#>  1:             AOC 0.023083 twt_srctw -1.831461 Tweet source of Twitter (official)
#>  2:             AOC 0.023083 twt_rtwts -0.537981                 Tweet via retweets
#>  3:             AOC 0.023083 twt_atssd -0.324472           Tweet mentions variation
#>  4:             AOC 0.023083 twt_srcna -0.254933            Tweet source of unknown
#>  5:             AOC 0.023083 usr_actyr -0.175848                   User account age
#>  6: American__Voter 0.979399 twt_srctw  1.681257 Tweet source of Twitter (official)
#>  7: American__Voter 0.979399 twt_srcna  0.561622            Tweet source of unknown
#>  8: American__Voter 0.979399 twt_rtwts  0.441444                 Tweet via retweets
#>  9: American__Voter 0.979399 twt_atssd  0.239626           Tweet mentions variation
#> 10: American__Voter 0.979399 usr_actyr  0.234932                   User account age
#> 11: MagicRealismBot 0.978815 twt_srctw  1.685465 Tweet source of Twitter (official)
#> 12: MagicRealismBot 0.978815 twt_srcna  0.561748            Tweet source of unknown
#> 13: MagicRealismBot 0.978815 twt_rtwts  0.448261                 Tweet via retweets
#> 14: MagicRealismBot 0.978815 twt_atssd  0.243587           Tweet mentions variation
#> 15: MagicRealismBot 0.978815 usr_actyr  0.226540                   User account age
#> 16:   NateSilver538 0.023230 twt_srctw -1.833996 Tweet source of Twitter (official)
#> 17:   NateSilver538 0.023230 twt_rtwts -0.469515                 Tweet via retweets
#> 18:   NateSilver538 0.023230 twt_atssd -0.292822           Tweet mentions variation
#> 19:   NateSilver538 0.023230 twt_srcna -0.251556            Tweet source of unknown
#> 20:   NateSilver538 0.023230 usr_actyr -0.191402                   User account age
#> 21:          hspter 0.023199 twt_srctw -1.832058 Tweet source of Twitter (official)
#> 22:          hspter 0.023199 twt_rtwts -0.502004                 Tweet via retweets
#> 23:          hspter 0.023199 twt_atssd -0.310035           Tweet mentions variation
#> 24:          hspter 0.023199 twt_srcna -0.250750            Tweet source of unknown
#> 25:          hspter 0.023199 usr_actyr -0.197901                   User account age
#> 26:       kearneymw 0.038251 twt_srctw -1.821676 Tweet source of Twitter (official)
#> 27:       kearneymw 0.038251 twt_rtwts -0.530070                 Tweet via retweets
#> 28:       kearneymw 0.038251 twt_atssd -0.351309           Tweet mentions variation
#> 29:       kearneymw 0.038251 usr_actyr  0.282569                   User account age
#> 30:       kearneymw 0.038251 twt_srcna -0.127965            Tweet source of unknown
#> 31:         kumailn 0.022726 twt_srctw -1.825238 Tweet source of Twitter (official)
#> 32:         kumailn 0.022726 twt_rtwts -0.414914                 Tweet via retweets
#> 33:         kumailn 0.022726 twt_atssd -0.262064           Tweet mentions variation
#> 34:         kumailn 0.022726 twt_srcna -0.239067            Tweet source of unknown
#> 35:         kumailn 0.022726 usr_actyr -0.206001                   User account age
#> 36:     mindykaling 0.023267 twt_srctw -1.830246 Tweet source of Twitter (official)
#> 37:     mindykaling 0.023267 twt_rtwts -0.486864                 Tweet via retweets
#> 38:     mindykaling 0.023267 twt_atssd -0.295756           Tweet mentions variation
#> 39:     mindykaling 0.023267 twt_srcna -0.256129            Tweet source of unknown
#> 40:     mindykaling 0.023267 usr_actyr -0.198855                   User account age
#> 41:     mitchhedbot 0.976384 twt_srctw  1.812258 Tweet source of Twitter (official)
#> 42:     mitchhedbot 0.976384 twt_srcna  0.575901            Tweet source of unknown
#> 43:     mitchhedbot 0.976384 twt_rtwts  0.479413                 Tweet via retweets
#> 44:     mitchhedbot 0.976384 twt_atssd  0.269638           Tweet mentions variation
#> 45:     mitchhedbot 0.976384 usr_actyr -0.124908                   User account age
#> 46:     newstarsbot 0.979408 twt_srctw  1.838576 Tweet source of Twitter (official)
#> 47:     newstarsbot 0.979408 twt_rtwts  0.489507                 Tweet via retweets
#> 48:     newstarsbot 0.979408 twt_atssd  0.277125           Tweet mentions variation
#> 49:     newstarsbot 0.979408 usr_actyr  0.186995                   User account age
#> 50:     newstarsbot 0.979408 twt_srcna -0.082824            Tweet source of unknown
#>         screen_name prob_bot   feature     value                feature_description
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

## [Botometer](https://botometer.iuni.iu.edu)

### Use `predict_botometer()` to get their automation probability scores

``` r
## get botometer scores
predict_botometer(c('kearneymw', 'netflix_bot'))
#> @kearneymw (1/2)
#> @netflix_bot (2/2)
#>       user_id screen_name botometer
#> 1: 2973406683   kearneymw  0.045344
#> 2: 1203840834 netflix_bot  0.706420
```

### Comparison with `{tweetbotornot2}`

Accuracy of tweetbotornot versus botometer across multiple datasets:

![](man/figures/README-modcomp.png)
