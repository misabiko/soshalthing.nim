import twitter, httpclient, jester, json

let credentials = parseFile("credentials.json")

var consumerToken = newConsumerToken(credentials["consumer_key"].str, credentials["consumer_secret"].str)
var twitterAPI = newTwitterAPI(consumerToken, credentials["access_key"].str, credentials["access_secret"].str)

# Simply get.
var resp = twitterAPI.get("account/verify_credentials.json")
echo "Twitter credenditals status: " & resp.status


routes:
    get "/home_timeline":
        let r = twitterAPI.statusesHomeTimeline()
        resp(Http200, {"Access-Control-Allow-Origin":"*"}, r.body)