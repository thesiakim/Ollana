package com.c104.ollana.presentation.data

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.c104.ollana.presentation.MainActivity
import com.c104.ollana.presentation.sensor.SensorCollectorService
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService
import com.google.gson.Gson
import org.json.JSONObject
import java.io.ByteArrayInputStream
import java.io.ObjectInputStream

class WatchMessageListenerService : WearableListenerService() {

    private val TAG = "WatchMessageService"

    override fun onMessageReceived(event: MessageEvent) {
        super.onMessageReceived(event)

        Log.d(TAG, "📩 백그라운드 메시지 수신: ${event.path}")

        try {
            // 메시지 payload 역직렬화 (ByteArray → Map)
            val bais = ByteArrayInputStream(event.data)
            val ois = ObjectInputStream(bais)
            val map = ois.readObject() as HashMap<*, *>
            ois.close()

            // JSON 파싱
            val jsonString = Gson().toJson(map)
            val json = JSONObject(jsonString)

            val path = json.optString("path", "")

            Log.d(TAG,"백그라운드 path=${path}")

            when (path) {

                "/START_TRACKING" -> {
                    // 트래킹 시작 → 센서 수집 서비스 실행 (심박수)
                    Log.d(TAG, "📡 트래킹 시작 요청 수신 → 센서 수집 서비스 시작")
                    val intent = Intent(this, SensorCollectorService::class.java)
                    ContextCompat.startForegroundService(this, intent)
                }

                "/STOP_TRACKING" -> {
                    // 트래킹 종료 → 센서 수집 서비스 종료
                    Log.d(TAG, "🛑 트래킹 종료 요청 수신 → 센서 수집 중지")
                    stopService(Intent(this, SensorCollectorService::class.java))
                }

                "/REACHED" -> {
                    // 정상 부근 도착 → 진동 + 화면 띄우기
                    vibrate()
                    showNotification("정상 도착!", "트래킹 종료를 눌러 기록을 저장하세요")

                    val intent = Intent(this, MainActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                        putExtra("trigger", "reached") // 이걸 통해 MainActivity에서 분기 가능
                    }
                    startActivity(intent)
                    Log.d(TAG, "📢 정상 도착 화면 실행 시도")
                }

                "/PROGRESS" -> {

                    vibrate()

                    // 30분마다 나와의 비교 결과 수신
                    val type = json.optString("type","")
                    val diff = json.optInt("difference",0)
                    Log.d(TAG,"PROGRESS : type=${type}, diff=${diff}")
                    val title = if (type == "FAST") "🐇 더 빠르게 이동 중" else "🐢 느리게 이동 중"
                    Log.d(TAG,"title=${title}")
                    val message = "이전 기록보다 %.1f 미터 차이".format(diff.toDouble())
                    Log.d(TAG,"message=${message}")
                    showNotification(title, message)
                    Log.d(TAG, "🔥 실시간 비교 인텐트 생성 시작")
                    val intent = Intent(this, MainActivity::class.java).apply {
                        addFlags(
                            Intent.FLAG_ACTIVITY_NEW_TASK or
                                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                                    Intent.FLAG_ACTIVITY_SINGLE_TOP)
                        putExtra("trigger", "progress")
                        putExtra("type", type)
                        putExtra("difference", diff)
                    }
                    Log.d(TAG, "✅ 인텐트 생성 완료 → startActivity 호출 직전")
                    startActivity(intent)
                    Log.d(TAG, "📢 실시간 비교 화면 실행 시도")
                }

                // 추후 페이스메이커, 도착 예상 시간 등 추가 예정
            }

        } catch (e: Exception) {
            Log.e(TAG, "❌ 메시지 처리 실패", e)
        }
    }

    // 진동 처리
    private fun vibrate() {
        val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createOneShot(1000, VibrationEffect.DEFAULT_AMPLITUDE))
        } else {
            vibrator.vibrate(1000)
        }
    }

    // 알림 표시
    private fun showNotification(title: String, message: String) {
        val channelId = "ollana_channel"
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "Ollana 알림", NotificationManager.IMPORTANCE_HIGH)
            manager.createNotificationChannel(channel)
        }

        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        manager.notify(System.currentTimeMillis().toInt(), notification)
    }
}
