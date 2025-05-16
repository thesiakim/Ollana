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

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'theme_mountain_image_$index',
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      imgUrl != null
                          ? Image.network(
                              imgUrl,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (ctx, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: Colors.grey.shade200,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: progress.expectedTotalBytes != null
                                          ? progress.cumulativeBytesLoaded /
                                              progress.expectedTotalBytes!
                                          : null,
                                      valueColor:
                                          AlwaysStoppedAnimation(const Color(0xFF52A486)),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (ctx, err, st) {
                                debugPrint('   이미지 에러: $err');
                                return Image.asset(
                                  'lib/assets/images/mount_default.png',
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                          : Image.asset(
                              'lib/assets/images/mount_default.png',
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                      // 산 이름이 표시되는 영역에만 반투명 배경 추가
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              // 아이콘에 테두리 효과 추가
                              Stack(
                                children: [
                                  // 테두리를 위한 아이콘 (검은색)
                                  Icon(
                                    Icons.terrain,
                                    color: Colors.black,
                                    size: 24, // 약간 더 크게 설정하여 테두리 효과
                                  ),
                                  // 원래 아이콘
                                  Icon(
                                    Icons.terrain,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              // 텍스트에 테두리 효과 추가
                              Expanded(
                                child: Stack(
                                  children: [
                                    // 테두리 효과를 위한 텍스트
                                    Text(
                                      name ?? '',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        foreground: Paint()
                                          ..style = PaintingStyle.stroke
                                          ..strokeWidth = 3
                                          ..color = Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    // 원래의 텍스트
                                    Text(
                                      name ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(1, 1),
                                            blurRadius: 3,
                                            color: Color.fromARGB(150, 0, 0, 0),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      desc ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.visibility),
                          label: const Text('자세히 보기'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF52A486),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}