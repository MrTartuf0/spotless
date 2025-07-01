import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchRepository {
  final Dio _dio = Dio();
  final String baseUrl = 'https://spc.rickyscloud.com/api/query';

  Future<Map<String, dynamic>> search(String query) async {
    if (query.isEmpty) {
      return {"albums": [], "tracks": []};
    }

    try {
      // Configure headers as specified in the curl command
      final options = Options(
        headers: {
          'accept': 'application/json, text/plain, */*',
          'accept-language': 'en-US,en;q=0.9,it-IT;q=0.8,it;q=0.7',
          'cache-control': 'no-cache',
          'dnt': '1',
          'pragma': 'no-cache',
          'priority': 'u=1, i',
          'referer': 'https://spc.rickyscloud.com/',
          'sec-fetch-dest': 'empty',
          'sec-fetch-mode': 'cors',
          'sec-fetch-site': 'same-origin',
          'user-agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
        },
      );

      final response = await _dio.get(
        baseUrl,
        options: options,
        queryParameters: {'q': query},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        print('Error: ${response.statusCode}');
        return {"albums": [], "tracks": []};
      }
    } catch (e) {
      print('Search error: $e');
      return {"albums": [], "tracks": []};
    }
  }
}

// Provider

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository();
});
