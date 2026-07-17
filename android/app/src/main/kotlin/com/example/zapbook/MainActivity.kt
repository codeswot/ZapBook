package com.example.zapbook

import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    override fun provideFlutterEngine(context: Context): FlutterEngine {
        return EngineHolder.getOrCreate(context)
    }

    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EngineHolder.nip55Plugin?.activity = this
        EngineHolder.syncServicePlugin?.activity = this
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        EngineHolder.nip55Plugin?.handleActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        if (EngineHolder.nip55Plugin?.activity === this) {
            EngineHolder.nip55Plugin?.activity = null
        }
        if (EngineHolder.syncServicePlugin?.activity === this) {
            EngineHolder.syncServicePlugin?.activity = null
        }
        super.onDestroy()
    }
}
