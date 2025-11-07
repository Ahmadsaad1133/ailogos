package com.example.ailogos  // 👈 must match your manifest package!

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform

class MainActivity : FlutterActivity() {
    private val CHANNEL = "chaquopy"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "runPythonTTS") {
                    val text = call.argument<String>("text") ?: ""
                    val path = call.argument<String>("path") ?: ""

                    try {
                        if (!Python.isStarted()) {
                            Python.start(AndroidPlatform(this))
                        }

                        val py = Python.getInstance()
                        val module = py.getModule("local_tts")
                        val output = module.callAttr("generate_tts", text, path).toString()
                        result.success(output)

                    } catch (e: Exception) {
                        result.error("PYTHON_ERROR", e.message, e.stackTraceToString())
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
