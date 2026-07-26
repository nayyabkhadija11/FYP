import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailValidatorService {
  static const String _apiKey = '2caf39664ab24f02928e0e41079b6c05';

  static Future<bool> isEmailValidAndActive(String email) async {
    try {
      final url = Uri.parse(
        'https://emailreputation.abstractapi.com/v1/?api_key=$_apiKey&email=$email',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final emailDeliverability = data['email_deliverability'] ?? {};
        String status = emailDeliverability['status'] ?? '';
        bool isFormatValid = emailDeliverability['is_format_valid'] ?? false;

        if (status.toLowerCase() == 'deliverable' && isFormatValid) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}