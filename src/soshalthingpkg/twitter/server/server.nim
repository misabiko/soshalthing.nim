import twitter, httpclient, jester, json, strtabs, strutils

let credentials = parseFile("credentials.json")

var consumerToken = newConsumerToken(credentials["consumer_key"].str, credentials["consumer_secret"].str)
var twitterAPI = newTwitterAPI(consumerToken, credentials["access_key"].str, credentials["access_secret"].str)

# Simply get.
var resp = twitterAPI.get("account/verify_credentials.json")
echo "Twitter credenditals status: " & resp.status

let rateLimitResources = {"resources": "application,statuses,lists,search"}.newStringTable

routes:
# search
    get "/search":
        echo "q: " & request.params.getOrDefault("q")
        let r = twitterAPI.searchTweets(request.params.getOrDefault("q"), {"tweet_mode": "extended", "result_type": "recent", "count": "200"}.newStringTable)
        resp(Http200, {"Access-Control-Allow-Origin":"*"}, r.body)

# lists
    get "/list":
        let r = twitterAPI.listsStatuses(request.params.getOrDefault("slug"), {"tweet_mode": "extended", "include_rts": "false", "count": "200", "owner_screen_name": request.params.getOrDefault("owner_screen_name")}.newStringTable)
        resp(Http200, {"Access-Control-Allow-Origin":"*"}, r.body)

# statuses
    get "/home_timeline":
        let r = twitterAPI.statusesHomeTimeline {"tweet_mode": "extended"}.newStringTable
        resp(Http200, {"Access-Control-Allow-Origin":"*"}, r.body)

    get "/user_timeline":
        let r = twitterAPI.statusesUserTimeline {"tweet_mode": "extended", "include_rts": "false", "count": "200"}.newStringTable
        resp(Http200, {"Access-Control-Allow-Origin":"*"}, r.body)

    get "/status/@id":
        let r = twitterAPI.statusesShow(parseInt(@"id"), {"tweet_mode": "extended"}.newStringTable)
        resp(Http200, {"Access-Control-Allow-Origin":"*"}, r.body)

    post "/retweet/@id":
        let id = parseInt(@"id")
        let r = twitterAPI.statusesRetweet(id)
        resp(Http200, {"Access-Control-Allow-Origin":"*"}, r.body)

# application
    get "/ratelimit":
        let r = twitterAPI.applicationRateLimitData(rateLimitResources)
        resp(Http200, {"Access-Control-Allow-Origin":"*"}, r.body)

# favorites
    post "/like/@id":
        let id = parseInt(@"id")
        let r = twitterAPI.favoritesCreate(id)
        resp(Http200, {"Access-Control-Allow-Origin":"*"}, r.body)

    post "/unlike/@id":
        let id = parseInt(@"id")
        let r = twitterAPI.favoritesDestroy(id)
        resp(Http200, {"Access-Control-Allow-Origin":"*"}, r.body)