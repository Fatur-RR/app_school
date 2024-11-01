import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class InfoScreen extends StatefulWidget {
  @override
  _InfoScreenState createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  List<Info> infoList = [];
  File? _selectedImage;
  bool isGuest = false;

  @override
  void initState() {
    super.initState();
    _checkGuestStatus();
    fetchInfo();
  }

  Future<void> _checkGuestStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isGuest = prefs.getBool('is_guest') ?? false;
    });
  }

  Future<void> fetchInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final isGuest = prefs.getBool('is_guest') ?? false;
      
      if (isGuest) {
        final response = await http.get(
          Uri.parse('http://10.0.2.2/Web_Gallery/public/api/informasi'),
          headers: {
            'Accept': 'application/json',
          },
        ).timeout(Duration(seconds: 10));

        if (response.statusCode == 200) {
          List<dynamic> data = jsonDecode(response.body);
          setState(() {
            infoList = data.map((json) => Info.fromJson(json)).toList();
          });
        } else {
          throw Exception('Failed to load info');
        }
        return;
      }

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2/Web_Gallery/public/api/informasi'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 10));

      print('Fetch Response Status: ${response.statusCode}');
      print('Fetch Response Body: ${response.body}');

      if (response.statusCode == 401) {
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          infoList = data.map((json) => Info.fromJson(json)).toList();
        });
      } else {
        throw Exception('Failed to load info');
      }
    } catch (e) {
      print("Error fetching info: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void showInfoDetail(Info info) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.judul,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                CachedNetworkImage(
                  imageUrl: info.file,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) =>
                      Icon(Icons.error, color: Colors.grey),
                ),
                SizedBox(height: 10),
                Text(info.isi, style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Text('Ringkasan: ${info.ringkasan}',
                    style: TextStyle(fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                SizedBox(height: 10),
                Text('Status: ${info.status}', style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Text('Dibuat oleh User ID: ${info.userId}',
                    style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Text('Tanggal Dibuat: ${info.createdAt}',
                    style: TextStyle(fontSize: 16)),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
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

  void showAddEditInfoModal({Info? info}) {
    final titleController = TextEditingController(text: info?.judul);
    final contentController = TextEditingController(text: info?.isi);
    final summaryController = TextEditingController(text: info?.ringkasan);
    final statusController = TextEditingController(text: info?.status);
    final kategoriController = TextEditingController(text: info?.kategoriId.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
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
                  info == null ? 'Tambah Informasi' : 'Edit Informasi',
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
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: 'Isi',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 8),
                TextField(
                  controller: summaryController,
                  decoration: InputDecoration(
                    labelText: 'Ringkasan',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: statusController,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: kategoriController,
                  decoration: InputDecoration(
                    labelText: 'Kategori ID',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                if (_selectedImage != null)
                  Image.file(
                    _selectedImage!,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.photo_camera),
                  label: Text(_selectedImage != null ? 'Ganti Gambar' : 'Pilih Gambar'),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      if (info == null) {
                        await addInfo(
                          titleController.text,
                          contentController.text,
                          summaryController.text,
                          statusController.text,
                          int.parse(kategoriController.text),
                        );
                      } else {
                        await updateInfo(
                          info.id,
                          titleController.text,
                          contentController.text,
                          summaryController.text,
                          statusController.text,
                          int.parse(kategoriController.text),
                        );
                      }
                      Navigator.pop(context);
                      fetchInfo();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  child: Text(info == null ? 'Tambah' : 'Update'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> addInfo(String judul, String isi, String ringkasan, String status, int kategoriId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Not authenticated');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2/Web_Gallery/public/api/informasi'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields.addAll({
        'judul': judul,
        'isi': isi,
        'ringkasan': ringkasan,
        'status': status,
        'KategoriID': kategoriId.toString(),
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

      print('Add Response Status: ${response.statusCode}');
      print('Add Response Body: ${response.body}');

      if (response.statusCode == 401) {
        Navigator.of(context).pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      }

      if (response.statusCode != 201) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to add info');
      }

      setState(() {
        _selectedImage = null;
      });

    } catch (e) {
      print('Error in addInfo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      throw e;
    }
  }

  Future<void> updateInfo(int id, String judul, String isi, String ringkasan, String status, int kategoriId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        throw Exception('Not authenticated');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2/Web_Gallery/public/api/informasi/$id'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields.addAll({
        'judul': judul,
        'isi': isi,
        'ringkasan': ringkasan,
        'status': status,
        'KategoriID': kategoriId.toString(),
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

      print('Update Response Status: ${response.statusCode}');
      print('Update Response Body: ${response.body}');

      if (response.statusCode == 401) {
        Navigator.of(context).pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update info');
      }

      setState(() {
        _selectedImage = null;
      });

    } catch (e) {
      print('Error in updateInfo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      throw e;
    }
  }

  Future<void> deleteInfo(int id) async {
    final response = await http.delete(
      Uri.parse('http://10.0.2.2/Web_Gallery/public/api/informasi/$id'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete info');
    }
  }

  void confirmDelete(Info info) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content: Text('Yakin ingin menghapus informasi "${info.judul}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await deleteInfo(info.id);
                  Navigator.pop(context);
                  fetchInfo();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Informasi'),
        actions: [
          if (!isGuest)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => showAddEditInfoModal(),
            ),
        ],
      ),
      body: ListView.builder(
        itemCount: infoList.length,
        itemBuilder: (context, index) {
          final info = infoList[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(
                info.judul,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.ringkasan,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Kategori: ${info.kategori}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              trailing: !isGuest
                  ? PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          showAddEditInfoModal(info: info);
                        } else if (value == 'delete') {
                          confirmDelete(info);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    )
                  : null,
              onTap: () => showInfoDetail(info),
            ),
          );
        },
      ),
    );
  }
}

class Info {
  final int id;
  final String judul;
  final String isi;
  final String ringkasan;
  final String status;
  final int userId;
  final String createdAt;
  final String file;
  final String kategori;
  final int kategoriId;

  Info({
    required this.id,
    required this.judul,
    required this.isi,
    required this.ringkasan,
    required this.status,
    required this.userId,
    required this.createdAt,
    required this.file,
    required this.kategori,
    required this.kategoriId,
  });

  factory Info.fromJson(Map<String, dynamic> json) {
    return Info(
      id: json['id'] ?? 0,
      judul: json['judul'] ?? '',
      isi: json['isi'] ?? '',
      ringkasan: json['ringkasan'] ?? '',
      status: json['status'] ?? '',
      userId: json['user_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      file: json['file'] ?? '',
      kategori: json['kategori'] != null ? json['kategori']['judul'] ?? '' : '',
      kategoriId: json['KategoriID'] ?? 0,
    );
  }
}

