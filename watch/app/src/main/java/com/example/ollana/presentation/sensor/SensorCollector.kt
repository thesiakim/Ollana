package com.example.ollana.presentation.sensor

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.util.Log
import com.example.ollana.presentation.data.MessageSender
import org.json.JSONObject

class SensorCollector(private val context : Context) : SensorEventListener{

    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager

    //사용자 센서 정의(심박수, 걸음수)
    private val heartRateSensor : Sensor?=sensorManager.getDefaultSensor(Sensor.TYPE_HEART_RATE)
    private val stepSensor : Sensor?=sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)

    //최근 수집된 센서 값 저장
    private var lastHeartRate : Float?=null
    private var lastStepCount : Float?=null

    //마지막 전송 시간(3초마다 한번만 전송하기위한 체크용)
    private var lastSensorTime=0L

    val TAG="SensorCollector"

    //센서 수집
    fun start(){
        heartRateSensor?.let {
            sensorManager.registerListener(this,it,SensorManager.SENSOR_DELAY_NORMAL)
        }
        stepSensor?.let{
            sensorManager.registerListener(this,it,SensorManager.SENSOR_DELAY_NORMAL)
        }
        Log.d(TAG,"센서수집 시작")
    }

    //센서 수집 중단
    fun stop(){
        sensorManager.unregisterListener(this)
        Log.d(TAG,"센서 수집 중단")
    }

    //센서 데이터가 들어왔을대 호출
    override fun onSensorChanged(event: SensorEvent?) {

        if(event ==null) return

        when(event.sensor.type){

            Sensor.TYPE_HEART_RATE->{
                lastHeartRate=event.values[0]
                Log.d(TAG, "심박수 수신됨: ${lastHeartRate}")
            }
            Sensor.TYPE_STEP_COUNTER->{
                lastStepCount=event.values[0]
                Log.d(TAG, "👣 걸음 수 수신됨: ${lastStepCount}")
            }
        }
        
        //5초마다 전송
        val currentTime = System.currentTimeMillis()
        val shouldSend =currentTime-lastSensorTime >=5000
        
        if(shouldSend && lastHeartRate !=null && lastStepCount!=null){
            sendSensorData()
            lastSensorTime=currentTime
        }
    }
    //센서 데이터를 앱에 전송
    private fun sendSensorData() {
        
        val json = JSONObject().apply { 
            put("heartRate",lastHeartRate)
            put("steps",lastStepCount)
        }
        //전송
        MessageSender.send(
            path="/SENSOR_DATA",
            message = json.toString(),
            context=context
        )
        Log.d("SensorCollector","센서 데이터 전송:${json}")
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
       //정확도 변경
    }

}