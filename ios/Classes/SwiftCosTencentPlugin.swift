import Flutter
import UIKit
import QCloudCOSXML

public class SwiftCosTencentPlugin: NSObject, FlutterPlugin,QCloudSignatureProvider {
    var arguments:[String:Any]!;
    var  channel:FlutterMethodChannel!;
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "cos_tencent_plugin", binaryMessenger: registrar.messenger())
        //        let instance = SwiftCosTencentPlugin()
        let instance = SwiftCosTencentPlugin().initWithChannel(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func initWithChannel(channel:FlutterMethodChannel) -> SwiftCosTencentPlugin{
        self.channel = channel;
        return self;
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        self.arguments = call.arguments as? [String:Any]
        //        self.arguments = call.arguments;
        print(self.arguments as Any)
        switch(call.method){
            
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
            break;
            
        case "getNative":
            result("iOS getNative");
            break;
        case "uploadFile":
            NSLog("self.arguments")
            let urlStr = self.arguments?["localPath"] as? String
            let url = URL(fileURLWithPath: urlStr!)
            let appid = self.arguments?["appid"] as? String
            let region = self.arguments?["region"] as? String
            let cosPath = self.arguments?["cosPath"] as? String
            let bucket = self.arguments?["bucket"] as? String
            print(urlStr as Any)
            print(appid as Any)
            print(region as Any)
            print(cosPath as Any)
            print(bucket as Any)
            
            let config = QCloudServiceConfiguration.init();
            config.appID = appid;
            
            
            
            // 密钥提供者为自己
            config.signatureProvider = self;
            
            
            
            let endpoint = QCloudCOSXMLEndPoint.init();
            //服务地域简称，例如广州地域是 ap-guangzhou
            endpoint.regionName = region;
            config.endpoint = endpoint;
            
            // 使用 HTTPS
            endpoint.useHTTPS = true;
            print(QCloudCOSXMLService.hasService(forKey: region!))
            // 初始化 COS 服务示例
            if(!QCloudCOSXMLService.hasService(forKey: region!)){
                    QCloudCOSXMLService.registerCOSXML(with: config, withKey: region!)
            }
            let put:QCloudCOSXMLUploadObjectRequest = QCloudCOSXMLUploadObjectRequest<AnyObject>();
            
            put.object = cosPath!;
            put.bucket = bucket!;
            put.body =  url as AnyObject;
            
            
            //监听上传进度
            put.sendProcessBlock = { (bytesSent, totalBytesSent,
                                      totalBytesExpectedToSend) in
                //      bytesSent                 本次要发送的字节数（一个大文件可能要分多次发送）
                //      totalBytesSent            已发送的字节数
                //      totalBytesExpectedToSend  本次上传要发送的总字节数（即一个文件大小）
                
                let a = NSNumber(value: totalBytesSent)
                let b = NSNumber(value: totalBytesExpectedToSend)
                let c = NSNumber(value: a.doubleValue / b.doubleValue * 100)
                
                let reslutMap: [String:Any] = [
                    "localPath": urlStr!,
                    "cosPath": cosPath!,
                    "progress": c,
                ]
                
                self.channel.invokeMethod("progress", arguments: reslutMap)
                
            };
            
            put.setFinish { (resultT, error)in
                if error != nil{
                    let reslutMap: [String:Any] = [
                        "localPath": urlStr!,
                        "cosPath": cosPath!,
                        "message": error!.localizedDescription,
                    ]
                    result(reslutMap)
                    self.channel.invokeMethod("onFailed", arguments: reslutMap)
                }else{
                    let reslutMap: [String:Any] = [
                        "localPath": urlStr!,
                        "cosPath": cosPath!,
                    ]
                    result(reslutMap)
                    self.channel.invokeMethod("onSuccess", arguments: reslutMap)
                }
            }
            QCloudCOSTransferMangerService.registerCOSTransferManger(with: config, withKey: region!).uploadObject(put);
//            QCloudCOSTransferMangerService.defaultCOSTransferManager().uploadObject(put);
            
            break;
            
        default:
            result("method:\(call.method) not implement");
        }
    }
    
    public func signature(with fileds: QCloudSignatureFields!, request: QCloudBizHTTPRequest!, urlRequest urlRequst: NSMutableURLRequest!, compelete continueBlock: QCloudHTTPAuthentationContinueBlock!) {
        let credential = QCloudCredential.init();
        
        //暂时使用永久
        credential.secretID = (self.arguments["secretId"] as! String);
        credential.secretKey = (self.arguments["secretKey"] as! String);
        
//        credential.secretID = (self.arguments["secretId"] as! String);
//        credential.secretKey = (self.arguments["secretKey"] as! String);
//        credential.token = (self.arguments["sessionToken"] as! String);
//
//        credential.startDate = Date.init(timeIntervalSince1970: TimeInterval(truncating: (self.arguments["startTime"] as! NSNumber)));
//        credential.expirationDate = Date.init(timeIntervalSince1970: TimeInterval(truncating: (self.arguments["expiredTime"] as! NSNumber)))
//
        let auth = QCloudAuthentationV5Creator.init(credential: credential);
        let signature = auth?.signature(forData: urlRequst)
        continueBlock(signature,nil);
        
    }
    
}
