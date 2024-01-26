import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:http_parser/http_parser.dart';
import 'constant.dart';

class EditProfilePicPage extends StatefulWidget {
  final String driverId;
  final String? driverProfile;

  EditProfilePicPage({required this.driverId, required this.driverProfile});

  @override
  _EditProfilePicPageState createState() => _EditProfilePicPageState();
}

class _EditProfilePicPageState extends State<EditProfilePicPage> {
  File? _image; // Make it nullable to handle the default profile pic as an asset

  @override
  void initState() {
    super.initState();
    // Don't initialize _image here to handle the default profile pic as an asset
  }

  Future<void> _getImage(ImageSource source, {int targetSizeKB = 100}) async {
    final pickedFile = await ImagePicker().pickImage(
      source: source,
    );

    if (pickedFile != null) {
      // Perform asynchronous work (e.g., image compression) outside of setState
      File? compressedImage = await compressImage(File(pickedFile.path), targetSizeKB);

      if (compressedImage != null) {
        // Update the state synchronously after the asynchronous work is done
        setState(() {
          _image = compressedImage;
        });
      }
    }
  }

  Future<File?> compressImage(File imageFile, int targetSizeKB) async {
    final bytes = await imageFile.readAsBytes();

    // Decode the image
    final image = img.decodeImage(Uint8List.fromList(bytes));

    if (image != null) {
      // Resize the image (adjust width and height as needed)
      final resizedImage = img.copyResize(image, width: 800);

      // Encode the resized image as JPEG with a specific quality
      final compressedBytes = img.encodeJpg(resizedImage, quality: 70);

      // Create a temporary file to store the compressed image
      final compressedFile = File('${imageFile.path}_compressed.jpg');

      // Write the compressed bytes to the file
      await compressedFile.writeAsBytes(compressedBytes);

      return compressedFile;
    }

    return null;
  }

  Future<void> _uploadImage() async {
    if (_image == null) {
      print('No image to upload.');
      return;
    }

    final compressedImage = await compressImage(_image!, 100);
    if (compressedImage == null) {
      print('Failed to compress image.');
      return;
    }

    final uri = Uri.parse('${Constants.apiUrl}/api/uploadProfilePic');
    final request = http.MultipartRequest('POST', uri);

    // Add other fields if needed
    request.fields['driver_id'] = widget.driverId;

    // Add the image as a file in the request
    request.files.add(
      await http.MultipartFile.fromBytes(
        'image',
        compressedImage.readAsBytesSync(),
        filename: 'profile_pic.jpg', // Provide a filename
        contentType: MediaType('image', '*'), // Adjust the content type as needed
      ),
    );

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        print('Image uploaded successfully');
        Navigator.pop(context);
      } else {
        print('Failed to upload image. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error uploading image: $error');
    }
  }
  void _removeImage() {
    setState(() {
      _image = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile Picture'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    // Profile picture
                    _image != null
                        ? Image.file(
                      _image!,
                      height: 300,
                      width: 300,
                      fit: BoxFit.cover,
                    )
                        : Image.network(
                      widget.driverProfile ?? '/upload_mobile/profilepic.png',
                      height: 300,
                      width: 300,
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
                if (_image != null)
                  IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: _removeImage,
                  ),
                // Button to upload or remove profile picture
                if (_image != null)
                  ElevatedButton(
                    onPressed: _uploadImage,
                    child: Text('Upload'),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return Card(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                ListTile(
                                  title: Text('Select an image source'),
                                ),
                                ListTile(
                                  leading: Icon(Icons.photo),
                                  title: Text('Gallery'),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    _getImage(ImageSource.gallery, targetSizeKB: 100);
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.camera_alt_sharp),
                                  title: Text('Camera'),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    _getImage(ImageSource.camera, targetSizeKB: 100);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: Text('Upload a Profile Picture'),
                  ),
                // Add your profile picture editing UI here
              ],
            ),
          ),
        ),
      ),
    );
  }
}

