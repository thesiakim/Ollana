import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/my_footprint_service.dart';
import '../../models/app_state.dart';
import '../../models/footprint_response.dart';
import '../../models/footprint_mountain.dart';

class MyFootprintScreen extends StatefulWidget {
  const MyFootprintScreen({super.key});

  @override
  State<MyFootprintScreen> createState() => _MyFootprintScreenState();
}

class _MyFootprintScreenState extends State<MyFootprintScreen> {
  List<footprintMountain> footprints = [];
  bool isLoading = true;

  int _currentPage = 0;
  bool _isFetching = false;
  bool _hasNextPage = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  late FootprintResponse response;

  Future<void> _fetchFootprints(String token) async {
    if (_isFetching || !_hasNextPage) return;

    setState(() => _isFetching = true);

    try {
      final service = MyFootprintService();
      final newResponse = await service.getFootprints(token, page: _currentPage);

      setState(() {
        if (_currentPage == 0) {
          footprints = newResponse.mountains;
        } else {
          footprints.addAll(newResponse.mountains);
        }

        _hasNextPage = !newResponse.last;
        _currentPage++;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('발자취 목록 로딩 중 에러 발생: $e');
      setState(() => isLoading = false);
    } finally {
      setState(() => _isFetching = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      final token = Provider.of<AppState>(context, listen: false).accessToken ?? '';
      _fetchFootprints(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    if (isLoading) {
      _fetchFootprints(appState.accessToken ?? '');
    }

    return Scaffold(
      appBar: AppBar(title: const Text("나의 발자취")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                controller: _scrollController,
                itemCount: footprints.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, index) {
                  final item = footprints[index];

                  return Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: item.imgUrl.isNotEmpty
                              ? Image.network(
                                  item.imgUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.image_not_supported, size: 80),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.mountainName,
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
