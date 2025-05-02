package com.example.ollana.presentation.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import com.example.ollana.presentation.util.MessageSender
import org.json.JSONObject


//전송 로직을 ViewModel에 위임
class TrackingViewModel(application: Application) : AndroidViewModel(application){

    //path : /test
    //앱으로 테스트 메시지 전송하는 함수
    fun sendTestMessage(){
        val json  = buildTestMessage()
        MessageSender.send(path="/test", message = json, context = getApplication())
    }
    private fun buildTestMessage(): String{
        val data= mapOf(
            "type" to "TEST",
            "message" to "hello from watch"
        )
        return JSONObject(data).toString()
    }

}