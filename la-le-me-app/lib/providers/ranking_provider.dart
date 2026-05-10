import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ranking.dart';
import '../models/season.dart';
import '../services/api_service.dart';

final globalRankingProvider = FutureProvider<RankingPageResult>((ref) async {
  return await ApiService.getGlobalRanking(page: 1, limit: 20);
});

final currentSeasonProvider = Provider<String>((ref) {
  return SeasonManager.getCurrentSeason();
});