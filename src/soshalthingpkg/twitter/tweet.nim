import karax / reactive, json, options, times, sequtils, strutils
import ../article

type
    Post* = ref object of ArticleData
        authorName*: string
        authorHandle*: string
        authorAvatar*: string
        text*: string
        images*: seq[PostImageData]
        #video*: PostVideoData #Nullable
        liked*, reposted*: RBool
        likeCount*, repostCount*: RInt
        #userMentions?*: UserMentionData[]
        #hashtags?*: HashtagData[]
        #externalLinks?*: ExternalLinkData[]
    Repost* = ref object of ArticleData
        repostedId*: string
        reposterName*: string
        reposterHandle*: string
        reposterAvatar*: string
    Quote* = ref object of Post
        quotedId*: string
    #ImageSize = object
    #    w, h: int
    #    resize: string
    PostImageData* = object
        url*, compressed_url: string
        sizes*: JsonNode
        indices*: tuple[first: int, second: int]
    PostVideoData = object
        compressed_url: string
    PostURLData = object
        compressed, expanded, display: string
    Entities = object
        images: seq[PostImageData]
        video: PostVideoData
        #userMentions : UserMentionData[]
        #hashtags : HashtagData[]
        #externalLinks : ExternalLinkData[]
        urls: seq[PostURLData]
    Payload* = tuple[post: Post, repost: Option[Repost], quote: Option[Quote]]

#Tue Aug 18 00:00:00 +0000 2020
const tweetTimeFormat = initTimeFormat("ddd MMM dd HH:mm:ss zz'00' YYYY")

proc newImageData(media: JsonNode): PostImageData =
    result.compressed_url = media["url"].str
    result.url = media["media_url_https"].str
    result.sizes = media["sizes"]
    let rawIndices = media["indices"]
    result.indices = (first: rawIndices[0].num.int, second: rawIndices[1].num.int)

proc newURLData(url: JsonNode): PostURLData =
    result.compressed = url["url"].str
    result.expanded = url["expanded_url"].str
    result.display = url["display_url"].str

proc parseEntities(tweet: JsonNode): Entities =
    if tweet.hasKey("extended_entities"):
        let medias = tweet["extended_entities"]{"media"}

        if medias != nil:
            case medias[0]["type"].str:
                of "photo":
                    result.images = medias.getElems().map newImageData

        if tweet["extended_entities"].hasKey("urls"):
            result.urls = tweet["extended_entities"]["urls"].getElems().map newURLData
    elif tweet.hasKey("entities"):
        if tweet["entities"].hasKey("media"):
            result.images = @[tweet["entities"]["media"][0].newImageData]

        if tweet["entities"].hasKey("urls"):
            result.urls = tweet["entities"]["urls"].getElems().map newURLData

proc getText(tweet: JsonNode, entities: Entities): string =
    if tweet.hasKey("full_text"):
        result = tweet["full_text"].str
    else:
        result = tweet["text"].str

    for i in entities.images:
        result = result.replace(i.compressed_url)

    #if entities.video != nil:
    #    result = result.replace(entities.video.compressed_url)

    for i in entities.urls:
        result = result.replace(i.compressed, i.display)

    result = result.strip()

proc toPost*(tweet: JsonNode): Post =
    let user = tweet["user"]
    let entities = tweet.parseEntities()

    result = Post(
        id: tweet["id_str"].str,
        creationTime: tweet["created_at"].str.parse(tweetTimeFormat),
        hidden: false.rbool,
        authorName: user["name"].str,
        authorHandle: user["screen_name"].str,
        authorAvatar: user["profile_image_url_https"].str,
        text: tweet.getText(entities),
        images: entities.images,
        #video,
        liked: tweet["favorited"].bval.rbool,
        reposted: tweet["retweeted"].bval.rbool,
        likeCount: tweet["favorite_count"].num.int.rint,
        repostCount: tweet["retweet_count"].num.int.rint,
        #userMentions,
        #hashtags,
        #externalLinks,
        #rawObject: tweet,
    )

proc toRepost(tweet: JsonNode): Repost =
    let user = tweet["user"]

    result = Repost(
        id: tweet["id_str"].str,
        creationTime: tweet["created_at"].str.parse(tweetTimeFormat),
        hidden: false.rbool,
        repostedId: tweet["retweeted_status"]["id_str"].str,
        reposterName: user["name"].str,
        reposterHandle: user["screen_name"].str,
        reposterAvatar: user["profile_image_url_https"].str,
    )

proc toQuote(tweet: JsonNode): Quote =
    let user = tweet["user"]
    let entities = tweet.parseEntities()

    result = Quote(
        id: tweet["id_str"].str,
        creationTime: tweet["created_at"].str.parse(tweetTimeFormat),
        hidden: false.rbool,
        authorName: user["name"].str,
        authorHandle: user["screen_name"].str,
        authorAvatar: user["profile_image_url_https"].str,
        text: tweet.getText(entities),
        #images,
        #video,
        liked: tweet["favorited"].bval.rbool,
        reposted: tweet["retweeted"].bval.rbool,
        likeCount: tweet["favorite_count"].num.int.rint,
        repostCount: tweet["retweet_count"].num.int.rint,
        #userMentions,
        #hashtags,
        #externalLinks,
        quotedId: tweet["quoted_status"]["id_str"].str,
    )

proc parseTweet*(tweet: JsonNode): tuple[post: Post, repost: Option[Repost], quote: Option[Quote]] =
    if tweet.hasKey("retweeted_status"):
        result = (
            tweet["retweeted_status"].toPost,
            some(tweet.toRepost),
            none(Quote)
        )
    elif tweet.hasKey("quoted_status"):
        result = (
            tweet["quoted_status"].toPost,
            none(Repost),
            some(tweet.toQuote)
        )
    else:
        result = (
            tweet.toPost,
            none(Repost),
            none(Quote)
        )

# TODO Find how to keep this synced with type def
# TODO Also update directly with json
method update*(baseData, newData: Post) =
    update(baseData.ArticleData, newData.ArticleData)

    baseData.authorName = newData.authorName
    baseData.authorHandle = newData.authorHandle
    baseData.authorAvatar = newData.authorAvatar
    baseData.text = newData.text
    baseData.images = newData.images
    baseData.liked <- newData.liked.value
    baseData.reposted <- newData.reposted.value
    baseData.likeCount <- newData.likeCount.value
    baseData.repostCount <- newData.repostCount.value