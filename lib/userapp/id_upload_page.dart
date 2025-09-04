import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class IdUploadPage extends StatefulWidget {
  const IdUploadPage({super.key});

  @override
  State<IdUploadPage> createState() => _IdUploadPageState();
}

class _IdUploadPageState extends State<IdUploadPage> {
  XFile? frontId;
  XFile? backId;
  bool _isLoadingFront = false;
  bool _isLoadingBack = false;

  Future<void> pickImage(bool isFront, ImageSource source) async {
    setState(() {
      if (isFront) {
        _isLoadingFront = true;
      } else {
        _isLoadingBack = true;
      }
    });

    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (img != null) {
        setState(() {
          if (isFront) {
            frontId = img;
          } else {
            backId = img;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to pick image. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        if (isFront) {
          _isLoadingFront = false;
        } else {
          _isLoadingBack = false;
        }
      });
    }
  }

  void showPickerDialog(bool isFront) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choose from Gallery"),
              onTap: () {
                Navigator.pop(context);
                pickImage(isFront, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take a Photo"),
              onTap: () {
                Navigator.pop(context);
                pickImage(isFront, ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildIdCard(XFile? idImage, bool isFront) {
    final primaryColor = Colors.blue;
    final isLoading = isFront ? _isLoadingFront : _isLoadingBack;

    return GestureDetector(
      onTap: () => showPickerDialog(isFront),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 150,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: idImage != null ? primaryColor : Colors.grey[300]!,
            width: idImage != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : idImage == null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.credit_card, size: 40, color: Colors.grey),
              SizedBox(height: 6),
              Text(
                "Tap to Upload",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        )
            : ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(idImage.path),
            fit: BoxFit.cover,
            width: 150,
            height: 100,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Upload ID Documents",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              "Upload both sides of your ID",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                buildIdCard(frontId, true),
                buildIdCard(backId, false),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (frontId != null && backId != null)
                    ? () => Navigator.pop(context, true)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "✅ Save & Continue",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
