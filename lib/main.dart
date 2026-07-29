import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather App',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
      ),
      home: const WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Map<String, dynamic>? weatherData;
  bool isLoading = false;
  String errorMessage = '';
  final TextEditingController cityController = TextEditingController(text: 'Lahore');
  String currentCity = 'Lahore';

  // Time-based background corrected with correct asset paths
  String getTimeBasedImage() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'assets/images/morning_image.jpg';
    } else if (hour >= 12 && hour < 17) {
      return 'assets/images/aftarnoon_image.jpg';
    } else if (hour >= 17 && hour < 20) {
      return 'assets/images/evening_image.jpg';
    } else {
      return 'assets/images/night_images.jpg';
    }
  }

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    final city = cityController.text.trim();
    if (city.isEmpty) {
      setState(() => errorMessage = 'Please enter a city name');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
      currentCity = city;
    });

    try {
      final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key not found');
      }

      final url = 'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';
      final response = await http.get(Uri.parse(url));

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          weatherData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          weatherData = null;
          isLoading = false;
          errorMessage = response.statusCode == 404 ? 'City not found' : 'Request failed';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        weatherData = null;
        isLoading = false;
        errorMessage = 'Check your internet connection';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with time-based image
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                return Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              child: Image.asset(
                getTimeBasedImage(),
                key: ValueKey(getTimeBasedImage()),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => const DefaultGradient(),
              ),
            ),
          ),

          // Overlay Layer (slightly transparent to make text readable)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.6)],
                ),
              ),
            ),
          ),

          // Content Layer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildSearchBar(),
                  const SizedBox(height: 20),
                  Expanded(child: _buildWeatherBody()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.8), // Highly visible
          width: 2.0, // Increased width for better definition
        ),
      ),
      child: TextField(
        controller: cityController,
        textAlignVertical: TextAlignVertical.center, // Centers text vertically
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search city...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          border: InputBorder.none,
            contentPadding: const EdgeInsets.only( bottom: 5), // Adjust for perfect centering
          suffixIcon: IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: fetchWeather,
          ),
        ),
        onSubmitted: (_) => fetchWeather(),
      ),
    );
  }

  Widget _buildWeatherBody() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (errorMessage.isNotEmpty) return _buildErrorState();
    if (weatherData == null) return const Center(child: Text('Search for a city'));

    final temp = weatherData!['main']['temp'];
    final desc = weatherData!['weather'][0]['description'];
    final icon = weatherData!['weather'][0]['icon'];

    return RefreshIndicator(
      onRefresh: fetchWeather,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 40),
          Text(
            '${weatherData!['name']}, ${weatherData!['sys']['country']}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Image.network(
            'https://openweathermap.org/img/wn/$icon@4x.png',
            height: 120,
          ),
          Text(
            '${temp.toStringAsFixed(1)}°C',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 70, fontWeight: FontWeight.w300),
          ),
          Text(
            desc.toString().toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, letterSpacing: 2, color: Colors.white70),
          ),
          const SizedBox(height: 50),
          _buildInfoGrid(),
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.6), // Highly visible
          width: 2.0, // Increased width for better definition
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoItem(Icons.water_drop, '${weatherData!['main']['humidity']}%', 'Humidity'),
          _infoItem(Icons.air, '${weatherData!['wind']['speed']}m/s', 'Wind'),
          _infoItem(Icons.thermostat, '${weatherData!['main']['feels_like']}°', 'Feels Like'),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.blue[300]),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
          const SizedBox(height: 15),
          Text(errorMessage, style: const TextStyle(fontSize: 18)),
          TextButton(onPressed: fetchWeather, child: const Text('Try Again')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cityController.dispose();
    super.dispose();
  }
}

class DefaultGradient extends StatelessWidget {
  const DefaultGradient({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F0C29), Color(0xFF302B63)],
        ),
      ),
    );
  }
}
