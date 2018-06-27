//
//  CreateUrlController.swift
//  MySearchApp
//
//  Created by systena on 2018/06/27.
//  Copyright © 2018年 Mao Nishi. All rights reserved.
//

import UIKit

class CreateUrlController: UIViewController , UISearchBarDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var priceFromForm: UITextField!
    @IBOutlet weak var priceToForm: UITextField!
    
    let appid = "dj00aiZpPXBRZFIwWnZBY0dKUSZzPWNvbnN1bWVyc2VjcmV0Jng9ZTE-"
    
    let entryUrl: String = "https://shopping.yahooapis.jp/ShoppingWebService/V1/json/itemSearch"
    
    var requestUrl: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func createUrl() {
        guard let inputText = searchBar.text else {
            return
        }
        
        guard inputText.lengthOfBytes(using: String.Encoding.utf8) > 0 else {
            return
        }
        
        let inputPriceFrom: String = priceFromForm.text!
        let inputPriceTo: String = priceToForm.text!
        
        let parameter = ["appid": appid, "query": inputText, "price_from": inputPriceFrom, "price_to": inputPriceTo]
        
        // requestUrl : 生成したURL
        requestUrl = createRequestUrl(parameter: parameter)
        
        searchBar.resignFirstResponder()
    }
    
    func createRequestUrl(parameter: [String: String]) -> String {
        var parameterString = ""
        for key in parameter.keys {
            // 値の取り出し
            guard let value = parameter[key] else {
                // 値なし。次のfor文の処理を行う
                continue
            }
            // すでにパラメータが設定されていた場合
            if parameterString.lengthOfBytes(using: String.Encoding.utf8) > 0 {
                // パラメータ同士のセパレータである&を追加する
                parameterString += "&"
            }
            // 値をエンコードする
            guard let encodeValue = encodeParameter(key: key, value: value)
                else {
                    // エンコード失敗。次のfor文の処理を行う
                    continue
            }
            // エンコードした値をパラメータとして追加する
            parameterString += encodeValue
        }
        let requestUrl = entryUrl + "?" + parameterString
        return requestUrl
    }
    
    func encodeParameter(key: String, value: String) -> String? {
        // 値をエンコードする
        guard let escapedValue = value.addingPercentEncoding(
            withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
                // エンコード失敗
                return nil
        }
        // エンコードした値をkey=valueの形式で返却する
        return "\(key)=\(escapedValue)"
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // 入力画面を離れる際にURLを生成、生成したURLを次画面に渡す
        createUrl()
        let searchItemTableViewController = segue.destination as! SearchItemTableViewController
        searchItemTableViewController.requestUrl = requestUrl
    }
}
