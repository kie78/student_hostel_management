import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:5000/api/payments";

  // PAYMENT API
  static Future<Map<String, dynamic>> makePayment(
    String studentId,
    String amount,
    String phone,
    String method,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/pay"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "student_id": studentId,
        "amount": amount,
        "phone": phone,
        "payment_method": method
      }),
    );

    return jsonDecode(response.body);
  }

  // TRANSACTION HISTORY
  static Future<List<dynamic>> getTransactions() async {
    final response = await http.get(
      Uri.parse("$baseUrl/history"),
    );

    final data = jsonDecode(response.body);
    return data["data"];
  }
}