import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'l10n/app_localizations.dart';
import 'widgets.dart';

class TakeSnapScreen extends StatelessWidget {
  const TakeSnapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          '${AppLocalizations.of(context)!.take} Snap!',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
      ),
      body: const TakeSnap(),
    );
  }
}

class TakeSnap extends StatefulWidget {
  const TakeSnap({super.key});

  @override
  State<TakeSnap> createState() => _TakeSnapState();
}

class _TakeSnapState extends State<TakeSnap> {
  final picker = ImagePicker();
  XFile? _pickedImage;
  CroppedFile? _croppedImage;
  bool _isUploading = false;

  Future<void> getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _pickedImage = pickedFile;
        if (!kIsWeb) {
          // cropping does not work well on web
          _cropImage();
        } else {
          _croppedImage = CroppedFile(_pickedImage!.path);
        }
      } else {
        debugPrint('No image selected.');
        _pickedImage = null;
      }
    });
  }

  Future<void> _cropImage() async {
    if (_pickedImage != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _pickedImage!.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        maxHeight: 1024,
        maxWidth: 1024,
        aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Theme.of(context).colorScheme.onPrimary,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            aspectRatioPresets: [CropAspectRatioPreset.square],
          ),
          IOSUiSettings(title: 'Cropper'),
          WebUiSettings(context: context),
        ],
      );
      if (croppedFile != null) {
        setState(() {
          _croppedImage = croppedFile;
        });
      }
    }
  }

  Future<void> uploadImage() async {
    setState(() {
      _isUploading = true;
    });

    final userId = FirebaseAuth.instance.currentUser!.uid;
    final fileRef =
        'snaps/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final Reference storageReference = FirebaseStorage.instance.ref().child(
      fileRef,
    );

    final UploadTask uploadTask = kIsWeb
        ? storageReference.putData(
            await _croppedImage!
                .readAsBytes(), // Does not work on web as File is from io
            SettableMetadata(contentType: 'image/jpeg'),
          )
        : storageReference.putFile(File(_croppedImage!.path));

    await uploadTask.whenComplete(() => null);

    final imageUrl = await storageReference.getDownloadURL();

    await FirebaseFirestore.instance.collection('snaps').add({
      'url': imageUrl,
      'fileRef': fileRef,
      'title': titleController.text,
      'processed': false,
      'expireAt': DateTime.now().add(const Duration(hours: 24)),
      'createdAt': FieldValue.serverTimestamp(),
      'userId': userId,
    });

    if (!mounted) return;
    setState(() {
      _isUploading = false;
    });
  }

  final titleController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_isUploading)
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                kIsWeb
                    ? Image.network(_croppedImage!.path)
                    : Image.file(File(_croppedImage!.path)),
                const SizedBox(
                  height: 200,
                  width: 200,
                  child: CircularProgressIndicator(),
                ),
              ],
            ),
          ),
        if (!_isUploading && _croppedImage == null)
          PrimaryBlockButton(onPressed: getImage, text: 'Snap!'),
        if (!_isUploading && _croppedImage != null) ...[
          Expanded(
            child: kIsWeb
                ? Image.network(_croppedImage!.path)
                : Image.file(File(_croppedImage!.path)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              autofocus: true,
              controller: titleController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.title,
              ),
            ),
          ),
        ],
        PrimaryBlockButton(
          onPressed: _croppedImage != null
              ? () async {
                  await uploadImage();
                  if (context.mounted) {
                    context.go('/');
                    titleController.text = '';
                    _pickedImage = null;
                    _croppedImage = null;
                  }
                }
              : null,
          text: AppLocalizations.of(context)!.send,
        ),
      ],
    );

    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 500) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: content,
            );
          } else {
            return content;
          }
        },
      ),
    );
  }
}
