package com.ssafy.ollana.footprint.service;

import com.ssafy.ollana.common.util.PageResponse;
import com.ssafy.ollana.common.util.PaginateUtil;
import com.ssafy.ollana.footprint.persistent.entity.Footprint;
import com.ssafy.ollana.footprint.persistent.repository.FootprintRepository;
import com.ssafy.ollana.footprint.service.exception.NotFoundException;
import com.ssafy.ollana.footprint.web.dto.response.FootprintResponseDto;
import com.ssafy.ollana.user.UserRepository;
import com.ssafy.ollana.user.entity.User;
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
    public PageResponse<FootprintResponseDto> getFootprintList(Integer userId, Pageable pageable) {
        User user = userRepository.findById(userId)
                                  .orElseThrow();   // 유저 예외 처리 필요
        Page<Footprint> page = footprintRepository.findByUserId(userId, pageable);

        List<FootprintResponseDto> mountainDtos = page.getContent().stream()
                         .map(footprint -> FootprintResponseDto.builder()
                                                    .footprintId(footprint.getId())
                                                    .mountainName(footprint.getMountain().getMountainName())
                                                    .imgUrl(footprint.getMountain().getMountainBadge())
                                                    .build())
                        .toList();

        Page<FootprintResponseDto> paginateResult = PaginateUtil.paginate(
                mountainDtos, pageable.getPageNumber(), pageable.getPageSize());

        return new PageResponse<>("mountains", paginateResult);
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

