package com.c104.ollana.presentation.screen

import androidx.compose.foundation.background
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.wear.compose.material.*
import androidx.compose.foundation.layout.*
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun ETADistanceViewScreen(eta : String, distance : Int ){

    val formatted = String.format("%.1fkm", distance.toDouble() / 1000)

    Box(
        modifier =Modifier
            .fillMaxSize()
            .background(Color.Black),
        contentAlignment = Alignment.Center
    ){
        Column (horizontalAlignment = Alignment.CenterHorizontally){
            Text("⏱ 예상 도착 시간", fontSize = 16.sp, color = Color.White)
            Text(eta, fontSize = 24.sp, color = Color.Cyan)

            Spacer(modifier = Modifier.height(12.dp))

            Text("🥾 남은 거리", fontSize = 16.sp, color = Color.White)
            Text(formatted, fontSize = 24.sp, color = Color.Yellow)
        }
    }
}