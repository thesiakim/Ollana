// theme.dart: 앱 전체에서 사용하는 통일된 디자인 테마를 정의하는 파일
// - 앱의 기본 색상(primaryColor, colorScheme) 설정
// - AppBar 스타일(배경색, 글자색, 그림자) 설정
// - 버튼 스타일(ElevatedButton, TextButton) 설정
// - 앱 전체적인 디자인 일관성을 위한 테마 정의

import 'package:flutter/material.dart';

final appTheme = ThemeData(
  primaryColor: Colors.green,
  colorScheme: ColorScheme.fromSwatch().copyWith(
    primary: Colors.green,
    secondary: Colors.greenAccent,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.black,
    ),
  ),
);
