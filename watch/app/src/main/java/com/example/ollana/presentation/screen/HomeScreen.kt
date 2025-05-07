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
import androidx.wear.compose.material.Scaffold
import androidx.wear.compose.material.Text

@Composable
fun HomeScreen(receivedMessage: String) {

    val isFast = receivedMessage.contains("🐇")
    val isSlow = receivedMessage.contains("🐢")
    val distanceInfo = receivedMessage.substringAfter(" ").trim() // "+0.3km" 또는 "-0.1km"

    Scaffold {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black)
                .padding(8.dp), // 글자 및 이미지 위치를 위로 올림
            contentAlignment = Alignment.TopCenter
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(12.dp)  // 👉 간격 조절
            ) {

                // 🐇 or 🐢 이미지
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
                }

                // 거리 차이 텍스트만 보여주기 (ex. "+0.3km", "-0.1km")
                if (distanceInfo.isNotBlank()) {
                    Text(
                        text = distanceInfo,
                        fontSize = 20.sp,
                        textAlign = TextAlign.Center
                    )
                } else {
                    // 예외적으로 기타 메시지일 때 출력
                    Text(
                        text = receivedMessage,
                        fontSize = 18.sp,
                        textAlign = TextAlign.Center,
                        color = Color.White
                    )
                }
            }
        }
    }
}
