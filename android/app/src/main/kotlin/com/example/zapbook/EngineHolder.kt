package com.example.zapbook

import android.content.Context
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

object EngineHolder {
    const val ENGINE_ID = "zapbook_main"

    var nip55Plugin: Nip55Plugin? = null
        private set
    var syncServicePlugin: SyncServicePlugin? = null
        private set

    fun getOrCreate(context: Context): FlutterEngine {
        FlutterEngineCache.getInstance().get(ENGINE_ID)?.let { return it }

        val appContext = context.applicationContext
        val loader = FlutterInjector.instance().flutterLoader()
        if (!loader.initialized()) {
            loader.startInitialization(appContext)
        }
        loader.ensureInitializationComplete(appContext, null)

        val engine = FlutterEngine(appContext)
        if (!engine.dartExecutor.isExecutingDart) {
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )
        }
        nip55Plugin = Nip55Plugin(appContext, engine.dartExecutor.binaryMessenger)
        syncServicePlugin = SyncServicePlugin(appContext, engine.dartExecutor.binaryMessenger)
        FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
        return engine
    }
}
