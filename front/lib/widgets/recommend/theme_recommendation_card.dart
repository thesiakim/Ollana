import 'package:flutter/material.dart';
import '../../utils/ai_utils.dart';

class ThemeRecommendationCard extends StatelessWidget {
  final Map<String, dynamic> mountain;
  final int index;
  final VoidCallback onTap;

  const ThemeRecommendationCard({
    Key? key,
    required this.mountain,
    required this.index,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final name = mountain['mountain_name'] as String?;
    final desc = mountain['mountain_description'] as String?;
    final rawImg = mountain['image_url'] as String?;
    final imgUrl = formatImageUrl(rawImg);
    final primaryColor = const Color(0xFF52A486);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 140, // 고정된 높이로 카드 크기 제한
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // 블러 효과를 제거하기 위해 boxShadow 제거
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이미지 영역 (왼쪽)
              Hero(
                tag: 'theme_mountain_image_$index',
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: imgUrl != null
                      ? Image.network(
                          imgUrl,
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              width: 140,
                              height: 140,
                              color: Colors.grey.shade200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                      : null,
                                  valueColor: AlwaysStoppedAnimation(primaryColor),
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (ctx, err, st) {
                            debugPrint('   이미지 에러: $err');
                            return Image.asset(
                              'lib/assets/images/mount_default.png',
                              width: 140,
                              height: 140,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          'lib/assets/images/mount_default.png',
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              
              // 콘텐츠 영역 (오른쪽)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 산 이름
                      Row(
                        children: [
                          Icon(
                            Icons.terrain, 
                            size: 16, 
                            color: primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              name ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // 설명
                      Expanded(
                        child: Text(
                          desc ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      
                      // 상세 보기 버튼
                      Align(
                        alignment: Alignment.bottomRight,
                        child: TextButton(
                          onPressed: onTap,
                          style: TextButton.styleFrom(
                            foregroundColor: primaryColor,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(60, 28),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.visibility,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '상세 보기',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}