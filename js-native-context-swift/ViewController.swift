//
//  ViewController.swift
//  WKWebView-hybrid
//
//  Created by HelloMac on 16/6/29.
//  Copyright © 2016年 HelloMac. All rights reserved.
//

import UIKit
import WebKit

/**
 WKWebView:
 在苹果iOS8中引入的，目的是给出一个新的高性能的webView解决方案，完善UIWebView占用内存高的问题。
 
 苹果将UIWebViewDelegate与UIWebView重构成14个类和3个协议
 完善：
 1.将浏览器内核渲染进程提取出APP，有系统进行统一管理，这减少了相当一部分的性能损失
 2.js可以直接使用已经事先注入js runTime的js接口给native层传值，不必再通过iframe制造页面刷新在解析自定义协议的奇怪方式
 3.支持高达60fps的滚定刷新率，内置了手势探测
 */

/**
 (为了更方便在开发中调试问题，便于处理页面加载失败事件）处理加载失败事件    必须设置：self.wk.navigationDelegate = self
 主要也=与页面导航架在相关
 */
private typealias wkNavigationDelegate = ViewController
extension wkNavigationDelegate{
    func webView(webView:WKWebView,didFailNavigation navigation:WKNavigation!,withError error:NSError){
        NSLog(error.debugDescription)
        
    }
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        print(error.debugDescription)
    }
}

/**
 显示弹框，在UIWebView中，js的alert（）弹窗会自动以系统弹窗形式展示，但是wkwebview把这个接口也暴露给我们，让我们自己handle js传来的alert（），自己写代码handle这个事件
 与js交互时的UI展示相关，比较js的alert。confirm。prompt
 */
private typealias wkUIDelegate = ViewController
extension wkUIDelegate{
    
    func webView(webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: () -> Void) {
        let ac = UIAlertController(title: webView.title,message: message,preferredStyle: UIAlertControllerStyle.Alert)
        ac.addAction(UIAlertAction(title: "OK",style: UIAlertActionStyle.Cancel,handler: {(aa)->Void in
            completionHandler()
        }))
        self.presentViewController(ac, animated: true, completion: nil)
    }
}

//学习使用WKWebView传值方式，实心JavaScript层向native层的传值，并反射出我们想要的对方，执行我们想要的方法   与js交互相关，通常是iOS端注入名称，js端通过window.webkit.messageHandlers.{name}.postMessage()来发送消息到iOS端

private typealias wkScriptMessageHandler = ViewController
extension wkScriptMessageHandler{
    
    //实现反射   将反射出我们需要的对象，并执行指定的函数，把结果返回到js runtime中
    //传递js对象到native   就是我们说的json（js对象的键不用加双引号）  直接使用window.webkit.messageHandlers.OOXX.postMessage({className: "Callme", functionName: "maybe"}) 接口传递js对象  OOXX == ViewController
    
    //相应处理js那边的调用
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        
        if message.name == "OOXX" {
            print("OOXX")
            if let dic = message.body as? NSDictionary,
                className = dic["className"]?.description{

                print(className)
                self.albumCollection()
                if className == "Consol" {
                    
                    
                }else if className == "Accelerometer"{
                   
                    
                }

            }
        }
    }
}

//构造出一个完整的js->Native->js回调+传值的数据通道，并设计出插件协议，最终实现jsAPI层完全兼容Cordova
//实现js向swift的传值  Console插件就是js想swift传值的最好实例，用以在xcode中调试窗口显示jsconsole.log()的信息

//实现swift向js层传值
//分析Accelerometer这个插件的调用方式，这个插件用到两个回调函数，正确处理，和错误回溯，在每次调用之前把回调函数压入队列，把序列号传给native层，等native层返回结果时，再拿这个序列号来回调函数

class ViewController: UIViewController,WKNavigationDelegate,WKUIDelegate,WKScriptMessageHandler,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    var wk:WKWebView!
    
    var dic = Dictionary<String,AnyObject>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated);
        
        //注册scriptMessageHandle
        let conf = WKWebViewConfiguration()
        //添加一个名称，就可以在js通过这个名称发送消息
        conf.userContentController.addScriptMessageHandler(self, name: "OOXX")
        
        self.wk = WKWebView(frame: self.view.frame,configuration: conf)
        
        self.wk.navigationDelegate = self
        self.wk.UIDelegate = self
        
        //链接http，使用xcode7，加载页面会一片空白，是因为iOS9中不在支持非HTTPS的地址，在info.plist文件中添加NSAppTransportSecurity
        let url = NSURL.fileURLWithPath((NSBundle.mainBundle().pathForResource("js端", ofType: "html"))!)
        let request = NSURLRequest.init(URL: url)
        
        self.wk.loadRequest(request)
        
        self.view.addSubview(self.wk)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func albumCollection() {
        let pickerControll = UIImagePickerController();
        pickerControll.sourceType = UIImagePickerControllerSourceType.PhotoLibrary;
        pickerControll.delegate = self;
        self.presentViewController(pickerControll, animated: true, completion: nil);
    }
    
    /**
     pickerControll代理方法
     */
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        
        picker.dismissViewControllerAnimated(true, completion: nil);
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage;
        let imageUrl = info[UIImagePickerControllerReferenceURL];
        let strString = imageUrl?.absoluteString;
        let imageName = strString?.componentsSeparatedByString("?")[1];
        
        dic["image"] = imageName
        dic["width"] = image.size.width
        dic["height"] = image.size.height
        
        let selector = Selector(transformData(dic))
        
        if self.respondsToSelector(selector) {
            self.performSelector(selector)
        }
        
        picker.dismissViewControllerAnimated(true, completion: nil);
    }
    
    func transformData(dic:NSDictionary) {
        
        print("我111111111")
        
        print(dic);
        
        
        
        self.wk.evaluateJavaScript(<#T##javaScriptString: String##String#>, completionHandler: nil);
    }
    
    func saveImage(image:UIImage ,imageName:String) -> String {
        let fileManager = NSFileManager.defaultManager();
        let data = UIImageJPEGRepresentation(image, 1);
        let DocumentPath = NSHomeDirectory().stringByAppendingString("/Documents");
        
        do{
            try fileManager.createDirectoryAtPath(DocumentPath, withIntermediateDirectories: true, attributes: nil);
        }catch{
            
        }
        
        fileManager.createFileAtPath(DocumentPath.stringByAppendingString("/"+imageName), contents: data, attributes: nil);
        
        let fullPath = DocumentPath.stringByAppendingString("/"+imageName);
        
        return fullPath;
    }
    
}

