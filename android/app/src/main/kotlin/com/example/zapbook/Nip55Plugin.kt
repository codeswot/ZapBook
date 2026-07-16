package com.example.zapbook

import android.app.Activity
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class Nip55Plugin(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, CHANNEL).apply { setMethodCallHandler(this@Nip55Plugin) }
    private val mainHandler = Handler(Looper.getMainLooper())

    private var pending: MethodChannel.Result? = null
    private var pendingType: String? = null
    private var pendingPackage: String? = null
    private var pendingCurrentUser: String? = null
    private var timeoutRunnable: Runnable? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSignerInstalled" -> result.success(isSignerInstalled())
            "getPublicKey" -> getPublicKey(result)
            "signEvent" -> directed(call, result, TYPE_SIGN_EVENT, RESOLVER_SIGN_EVENT)
            "nip44Encrypt" -> directed(call, result, TYPE_NIP44_ENCRYPT, RESOLVER_NIP44_ENCRYPT)
            "nip44Decrypt" -> directed(call, result, TYPE_NIP44_DECRYPT, RESOLVER_NIP44_DECRYPT)
            "nip04Encrypt" -> directed(call, result, TYPE_NIP04_ENCRYPT, RESOLVER_NIP04_ENCRYPT)
            "nip04Decrypt" -> directed(call, result, TYPE_NIP04_DECRYPT, RESOLVER_NIP04_DECRYPT)
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    private fun isSignerInstalled(): Boolean {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("$SCHEME:"))
        return activity.packageManager.queryIntentActivities(intent, 0).isNotEmpty()
    }

    private fun getPublicKey(result: MethodChannel.Result) {
        if (!isSignerInstalled()) return result.error(ERR_NOT_INSTALLED, "No signer app installed", null)
        if (pending != null) return result.error(ERR_UNAVAILABLE, "Signer request already in progress", null)
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("$SCHEME:")).apply {
            putExtra("type", TYPE_GET_PUBLIC_KEY)
            putExtra("permissions", DEFAULT_PERMISSIONS)
        }
        launch(intent, TYPE_GET_PUBLIC_KEY, result, expectedPackage = null, currentUser = null)
    }

    private fun directed(
        call: MethodCall,
        result: MethodChannel.Result,
        type: String,
        resolverType: String,
    ) {
        val packageName = call.argument<String>("package")
        if (packageName.isNullOrEmpty()) return result.error(ERR_UNAVAILABLE, "Missing signer package", null)
        val currentUser = call.argument<String>("currentUser").orEmpty()

        val payload: String
        val counterparty: String
        if (type == TYPE_SIGN_EVENT) {
            payload = call.argument<String>("eventJson").orEmpty()
            counterparty = ""
        } else {
            payload = call.argument<String>("payload").orEmpty()
            counterparty = call.argument<String>("pubkey").orEmpty()
        }

        when (val row = queryResolver(resolverType, packageName, arrayOf(payload, counterparty, currentUser))) {
            is Row.Value -> return result.success(validateValue(type, row.value, currentUser, result) ?: return)
            Row.Rejected -> return result.error(ERR_REJECTED, "Signer rejected the request", null)
            Row.Unavailable -> Unit
        }

        if (payload.toByteArray(Charsets.UTF_8).size > MAX_INTENT_BYTES) {
            return result.error(ERR_UNAVAILABLE, "Payload too large for intent fallback", null)
        }
        if (pending != null) return result.error(ERR_UNAVAILABLE, "Signer request already in progress", null)

        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("$SCHEME:$payload")).apply {
            `package` = packageName
            putExtra("type", type)
            putExtra("id", System.currentTimeMillis().toString())
            putExtra("current_user", currentUser)
            if (type != TYPE_SIGN_EVENT) putExtra("pubkey", counterparty)
        }
        launch(intent, type, result, expectedPackage = packageName, currentUser = currentUser)
    }

    private fun launch(
        intent: Intent,
        type: String,
        result: MethodChannel.Result,
        expectedPackage: String?,
        currentUser: String?,
    ) {
        pending = result
        pendingType = type
        pendingPackage = expectedPackage
        pendingCurrentUser = currentUser
        timeoutRunnable = Runnable { finishError(ERR_TIMEOUT, "Signer timed out") }.also {
            mainHandler.postDelayed(it, APPROVAL_TIMEOUT_MS)
        }
        try {
            activity.startActivityForResult(intent, REQUEST_CODE)
        } catch (e: Exception) {
            finishError(ERR_UNAVAILABLE, e.message ?: "Could not launch signer")
        }
    }

    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val result = pending ?: return true
        val type = pendingType.orEmpty()
        val expectedPackage = pendingPackage
        val currentUser = pendingCurrentUser.orEmpty()
        clearPending()

        if (resultCode != Activity.RESULT_OK || data == null) {
            return finishTo(result) { it.error(ERR_REJECTED, "Signer rejected the request", null) }
        }
        if (data.getBooleanExtra("rejected", false)) {
            return finishTo(result) { it.error(ERR_REJECTED, "Signer rejected the request", null) }
        }

        val echoPackage = data.getStringExtra("package")
        if (expectedPackage != null && echoPackage != null && echoPackage != expectedPackage) {
            return finishTo(result) { it.error(ERR_MALFORMED, "Signer package mismatch", null) }
        }

        if (type == TYPE_GET_PUBLIC_KEY) {
            val pubkey = data.getStringExtra("result") ?: data.getStringExtra("signature")
            if (pubkey.isNullOrEmpty()) {
                return finishTo(result) { it.error(ERR_MALFORMED, "Empty public key", null) }
            }
            return finishTo(result) { it.success(mapOf("pubkey" to pubkey, "package" to echoPackage)) }
        }

        val value = data.getStringExtra("event")
            ?: data.getStringExtra("result")
            ?: data.getStringExtra("signature")
        if (value == null || value.isEmpty()) {
            return finishTo(result) { it.error(ERR_MALFORMED, "Empty signer response", null) }
        }
        val mismatch = validateMismatch(type, value, currentUser)
        if (mismatch != null) {
            return finishTo(result) { it.error(ERR_MALFORMED, mismatch, null) }
        }
        return finishTo(result) { it.success(value) }
    }

    private fun queryResolver(type: String, packageName: String, args: Array<String>): Row {
        val uri = Uri.parse("content://$packageName.$type")
        var cursor: Cursor? = null
        return try {
            cursor = activity.contentResolver.query(uri, args, null, null, null)
            if (cursor == null) return Row.Unavailable
            if (!cursor.moveToFirst()) return Row.Unavailable
            if (cursor.getColumnIndex("rejected") >= 0) return Row.Rejected
            val value = cursor.stringColumn("event")
                ?: cursor.stringColumn("result")
                ?: cursor.stringColumn("signature")
            if (value == null || value.isEmpty()) Row.Unavailable else Row.Value(value)
        } catch (e: Exception) {
            Row.Unavailable
        } finally {
            cursor?.close()
        }
    }

    private fun Cursor.stringColumn(name: String): String? {
        val idx = getColumnIndex(name)
        if (idx < 0) return null
        return try {
            getString(idx)
        } catch (e: Exception) {
            null
        }
    }

    private fun validateValue(
        type: String,
        value: String,
        currentUser: String,
        result: MethodChannel.Result,
    ): String? {
        val mismatch = validateMismatch(type, value, currentUser)
        if (mismatch != null) {
            result.error(ERR_MALFORMED, mismatch, null)
            return null
        }
        return value
    }

    private fun validateMismatch(type: String, value: String, currentUser: String): String? {
        if (type != TYPE_SIGN_EVENT || currentUser.isEmpty()) return null
        val pubkey = signedEventPubkey(value) ?: return null
        return if (pubkey.equals(currentUser, ignoreCase = true)) null else "Signed event pubkey mismatch"
    }

    private fun signedEventPubkey(eventJson: String): String? {
        val marker = "\"pubkey\""
        val at = eventJson.indexOf(marker)
        if (at < 0) return null
        val colon = eventJson.indexOf(':', at + marker.length)
        if (colon < 0) return null
        val open = eventJson.indexOf('"', colon + 1)
        if (open < 0) return null
        val close = eventJson.indexOf('"', open + 1)
        if (close < 0) return null
        return eventJson.substring(open + 1, close)
    }

    private fun finishError(code: String, message: String) {
        val result = pending ?: return
        clearPending()
        result.error(code, message, null)
    }

    private inline fun finishTo(result: MethodChannel.Result, block: (MethodChannel.Result) -> Unit): Boolean {
        block(result)
        return true
    }

    private fun clearPending() {
        timeoutRunnable?.let { mainHandler.removeCallbacks(it) }
        timeoutRunnable = null
        pending = null
        pendingType = null
        pendingPackage = null
        pendingCurrentUser = null
    }

    private sealed class Row {
        data class Value(val value: String) : Row()
        object Rejected : Row()
        object Unavailable : Row()
    }

    companion object {
        private const val CHANNEL = "zapbook/nip55"
        private const val SCHEME = "nostrsigner"
        private const val REQUEST_CODE = 42055
        private const val APPROVAL_TIMEOUT_MS = 120_000L
        private const val MAX_INTENT_BYTES = 64 * 1024

        private const val TYPE_GET_PUBLIC_KEY = "get_public_key"
        private const val TYPE_SIGN_EVENT = "sign_event"
        private const val TYPE_NIP44_ENCRYPT = "nip44_encrypt"
        private const val TYPE_NIP44_DECRYPT = "nip44_decrypt"
        private const val TYPE_NIP04_ENCRYPT = "nip04_encrypt"
        private const val TYPE_NIP04_DECRYPT = "nip04_decrypt"

        private const val RESOLVER_SIGN_EVENT = "SIGN_EVENT"
        private const val RESOLVER_NIP44_ENCRYPT = "NIP44_ENCRYPT"
        private const val RESOLVER_NIP44_DECRYPT = "NIP44_DECRYPT"
        private const val RESOLVER_NIP04_ENCRYPT = "NIP04_ENCRYPT"
        private const val RESOLVER_NIP04_DECRYPT = "NIP04_DECRYPT"

        private const val ERR_NOT_INSTALLED = "not-installed"
        private const val ERR_REJECTED = "rejected"
        private const val ERR_TIMEOUT = "timeout"
        private const val ERR_UNAVAILABLE = "unavailable"
        private const val ERR_MALFORMED = "malformed"

        private const val DEFAULT_PERMISSIONS =
            "[{\"type\":\"get_public_key\"},{\"type\":\"sign_event\"}," +
                "{\"type\":\"nip44_encrypt\"},{\"type\":\"nip44_decrypt\"}," +
                "{\"type\":\"nip04_encrypt\"},{\"type\":\"nip04_decrypt\"}]"
    }
}
