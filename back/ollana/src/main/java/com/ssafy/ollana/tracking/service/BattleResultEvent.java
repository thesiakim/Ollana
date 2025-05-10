package com.ssafy.ollana.tracking.service;

public record BattleResultEvent(
        Integer userId,
        Integer opponentId,
        Integer mountainId,
        Integer pathId,
        Integer recordId,
        Integer finalTime
) {}
