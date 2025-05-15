package com.c104.ollana.presentation.data

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import androidx.core.app.NotificationCompat
import com.c104.ollana.presentation.MainActivity
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService
import com.google.gson.Gson
import org.json.JSONObject
import java.io.ByteArrayInputStream
import java.io.ObjectInputStream

//앱이 실행되고있지않거나 화면이 꺼져 있을때도 메시지를 수신하고 알림표시
class WatchMessageListenerService : WearableListenerService(){

    private val TAG="WatchMessageService"

    override fun onMessageReceived(event: MessageEvent) {
        super.onMessageReceived(event)

        val gson= Gson()
        val path =event.path
        val sender=event.sourceNodeId

        try{
            //객체 역직렬화
            val bais=ByteArrayInputStream(event.data)
            val ois=ObjectInputStream(bais)
            val map=ois.readObject() as HashMap<*,*>
            ois.close()

            val jsonString = gson.toJson(map)
            Log.d(TAG,"수신된 메시지 : path=${path},from=${sender}, data=${jsonString}")

            handleIncomingMessage(jsonString)
        }catch (e:Exception){
            Log.e(TAG,"메시지 파싱 실패",e)
        }
    }
    //받은 메시지를 타입별로 분기 처리
    //UI 호출 없이도 알림 + 진동만 처리 가능
    private fun handleIncomingMessage(jsonStr:String){
        Log.d(TAG,"handleMessage:${jsonStr}")
        try{
            val obj=JSONObject(jsonStr)
            val path=obj.optString("path","")
            val payload=obj.optString("data","")

            Log.d(TAG,"handleMessage : path=${path} payload=${payload}")

            when(path){
                "/REACHED" -> {
                    vibrate()
                    showNotification("정상 도착!", "트래킹을 종료하시겠습니까?")
                    launchMainActivity()
                    Log.d(TAG, "🔔 알림 처리: /REACHED → 정상 도착 알림 표시")
                }
                "/PROGRESS" -> {
                    val data = JSONObject(payload)
                    val type = data.getString("type")
                    val diff = data.getDouble("difference") / 1000
                    val formatted = String.format("%.1fkm", diff)

                    val emoji = if (type == "FAST") "🐇" else "🐢"
                    val title = if (type == "FAST") "더 빨라요" else "천천히 가고 있어요"

                    vibrate()
                    showNotification(title, "$emoji $formatted")
                    launchMainActivity()
                    Log.d(TAG, "🔔 알림 처리: /PROGRESS → $type | $formatted")
                }
                "/BADGE" -> {
                    vibrate()
                    showNotification("뱃지 획득!", "새로운 뱃지를 받았어요.")
                    launchMainActivity()
                    Log.d(TAG, "🔔 알림 처리: /BADGE → 뱃지 알림 표시")
                }
                else->{
                    Log.w(TAG,"알수없는 경로:${path}")
                }

            }
        }catch (e:Exception){
            Log.e(TAG,"handleIncomingMessage 파싱오류",e)
        }
    }
    //워치에 진동 발생
    private fun vibrate(){
        val vibrator=getSystemService(VIBRATOR_SERVICE) as Vibrator
        if(Build.VERSION.SDK_INT>=Build.VERSION_CODES.O){
            vibrator.vibrate(VibrationEffect.createOneShot(800,VibrationEffect.DEFAULT_AMPLITUDE))
        }else{
            vibrator.vibrate(800)
        }
    }
    //시스템 알림
    private fun showNotification(title :String,content:String){
        val channelId="ollana_channel"
        val manager=getSystemService(NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "Ollana 알림", NotificationManager.IMPORTANCE_HIGH)
            manager.createNotificationChannel(channel)
        }
        val intent= Intent(this,MainActivity::class.java).apply{
            flags=Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent=PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(content)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        manager.notify(System.currentTimeMillis().toInt(), notification)
    }
    private fun launchMainActivity(){
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        startActivity(intent)
    }

}
