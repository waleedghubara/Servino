import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

/// تحويل صورة واحدة لـ MultipartFile
Future<MultipartFile> uploadImageToAPI(XFile image) async {
  return await MultipartFile.fromFile(
    image.path,
    filename: image.path.split('/').last,
  );
}

Future<List<MultipartFile>> convertImagesToMultipartFiles(
  List<XFile> images,
) async {
  List<MultipartFile> files = [];

  for (var image in images) {
    final file = await uploadImageToAPI(image);
    files.add(file);
  }

  return files;
}
