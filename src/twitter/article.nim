include karax / prelude
import tables, ../article

type
    TweetData* = object of ArticleData
        text: string

var datas* = initOrderedTable[string, TweetData]()

datas["0"] = TweetData(text: "boop")
datas["1"] = TweetData(text: "beep")
datas["2"] = TweetData(text: "bap")

proc article*(id: string): VNode =
    let data = datas[id]
    result = buildHtml(article):
        text data.text