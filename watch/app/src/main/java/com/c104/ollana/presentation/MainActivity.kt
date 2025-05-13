package com.c104.ollana.presentation

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.app.NotificationCompat
import com.c104.ollana.presentation.data.MessageSender
import com.c104.ollana.presentation.screen.HomeScreen
import com.c104.ollana.presentation.screen.TestScreen
import com.c104.ollana.presentation.sensor.SensorCollector
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.Wearable
import org.json.JSONObject

class MainActivity : ComponentActivity(), MessageClient.OnMessageReceivedListener {

    private val TAG = "MainActivity"

    // Wearable 메시지 통신 클라이언트
    private lateinit var messageClient: MessageClient

    // 심박수, 걸음 수 센서 수집 핸들러
    private lateinit var sensorCollector: SensorCollector

    // Compose 상태 변수들 (UI에 반영됨)
    private var messageState: MutableState<String>? = null
    private var isHomeState: MutableState<Boolean>? = null
    private var badgeUrlState: MutableState<String?>? = null
    private var showSaveDialogState: MutableState<Boolean>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 메시지 수신을 위한 Google Wearable 클라이언트 초기화
        messageClient = Wearable.getMessageClient(this)

        // 센서 수집 시작
        sensorCollector = SensorCollector(this)
        sensorCollector.start()

        // Jetpack Compose UI 설정
        setContent {
            val message = remember { mutableStateOf("센서 수집 중...") }
            val isHome = remember { mutableStateOf(false) }
            val badgeUrl = remember { mutableStateOf<String?>(null) }
            val showSaveDialog = remember { mutableStateOf(false) }

            // 상태를 외부에서도 업데이트할 수 있게 참조 저장
            messageState = message
            isHomeState = isHome
            badgeUrlState = badgeUrl
            showSaveDialogState = showSaveDialog

            // 전체 화면 기준으로 UI 구성
            Box(modifier = Modifier.fillMaxSize()) {

                // 홈 화면인지 테스트 화면인지 분기
                if (isHome.value) {
                    HomeScreen(
                        receivedMessage = message.value,
                        badgeImageUrl = badgeUrl.value,
                        onStopTracking = {
                            // 트래킹 종료 버튼 누르면 다이얼로그 표시
                            showSaveDialog.value = true
                        }
                    )
                } else {
                    TestScreen(
                        receivedMessage = message.value,
                        onFastTestClick = {
                            val fakeEvent = MessageEventFake("/PROGRESS", """{"type":"FAST,"difference":"300"}""")
                            handleIncomingMessage(fakeEvent)
                            isHome.value = true
                        },
                        onSlowTestClick = {
                            val fakeEvent = MessageEventFake("/PROGRESS", """{"type":"SLOW","difference":"150"}""")
                            handleIncomingMessage(fakeEvent)
                            isHome.value = true
                        },
                        onReachClick = {
                            val fakeEvent = MessageEventFake("/REACHED", "")
                            handleIncomingMessage(fakeEvent)
                            isHome.value = true
                        },
                        onBadgeClick = {
                            val fake = MessageEventFake("/BADGE", """{"type":"BADGE","url":""}""")
                            handleIncomingMessage(fake)
                            isHome.value = true
                        }
                    )
                }

                // 기록 저장 여부를 묻는 다이얼로그 표시 조건
                if (showSaveDialog.value) {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(Color.Black),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.Center,
                            modifier = Modifier
                                .background(Color.Black)
                                .padding(16.dp)
                        ) {
                            Text(
                                text = "기록을\n저장하시겠습니까?",
                                color = Color.White,
                                fontSize = 14.sp
                            )
                            Spacer(modifier = Modifier.height(16.dp))

                            // [네] 버튼 클릭 시 기록 저장 메시지 전송
                            Button(
                                onClick = {
                                    showSaveDialog.value = false
                                    message.value = "종료"
                                    MessageSender.send(
                                        path = "/STOP_TRACKING_CONFIRM",
                                        message = "",
                                        context = this@MainActivity
                                    )
                                },
                                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4CAF50)),
                                shape =CircleShape,
                                modifier = Modifier.size(60.dp)
                            ) {
                                Text("✔", fontSize = 24.sp, color = Color.White)
                            }

                            Spacer(modifier = Modifier.height(8.dp))

                            // [아니오] 버튼 클릭 시 저장 없이 종료 처리
                            Button(
                                onClick = {
                                    showSaveDialog.value = false
                                    message.value = "종료"
                                    MessageSender.send(
                                        path = "/STOP_TRACKING_CANCEL",
                                        message = "",
                                        context = this@MainActivity
                                    )
                                },
                                colors = ButtonDefaults.buttonColors(containerColor = Color.Red),
                                shape = CircleShape,
                                modifier = Modifier.size(60.dp)
                            ) {
                                Text("✖", fontSize = 24.sp, color = Color.White)
                            }
                        }
                    }
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        messageClient.addListener(this)
        Log.d(TAG,"리스너 등록")
    }

    override fun onPause() {
        super.onPause()
        messageClient.removeListener(this)
    }

    // 워치로부터 메시지 수신 시 호출됨
    override fun onMessageReceived(event: MessageEvent) {
        Log.d(TAG, "수신된 메시지: ${event.path}")
        Log.d("MainActivity", "📦 데이터: ${String(event.data)}")
        handleIncomingMessage(event)
        runOnUiThread { isHomeState?.value = true }

        // 트래킹 종료 요청이 오면 센서 수집 중지
        if (event.path == "/STOP_TRACKING_CONFIRM") {
            Log.d(TAG, "센서 수집 중지 요청 수신")
            sensorCollector.stop()
            runOnUiThread {
                messageState?.value = "종료"
            }
        }
    }

    // 진동과 시스템 알림을 동시에 표시하는 함수
    private fun vibrateAndNotify(title: String, content: String, id: Int = 1) {
        val vibrator = getSystemService(VIBRATOR_SERVICE) as Vibrator
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createOneShot(1000, 255))
        } else {
            vibrator.vibrate(1000)
        }

        val channelId = "ollana_alert_channel"
        val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "Ollana 알림", NotificationManager.IMPORTANCE_HIGH)
            notificationManager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(content)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(id, notification)
    }

    // 메시지 종류별 처리 로직
    private fun handleIncomingMessage(event: MessageEvent) {
        val path = event.path
        val dataStr = String(event.data)

        when (event.path) {
            "/REACHED" -> {
                runOnUiThread {
                    messageState?.value = "도착"
                    vibrateAndNotify("정상 도착", "트래킹 종료를 눌러 기록을 저장하세요")
                }
            }

            "/PROGRESS" -> {
                try {
                    val obj = JSONObject(dataStr)
                    val type = obj.getString("type")
                    val diffMeters = obj.getString("difference").toDoubleOrNull() ?: 0.0
                    val diffKm = diffMeters / 1000
                    val formatted = String.format("%.1fkm", diffKm)

                    val result = when (type) {
                        "FAST" -> "🐇 + $formatted"
                        "SLOW" -> "🐢 - $formatted"
                        else -> "🚶 이동 비교 결과: $formatted"
                    }
                    runOnUiThread {
                        messageState?.value = result
                        val title = if (type == "FAST") "더 빨라요" else "천천히 가고 있어요"
                        vibrateAndNotify(title, "이전기록보다 $formatted 차이납니다.")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "JSON 파싱 오류", e)
                }
            }

            "/BADGE" -> {
                try {
                    val json = JSONObject(dataStr)
                    val badgeUrl = json.getString("url")
                    runOnUiThread {
                        messageState?.value = "종료"
                        badgeUrlState?.value = badgeUrl
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "BADGE JSON 파싱 오류", e)
                }
            }

            else -> runOnUiThread {
                messageState?.value = "기타 메시지: $path"
            }
        }
    }

    // 테스트용 가짜 메시지 클래스 (디버깅용)
    class MessageEventFake(
        private val fakePath: String,
        private val dataStr: String
    ) : MessageEvent {
        override fun getSourceNodeId(): String = "testNode"
        override fun getRequestId(): Int = 0
        override fun getPath(): String = fakePath
        override fun getData(): ByteArray = dataStr.toByteArray()
    }
}
