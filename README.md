# Elastweet

This is a quick demo using Twitter's streaming API to insert tweets to Elasticsearch.

## Starting the app

### With Docker

First, copy _.env.example_ to _.env_ at the root of the project and fill in your twitter credentials and search terms.

Make sure you have _docker_ and _docker-compose_ installed and simply run
```
docker-compose up
```
This should build/pull the images and start all teh needed containers.
