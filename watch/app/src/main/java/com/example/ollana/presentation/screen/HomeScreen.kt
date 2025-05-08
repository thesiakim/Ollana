package com.example.ollana.presentation.screen

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ollana.R
import androidx.wear.compose.material.*

@Composable
fun HomeScreen(
    receivedMessage: String,
    onStopTracking: () -> Unit
) {
    val isFast = receivedMessage.contains("🐇")
    val isSlow = receivedMessage.contains("🐢")
    val isArrived = receivedMessage == "도착"
    val isStopped = receivedMessage == "종료"

    // 거리 정보만 추출
    val distanceInfo = receivedMessage.substringAfter(" ").trim()

    Scaffold {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black),
            contentAlignment = Alignment.TopCenter
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(8.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                Spacer(modifier = Modifier.height(20.dp))

                // 이미지 표시
                when {
                    isFast -> {
                        Image(
                            painter = painterResource(id = R.drawable.rabbit),
                            contentDescription = "빠름",
                            modifier = Modifier.size(100.dp),
                            contentScale = ContentScale.Fit
                        )
                    }

                    isSlow -> {
                        Image(
                            painter = painterResource(id = R.drawable.turtle),
                            contentDescription = "느림",
                            modifier = Modifier.size(100.dp),
                            contentScale = ContentScale.Fit
                        )
                    }

                    isStopped -> {
                        Image(
                            painter = painterResource(id = R.drawable.ic_check), // ✅ 아이콘
                            contentDescription = "종료",
                            modifier = Modifier.size(80.dp),
                            contentScale = ContentScale.Fit
                        )
                    }
                }

                // 거리 차이 or 메시지
                when {
                    isFast || isSlow -> {
                        Text(
                            text = distanceInfo,
                            fontSize = 20.sp,
                            color = Color.White,
                            textAlign = TextAlign.Center
                        )
                    }

                    isArrived -> {
                        Text(
                            text = "정상 도착!\n트래킹을 종료할까요?",
                            fontSize = 16.sp,
                            color = Color.White,
                            textAlign = TextAlign.Center
                        )

                        Button(
                            onClick = onStopTracking,
                            modifier = Modifier
                                .padding(horizontal = 16.dp)
                                .fillMaxWidth(0.8f),
                            colors = ButtonDefaults.buttonColors(
                                backgroundColor = Color.Red
                            )
                        ) {
                            Text("트래킹 종료", fontSize = 14.sp, color = Color.White)
                        }
                    }

                    isStopped -> {
                        Text(
                            text = "트래킹이 종료되었습니다 👏",
                            fontSize = 16.sp,
                            color = Color.White,
                            textAlign = TextAlign.Center
                        )
                    }

                    else -> {
                        Text(
                            text = receivedMessage,
                            fontSize = 16.sp,
                            color = Color.White,
                            textAlign = TextAlign.Center
                        )
                    }
                }
            }
        }
    }
}
