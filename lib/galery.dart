import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class GaleryScreen extends StatefulWidget {
  @override
  _GaleryScreenState createState() => _GaleryScreenState();
}

class AlbumOption {
  final int id;
  final String nama;

  AlbumOption({required this.id, required this.nama});

  factory AlbumOption.fromJson(Map<String, dynamic> json) {
    return AlbumOption(
      id: json['AlbumID'],
      nama: json['Nama'],
    );
  }
}

class _GaleryScreenState extends State<GaleryScreen> {
  List<Photo> photoList = [];
  List<AlbumOption> albumOptions = [];
  File? _selectedImage;
  bool isLoading = true;
  bool isGuest = false;

  @override
  void initState() {
    super.initState();
    _checkGuestStatus();
    fetchPhotos();
    fetchAlbums();
  }

  Future<void> _checkGuestStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isGuest = prefs.getBool('is_guest') ?? false;
    });
  }

  Future<void> fetchPhotos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final isGuest = prefs.getBool('is_guest') ?? false;
      
      if (isGuest) {
        final response = await http.get(
          Uri.parse('http://10.0.2.2/Web_Gallery/public/api/foto'),
          headers: {
            'Accept': 'application/json',
          },
        ).timeout(Duration(seconds: 10));

        if (response.statusCode == 200) {
          List<dynamic> data = jsonDecode(response.body);
          setState(() {
            photoList = data.map((json) => Photo.fromJson(json)).toList();
            isLoading = false;
          });
        }
        return;
      }

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2/Web_Gallery/public/api/foto'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 10));

      print('Fetch Photos Response: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          photoList = data.map((json) => Photo.fromJson(json)).toList();
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        throw Exception('Failed to load photos');
      }
    } catch (e) {
      print("Error fetching photos: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchAlbums() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2/Web_Gallery/public/api/albums'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          albumOptions = data.map((json) => AlbumOption.fromJson(json)).toList();
        });
      }
    } catch (e) {
      print("Error fetching albums: $e");
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void showAddEditPhotoModal({Photo? photo}) {
    final titleController = TextEditingController(text: photo?.judul);
    final descriptionController = TextEditingController(text: photo?.deskripsi);
    int? selectedAlbumId = photo?.albumId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      photo == null ? 'Tambah Foto' : 'Edit Foto',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Judul',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedAlbumId,
                      decoration: InputDecoration(
                        labelText: 'Album',
                        border: OutlineInputBorder(),
                      ),
                      items: albumOptions.map((album) {
                        return DropdownMenuItem(
                          value: album.id,
                          child: Text(album.nama),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedAlbumId = value;
                        });
                      },
                      hint: Text('Pilih Album'),
                    ),
                    SizedBox(height: 16),
                    if (photo != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Foto Saat Ini:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              photo.file,
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    if (_selectedImage != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Foto Baru:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImage!,
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.photo_camera),
                      label: Text(_selectedImage != null ? 'Ganti Foto' : 'Pilih Foto'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (selectedAlbumId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Silakan pilih album')),
                          );
                          return;
                        }
                        
                        if (photo == null && _selectedImage == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Silakan pilih foto')),
                          );
                          return;
                        }

                        try {
                          if (photo == null) {
                            await addPhoto(
                              titleController.text,
                              descriptionController.text,
                              selectedAlbumId!,
                            );
                          } else {
                            await updatePhoto(
                              photo.id,
                              titleController.text,
                              descriptionController.text,
                              selectedAlbumId!,
                            );
                          }
                          Navigator.pop(context);
                          fetchPhotos();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Text(photo == null ? 'Tambah' : 'Update'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> addPhoto(String judul, String deskripsi, int albumId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) throw Exception('Not authenticated');
      if (_selectedImage == null) throw Exception('Please select an image');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2/Web_Gallery/public/api/foto'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields.addAll({
        'judul': judul,
        'deskripsi': deskripsi,
        'AlbumID': albumId.toString(),
      });

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _selectedImage!.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Add Photo Response: ${response.body}');

      if (response.statusCode == 401) {
        Navigator.of(context).pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      }

      if (response.statusCode != 201) {
        throw Exception('Failed to add photo');
      }

      setState(() {
        _selectedImage = null;
      });
    } catch (e) {
      print('Error adding photo: $e');
      throw e;
    }
  }

  Future<void> updatePhoto(int id, String judul, String deskripsi, int albumId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) throw Exception('Not authenticated');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2/Web_Gallery/public/api/foto/$id'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields.addAll({
        '_method': 'PUT',
        'judul': judul,
        'deskripsi': deskripsi,
        'AlbumID': albumId.toString(),
      });

      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            _selectedImage!.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Update Photo Response Status: ${response.statusCode}');
      print('Update Photo Response Body: ${response.body}');

      if (response.statusCode == 401) {
        Navigator.of(context).pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      }

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update photo');
      }

      setState(() {
        _selectedImage = null;
      });
    } catch (e) {
      print('Error updating photo: $e');
      throw e;
    }
  }

  Future<void> deletePhoto(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('http://10.0.2.2/Web_Gallery/public/api/foto/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Delete Photo Response: ${response.body}');

      if (response.statusCode == 401) {
        Navigator.of(context).pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to delete photo');
      }
    } catch (e) {
      print('Error deleting photo: $e');
      throw e;
    }
  }

  void confirmDelete(Photo photo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content: Text('Yakin ingin menghapus foto "${photo.judul}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await deletePhoto(photo.id);
                  Navigator.pop(context);
                  fetchPhotos();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Hapus'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }

  void _showPhotoDetail(Photo photo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    photo.file,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.image, size: 100),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  photo.judul,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  photo.deskripsi,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Album: ${photo.albumName ?? "Unknown"}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gallery'),
        actions: [
          if (!isGuest)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => showAddEditPhotoModal(),
            ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 0.8,
              ),
              itemCount: photoList.length,
              itemBuilder: (context, index) {
                final photo = photoList[index];
                return GestureDetector(
                  onTap: () => _showPhotoDetail(photo),
                  child: Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 3, // Memberikan ruang lebih untuk foto
                              child: ClipRRect(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                                child: Image.network(
                                  photo.file,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.image, size: 50),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2, // Ruang untuk teks
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      photo.judul,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      photo.deskripsi,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Album: ${photo.albumName ?? "Unknown"}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!isGuest)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  showAddEditPhotoModal(photo: photo);
                                } else if (value == 'delete') {
                                  confirmDelete(photo);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class Photo {
  final int id;
  final String file;
  final String judul;
  final String deskripsi;
  final int albumId;
  final String? albumName;

  Photo({
    required this.id,
    required this.file,
    required this.judul,
    required this.deskripsi,
    required this.albumId,
    this.albumName,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['FotoID'] ?? 0,
      file: json['file'] ?? '',
      judul: json['judul'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      albumId: json['AlbumID'] ?? 0,
      albumName: json['album'] != null ? json['album']['Nama'] ?? '' : null,
    );
  }
}
