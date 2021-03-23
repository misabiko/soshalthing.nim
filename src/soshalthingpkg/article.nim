import karax / reactive, times, tables, options

type
    ArticleCollection* = OrderedTableRef[string, ArticleData]
    ArticleSize* = object
        width*, height*: RInt
    ArticleData* = ref object of RootObj
        id*: string
        creationTime*: DateTime
        hidden*: RBool
        size*: Option[ArticleSize]

proc newArticleSize*(width, height: int): Option[ArticleSize] =
    ArticleSize(width: width.rint, height: height.rint).some

method update*(baseData, newData: ArticleData) {.base.} =
    baseData.creationTime = newData.creationTime

proc update*(articles: ArticleCollection, id: string, newData: ArticleData) =
    if id in articles:
        articles[id].update(newData)
    else:
        articles[id] = newData