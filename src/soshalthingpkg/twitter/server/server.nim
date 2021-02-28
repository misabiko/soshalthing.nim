import twitter, httpclient, jester, json, strtabs, strutils

let credentials = parseFile("credentials.json")

var consumerToken = newConsumerToken(credentials["consumer_key"].str, credentials["consumer_secret"].str)
var twitterAPI = newTwitterAPI(consumerToken, credentials["access_key"].str, credentials["access_secret"].str)

# Simply get.
var resp = twitterAPI.get("account/verify_credentials.json")
echo "Twitter credenditals status: " & resp.status


routes:
    get "/home_timeline":
        let r = twitterAPI.statusesHomeTimeline {"tweet_mode": "extended"}.newStringTable
        resp(Http200, {"Access-Control-Allow-Origin":"*"}, r.body)

    get "/user_timeline":
        let r = twitterAPI.statusesUserTimeline {"tweet_mode": "extended", "include_rts": "false", "count": "200"}.newStringTable
        resp(Http200, {"Access-Control-Allow-Origin":"*"}, r.body)

    get "/search":
        echo "q: " & request.params.getOrDefault("q")
        let r = twitterAPI.searchTweets(request.params.getOrDefault("q"), {"tweet_mode": "extended", "result_type": "recent", "count": "200"}.newStringTable)
        resp(Http200, {"Access-Control-Allow-Origin":"*"}, r.body)

    get "/list":
        let r = twitterAPI.listsStatuses(request.params.getOrDefault("slug"), {"tweet_mode": "extended", "include_rts": "false", "count": "200", "owner_screen_name": request.params.getOrDefault("owner_screen_name")}.newStringTable)
        resp(Http200, {"Access-Control-Allow-Origin":"*"}, r.body)

    get "/status/@id":
        let r = twitterAPI.statusesShow(parseInt(@"id"), {"tweet_mode": "extended"}.newStringTable)
        resp(Http200, {"Access-Control-Allow-Origin":"*"}, r.body)