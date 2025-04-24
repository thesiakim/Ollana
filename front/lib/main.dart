import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.green,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(ChangeNotifierProvider(create: (_) => AppState(), child: const App()));
}

class AppState extends ChangeNotifier {
  bool _isLoggedIn = false;
  int _currentPageIndex = 0;

  bool get isLoggedIn => _isLoggedIn;
  int get currentPageIndex => _currentPageIndex;

  void toggleLogin() {
    _isLoggedIn = !_isLoggedIn;
    notifyListeners();
  }

  void changePage(int index) {
    _currentPageIndex = index;
    notifyListeners();
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const HomePage());
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          return IndexedStack(
            index: appState.currentPageIndex,
            children: const [
              HomeBody(),
              Center(child: Text('Page 2')),
              Center(child: Text('Page 3')),
            ],
          );
        },
      ),
      bottomNavigationBar: const CustomFooter(),
    );
  }
}

class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  // CardData 리스트 생성
  final List<CardData> cards = List.generate(
    5,
    (i) => CardData(
      id: i + 1,
      gradient: [
        Colors.primaries[i * 2 % Colors.primaries.length].shade400,
        Colors.primaries[(i * 2 + 1) % Colors.primaries.length].shade300,
      ],
    ),
  );

  final double cardPaddingVertical = 4.0;
  final double cardPaddingHorizontal = 10.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '로그인을 하고 동산할\n신과 코스를 추천받으세요!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '관심있는 산을 검색하세요...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8.0, bottom: 1.0),
                  child: Text(
                    '추천 코스',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 이미지 카드 리스트를 보여줌
                Expanded(
                  child: ListView.builder(
                    itemCount: courseList.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      return ImageCourseCard(course: courseList[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      height: kToolbarHeight + statusBarHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(height: statusBarHeight),
          Expanded(
            child: Row(
              children: [
                _buildLogoButton(context),
                const Spacer(),
                _buildLoginButton(context, appState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: TextButton(
        onPressed: () {
          context.read<AppState>().changePage(0);
        },
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(Colors.black),
          padding: WidgetStateProperty.all(EdgeInsets.zero),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
        ),
        child: const Text(
          "Ollana",
          style: TextStyle(
            overflow: TextOverflow.ellipsis,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, AppState appState) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: TextButton(
        onPressed: appState.toggleLogin,
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(Colors.black),
          padding: WidgetStateProperty.all(EdgeInsets.zero),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
        ),
        child: Text(appState.isLoggedIn ? "logout" : "login"),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class CustomFooter extends StatelessWidget {
  const CustomFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 60 + bottomPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFooterButton(context, 0, Icons.home, '홈'),
              _buildFooterButton(context, 1, Icons.search, '검색'),
              _buildFooterButton(context, 2, Icons.person, '프로필'),
            ],
          ),
          SizedBox(height: bottomPadding),
        ],
      ),
    );
  }

  Widget _buildFooterButton(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final appState = context.watch<AppState>();
    final isSelected = appState.currentPageIndex == index;

    return GestureDetector(
      onTap: () => appState.changePage(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.green : Colors.grey),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.green : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomStackedCards extends StatefulWidget {
  final List<Widget> items;

  const CustomStackedCards({
    super.key,
    required this.items,
  });

  @override
  State<CustomStackedCards> createState() => _CustomStackedCardsState();
}

class _CustomStackedCardsState extends State<CustomStackedCards> {
  late PageController _pageController;
  double _currentPageValue = 0.0;

  @override
  void initState() {
    super.initState();
    // PageController 생성: viewportFraction=0.4 (화면에 카드 40% 크기로 표시)
    _pageController = PageController(viewportFraction: 0.4);
    // Scroll 시 리스너 등록: 페이지 위치를 _currentPageValue로 업데이트
    _pageController.addListener(() {
      setState(() {
        // page 프로퍼티: 현재 스크롤 위치를 실수 값으로 반환
        _currentPageValue = _pageController.page!;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      // PageView.builder: 스크롤 가능한 페이지 뷰 생성
      controller: _pageController, // 컨트롤러 지정
      itemCount: widget.items.length, // 총 아이템 개수 지정
      scrollDirection: Axis.vertical, // 세로 방향으로 스크롤
      itemBuilder: (context, index) {
        // index: 빌드 중인 페이지 번호
        double difference = index - _currentPageValue; // 페이지 차이 계산
        difference = difference.abs(); // 음수 제거하여 절대값 사용
        // verticalPosition: 카드 위치 오프셋 (index 간 차이 * 120px)
        final verticalPosition = difference * 120.0;
        // scale: 카드 크기 비율 (뒤로 갈수록 작아짐)
        final scale = 1 - (difference * 0.2);
        // z: 3D 깊이 배치 (뒤쪽 카드가 더 멀어지도록 음수 값)
        final z = -difference * 100.0;

        return Padding(
          // 카드 간 패딩: 아래쪽 여백 10px
          padding: const EdgeInsets.only(bottom: 10),
          child: Transform(
            // Transform: 변환 행렬을 적용하여 3D 효과
            alignment: Alignment.center, // 변환 기준점: 중앙
            transform: Matrix4.identity()
              // setEntry(3,2,value): 원근감 강도 조절 (값이 작으면 미묘한 효과)
              ..setEntry(3, 2, 0.001)
              // translate: y(offset), z(depth) 값 설정
              ..translate(0.0, verticalPosition, z)
              // rotateX: X축 기준 회전 (현재 rotationY=0, 회전 없음)
              ..rotateX(0)
              // scale: x,y 축 동일 비율로 크기 조정
              ..scale(scale, scale),
            child: Card(
              // Card 위젯: 표시할 카드 모양 정의
              margin: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 5), // 카드 외곽 여백
              elevation:
                  8 - (difference * 2).clamp(0, 8).toDouble(), // 그림자 높이 조정
              shape: RoundedRectangleBorder(
                // 모서리 둥글게
                borderRadius: BorderRadius.circular(16),
              ),
              // child: 실제 카드 콘텐츠
              child: widget.items[index],
            ),
          ),
        );
      },
    );
  }
}

// 데이터 모델: 카드 정보
class CardData {
  final int id;
  final List<Color> gradient;
  CardData({required this.id, required this.gradient});
}

// 카드 표시 위젯
class CardItem extends StatelessWidget {
  final CardData data;
  const CardItem({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '추천 코스 ${data.id}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// 데이터 모델: 이미지 추천 코스
class CourseData {
  final String title;
  final String subtitle;
  final String imagePath;
  CourseData(
      {required this.title, required this.subtitle, required this.imagePath});
}

// 샘플 이미지 코스 리스트
final List<CourseData> courseList = [
  CourseData(
    title: '봄꽃 구경 추천 코스',
    subtitle: 'BEST 6',
    imagePath: 'lib/assets/images/spring.jpg',
  ),
  CourseData(
    title: '영남알프스 4일 완성 속성반',
    subtitle: 'BEST 4',
    imagePath: 'lib/assets/images/alps.jpg',
  ),
  CourseData(
    title: '초보 산행이 추천 코스',
    subtitle: 'BEST 9',
    imagePath: 'lib/assets/images/beginner.jpg',
  ),
  CourseData(
    title: '케이블카 추천 코스',
    subtitle: 'BEST 5',
    imagePath: 'lib/assets/images/cablecar.jpg',
  ),
];

// 이미지 카드 위젯
class ImageCourseCard extends StatelessWidget {
  final CourseData course;
  const ImageCourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: AssetImage(course.imagePath),
          fit: BoxFit.cover,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withAlpha(130), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Text(
                course.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: Text(
                course.subtitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
