package com.ssafy.ollana.common.util;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

import java.util.List;

public class PaginateUtil {
    // 가져온 목록을 페이지네이션하기
    public static <T> Page<T> paginate(List<T> allItems, int page, int size) {
        int total = allItems.size();
        int start = Math.min(page * size, total);
        int end = Math.min((page + 1) * size, total);

        return new PageImpl<>(
                allItems.subList(start, end),
                PageRequest.of(page, size),
                total
        );
    }
}
