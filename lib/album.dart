import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AlbumScreen extends StatefulWidget {
  @override
  _AlbumScreenState createState() => _AlbumScreenState();
}

class KategoriOption {
  final int id;
  final String judul;

  KategoriOption({required this.id, required this.judul});

  factory KategoriOption.fromJson(Map<String, dynamic> json) {
    return KategoriOption(
      id: json['KategoriID'],
      judul: json['judul'],
    );
  }
}

class _AlbumScreenState extends State<AlbumScreen> {
  List<Album> albumList = [];
  List<KategoriOption> kategoriOptions = [];
  bool isLoading = true;
  bool isGuest = false;

  @override
  void initState() {
    super.initState();
    _checkGuestStatus();
    fetchAlbums();
    fetchKategori();
  }

  Future<void> _checkGuestStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isGuest = prefs.getBool('is_guest') ?? false;
    });
  }

  Future<void> fetchAlbums() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final isGuest = prefs.getBool('is_guest') ?? false;
      
      if (isGuest) {
        final response = await http.get(
          Uri.parse('http://10.0.2.2/Web_Gallery/public/api/albums'),
          headers: {
            'Accept': 'application/json',
          },
        ).timeout(Duration(seconds: 10));

        if (response.statusCode == 200) {
          List<dynamic> data = jsonDecode(response.body);
          setState(() {
            albumList = data.map((json) => Album.fromJson(json)).toList();
            isLoading = false;
          });
        }
        return;
      }

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2/Web_Gallery/public/api/albums'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          albumList = data.map((json) => Album.fromJson(json)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching albums: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<Photo>> fetchPhotos(int albumId) async {
    try {
      final response = await http
          .get(Uri.parse('http://10.0.2.2/Web_Gallery/public/api/albums/$albumId'))
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        List<dynamic> photoData = data['fotos']; // Ambil array fotos
        return photoData.map((json) => Photo.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load photos');
      }
    } catch (e) {
      print("Error fetching photos: $e");
      return [];
    }
  }

  void _showPhotosDialog(int albumId) async {
    List<Photo> photos = await fetchPhotos(albumId);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Photos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: photos.isEmpty
                      ? Center(
                          child: Text(
                            'No photos in this album',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(8.0),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: photos.length,
                          itemBuilder: (context, index) {
                            final photo = photos[index];
                            return GestureDetector(
                              onTap: () => _showPhotoDetail(photo),
                              child: Card(
                                elevation: 4.0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(15),
                                        ),
                                        child: Image.network(
                                          photo.file,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Icon(Icons.image, size: 50),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
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
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showAddEditAlbumModal({Album? album}) {
    final nameController = TextEditingController(text: album?.nama);
    final descriptionController = TextEditingController(text: album?.deskripsi);
    int? selectedKategoriId = album?.kategoriId;

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
                      album == null ? 'Tambah Album' : 'Edit Album',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Album',
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
                      value: selectedKategoriId,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                      ),
                      items: kategoriOptions.map((kategori) {
                        return DropdownMenuItem(
                          value: kategori.id,
                          child: Text(kategori.judul),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedKategoriId = value;
                        });
                      },
                      hint: Text('Pilih Kategori'),
                    ),
                    SizedBox(height: 16),
                    if (album != null && album.coverImageUrl.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cover Image:',
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
                              album.coverImageUrl,
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.image, size: 50),
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    ElevatedButton(
                      onPressed: () async {
                        if (selectedKategoriId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Silakan pilih kategori')),
                          );
                          return;
                        }

                        try {
                          if (album == null) {
                            await addAlbum(
                              nameController.text,
                              descriptionController.text,
                              selectedKategoriId!,
                            );
                          } else {
                            await updateAlbum(
                              album.id,
                              nameController.text,
                              descriptionController.text,
                              selectedKategoriId!,
                            );
                          }
                          Navigator.pop(context);
                          fetchAlbums();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Text(album == null ? 'Tambah' : 'Update'),
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

  Future<void> addAlbum(String nama, String deskripsi, int kategoriId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('http://10.0.2.2/Web_Gallery/public/api/albums'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'Nama': nama,
          'Deskripsi': deskripsi,
          'KategoriID': kategoriId,
        }),
      );

      print('Add Response Status: ${response.statusCode}');
      print('Add Response Body: ${response.body}');

      if (response.statusCode == 401) {
        Navigator.of(context).pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      }

      if (response.statusCode != 201) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to add album');
      }
    } catch (e) {
      print('Error adding album: $e');
      throw e;
    }
  }

  Future<void> updateAlbum(int id, String nama, String deskripsi, int kategoriId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('http://10.0.2.2/Web_Gallery/public/api/albums/$id'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'Nama': nama,
          'Deskripsi': deskripsi,
          'KategoriID': kategoriId,
        }),
      );

      print('Update Response Status: ${response.statusCode}');
      print('Update Response Body: ${response.body}');

      if (response.statusCode == 401) {
        Navigator.of(context).pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      }

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update album');
      }
    } catch (e) {
      print('Error updating album: $e');
      throw e;
    }
  }

  Future<void> deleteAlbum(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('http://10.0.2.2/Web_Gallery/public/api/albums/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Delete Response Status: ${response.statusCode}');
      print('Delete Response Body: ${response.body}');

      if (response.statusCode == 401) {
        Navigator.of(context).pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      }

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete album');
      }
    } catch (e) {
      print('Error deleting album: $e');
      throw e;
    }
  }

  void confirmDelete(Album album) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content: Text('Yakin ingin menghapus album "${album.nama}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await deleteAlbum(album.id);
                  Navigator.pop(context);
                  fetchAlbums();
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

  Future<void> fetchKategori() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2/Web_Gallery/public/api/kategori'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          List<dynamic> data = responseData['data'];
          setState(() {
            kategoriOptions = data.map((json) => KategoriOption.fromJson(json)).toList();
          });
        }
      }
    } catch (e) {
      print("Error fetching kategori: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Album', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (!isGuest)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => showAddEditAlbumModal(),
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
              itemCount: albumList.length,
              itemBuilder: (context, index) {
                final album = albumList[index];
                return GestureDetector(
                  onTap: () => _showPhotosDialog(album.id),
                  onLongPress: !isGuest ? () => showAddEditAlbumModal(album: album) : null,
                  child: Stack(
                    children: [
                      Card(
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                                  image: DecorationImage(
                                    image: NetworkImage(album.coverImageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Text(
                                    album.nama,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    album.deskripsi,
                                    style: TextStyle(fontSize: 14, color: Colors.black87),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isGuest)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                showAddEditAlbumModal(album: album);
                              } else if (value == 'delete') {
                                confirmDelete(album);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class Album {
  final int id;
  final String nama;
  final String deskripsi;
  final String coverImageUrl;
  final int kategoriId;

  Album({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.coverImageUrl,
    required this.kategoriId,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['AlbumID'],
      nama: json['Nama'],
      deskripsi: json['Deskripsi'],
      coverImageUrl: json['cover_image'] != null ? json['cover_image']['file'] : '',
      kategoriId: json['KategoriID'] ?? 0,
    );
  }
}

class Photo {
  final int id;
  final String file;
  final String judul; // Jika diperlukan
  final String deskripsi; // Jika diperlukan

  Photo({
    required this.id,
    required this.file,
    required this.judul,
    required this.deskripsi,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['FotoID'],
      file: json['file'],
      judul: json['judul'], // Jika diperlukan
      deskripsi: json['deskripsi'], // Jika diperlukan
    );
  }
}
