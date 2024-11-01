import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'agenda.dart';
import 'info.dart';
import 'album.dart';
import 'galery.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? homeData;
  bool isLoading = true;
  bool isGuest = false;

  @override
  void initState() {
    super.initState();
    _checkGuestStatus();
    fetchHomeData();
  }

  Future<void> _checkGuestStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isGuest = prefs.getBool('is_guest') ?? false;
    });
  }

  Future<void> fetchHomeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final isGuest = prefs.getBool('is_guest') ?? false;
      
      if (isGuest) {
        final response = await http.get(
          Uri.parse('http://10.0.2.2/Web_Gallery/public/api/home'),
          headers: {
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          if (responseData['status'] == 'success' && responseData['data'] != null) {
            setState(() {
              homeData = responseData['data'];
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
        Uri.parse('http://10.0.2.2/Web_Gallery/public/api/home'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Home Response Status: ${response.statusCode}');
      print('Home Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success' && responseData['data'] != null) {
          setState(() {
            homeData = responseData['data'];
            isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      print("Error fetching home data: $e");
      setState(() {
        isLoading = false;
      });
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

  Future<String?> fetchMapPhoto() async {
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
        );

        if (response.statusCode == 200) {
          List<dynamic> data = jsonDecode(response.body);
          var mapPhoto = data.firstWhere(
            (photo) => photo['judul'].toString().toLowerCase().contains('map') || 
                       photo['judul'].toString().toLowerCase().contains('denah'),
            orElse: () => null,
          );
          
          if (mapPhoto != null) {
            return mapPhoto['file'];
          }
        }
        return null;
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
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        var mapPhoto = data.firstWhere(
          (photo) => photo['judul'].toString().toLowerCase().contains('map') || 
                     photo['judul'].toString().toLowerCase().contains('denah'),
          orElse: () => null,
        );
        
        if (mapPhoto != null) {
          return mapPhoto['file'];
        }
      }
      return null;
    } catch (e) {
      print("Error fetching map photo: $e");
      return null;
    }
  }

  Widget _buildStatCard(String title, dynamic count, IconData icon, Color color) {
    final displayCount = count != null ? count.toString() : '0';
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.8), color],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.white),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              displayCount,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSection(String title, List<dynamic>? items, IconData icon, String type) {
    if (items == null || items.isEmpty) {
      return SizedBox.shrink();
    }

    String getTitle(dynamic item) {
      switch (type) {
        case 'agenda':
        case 'informasi':
          return item['judul'] ?? '';
        case 'album':
          return item['Nama'] ?? '';
        case 'foto':
          return item['judul'] ?? '';
        default:
          return '';
      }
    }

    String getSubtitle(dynamic item) {
      switch (type) {
        case 'agenda':
        case 'informasi':
          return item['kategori'] != null ? item['kategori']['judul'] ?? '' : '';
        case 'album':
          return item['kategori'] != null ? item['kategori']['judul'] ?? '' : '';
        case 'foto':
          return item['album'] != null ? item['album']['Nama'] ?? '' : '';
        default:
          return '';
      }
    }

    void navigateToDetail(dynamic item) {
      switch (type) {
        case 'agenda':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AgendaScreen(),
            ),
          ).then((_) => fetchHomeData());
          break;
        case 'informasi':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InfoScreen(),
            ),
          ).then((_) => fetchHomeData());
          break;
        case 'album':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AlbumScreen(),
            ),
          ).then((_) => fetchHomeData());
          break;
        case 'foto':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GaleryScreen(),
            ),
          ).then((_) => fetchHomeData());
          break;
      }
    }

    void navigateToList() {
      switch (type) {
        case 'agenda':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AgendaScreen()),
          ).then((_) => fetchHomeData());
          break;
        case 'informasi':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => InfoScreen()),
          ).then((_) => fetchHomeData());
          break;
        case 'album':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AlbumScreen()),
          ).then((_) => fetchHomeData());
          break;
        case 'foto':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GaleryScreen()),
          ).then((_) => fetchHomeData());
          break;
      }
    }

    return Card(
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: navigateToList,
                  child: Text(
                    'Lihat Semua',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: items.length > 5 ? 5 : items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(
                  getTitle(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  getSubtitle(item),
                  style: TextStyle(fontSize: 12),
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => navigateToDetail(item),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard() {
    return FutureBuilder<String?>(
      future: fetchMapPhoto(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            margin: EdgeInsets.all(8),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return Card(
          margin: EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.map, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Denah Sekolah',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (snapshot.hasData)
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        child: Container(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.network(
                                snapshot.data!,
                                fit: BoxFit.contain,
                              ),
                              SizedBox(height: 16),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Close'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    child: Image.network(
                      snapshot.data!,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  height: 200,
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      'Denah tidak tersedia',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (homeData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No data available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            TextButton(
              onPressed: fetchHomeData,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    final stats = homeData!['total_stats'] ?? {};

    return RefreshIndicator(
      onRefresh: fetchHomeData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard('Agenda', stats['total_agendas'], Icons.event, Colors.blue),
                _buildStatCard('Informasi', stats['total_informasi'], Icons.info, Colors.green),
                _buildStatCard('Album', stats['total_albums'], Icons.photo_album, Colors.orange),
                _buildStatCard('Foto', stats['total_fotos'], Icons.photo_library, Colors.purple),
                _buildStatCard('Kategori', stats['total_kategoris'], Icons.category, Colors.teal),
              ],
            ),
            SizedBox(height: 24),
            Text(
              'Recent Updates',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _buildRecentSection('Recent Agenda', homeData!['agendas'], Icons.event, 'agenda'),
            _buildRecentSection('Recent Informasi', homeData!['informasi'], Icons.info, 'informasi'),
            _buildRecentSection('Recent Albums', homeData!['albums'], Icons.photo_album, 'album'),
            _buildRecentSection('Recent Photos', homeData!['fotos'], Icons.photo_library, 'foto'),
            SizedBox(height: 24),
            _buildMapCard(),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
