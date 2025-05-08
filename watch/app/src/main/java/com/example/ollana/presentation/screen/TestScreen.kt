package com.example.ollana.presentation.screen

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material.Button
import androidx.wear.compose.material.Text

@Composable
fun TestScreen(
    receivedMessage: String,
    onFastTestClick: () -> Unit,
    onSlowTestClick: () -> Unit,
    onReachClick: () -> Unit

) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // 현재 메시지 표시
        Text(text = receivedMessage, fontSize = 16.sp)
        Spacer(modifier = Modifier.height(20.dp))

        //빠름 테스트 버튼
        Button(onClick = onFastTestClick) {
            Text("🐇 빠름 테스트", fontSize = 14.sp)
        }
        Spacer(modifier = Modifier.height(10.dp))

        //느림 테스트 버튼
        Button(onClick = onSlowTestClick) {
            Text("🐢 느림 테스트", fontSize = 14.sp)
        }
        Spacer(modifier = Modifier.height(10.dp))

        //정상 도착 테스트 버튼
        Button(onClick = onReachClick) {
            Text("정상 도착 테스트", fontSize = 14.sp)
        }

    }
}
