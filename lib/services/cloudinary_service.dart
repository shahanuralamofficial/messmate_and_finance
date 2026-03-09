import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Cloudinary Dashboard থেকে এই তথ্যগুলো সংগ্রহ করুন
  static const String _cloudName = "dhbz88gjs";
  static const String _uploadPreset = "messmate_and_finance";

  static Future<String?> uploadImage(File imageFile) async {
    final url = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/image/upload");

    try {
      final request = http.MultipartRequest("POST", url)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url']; // ইমেজটির সিকিউর URL রিটার্ন করবে
      } else {
        print("Cloudinary Upload Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Cloudinary Exception: $e");
      return null;
    }
  }
}
