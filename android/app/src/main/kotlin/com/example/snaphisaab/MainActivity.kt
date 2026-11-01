package com.example.snaphisaab

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.speech.RecognizerIntent
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val VOICE_CHANNEL = "com.example.snaphisaab/voice"
    private val SMS_CHANNEL = "snaphisaab/sms"
    private val REQ_CODE_SPEECH_INPUT = 100
    private val REQ_CODE_SMS_PERM = 200

    private var pendingSpeechResult: MethodChannel.Result? = null
    private var pendingSmsPermResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Voice Recognition Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VOICE_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startVoiceRecognition") {
                pendingSpeechResult = result
                val language = call.argument<String>("language") ?: "mr-IN"
                startVoiceRecognition(language)
            } else {
                result.notImplemented()
            }
        }

        // Native SMS Reader Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestSmsPermission" -> {
                    if (hasSmsPermission()) {
                        result.success(true)
                    } else {
                        pendingSmsPermResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.READ_SMS),
                            REQ_CODE_SMS_PERM
                        )
                    }
                }
                "readSmsInbox" -> {
                    if (!hasSmsPermission()) {
                        result.error("PERMISSION_DENIED", "READ_SMS permission not granted", null)
                        return@setMethodCallHandler
                    }
                    val sinceTimestamp = call.argument<Long>("sinceTimestamp") ?: 0L
                    try {
                        val smsList = readSmsInbox(sinceTimestamp)
                        result.success(smsList)
                    } catch (e: Exception) {
                        result.error("SCAN_ERROR", e.localizedMessage, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun hasSmsPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.READ_SMS
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun readSmsInbox(sinceTimestamp: Long): List<Map<String, Any>> {
        val list = mutableListOf<Map<String, Any>>()
        val uri = Uri.parse("content://sms/inbox")
        val projection = arrayOf("address", "body", "date")
        
        var selection: String? = null
        var selectionArgs: Array<String>? = null
        if (sinceTimestamp > 0L) {
            selection = "date >= ?"
            selectionArgs = arrayOf(sinceTimestamp.toString())
        }

        val cursor = contentResolver.query(
            uri,
            projection,
            selection,
            selectionArgs,
            "date DESC"
        )

        cursor?.use { c ->
            val addressIdx = c.getColumnIndex("address")
            val bodyIdx = c.getColumnIndex("body")
            val dateIdx = c.getColumnIndex("date")

            while (c.moveToNext()) {
                val address = if (addressIdx != -1) c.getString(addressIdx) ?: "" else ""
                val body = if (bodyIdx != -1) c.getString(bodyIdx) ?: "" else ""
                val date = if (dateIdx != -1) c.getLong(dateIdx) else 0L

                list.add(
                    mapOf(
                        "sender" to address,
                        "body" to body,
                        "timestamp" to date
                    )
                )
            }
        }

        return list
    }

    private fun startVoiceRecognition(language: String) {
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, language)
        intent.putExtra(RecognizerIntent.EXTRA_PROMPT, "काहीतरी बोला (Speak now)...")
        try {
            startActivityForResult(intent, REQ_CODE_SPEECH_INPUT)
        } catch (e: Exception) {
            pendingSpeechResult?.error("NOT_AVAILABLE", "Voice recognition not available", null)
            pendingSpeechResult = null
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQ_CODE_SMS_PERM) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingSmsPermResult?.success(granted)
            pendingSmsPermResult = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQ_CODE_SPEECH_INPUT) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val result = data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
                if (result != null && result.isNotEmpty()) {
                    pendingSpeechResult?.success(result[0])
                } else {
                    pendingSpeechResult?.error("NO_RESULT", "No speech recognized", null)
                }
            } else if (resultCode == Activity.RESULT_CANCELED) {
                pendingSpeechResult?.error("CANCELED", "Voice recognition canceled", null)
            } else {
                pendingSpeechResult?.error("ERROR", "Voice recognition error", null)
            }
            pendingSpeechResult = null
        }
    }
}
