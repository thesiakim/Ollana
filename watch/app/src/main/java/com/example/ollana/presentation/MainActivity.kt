package com.example.ollana.presentation

import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.*
import com.example.ollana.presentation.data.MessageSender
import com.example.ollana.presentation.screen.HomeScreen
import com.example.ollana.presentation.screen.TestScreen
import com.google.android.gms.wearable.MessageClient
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.Wearable
import org.json.JSONObject

class MainActivity : ComponentActivity(), MessageClient.OnMessageReceivedListener {

    private val TAG = "MainActivity"

    // // 메시지 수신을 위한 Google API Client
    private lateinit var messageClient: MessageClient

    // 상태 저장 변수 (UI 업데이트 용도)
    private var messageState: MutableState<String>? = null // UI에 표시할 메시지
    private var isHomeState: MutableState<Boolean>? = null // HomeScreen 전환 여부
    private var badgeUrlState: MutableState<String?>? = null         // 뱃지 이미지 URL 상태

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Wearable 메시지 클라이언트 초기화
        messageClient = Wearable.getMessageClient(this)

        // UI 설정
        setContent {
            val message = remember { mutableStateOf("테스트 모드 시작") }
            val isHome = remember { mutableStateOf(false) }  // 화면 전환 상태
            val badgeUrl = remember { mutableStateOf<String?>(null) }

            // 외부에서도 접근 가능하게 설정
            messageState = message
            isHomeState = isHome
            badgeUrlState = badgeUrl

            if (isHome.value) {
                // 실제 메시지 수신 후 화면
                HomeScreen(
                    receivedMessage = message.value,
                    badgeImageUrl = badgeUrl.value,
                    onStopTracking={
                        //앱에 트래킹 종료 메시지 전송
                        MessageSender.send(
                         "/STOP_TRACKING_CONFIRM",
                           "",
                            this
                        )
                        //워치 화면도 종료 UI로 전환
                        message.value="종료"
                    })
            } else {
                // 테스트 모드 화면
                TestScreen(
                    receivedMessage = message.value,
                    onFastTestClick = {
                        val fakeEvent = MessageEventFake("/PROGRESS", """{"type":"FAST","difference":"300"}""")
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
        }
    }

    override fun onResume() {
        super.onResume()
        messageClient.addListener(this)
    }

    override fun onPause() {
        super.onPause()
        messageClient.removeListener(this)
    }

    // 실제 메시지 수신
    override fun onMessageReceived(event: MessageEvent) {
        Log.d(TAG, "수신된 메시지: ${event.path}")

        handleIncomingMessage(event)

        // 메시지를 받으면 자동으로 홈 화면으로 전환
        runOnUiThread {
            isHomeState?.value = true
        }
    }

    // 메시지를 받아 UI용 텍스트로 변환
    private fun handleIncomingMessage(event: MessageEvent) {

        val path = event.path
        val dataStr = String(event.data)

        when (event.path) {
            "/REACHED" -> {
                runOnUiThread {
                    messageState?.value = "도착"
                }
            }

            "/PROGRESS" -> {
                try {
                    val obj = JSONObject(String(event.data))
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


    // 테스트용 메시지 시뮬레이션 클래스
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
