import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class KategoriScreen extends StatefulWidget {
  @override
  _KategoriScreenState createState() => _KategoriScreenState();
}

class _KategoriScreenState extends State<KategoriScreen> {
  List<Kategori> kategoriList = [];
  bool isLoading = true;
  bool isGuest = false;

  @override
  void initState() {
    super.initState();
    _checkGuestStatus();
    fetchKategori();
  }

  Future<void> _checkGuestStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isGuest = prefs.getBool('is_guest') ?? false;
    });
  }

  Future<void> fetchKategori() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final isGuest = prefs.getBool('is_guest') ?? false;
      
      if (isGuest) {
        final response = await http.get(
          Uri.parse('http://10.0.2.2/Web_Gallery/public/api/kategori'),
          headers: {
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          if (responseData['status'] == 'success') {
            List<dynamic> data = responseData['data'];
            setState(() {
              kategoriList = data.map((json) => Kategori.fromJson(json)).toList();
              isLoading = false;
            });
          }
        }
        return;
      }

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
            kategoriList = data.map((json) => Kategori.fromJson(json)).toList();
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching kategori: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void showAddEditKategoriModal({Kategori? kategori}) {
    final judulController = TextEditingController(text: kategori?.judul);

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
                  kategori == null ? 'Tambah Kategori' : 'Edit Kategori',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: judulController,
                  decoration: InputDecoration(
                    labelText: 'Judul Kategori',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      if (kategori == null) {
                        await addKategori(judulController.text);
                      } else {
                        await updateKategori(kategori.id, judulController.text);
                      }
                      Navigator.pop(context);
                      fetchKategori();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  child: Text(kategori == null ? 'Tambah' : 'Update'),
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

  Future<void> addKategori(String judul) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('http://10.0.2.2/Web_Gallery/public/api/kategori'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'judul': judul,
        }),
      );

      if (response.statusCode == 401) {
        Navigator.of(context).pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      }

      if (response.statusCode != 201) {
        throw Exception('Failed to add kategori');
      }
    } catch (e) {
      print('Error adding kategori: $e');
      throw e;
    }
  }

  Future<void> updateKategori(int id, String judul) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('http://10.0.2.2/Web_Gallery/public/api/kategori/$id'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'judul': judul,
        }),
      );

      if (response.statusCode == 401) {
        Navigator.of(context).pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to update kategori');
      }
    } catch (e) {
      print('Error updating kategori: $e');
      throw e;
    }
  }

  Future<void> deleteKategori(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('http://10.0.2.2/Web_Gallery/public/api/kategori/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        Navigator.of(context).pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to delete kategori');
      }
    } catch (e) {
      print('Error deleting kategori: $e');
      throw e;
    }
  }

  void confirmDelete(Kategori kategori) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content: Text('Yakin ingin menghapus kategori "${kategori.judul}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await deleteKategori(kategori.id);
                  Navigator.pop(context);
                  fetchKategori();
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
        title: Text('Kategori'),
        actions: [
          if (!isGuest)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => showAddEditKategoriModal(),
            ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: kategoriList.length,
              itemBuilder: (context, index) {
                final kategori = kategoriList[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(
                      kategori.judul,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: !isGuest
                        ? PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                showAddEditKategoriModal(kategori: kategori);
                              } else if (value == 'delete') {
                                confirmDelete(kategori);
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
                  ),
                );
              },
            ),
    );
  }
}

class Kategori {
  final int id;
  final String judul;
  final String? createdAt;
  final String? updatedAt;

  Kategori({
    required this.id,
    required this.judul,
    this.createdAt,
    this.updatedAt,
  });

  factory Kategori.fromJson(Map<String, dynamic> json) {
    return Kategori(
      id: json['KategoriID'] ?? 0,
      judul: json['judul'] ?? '',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
} 