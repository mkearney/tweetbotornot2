
<!-- README.md is generated from README.Rmd. Please edit that file -->

# tweetbotornot2

<!-- badges: start -->

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
#>       user_id     screen_name  prob_bot
#> 1: 1203840834     netflix_bot 0.9974465
#> 2:   24228154          hspter 0.0038939
#> 3: 3701125272 MagicRealismBot 0.9999900
#> 4:    9308212          rdpeng 0.0171962
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
#>                 user_id     screen_name   prob_bot
#>  1:          3701125272 MagicRealismBot 0.99998999
#>  2:  780707721209188352     newstarsbot 0.99998736
#>  3:  935569091678691328 tidyversetweets 0.99997628
#>  4:  829792389925597184 American__Voter 0.99997056
#>  5:          3325527710   thinkpiecebot 0.99996030
#>  6: 1075011651366199297       rstats4ds 0.99983037
#>  7:           214244836     mitchhedbot 0.99942195
#>  8:          2973406683       kearneymw 0.05339408
#>  9:            25073877 realDonaldTrump 0.01949467
#> 10:             9308212          rdpeng 0.01719619
#> 11:            16017475   NateSilver538 0.00723628
#> 12:            24228154          hspter 0.00389387
#> 13:           138203134             AOC 0.00122775
#> 14:            23544596     mindykaling 0.00016858
#> 15:            28406270         kumailn 0.00016037
```

## Explain

### Use `explain_bot()` to see the contributions made by each feature in the model

Examine prediction contributions for features in the model

``` r
## view top features in predictions of each user
explain_bot(twtdat)[feature %in% feature[1:10], .SD, on = "feature"][1:30, -1]
#>         screen_name  prob_bot   feature     value                feature_description
#>  1:             AOC 0.0012278 twt_srctw -2.349361 Tweet source of Twitter (official)
#>  2:             AOC 0.0012278 usr_verif -1.288429                      User verified
#>  3:             AOC 0.0012278 usr_actyr -0.989596                   User account age
#>  4:             AOC 0.0012278 twt_wrdsd  0.467928         Tweet word count variation
#>  5:             AOC 0.0012278 twt_hshsd -0.451500           Tweet hashtags variation
#>  6:             AOC 0.0012278 usr_fllws -0.444115                     User followers
#>  7:             AOC 0.0012278 twt_srcna -0.434539            Tweet source of unknown
#>  8:             AOC 0.0012278      BIAS  0.428031             Intercept (y when x=0)
#>  9:             AOC 0.0012278 twt_wrdmn  0.422080              Tweet word count mean
#> 10:             AOC 0.0012278 twt_wdtsd -0.391492     Tweet display widht variatiojn
#> 11: American__Voter 0.9999706 twt_srctw  2.447532 Tweet source of Twitter (official)
#> 12: American__Voter 0.9999706 usr_actyr  1.839742                   User account age
#> 13: American__Voter 0.9999706 twt_srcna  0.995951            Tweet source of unknown
#> 14: American__Voter 0.9999706      BIAS  0.428031             Intercept (y when x=0)
#> 15: American__Voter 0.9999706 twt_wdtsd  0.294240     Tweet display widht variatiojn
#> 16: American__Voter 0.9999706 usr_fllws -0.170949                     User followers
#> 17: American__Voter 0.9999706 twt_wrdmn -0.121823              Tweet word count mean
#> 18: American__Voter 0.9999706 twt_hshsd  0.113032           Tweet hashtags variation
#> 19: American__Voter 0.9999706 twt_wrdsd  0.052839         Tweet word count variation
#> 20: American__Voter 0.9999706 usr_verif  0.037238                      User verified
#> 21: MagicRealismBot 0.9999900 twt_srctw  2.312730 Tweet source of Twitter (official)
#> 22: MagicRealismBot 0.9999900 usr_actyr  2.304153                   User account age
#> 23: MagicRealismBot 0.9999900 twt_srcna  0.824347            Tweet source of unknown
#> 24: MagicRealismBot 0.9999900      BIAS  0.428031             Intercept (y when x=0)
#> 25: MagicRealismBot 0.9999900 twt_wrdmn  0.395463              Tweet word count mean
#> 26: MagicRealismBot 0.9999900 usr_fllws -0.351515                     User followers
#> 27: MagicRealismBot 0.9999900 twt_wdtsd  0.325772     Tweet display widht variatiojn
#> 28: MagicRealismBot 0.9999900 twt_hshsd  0.143245           Tweet hashtags variation
#> 29: MagicRealismBot 0.9999900 twt_wrdsd  0.060281         Tweet word count variation
#> 30: MagicRealismBot 0.9999900 usr_verif  0.039289                      User verified
#>         screen_name  prob_bot   feature     value                feature_description
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
