def cal_score(weather_data, dust_data):
    temp = weather_data["main"]["feels_like"]
    wind = weather_data["wind"]["speed"]
    humidity = weather_data["main"]["humidity"]
    cloud = weather_data["clouds"]["all"]
    pm10 = dust_data["list"][0]["components"]["pm10"]
    pm25 = dust_data["list"][0]["components"]["pm2_5"]
    
    # 체감온도 계산
    if 12 < temp < 22:
        temp_score = 100
    else:
        temp_score = max(0, 100 - abs(temp - 17) * 5)
        
    # 풍속 점수 계산
    if wind <= 3:
        wind_score = 100
    elif wind >= 6:
        wind_score = 50
    else:
        wind_score = 100 - (wind - 3) * 15
    
    # 습도 점수
    if 40 <= humidity <= 60:
        hum_score = 100
    else:
        hum_score = max(0, 100 - abs(humidity - 50) * 2)
        
    # 구름 점수
    if 20 <= cloud <= 50:
        cloud_score = 100
    else:
        cloud_score = max(40, 100 - abs(cloud - 35) * 3)

    # 미세먼지 PM10 점수
    if pm10 <= 30:
        pm10_score = 100
    elif pm10 <= 80:
        pm10_score = 60
    else:
        pm10_score = 30

    # 초미세먼지 PM2.5 점수
    if pm25 <= 15:
        pm25_score = 100
    elif pm25 <= 35:
        pm25_score = 70
    else:
        pm25_score = 40
    
    # 가중 평균
    total_score = (
        temp_score * 0.25 +
        wind_score * 0.15 +
        hum_score * 0.15 +
        cloud_score * 0.10 +
        pm10_score * 0.2 +
        pm25_score * 0.15
    )
    
    return round(total_score, 1)
