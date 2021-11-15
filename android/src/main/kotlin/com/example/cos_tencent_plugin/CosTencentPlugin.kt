package com.example.cos_tencent_plugin

import android.app.Activity
import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import com.tencent.cos.xml.CosXmlService
import com.tencent.cos.xml.CosXmlServiceConfig
import com.tencent.cos.xml.exception.CosXmlClientException
import com.tencent.cos.xml.exception.CosXmlServiceException
import com.tencent.cos.xml.ktx.cosService
import com.tencent.cos.xml.listener.CosXmlProgressListener
import com.tencent.cos.xml.listener.CosXmlResultListener
import com.tencent.cos.xml.model.CosXmlRequest
import com.tencent.cos.xml.model.CosXmlResult
import com.tencent.cos.xml.transfer.COSXMLUploadTask
import com.tencent.cos.xml.transfer.TransferConfig
import com.tencent.cos.xml.transfer.TransferManager

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.HashMap
import com.tencent.qcloud.core.auth.ShortTimeCredentialProvider

import com.tencent.qcloud.core.auth.QCloudCredentialProvider
import com.tencent.qcloud.core.auth.SessionQCloudCredentials


/** CosTencentPlugin */
class CosTencentPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var mContext: Context
    private lateinit var mActivity: Activity

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "cos_tencent_plugin")
        mContext = flutterPluginBinding.applicationContext
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else if (call.method == "getNative") {
            result.success("getNative")
        } else if (call.method == "uploadFile") {


            Log.d("onMethodCall", "uploadFile")

//            val secretId = call.argument<String>("secretId") //secretId
//
//            val secretKey = call.argument<String>("secretKey") //secretKey


            // 此秘钥计算方法与项目中用到的不符合，所以不使用该方法生成秘钥
            // QCloudCredentialProvider myCredentialProvider =
            //        new ShortTimeCredentialProvider(secretId, secretKey, 300);

//            val secretId = "secretId" //永久密钥 secretId
//
//            val secretKey = "secretKey" //永久密钥 secretKey
//
//            // keyDuration 为请求中的密钥有效期，单位为秒
//            val myCredentialProvider: QCloudCredentialProvider = ShortTimeCredentialProvider(secretId, secretKey, 300)

            val myCredentialProvider = call.argument<String>("secretId")?.let {
                LocalSessionCredentialProvider(
                        it,
                        call.argument<String>("secretKey")!!,
                        call.argument<String>("sessionToken")!!,
                        call.argument<Any>("expiredTime").toString().toLong()

                )
            }

            val region = call.argument<String>("region") // region
            val bucket = call.argument<String>("bucket") // bucket
            val localPath = call.argument<String>("localPath") // localPath
            val cosPath = call.argument<String>("cosPath") // cosPath

            /// 初始化 COS Service
            // 创建 CosXmlServiceConfig 对象，根据需要修改默认的配置参数

            /// 初始化 COS Service
            // 创建 CosXmlServiceConfig 对象，根据需要修改默认的配置参数
            val serviceConfig = CosXmlServiceConfig.Builder()
                    .setRegion(region)
                    .isHttps(true) // 使用 HTTPS 请求, 默认为 HTTP 请求
                    .builder()

            val cosXmlService = CosXmlService(mContext, serviceConfig, myCredentialProvider)

            // 初始化 TransferConfig，这里使用默认配置，如果需要定制，请参考 SDK 接口文档

            // 初始化 TransferConfig，这里使用默认配置，如果需要定制，请参考 SDK 接口文档
            val transferConfig = TransferConfig.Builder().build()
            //初始化 TransferManager
            //初始化 TransferManager
            val transferManager = TransferManager(cosXmlService, transferConfig)
            //上传文件
            //上传文件
            val cosxmlUploadTask = transferManager.upload(bucket, cosPath, localPath, null)

            val data = HashMap<String, Any>()
            data["localPath"] = localPath!!
            data["cosPath"] = cosPath!!

            Log.d("onMethodCall", "startUpload")

            cosxmlUploadTask.setCosXmlProgressListener { complete, target ->
                Log.d("onProgress", "$complete : $target")
                mActivity.runOnUiThread {
                    val progress = HashMap<String, Any>()
                    progress["cosPath"] = cosPath!!
                    progress["localPath"] = localPath
                    progress["progress"] = complete * 100.0 / target
                    channel.invokeMethod("onProgress", progress)
                }
            }

            //设置返回结果回调
            cosxmlUploadTask.setCosXmlResultListener(object : CosXmlResultListener {
                override fun onSuccess(request: CosXmlRequest, httpResult: CosXmlResult) {
                    Log.d("onSuccess", httpResult.printResult())
                    mActivity.runOnUiThread {
                        result.success(data)
                        channel.invokeMethod("onSuccess", cosPath)
                    }
                }

                override fun onFail(request: CosXmlRequest, exception: CosXmlClientException, serviceException: CosXmlServiceException) {
                    Log.d("onFail", exception.toString() + serviceException.toString())
                    data["message"] = exception.toString() + serviceException.toString()
                    mActivity.runOnUiThread {
                        result.error("400", "error", exception.toString())
                        channel.invokeMethod("onFailed", data)
                    }
                    if (exception != null) {
                        exception.printStackTrace()
                    } else {
                        serviceException.printStackTrace()
                    }
                }
            })

        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        mActivity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        TODO("Not yet implemented")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        TODO("Not yet implemented")
    }

    override fun onDetachedFromActivity() {
        TODO("Not yet implemented")
    }
}
