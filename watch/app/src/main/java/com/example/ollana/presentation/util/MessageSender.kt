package com.example.ollana.presentation.util

import android.content.Context
import android.util.Log
import com.google.android.gms.tasks.Tasks
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

//워치에서 폰 메시지 전송 함수
object MessageSender {
    private const val TAG="MessageSender"

    //path : 메시지를 전달할 경로
    //message : 보낼 메시지 내용
    fun send(path : String, message:String, context : Context){

        CoroutineScope(Dispatchers.IO).launch{
            try{
                //현재 연결된 폰디바이스를 가져옴
                val nodes = Tasks.await(Wearable.getNodeClient(context).connectedNodes)

                if(nodes.isEmpty()){
                    Log.w(TAG,"연결된 디바이스가 없습니다.")
                    return@launch
                }
                //각 노드에 메시지를 전송
                for(node in nodes){
                    val task = Wearable.getMessageClient(context)
                        .sendMessage(node.id, path, message.toByteArray(Charsets.UTF_8))
                    //전송 성공/ 실패 결과
                    task.addOnSuccessListener {
                        Log.d(TAG,"sent to${node.displayName}:${message}")
                    }.addOnFailureListener{
                        e->Log.e(TAG,"failed to send message to ${node.displayName}",e)
                    }
                }
            }catch (e : Exception){
                Log.e(TAG,"send 예외 발생",e)
            }
        }
    }
}