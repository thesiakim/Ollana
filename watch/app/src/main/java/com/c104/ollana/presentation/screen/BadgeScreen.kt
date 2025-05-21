package com.c104.ollana.presentation.screen

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.wear.compose.material.MaterialTheme.typography
import androidx.wear.compose.material.Text
import coil.compose.AsyncImage

@Composable
fun BadgeScreen(badgeUrl: String) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = "🏅 수고하셨습니다!",
                style = typography.title1,
                color = Color.White,
                modifier = Modifier.padding(8.dp)
            )

            AsyncImage(
                model = badgeUrl,
                contentDescription = "Badge Image",
                modifier = Modifier
                    .size(120.dp)
                    .padding(top = 16.dp)
            )
        }
    }
}