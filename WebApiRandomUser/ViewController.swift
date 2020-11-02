//
//  ViewController.swift
//  WebApiRandomUser
//
//  Created by Mike Gu on 2020/11/2.
//

import UIKit

struct User {
    var name:String?
    var phone:String?
    var email:String?
    var image:String?
    var date:Int?
    
}

struct allData:Decodable {
    var results : [singleData]?
}
struct singleData:Decodable {
    var name:Name?
    var email:String?
    var phone:String?
    var picture:Picture?
    var dob:Dob?
}
struct Name:Decodable {
    var title:String?
    var first:String?
    var last:String?
}
struct Picture:Decodable {
    var large:String?
}
struct Dob:Decodable {
    var age:Int?
}

class ViewController: UIViewController {
    var isDownLoading:Bool = false
    
    @IBOutlet weak var userImage: UIImageView!
    
    @IBOutlet weak var userName: UILabel!
    @IBAction func makeNewUser(_ sender: UIBarButtonItem) {
        if isDownLoading == false{
            downInfo(withAddress: apiAddress)
        }
    }
    
    var infoTableViewController:infoTableViewController?
    let apiAddress = "https://randomuser.me/api/"
    let urlSession = URLSession(configuration: .default)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//       let aUser = User(name: "Mikey", phone: "0909090909", email: "Mikey@hotmail.com", image: "http//picture.me")
//        settingInfo(user: aUser)
        downInfo(withAddress: apiAddress)
    }
    func downInfo(withAddress webAddress:String){
        if let url = URL(string: webAddress){
            let task = urlSession.dataTask(with: url, completionHandler: {(data,responds,error) in if error != nil{
                let errorCode = (error! as NSError).code
                if errorCode == -1009{
                    DispatchQueue.main.async {
                        self.popAlert(withTitle: "無網路服務")
                    }
                }else{
                    DispatchQueue.main.async {
                        self.popAlert(withTitle: "程式錯誤")
                    }
                }
                self.isDownLoading = false
                return
            }
            if let loadedData = data{
                do{
                    let okData = try JSONDecoder().decode(allData.self, from: loadedData)
                    let firstName = okData.results?[0].name?.first
                    let lastName = okData.results?[0].name?.last
                    let title = okData.results?[0].name?.title
                    
                    let fullName:String? = {
                        guard let okFirstName = firstName else{return nil}
                        guard let okLastName = lastName else{return nil}
                        guard let okTitle = title else{return nil}
                        return okTitle + ". " + okFirstName + " " + okLastName
                    }()
                   
                    let date = okData.results?[0].dob?.age
                    let email = okData.results?[0].email
                    let phone = okData.results?[0].phone
                    let pic = okData.results?[0].picture?.large
                    let aUser = User(name: fullName, phone: phone, email: email, image: pic,date: date)
                    DispatchQueue.main.async {
                        self.settingInfo(user: aUser)
                    }
//                   let json = try JSONSerialization.jsonObject(with: loadedData, options: [])
//                    DispatchQueue.main.async {
//                        self.parseJson(json: json)
                }catch{
                    DispatchQueue.main.async {
                        self.popAlert(withTitle: "Sorry")
                    }
                    self.isDownLoading = false
                }
                return
            }else{
                self.isDownLoading = false
            }
            })
            task.resume()
            isDownLoading = true
        }
    }
    //Json轉換
    func userFullName(nameDictionary:Any?) ->String?{
        if let okDictionary = nameDictionary as? [String:String]{
        let firstName = okDictionary["first"] ?? ""
        let lastName = okDictionary["last"] ?? ""
            return firstName + " " + lastName
        }else{
            return nil
        }
    }
    //json資料
    func parseJson(json:Any) {
        if let okJson = json as? [String:Any]{
            if let infoArray = okJson["results"] as? [[String:Any]]{
                let infoDictionary = infoArray[0]
                let loadedName = userFullName(nameDictionary: infoDictionary["name"])
                let loadedEmail = infoDictionary["email"] as? String
                let loadedphone = infoDictionary["phone"] as? String
                let loadedImage = infoDictionary["picture"] as? [String:String]
                let loadedPicPath = loadedImage?["large"]
                
                let loadedUser = User(name: loadedName, phone: loadedphone, email: loadedEmail, image: loadedPicPath)
                 settingInfo(user: loadedUser)
            }
            
        }
    }
    
    //錯誤提示
    func popAlert(withTitle title:String){
        let alert = UIAlertController(title: title, message: "請稍後再試", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    //moreInfo segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "moreInfo"{
            infoTableViewController = segue.destination as? infoTableViewController
        }
    }
    
    
    func settingInfo(user:User){

        userName.text = user.name
        infoTableViewController?.phoneLab.text = user.phone
        infoTableViewController?.emailLab.text = user.email
        infoTableViewController?.dateLab.text = user.date?.description
        if let imageAddress = user.image{
            if let imageUrl = URL(string:imageAddress){
                let task = urlSession.downloadTask(with: imageUrl, completionHandler: {(url,response,error) in
                    if error != nil{
                        DispatchQueue.main.async {
                            self.popAlert(withTitle: "Sorry")
                        }
                        return
                    }
                    if let okUrl = url{
                        do{
                            let downloadImage = UIImage(data:try Data(contentsOf: okUrl))
                            DispatchQueue.main.async {
                                self.userImage.image = downloadImage
                            }
                            self.isDownLoading = false
                        }
                        catch{
                            DispatchQueue.main.async {
                                self.popAlert(withTitle: "Sorry")
                            }
                            self.isDownLoading = false
                        }
                    }else{
                        self.isDownLoading = false
                    }
                })
                task.resume()
            }else{
                self.isDownLoading = false
            }
        }else{
            self.isDownLoading = false
        }
    }
    
    //畫面讀取完畢後畫面 可使圖片不變形
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        userImage.layer.cornerRadius = userImage.frame.size.width/2
        userImage.clipsToBounds=true
    }

}

