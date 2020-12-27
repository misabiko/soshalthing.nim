import twitter, httpclient, jester, json, sequtils, options
import ../tweet

type
    TimelinePayload = object
        posts: seq[Post]
        reposts: seq[Repost]
        quotes: seq[Quote]
        newArticles: seq[string]

proc parseTweets(tweets: JsonNode): TimelinePayload =
    for t in tweets:
        let parsed = parseTweet(t)

        if not result.posts.any(proc (p: Post): bool = p.id == parsed.post.id):
            result.posts.add(parsed.post)
        
        if parsed.repost.isSome:
            result.reposts.add(parsed.repost.get())
        elif parsed.quote.isSome:
            result.quotes.add(parsed.quote.get())
        #else:

let credentials = parseFile("credentials.json")

var consumerToken = newConsumerToken(credentials["consumer_key"].str, credentials["consumer_secret"].str)
var twitterAPI = newTwitterAPI(consumerToken, credentials["access_key"].str, credentials["access_secret"].str)

# Simply get.
var resp = twitterAPI.get("account/verify_credentials.json")
echo resp.status

# Using proc corresponding twitter REST APIs.
resp = twitterAPI.statusesHomeTimeline()
let payload = parseTweets(parseJson(resp.body))
echo payload.posts[0].text

routes:
    get "/":
        resp(Http200, {"Access-Control-Allow-Origin":"*"}, "ok")