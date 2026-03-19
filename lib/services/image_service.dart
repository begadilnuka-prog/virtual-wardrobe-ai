import 'package:image_picker/image_picker.dart';

class ImageService {
  ImageService() : _picker = ImagePicker();

  final ImagePicker _picker;

  Future<XFile?> pickFromGallery() {
    return _picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
  }

  Future<XFile?> pickFromCamera() {
    return _picker.pickImage(source: ImageSource.camera, imageQuality: 88);
  }
}
