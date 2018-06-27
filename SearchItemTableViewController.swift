import UIKit

class SearchItemTableViewController: UITableViewController, UISearchBarDelegate {

    var itemDataArray =  [ItemData]()

    var imageCache = NSCache<AnyObject, UIImage>()
    var requestUrl: String?

    // 数字を金額の形式に整形するためのフォーマッター
    let priceFormat = NumberFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        itemDataArray.removeAll()

        // 価格のフォーマット指定
        priceFormat.numberStyle = .currency
        priceFormat.currencyCode = "JPY"
        
        // APIをリクエストする
        request(requestUrl: requestUrl!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // リクエストを行う
    func request(requestUrl: String) {
        // URL生成
        guard let url = URL(string: requestUrl) else {
            // URL生成失敗
            return
        }
        // リクエスト生成
        let request = URLRequest(url: url)
        // 商品検索APIをコールして商品検索を行う
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data:Data?,
            response:URLResponse?, error:Error?) in
            // 通信完了後の処理
            // エラーチェック
            guard error == nil else {
                // エラー表示
                let alert = UIAlertController(title: "エラー",
                                              message: error?.localizedDescription,
                                              preferredStyle: UIAlertControllerStyle.alert)
                // UIに関する処理はメインスレッド上で行う
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            // JSONで返却されたデータをパースして格納する
            guard let data = data else {
                // データなし
                return
            }

            do {
                // パース実施
                let resultSet = try JSONDecoder().decode(ItemSearchResultSet.self, from: data)
                // 商品のリストに追加
                self.itemDataArray.append(contentsOf: resultSet.resultSet.firstObject.result.items)

            } catch let error {
                print("## error: \(error)")
            }

            // テーブルの描画処理を実施
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        // 通信開始
        task.resume()
    }

    // MARK: - Table view data source
    // テーブルのセクション数を取得
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    // セクション内の商品数を取得
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemDataArray.count
    }

    // MARK: - Table view data source
    // テーブルセルの取得処理
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier:
            "itemCell", for: indexPath) as? ItemTableViewCell else {
                return UITableViewCell()
        }
        let itemData = itemDataArray[indexPath.row]
        // 商品のタイトル設定
        cell.itemTitleLabel.text = itemData.name
        // 商品価格設定処理（日本通貨の形式で設定する）
        let number = NSNumber(integerLiteral: Int(itemData.priceInfo.price!)!)
        cell.itemPriceLabel.text = priceFormat.string(from: number)
        // 商品のURL設定
        cell.itemUrl = itemData.url
        // 画像の設定処理
        // すでにセルに設定されている画像と同じかどうかチェックする
        // 画像がまだ設定されていない場合に処理を行う
        guard let itemImageUrl = itemData.imageInfo.medium else {
            // 画像なし商品
            return cell
        }
        // キャッシュの画像を取り出す
        if let cacheImage = imageCache.object(forKey: itemImageUrl as
            AnyObject) {
            // キャッシュ画像の設定
            cell.itemImageView.image = cacheImage
            return cell
        }
        // キャッシュの画像がないためダウンロードする
        guard let url = URL(string: itemImageUrl) else {
            // urlが生成できなかった
            return cell
        }

        let request = URLRequest(url: url)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data:Data?,
            response:URLResponse?, error:Error?) in
            guard error == nil else {
                // エラーあり
                return
            }
            guard let data = data else {
                // データが存在しない
                return
            }
            guard let image = UIImage(data: data) else {
                // imageが生成できなかった
                return
            }
            // ダウンロードした画像をキャッシュに登録しておく
            self.imageCache.setObject(image, forKey: itemImageUrl as AnyObject)
            // 画像はメインスレッド上で設定する
            DispatchQueue.main.async {
                cell.itemImageView.image = image
            }
        }
        // 画像の読み込み処理開始
        task.resume()

        return cell
     }

    // 商品をタップして次の画面に遷移する前の処理
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cell = sender as? ItemTableViewCell {
            if let webViewController =
                segue.destination as? WebViewController {
                // 商品ページのURLを設定する
                webViewController.itemUrl = cell.itemUrl
            }
        }
     }
    
}
