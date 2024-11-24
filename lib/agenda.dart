import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AgendaScreen extends StatefulWidget {
  @override
  _AgendaScreenState createState() => _AgendaScreenState();
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

class _AgendaScreenState extends State<AgendaScreen> {
  List<Agenda> agendaList = [];
  List<Agenda> filteredAgendaList = [];
  List<KategoriOption> kategoriOptions = [];
  bool isLoading = true;
  bool isGuest = false;
  TextEditingController searchController = TextEditingController();
  int? selectedKategoriId;

  @override
  void initState() {
    super.initState();
    _checkGuestStatus();
    fetchAgenda();
    fetchKategori();
    searchController.addListener(_filterAgenda);
  }

  void _filterAgenda() {
    String searchTerm = searchController.text.toLowerCase();
    setState(() {
      filteredAgendaList = agendaList.where((agenda) {
        bool matchesSearch = searchTerm.isEmpty ||
            agenda.judul.toLowerCase().contains(searchTerm) ||
            agenda.isi.toLowerCase().contains(searchTerm) ||
            agenda.kategori.toLowerCase().contains(searchTerm);

        bool matchesKategori = selectedKategoriId == null ||
            agenda.kategoriId == selectedKategoriId;

        return matchesSearch && matchesKategori;
      }).toList();
    });
  }

  Future<void> _checkGuestStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isGuest = prefs.getBool('is_guest') ?? false;
    });
  }

  Future<void> fetchAgenda() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final isGuest = prefs.getBool('is_guest') ?? false;
      
      final response = await http.get(
        Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0077534259/Web_Gallery/public/api/agenda'),
        headers: {
          'Accept': 'application/json',
          if (!isGuest && token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          agendaList = data.map((json) => Agenda.fromJson(json)).toList();
          filteredAgendaList = List.from(agendaList);
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        throw Exception('Failed to load agenda');
      }
    } catch (e) {
      print("Error fetching agenda: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchKategori() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.get(
        Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0077534259/Web_Gallery/public/api/kategori'),
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
            kategoriOptions = data.map((json) => KategoriOption.fromJson(json)).toList();
          });
        }
      }
    } catch (e) {
      print("Error fetching kategori: $e");
    }
  }

  void showAddEditAgendaModal({Agenda? agenda}) {
    final titleController = TextEditingController(text: agenda?.judul);
    final contentController = TextEditingController(text: agenda?.isi);
    final statusController = TextEditingController(text: agenda?.status);
    int? selectedKategoriId = agenda?.kategoriId;

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
                      agenda == null ? 'Tambah Agenda' : 'Edit Agenda',
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
                    ElevatedButton(
                      onPressed: () async {
                        if (selectedKategoriId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Silakan pilih kategori')),
                          );
                          return;
                        }

                        try {
                          if (agenda == null) {
                            await addAgenda(
                              titleController.text,
                              contentController.text,
                              statusController.text,
                              selectedKategoriId!,
                            );
                          } else {
                            await updateAgenda(
                              agenda.id,
                              titleController.text,
                              contentController.text,
                              statusController.text,
                              selectedKategoriId!,
                            );
                          }
                          Navigator.pop(context);
                          fetchAgenda();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                      child: Text(agenda == null ? 'Tambah' : 'Update'),
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

  void showAgendaDetail(Agenda agenda) {
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
                Text(
                  agenda.judul,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  agenda.isi,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Status: ${agenda.status}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Kategori: ${agenda.kategori}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 16),
                Center(
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

  Future<void> addAgenda(String judul, String isi, String status, int kategoriId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0077534259/Web_Gallery/public/api/agenda'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'judul': judul,
          'isi': isi,
          'status': status,
          'KategoriID': kategoriId,
          'user_id': 1, // Sesuaikan dengan user ID yang sedang login
        }),
      );

      if (response.statusCode == 401) {
        Navigator.of(context).pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      }

      if (response.statusCode != 201) {
        throw Exception('Failed to add agenda');
      }
    } catch (e) {
      print('Error adding agenda: $e');
      throw e;
    }
  }

  Future<void> updateAgenda(int id, String judul, String isi, String status, int kategoriId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0077534259/Web_Gallery/public/api/agenda/$id'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'judul': judul,
          'isi': isi,
          'status': status,
          'KategoriID': kategoriId,
          'user_id': 1, // Sesuaikan dengan user ID yang sedang login
        }),
      );

      if (response.statusCode == 401) {
        Navigator.of(context).pushReplacementNamed('/login');
        throw Exception('Unauthorized');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to update agenda');
      }
    } catch (e) {
      print('Error updating agenda: $e');
      throw e;
    }
  }

  Future<void> deleteAgenda(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('https://ujikom2024pplg.smkn4bogor.sch.id/0077534259/Web_Gallery/public/api/agenda/$id'),
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
        throw Exception('Failed to delete agenda');
      }
    } catch (e) {
      print('Error deleting agenda: $e');
      throw e;
    }
  }

  void confirmDelete(Agenda agenda) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content: Text('Yakin ingin menghapus agenda "${agenda.judul}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await deleteAgenda(agenda.id);
                  Navigator.pop(context);
                  fetchAgenda();
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
        title: Text('Agenda'),
        actions: [
          if (!isGuest)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => showAddEditAgendaModal(),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Agenda',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  width: 150,
                  child: DropdownButtonFormField<int>(
                    value: selectedKategoriId,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
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
                    onChanged: (value) {
                      setState(() {
                        selectedKategoriId = value;
                        _filterAgenda();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredAgendaList.length,
                    itemBuilder: (context, index) {
                      final agenda = filteredAgendaList[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          title: Text(
                            agenda.judul,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                agenda.isi,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Status: ${agenda.status} | Kategori: ${agenda.kategori}',
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
                                      showAddEditAgendaModal(agenda: agenda);
                                    } else if (value == 'delete') {
                                      confirmDelete(agenda);
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
                          onTap: () => showAgendaDetail(agenda),
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

class Agenda {
  final int id;
  final String judul;
  final String isi;
  final String status;
  final int userId;
  final String kategori;
  final int kategoriId;

  Agenda({
    required this.id,
    required this.judul,
    required this.isi,
    required this.status,
    required this.userId,
    required this.kategori,
    required this.kategoriId,
  });

  factory Agenda.fromJson(Map<String, dynamic> json) {
    return Agenda(
      id: json['id'] ?? 0,
      judul: json['judul'] ?? '',
      isi: json['isi'] ?? '',
      status: json['status'] ?? '',
      userId: json['user_id'] ?? 0,
      kategori: json['kategori'] != null ? json['kategori']['judul'] ?? '' : '',
      kategoriId: json['KategoriID'] ?? 0,
    );
  }
}
