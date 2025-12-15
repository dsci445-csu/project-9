# project-9

## Summary:
League of Legends is a massively popular online game where players can compete to increase their matchmaking rating. The creators of League of Legends, Riot Games, provide extremely dense data through an API. The goal of this project is to attempt to create a post-game performance review tool similar to the infamous review tool available for chess on chess.com. 


## Main Questions:
1. Which data available through the API best accounts for predicting the outcome of a given match?
2. Using our prediction model as a base, is it possible to provide meaningful feedback on a player's gameplay? (We will get the opinion of high-level players to benchmark this feedback)

Group 9 Project for DSCI445 @ CSU

## Steps to Reproduce:
1. Use data-collection/ryan-collector.py to make API requests and collect match and timelines data for a specific skill division (we used diamond II)
2. It may be required to make an account to receive an API key to make api requests mentioned in (1). That can be done here: https://developer.riotgames.com/docs/portal#web-apis_api-keys
3. Run matchcleaner.py using python to zip and clean match and timelines data together. This will output your "performance" dataset.
4. Run the desired .rmd file to perform analysis, changing file paths to point to the correct data. Default path is `data/d2_500_10_performance.csv`.
5. Results can be entirely reproduced within paper.rmd either by knitting or running code blocks individually.
6. Additional exploratory data analysis can be found in other files, primarily `ryan-eda.Rmd`.
