/* While this template provides a good starting point for using Wear Compose, you can always
 * take a look at https://github.com/android/wear-os-samples/tree/main/ComposeStarter to find the
 * most up to date changes to the libraries and their usages.
 */

package com.example.ollana.presentation.ui

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.wear.compose.material.*
import androidx.compose.runtime.Composable
import com.example.ollana.presentation.viewmodel.TrackingViewModel
import com.example.ollana.presentation.theme.OllanaTheme

class MainActivity : ComponentActivity() {

    private val viewModel : TrackingViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)

        setTheme(android.R.style.Theme_DeviceDefault)

        setContent{
            WearApp(viewModel =viewModel)
        }
    }
}

@Composable
fun WearApp(viewModel : TrackingViewModel) {

    OllanaTheme {
        ScalingLazyColumn {
            //상단 시간 표시
            item{
                TimeText()
            }
            //앱으로 메시지 전송 버튼
            item{
                Chip(
                    label={
                        Text("앱으로 전송")
                    },
                    onClick={
                        viewModel.sendTestMessage()
                    },
                    colors=ChipDefaults.primaryChipColors()
                )
            }
        }
    }
}

