import Flutter
import UIKit
import QCloudCOSXML

public class SwiftCosTencentPlugin: NSObject, FlutterPlugin,QCloudSignatureProvider {
    var arguments:[String:Any]!;
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "cos_tencent_plugin", binaryMessenger: registrar.messenger())
        let instance = SwiftCosTencentPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
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
            //          endpoint.useHTTPS = true;
            
            // 初始化 COS 服务示例
            QCloudCOSXMLService.registerDefaultCOSXML(with: config);
            QCloudCOSTransferMangerService.registerDefaultCOSTransferManger(
                with: config);
            let put:QCloudCOSXMLUploadObjectRequest = QCloudCOSXMLUploadObjectRequest<AnyObject>();
            
            put.object = cosPath!;
            put.bucket = bucket!;
            put.body =  NSURL.fileURL(withPath: urlStr!) as AnyObject;
            
            
            
            //监听上传进度
            put.sendProcessBlock = { (bytesSent, totalBytesSent,
                                      totalBytesExpectedToSend) in
                //      bytesSent                 本次要发送的字节数（一个大文件可能要分多次发送）
                //      totalBytesSent            已发送的字节数
                //      totalBytesExpectedToSend  本次上传要发送的总字节数（即一个文件大小）
                
                //空字典创建
                var data = [String: String]()
                data.updateValue(urlStr!, forKey: "localPath")
                data.updateValue(cosPath!, forKey: "cosPath")
                
                //                        int c = totalBytesSent/totalBytesExpectedToSend*100;
                //
                //                        data.updateValue(c, forKey: "progress")
                
            };
            
            
            
            
            break;
            
        default:
            result("method:\(call.method) not implement");
        }
    }
    
    public func signature(with fileds: QCloudSignatureFields!, request: QCloudBizHTTPRequest!, urlRequest urlRequst: NSMutableURLRequest!, compelete continueBlock: QCloudHTTPAuthentationContinueBlock!) {
        let credential = QCloudCredential.init();
        credential.secretID = (self.arguments["secretId"] as! String);
        credential.secretKey = (self.arguments["secretKey"] as! String);
        credential.token = (self.arguments["sessionToken"] as! String);
        
        // 使用永久密钥计算签名
        let auth = QCloudAuthentationV5Creator.init(credential: credential);
        let signature = auth?.signature(forData: urlRequst)
        continueBlock(signature,nil);
        
    }
    
}
