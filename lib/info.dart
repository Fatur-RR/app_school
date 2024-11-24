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
  List<Info> filteredInfoList = [];
  List<KategoriOption> kategoriOptions = [];
  File? _selectedImage;
  bool isLoading = true;
  bool isGuest = false;
  TextEditingController searchController = TextEditingController();
  int? selectedKategoriFilter;

  @override
  void initState() {
    super.initState();
    _checkGuestStatus();
    fetchInfo();
    fetchKategori();
  }

  void filterInfo(String query) {
    setState(() {
      filteredInfoList = infoList.where((info) {
        bool matchesSearch =
            info.judul.toLowerCase().contains(query.toLowerCase()) ||
                info.ringkasan.toLowerCase().contains(query.toLowerCase());
        bool matchesKategori = selectedKategoriFilter == null ||
            info.kategoriId == selectedKategoriFilter;
        return matchesSearch && matchesKategori;
      }).toList();
    });
  }

  void filterByKategori(int? kategoriId) {
    setState(() {
      selectedKategoriFilter = kategoriId;
      if (kategoriId == null) {
        filteredInfoList = infoList;
      } else {
        filteredInfoList =
            infoList.where((info) => info.kategoriId == kategoriId).toList();
      }
      // Re-apply search filter if there's text in search
      if (searchController.text.isNotEmpty) {
        filterInfo(searchController.text);
      }
    });
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

      final response = await http.get(
        Uri.parse(
            'https://ujikom2024pplg.smkn4bogor.sch.id/0077534259/Web_Gallery/public/api/informasi'),
        headers: {
          'Accept': 'application/json',
          if (!isGuest && token != null) 'Authorization': 'Bearer $token',
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
          filteredInfoList = infoList;
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

  Future<void> fetchKategori() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(
            'https://ujikom2024pplg.smkn4bogor.sch.id/0077534259/Web_Gallery/public/api/kategori'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          List<dynamic> data = responseData['data'];
          setState(() {
            kategoriOptions =
                data.map((json) => KategoriOption.fromJson(json)).toList();
          });
        }
      }
    } catch (e) {
      print("Error fetching kategori: $e");
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
    int? selectedKategoriId = info?.kategoriId;

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
                      info == null ? 'Tambah Informasi' : 'Edit Informasi',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    DropdownButtonFormField<int>(
                      value: selectedKategoriId,
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                      label: Text(_selectedImage != null
                          ? 'Ganti Gambar'
                          : 'Pilih Gambar'),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (selectedKategoriId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Silakan pilih kategori')),
                          );
                          return;
                        }

                        try {
                          if (info == null) {
                            await addInfo(
                              titleController.text,
                              contentController.text,
                              summaryController.text,
                              statusController.text,
                              selectedKategoriId!,
                            );
                          } else {
                            await updateInfo(
                              info.id,
                              titleController.text,
                              contentController.text,
                              summaryController.text,
                              statusController.text,
                              selectedKategoriId!,
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
      },
    );
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> addInfo(String judul, String isi, String ringkasan,
      String status, int kategoriId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://ujikom2024pplg.smkn4bogor.sch.id/0077534259/Web_Gallery/public/api/informasi'),
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

  Future<void> updateInfo(int id, String judul, String isi, String ringkasan,
      String status, int kategoriId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://ujikom2024pplg.smkn4bogor.sch.id/0077534259/Web_Gallery/public/api/informasi/$id'),
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
      Uri.parse(
          'https://ujikom2024pplg.smkn4bogor.sch.id/0077534259/Web_Gallery/public/api/informasi/$id'),
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
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Cari Informasi',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    onChanged: filterInfo,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<int>(
                    value: selectedKategoriFilter,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    ),
                    items: [
                      DropdownMenuItem<int>(
                        value: null,
                        child: Text('Semua'),
                      ),
                      ...kategoriOptions.map((kategori) {
                        return DropdownMenuItem(
                          value: kategori.id,
                          child: Text(kategori.judul),
                        );
                      }).toList(),
                    ],
                    onChanged: filterByKategori,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredInfoList.length,
              itemBuilder: (context, index) {
                final info = filteredInfoList[index];
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
                                child: Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          )
                        : null,
                    onTap: () => showInfoDetail(info),
                  ),
                );
              },
            ),
          ),
        ],
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
