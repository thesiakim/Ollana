package com.c104.ollana.presentation.screen

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material.*

@Composable
fun PacemakerScreen(level : String, message:String){

    Box(
        modifier=Modifier
            .fillMaxSize()
            .background(Color.Black),
        contentAlignment = Alignment.Center
    ){
        Column(horizontalAlignment = Alignment.CenterHorizontally){
            Text(
                text = "🔥 페이스메이커 안내",
                fontSize = 18.sp,
                color = Color.White
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text="난이도 : $level",
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
                color = Color.Cyan
            )
            Spacer(modifier = Modifier.height(12.dp))
            Text(
                text=message,
                fontSize = 16.sp,
                color=Color.Yellow
            )
        }
    }
}