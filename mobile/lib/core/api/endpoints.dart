// API endpoint constants for the Email OSINT backend.
class Endpoints {
  static const String login = '/api/v1/auth/login';
  static const String register = '/api/v1/auth/register';
  static const String logout = '/api/v1/auth/logout';

  static const String startSearch = '/api/v1/search';
  static String searchStatus(String id) => '/api/v1/search/$id/status';
  static String searchResults(String id) => '/api/v1/search/$id/results';
  static String deleteSearch(String id) => '/api/v1/search/$id';

  static const String history = '/api/v1/history';
  static const String recentSearches = '/api/v1/history/recent';

  static String exportJson(String id) => '/api/v1/export/$id/json';
  static String exportPdf(String id) => '/api/v1/export/$id/pdf';
}
