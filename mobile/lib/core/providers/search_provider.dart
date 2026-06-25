import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/osint_results.dart';

// ── Search state ───────────────────────────────────────────────────────────────

enum SearchPhase { idle, submitting, polling, completed, failed }

class SearchState {
  final SearchPhase phase;
  final String? searchId;
  final String? email;
  final int progressPct;
  final OsintResults? results;
  final String? error;

  const SearchState({
    this.phase = SearchPhase.idle,
    this.searchId,
    this.email,
    this.progressPct = 0,
    this.results,
    this.error,
  });

  bool get isLoading =>
      phase == SearchPhase.submitting || phase == SearchPhase.polling;

  SearchState copyWith({
    SearchPhase? phase,
    String? searchId,
    String? email,
    int? progressPct,
    OsintResults? results,
    String? error,
  }) =>
      SearchState(
        phase: phase ?? this.phase,
        searchId: searchId ?? this.searchId,
        email: email ?? this.email,
        progressPct: progressPct ?? this.progressPct,
        results: results ?? this.results,
        error: error ?? this.error,
      );
}

// ── Search notifier ────────────────────────────────────────────────────────────

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier() : super(const SearchState());

  final _api = ApiClient.instance;
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Submit a new email search and start polling for results.
  Future<void> startSearch(String email) async {
    _pollTimer?.cancel();
    state = SearchState(phase: SearchPhase.submitting, email: email);

    try {
      final resp = await _api.post(
        Endpoints.startSearch,
        data: {'email': email},
      );
      final data = resp.data as Map<String, dynamic>;
      final searchId = data['search_id'] as String;

      state = state.copyWith(
        phase: SearchPhase.polling,
        searchId: searchId,
        progressPct: 5,
      );

      _startPolling(searchId);
    } on ApiException catch (e) {
      state = state.copyWith(phase: SearchPhase.failed, error: e.message);
    }
  }

  void _startPolling(String searchId) {
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final statusResp = await _api.get(Endpoints.searchStatus(searchId));
        final statusData = statusResp.data as Map<String, dynamic>;
        final status = statusData['status'] as String;
        final pct = statusData['progress_pct'] as int? ?? state.progressPct;

        if (status == 'completed') {
          _pollTimer?.cancel();
          await _fetchResults(searchId);
        } else if (status == 'failed') {
          _pollTimer?.cancel();
          state = state.copyWith(
            phase: SearchPhase.failed,
            error: statusData['error_message'] as String? ?? 'Search failed',
          );
        } else {
          state = state.copyWith(progressPct: pct);
        }
      } on ApiException catch (e) {
        _pollTimer?.cancel();
        state = state.copyWith(phase: SearchPhase.failed, error: e.message);
      }
    });
  }

  Future<void> _fetchResults(String searchId) async {
    try {
      final resp = await _api.get(Endpoints.searchResults(searchId));
      final data = resp.data as Map<String, dynamic>;
      final results = OsintResults.fromJson(
        data['results'] as Map<String, dynamic>? ?? {},
      );
      state = state.copyWith(
        phase: SearchPhase.completed,
        results: results,
        progressPct: 100,
      );
    } on ApiException catch (e) {
      state = state.copyWith(phase: SearchPhase.failed, error: e.message);
    }
  }

  void reset() {
    _pollTimer?.cancel();
    state = const SearchState();
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>(
  (ref) => SearchNotifier(),
);

// ── History provider ───────────────────────────────────────────────────────────

final historyProvider = FutureProvider.autoDispose<List<SearchRecord>>((ref) async {
  final api = ApiClient.instance;
  final resp = await api.get(Endpoints.history, queryParameters: {'limit': 50});
  final data = resp.data as Map<String, dynamic>;
  final list = data['searches'] as List<dynamic>? ?? [];
  return list
      .map((e) => SearchRecord.fromJson(e as Map<String, dynamic>))
      .toList();
});

final recentSearchesProvider = FutureProvider.autoDispose<List<SearchRecord>>((ref) async {
  final api = ApiClient.instance;
  final resp = await api.get(Endpoints.recentSearches);
  final data = resp.data as Map<String, dynamic>;
  final list = data['searches'] as List<dynamic>? ?? [];
  return list
      .map((e) => SearchRecord.fromJson(e as Map<String, dynamic>))
      .toList();
});
