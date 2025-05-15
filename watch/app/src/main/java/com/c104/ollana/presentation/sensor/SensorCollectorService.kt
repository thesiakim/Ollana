package com.c104.ollana.presentation.sensor

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.c104.ollana.R

class SensorCollectorService : Service(){

    private val TAG="SensorCollectorService"
    private lateinit var sensorCollector: SensorCollector

    override fun onCreate() {
        super.onCreate()

        //센서 수집 클래스 초기화 및 시작
        sensorCollector = SensorCollector(this)
        sensorCollector.start()

        //서비스 알림 표시
        startForeground(1001,createNotification())
        Log.d(TAG, "✅ 센서 수집 서비스 시작됨 (Foreground)")
    }

    override fun onDestroy() {
        super.onDestroy()

        //서비스가 종료될때 센서 수집도 중단
        sensorCollector.stop()
        Log.d(TAG,"센서 수집 서비스 종료")
    }

    override fun onBind(intent : Intent?) : IBinder?=null

    //ForegroundService 알림 생성
    private fun createNotification() : Notification{
        val channelId="sensor_channel_id"
        val channelName="센서 수집 서비스"

        if(Build.VERSION.SDK_INT>=Build.VERSION_CODES.O){
            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_LOW
            )
            val manager=getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("트래킹 진행 중")
            .setContentText("심박수 데이터를 전송하고 있어요")
            .setSmallIcon(R.drawable.logo) // 너희 앱의 아이콘으로 변경해도 됨
            .setOngoing(true)
            .build()
    }

}