package com.ssafy.ollana.footprint.service;

import com.ssafy.ollana.common.util.PageResponse;
import com.ssafy.ollana.common.util.PaginateUtil;
import com.ssafy.ollana.footprint.persistent.entity.Footprint;
import com.ssafy.ollana.footprint.persistent.repository.FootprintRepository;
import com.ssafy.ollana.footprint.service.exception.NotFoundException;
import com.ssafy.ollana.footprint.web.dto.response.FootprintListResponseDto;
import com.ssafy.ollana.footprint.web.dto.response.FootprintResponseDto;

import com.ssafy.ollana.user.entity.User;
import com.ssafy.ollana.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class FootprintService {

    private final FootprintRepository footprintRepository;
    private final UserRepository userRepository;

    /*
     * 발자취 목록 조회
     */
    @Transactional(readOnly = true)
    public FootprintListResponseDto getFootprintList(Integer userId, Pageable pageable) {
        Page<Footprint> page = footprintRepository.findByUserId(userId, pageable);
        double totalDistance = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."))
                .getTotalDistance();

        List<FootprintResponseDto> dtoList = page.stream()
                .map(footprint -> FootprintResponseDto.builder()
                        .footprintId(footprint.getId())
                        .mountainName(footprint.getMountain().getMountainName())
                        .imgUrl(footprint.getMountain().getMountainBadge())
                        .build())
                .toList();

        return FootprintListResponseDto.builder()
                .currentPage(page.getNumber())
                .totalPages(page.getTotalPages())
                .totalElements(page.getTotalElements())
                .last(page.isLast())
                .totalDistance(totalDistance)
                .mountains(dtoList)
                .build();
    }


    /*
     * 특정 발자취 조회
     */
    @Transactional(readOnly = true)
    public Footprint getFootprint(Integer footprintId) {
        Footprint footprint = footprintRepository.findById(footprintId)
                                                 .orElseThrow(NotFoundException::new);
        return footprint;
    }
}

