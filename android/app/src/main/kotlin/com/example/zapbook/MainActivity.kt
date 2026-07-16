package com.example.zapbook

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var nip55Plugin: Nip55Plugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        nip55Plugin = Nip55Plugin(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        nip55Plugin?.handleActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        nip55Plugin?.dispose()
        nip55Plugin = null
        super.onDestroy()
    }
}
