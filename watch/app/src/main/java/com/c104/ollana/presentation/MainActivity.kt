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
import com.google.gson.Gson
import org.json.JSONObject
import java.io.ByteArrayInputStream
import java.io.InvalidClassException
import java.io.ObjectInputStream
import java.io.StreamCorruptedException
import java.nio.charset.StandardCharsets
import java.util.Arrays

class MainActivity : ComponentActivity(), MessageClient.OnMessageReceivedListener {

    private val TAG = "MainActivity"

    // Wear OS 메시지 전송/수신을 위한 클라이언트
    private lateinit var messageClient: MessageClient

    // 심박수/걸음수 센서를 수집하는 클래스
    private lateinit var sensorCollector: SensorCollector

    // Compose 상태 변수들 (UI 상태 저장용)
    private var messageState: MutableState<String>? = null
    private var isHomeState: MutableState<Boolean>? = null
    private var badgeUrlState: MutableState<String?>? = null
    private var showSaveDialogState: MutableState<Boolean>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 메시지 통신 클라이언트 초기화
        messageClient = Wearable.getMessageClient(this)

        // 센서 수집 시작
        sensorCollector = SensorCollector(this)
        sensorCollector.start()

        // UI 렌더링
        setContent {
            val message = remember { mutableStateOf("센서 수집 중...") }
            val isHome = remember { mutableStateOf(true) }
            val badgeUrl = remember { mutableStateOf<String?>(null) }
            val showSaveDialog = remember { mutableStateOf(false) }

            // 상태 변수를 외부에서도 접근 가능하게 저장
            messageState = message
            isHomeState = isHome
            badgeUrlState = badgeUrl
            showSaveDialogState = showSaveDialog

            Box(modifier = Modifier.fillMaxSize()) {
                // 실제 트래킹 홈 화면 or 테스트 화면 선택
                if (isHome.value) {
                    HomeScreen(
                        receivedMessage = message.value,
                        badgeImageUrl = badgeUrl.value,
                        onStopTracking = {
                            showSaveDialog.value = true // 종료 시 확인 다이얼로그 표시
                        }
                    )
                } else {
                    TestScreen(
                        receivedMessage = message.value,
                        onFastTestClick = {
                            val fakeEvent = MessageEventFake(
                                "/watch_connectivity",
                                """{"path":"/PROGRESS","data":"{"type":"FAST","difference":300}"}""".trimIndent()
                            )
                            handleIncomingMessage(String(fakeEvent.data))
                            isHome.value = true
                        },
                        onSlowTestClick = {
                            val fakeEvent = MessageEventFake(
                                "/watch_connectivity",
                                """{"path":"/PROGRESS","data":"{"type":"SLOW","difference":300}"}""".trimIndent()
                            )
                            handleIncomingMessage(String(fakeEvent.data))
                            isHome.value = true
                        },
                        onReachClick = {
                            val fakeEvent = MessageEventFake(
                                "/watch_connectivity",
                                """{"path":"/REACHED","data":""}"""
                            )
                            handleIncomingMessage(String(fakeEvent.data))
                            isHome.value = true
                        },
                        onBadgeClick = {
                            val fakeEvent = MessageEventFake(
                                "/watch_connectivity",
                                """{"path":"/BADGE","data":"{"url":"https://example.com"}"}""".trimIndent()
                            )
                            handleIncomingMessage(String(fakeEvent.data))
                            isHome.value = true
                        }
                    )
                }
                FloatingActionButton(
                    onClick={
                        sensorCollector.sendTestDataManually()
                    },
                    containerColor = Color(0xFF2196F3),
                    modifier = Modifier
                        .align(Alignment.BottomEnd)
                        .padding(16.dp)
                ){
                    Text("TEST",color=Color.White)
                }


                // 기록 저장 여부 다이얼로그
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
                            modifier = Modifier.padding(12.dp)
                        ) {
                            Text(
                                text = "기록을 저장하시겠습니까?",
                                color = Color.White,
                                fontSize = 15.sp,
                                modifier = Modifier.padding(bottom = 12.dp)
                            )

                            // 버튼 나란히 정렬
                            Row(
                                horizontalArrangement = Arrangement.spacedBy(24.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                // ✔ 확인 버튼
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
                                    shape = CircleShape,
                                    modifier = Modifier.size(60.dp)
                                ) {
                                    Box(
                                        modifier = Modifier.fillMaxSize(),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Text("✔", fontSize = 20.sp, color = Color.White)
                                    }
                                }

                                // ✖ 취소 버튼
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
                                    Box(
                                        modifier = Modifier.fillMaxSize(),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Text("✖", fontSize = 20.sp, color = Color.White)
                                    }
                                }
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
        Log.d(TAG, "리스너 등록")
    }

    override fun onPause() {
        super.onPause()
        messageClient.removeListener(this)
    }

    // 워치로부터 메시지 수신
    override fun onMessageReceived(event: MessageEvent) {
        val gson = Gson()
        val path = event.path                     // event.getPath()
        val senderNode = event.sourceNodeId       // event.getSourceNodeId()
        try {
            val bais = ByteArrayInputStream(event.data)
            val ois = ObjectInputStream(bais)

            val map = ois.readObject() as HashMap<*, *>
            ois.close()

            val jsonString = gson.toJson(map)
            Log.d(TAG, "path=$path, from=$senderNode, data=$jsonString")
            handleIncomingMessage(jsonString)
        } catch (e: InvalidClassException) {
            Log.e(TAG, "직렬화 버전 불일치", e)
        } catch (e: StreamCorruptedException) {
            Log.e(TAG, "스트림 손상", e)
        } catch (e: Exception) {
            Log.e(TAG, "역직렬화 실패", e)
        }


        runOnUiThread { isHomeState?.value = true }

        if (event.path == "/STOP_TRACKING_CONFIRM") {
            Log.d(TAG, "센서 수집 중지 요청 수신")
            sensorCollector.stop()
            runOnUiThread {
                messageState?.value = "종료"
            }
        }
    }

    // 시스템 진동 및 알림 호출
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

    // 메시지 타입에 따라 처리
    private fun handleIncomingMessage(jsonStr: String) {
        try{
            val obj=JSONObject(jsonStr)
            val path = obj.optString("path","")
            val payload =obj.optString("data","")
            when (path) {
                "/REACHED" -> {
                    runOnUiThread {
                        messageState?.value = "도착"
                        vibrateAndNotify("정상 도착", "트래킹 종료를 눌러 기록을 저장하세요")
                    }
                }

                "/PROGRESS" -> {

                        val data = JSONObject(payload)
                        val type = data.getString("type")
                        val diffMeters = data.getDouble("difference")
                        val formatted = String.format("%.1fkm", diffMeters / 1000)

                        val result = when (type) {
                            "FAST" -> "🐇 + $formatted"
                            "SLOW" -> "🐢 - $formatted"
                            else -> "🚶 이동 비교 결과: $formatted"
                        }
                        runOnUiThread {
                            messageState?.value = result
                            val title = if (type == "FAST") "더 빨라요" else "천천히 가고 있어요"
                            vibrateAndNotify(title, "이전 기록보다 $formatted 차이납니다.")
                        }

                }

                "/BADGE" -> {
                        val badgeUrl = JSONObject(payload).getString("url")
                        runOnUiThread {
                            messageState?.value = "종료"
                            badgeUrlState?.value = badgeUrl
                        }


                }

                else -> runOnUiThread {
                    messageState?.value = "알수없는 경로: $path"
                }
            }
        }catch(e: Exception){
            Log.e(TAG,"메시지 파싱 오류",e)
        }

    }

    // 테스트용 가짜 메시지 클래스
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
