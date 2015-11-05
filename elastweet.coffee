Twitter = require 'twitter'
Redis = require 'Redis'
Entities = require('html-entities').AllHtmlEntities
sentiment = require('sentiment')
sentimentFrench = require('sentiment-french')
http = require('http')

twitter = new Twitter({
  consumer_key: process.env.TWITTER_CONSUMER_KEY,
  consumer_secret: process.env.TWITTER_CONSUMER_SECRET,
  access_token_key: process.env.TWITTER_ACCESS_TOKEN_KEY,
  access_token_secret: process.env.TWITTER_ACCESS_TOKEN_SECRET
})

###
redis = Redis.createClient('redis://redis:6379')
redis.on 'error', (err)->
  console.log "Redis error #{err}"
###

entities = new Entities()

isRetweet = (tweet)->
  !!tweet.retweeted_status

getOriginalTweet = (tweet)->
  if isRetweet(tweet)
    tweet.retweeted_status
  else
    return tweet

sentimentToSmiley = (score)->
  if score <= -2
    '☹️'
  else if (score < 0 && score > -2)
    '😕'
  else if score == 0
    '😐'
  else if (score > 0 && score < 2)
    '🙂'
  else
    '😀'

sentimentToText = (score)->
  if score <= -2
    'très négatif'
  else if (score < 0 && score > -2)
    'négatif'
  else if score == 0
    'neutre'
  else if (score > 0 && score < 2)
    'positif'
  else
    'très positif'

setupTweetIndex = ->
  index = {
    mappings: {
      tweet: {
        properties: {
          timestamp_ms: {
            type: "date"
          }
        }
      }
    }
  }

  req_options = {
    method: 'PUT',
    host: 'elasticsearch',
    port: '9200',
    path: "/tweets"
  }

  mapping_req = http.request(req_options, (response)->
    console.log 'response: ' + response
  )
  mapping_req.on 'error', (err)->
    console.log 'error ' + err

  mapping_req.write(JSON.stringify(index))
  mapping_req.end()


startStream = ->
  setupTweetIndex()
  twitter.stream('statuses/filter', { track: process.env.TWITTER_TRACK_TERMS }, (stream)->
    stream.on 'data', (tweet)->
      if isRetweet(tweet)
        # redis.zadd 'retweets', tweet.retweeted_status.retweet_count, tweet.retweeted_status.id_str
      else
        score =
          if tweet.lang == 'fr'
            sentimentFrench(tweet.text).score
          else
            sentiment(tweet.text).score
        tweet.score = score
        tweet.sentiment = sentimentToText(score)
        tweet.smiley = sentimentToSmiley(score)
        tweet._timestamp = parseInt(tweet.timestamps_ms)
        req_options = {
          method: 'PUT',
          host: 'elasticsearch',
          port: '9200',
          path: "/tweets/tweet/#{tweet.id}"
        }
        req = http.request(req_options, (response)->
          # console.log('STATUS: ' + response.statusCode)
        )
        req.on('error', (err)->
          console.log('problem with request: ' + err.message)
        )

        req.write(JSON.stringify(tweet))
        req.end()
        console.log "#{tweet.lang} (#{score})  #{sentimentToSmiley(score)}  -- #{tweet.text}"

    stream.on 'error', (error)->
      console.log error
  )



setTimeout( startStream, 10000)
