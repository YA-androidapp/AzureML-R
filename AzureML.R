# 参考：
#  * ftp://cran.r-project.org/pub/R/web/packages/AzureML/AzureML.pdf



# AzureMLをシームレスに使うためのライブラリをインストール
install.packages("AzureML", dependencies=T)
library(AzureML)



# AzureML StudioのSettingsタブを開き
#  (1)NAME→WORKSPACE ID
#  (2)AUTHORIZATION TOKENS→PRIMARY AUTHORIZATION TOKEN
# を確認し、以下の変数へ格納
amlId   <- "**********"
amlAuth <- "**********"

# AzureMLへ接続
ws <- workspace(id=amlId, auth=amlAuth)
# 米国中南部以外の地域にホストされている場合はapi_endpointを指定しなければいけない
# ws <- workspace(id=amlId, auth=amlAuth,
                # api_endpoint = "https://asiasoutheast.studio.azureml.net/"
                #    OR
                # api_endpoint = "https://europewest.studio.azureml.net/"
                # )

# 設定を取得
read.AzureML.config(config = getOption("AzureML.config"))
# read.AzureML.config(config=getOption("AzureML.config"), id=amlId, auth=amlAuth)

# ワークスペース上のオブジェクトをリフレッシュ
refresh(ws, what="everything") # c("everything", "datasets", "experiments", "services")



# RオブジェクトがAzure ML上でどのように扱われるかを判定する関数
checkObjectMode <- function(x) {
  if(is.Dataset(x)){
    print("Azure ML Dataset")
    return("Dataset")
  } else if(is.Endpoint(x)){
    print("Azure ML Endpoint")
    return("Endpoint")
  } else if(is.Service(x)){
    print("Azure ML Service")
    return("Service")
  } else if(is.Workspace(x)){
    print("Azure ML Workspace")
    return("Workspace")
  }
}



# データセットのアップロード
#  アップロード完了後、Azure ML Studioに反映されるまで若干タイムラグがあるので少し時間をおいてから確認する
data(airquality)                # アップロードしたいデータセットを、
df <- data.frame(airquality)    # データフレームとして予め用意
# upload.dataset(df, ws, name="データセットの名称")
upload.dataset(df, ws, name="airquality") # nameにはデータセットの名称を指定



# アップロードされているデータセットの一覧を取得
head(datasets(ws))



## データセットのダウンロード
ds <- datasets(ws)
ds <- ds[order(ds$CreatedDate, decreasing=T),]
rownames(ds) <- c(1:nrow(ds))
( dsName <- ds[,"Name"][1] ) # 最近アップロードしたデータセットの名称を取得
# df <- download.datasets(ws, name="データセットの名称")
df <- download.datasets(ws, dsName)
head(df)



# データセットの削除
#   実行するときは以下の行のコメントを外す
#result <- delete.datasets(ws, name=dsName)
if(result$Deleted==TRUE) print("Done") else print("Failed")



# 実験の一覧を取得
es <- experiments(ws, filter = "all")           # すべての実験
es <- experiments(ws, filter = "samples")       # サンプルの実験
es <- experiments(ws, filter = "my datasets")   # 自作した実験
es <- es[order(es$CreationTime, decreasing=F),] # 最近作成した実験の名称を取得
rownames(es) <- c(1:nrow(es))
( esName <- es[,"Description"][1] )

# 実験にあるモジュールからデータセットをダウンロード
#  データセットをダウンロードするための設定
#   Azure MLの実験にある「Convert to CSV」モジュールの出力端子をクリックし、
#   メニューの「Generate Data Access Code」をクリックして、コード(と以下のキー)を取得
node_id     <- "**********"
experiment  <- "**********"
#  Azure MLの実験にある「Convert to CSV」モジュールの出力端子をクリックし、
#  メニューの「Generate Data Access Code」をクリックして、コードを取得
#  "AzureML"パッケージの読込みとworkspaceオブジェクトの作成は先頭で実行済なのでコピペ不要
ds <- download.intermediate.dataset(
  ws = ws,
  node_id = node_id,
  experiment = experiment,
  port_name = "Results dataset",
  data_type_id = "GenericCSV"
)
head(ds)



# Webサービスの一覧を取得
ss <- services(ws)
endpoints(ws, ss$Id[1]) | endpoints(ws, ss[1,]) | getEndpoints(ws, ss$Id[1])



## Webサービスを発行
#   Webサービスを発行するためにはRToolsに含まれるzipユーティリティが必要
#    ( https://cran.r-project.org/bin/windows/Rtools/ )
# Simple example using scalar input ------------------------------------------
sum <- function(x,y) x + y
endpoint <- publishWebService(
  ws,
  fun = sum,
  name = "sumSrv",
  inputSchema = list(
    x="numeric",
    y="numeric"
    ),
  outputSchema = list(ans="numeric")
  )
# Rでいう
# numeric, logical, integer, character
# は、Azure MLではそれぞれ
# double, boolean, int32, string, respectively
# として扱われる

# Webサービスによる評価(endpointが取得済みの場合)
consume(endpoint, list(x=pi, y=2)) # 発行したWebサービスで評価

# Webサービスによる評価(endpointが取得済みでない場合)
ss <- services(ws)
ss <- ss[order(ss$CreationTime, decreasing=T),]
rownames(ss) <- c(1:nrow(ss))
# 最近作成したエンドポイントの名称を取得
es <- endpoints(ws, ss$Id[1])
es <- es[order(ss$CreationTime, decreasing=T),]
rownames(es) <- c(1:nrow(es))
consume(es[1,], list(x=pi, y=2))



## Webサービスを削除
ss <- services(ws)
ss <- ss[order(ss$CreationTime, decreasing=T),]
rownames(ss) <- c(1:nrow(ss))
# 最近アップロードしたデータセットの名称を取得
( ssName <- ss[,"Name"][1] )
# 実行するときは以下の行のコメントを外す
#deleteWebService(ws, ssName)
