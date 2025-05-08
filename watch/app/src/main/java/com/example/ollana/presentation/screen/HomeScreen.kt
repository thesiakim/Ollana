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
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ollana.R
import androidx.wear.compose.material.*
import coil.compose.rememberAsyncImagePainter

@Composable
fun HomeScreen(
    receivedMessage: String,
    badgeImageUrl: String?, // 서버에서 받은 뱃지 이미지 URL
    onStopTracking: () -> Unit //트래킹 종료 시 앱에 전송
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
                .background(Color.Black)
                .padding(horizontal = 12.dp, vertical = 16.dp),
            contentAlignment = Alignment.TopCenter
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Top
            ) {
                Spacer(modifier = Modifier.height(16.dp))

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
                    // 뱃지 이미지가 존재하면 종료 시 표시
                    isStopped && badgeImageUrl != null -> {
                        Image(
                            painter = rememberAsyncImagePainter(badgeImageUrl),
                            contentDescription = "뱃지",
                            modifier = Modifier.size(100.dp),
                            contentScale = ContentScale.Fit
                        )
                    }

                    isStopped -> {
                        Image(
                            painter = painterResource(id = R.drawable.ic_check), // ✅ 아이콘
                            contentDescription = "종료",
                            modifier = Modifier.size(100.dp),
                            contentScale = ContentScale.Fit
                        )
                    }
                }
                Spacer(modifier = Modifier.height(4.dp))

                // 메시지 출력 영역
                Text(
                    text=when {
                        isFast || isSlow -> distanceInfo
                        isArrived->"정상 도착!\n트래킹을 종료할까요?"
                        isStopped && badgeImageUrl != null -> "트래킹이 종료되었습니다."
                        isStopped->"트래킹이 종료되었습니다."
                        else->receivedMessage
                    },
                    fontSize = 14.sp,
                    color=Color.White,
                    textAlign = TextAlign.Center,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier
                        .padding(horizontal = 6.dp)
                        .fillMaxWidth()
                )
                // 도착 시만 종료 버튼 출력
                    if(isArrived) {
                        Spacer(modifier = Modifier.height(8.dp))

                        Button(
                            onClick = onStopTracking,
                            modifier = Modifier
                                .fillMaxWidth(0.7f),
                            colors = ButtonDefaults.buttonColors(
                                backgroundColor = Color.Red
                            )
                        ) {
                            Text("트래킹 종료", fontSize = 14.sp, color = Color.White)
                        }
                    }
                }
            }
        }
    }

