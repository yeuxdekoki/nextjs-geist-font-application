// Import necessary Flutter packages and services
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';

/// Entry point of the application
/// Initializes Firebase and runs the My Skincare Harmony app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  runApp(const MySkincareHarmonyApp());
}

/// Main application widget with enhanced theme and state management
/// Integrates Provider for state management and Firebase for backend services
class MySkincareHarmonyApp extends StatelessWidget {
  const MySkincareHarmonyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme provider for dark/light mode
        ChangeNotifierProvider(create: (_) => ThemeProvider()..initTheme()),
        // Auth service provider
        Provider<AuthService>(create: (_) => AuthService()),
        // Database service provider
        Provider<DatabaseService>(create: (_) => DatabaseService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'My Skincare Harmony',
            // Dynamic theme based on user preference
            theme: themeProvider.currentTheme,
            // Apply Google Fonts globally
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  textTheme: GoogleFonts.helveticaTextTheme(
                    Theme.of(context).textTheme,
                  ),
                ),
                child: child!,
              );
            },
            // Set auth wrapper as initial screen
            home: const AuthWrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

/// Authentication wrapper to handle login state
/// Automatically navigates between login and main app based on auth status
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasData) {
          return const MainPage();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

/// Enhanced login page with real authentication and improved UX
/// Supports email/password and Google Sign-In with error handling
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLogin = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Handle email/password authentication
  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      if (_isLogin) {
        await authService.signInWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await authService.registerWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Handle Google Sign-In
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithGoogle();
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Show error message
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Register'),
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: themeProvider.toggleTheme,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App logo/title
                const SizedBox(height: 40),
                Text(
                  'My Skincare Harmony',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Please enter email';
                    if (!value!.contains('@')) return 'Please enter valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Please enter password';
                    if (value!.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Login/Register button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleEmailAuth,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isLogin ? 'Login' : 'Register'),
                ),
                const SizedBox(height: 16),
                
                // Toggle login/register
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin 
                        ? 'Don\'t have an account? Register'
                        : 'Already have an account? Login',
                  ),
                ),
                const SizedBox(height: 24),
                
                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Google Sign-In button
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: const Icon(Icons.login, color: Colors.red),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Enhanced main navigation page with improved UX and theme support
/// Features animated cards, user profile, and modern design
class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Enhanced navigation card with animations and modern design
  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        elevation: 8,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Handle user logout
  Future<void> _handleLogout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Skincare Harmony'),
        elevation: 0,
        actions: [
          // Theme toggle
          IconButton(
            icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: themeProvider.toggleTheme,
          ),
          // User menu
          PopupMenuButton(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  subtitle: Text(user?.email ?? 'User'),
                ),
              ),
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: _handleLogout,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Welcome header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take care of your skin with smart reminders',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // Feature cards
            _buildFeatureCard(
              title: 'Sunscreen Reminder',
              subtitle: 'UV-based protection timing',
              icon: Icons.wb_sunny,
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SunscreenReminderPage()),
              ),
            ),
            
            _buildFeatureCard(
              title: 'Skincare Cabinet',
              subtitle: 'Track product expiration',
              icon: Icons.inventory_2,
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SkincareCabinetPage()),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// Import packages for location services, HTTP requests, and async operations
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

/// Sunscreen Reminder page that provides UV-based sunscreen reapplication timing
/// Integrates location services, UV index data, and personalized skin type settings
class SunscreenReminderPage extends StatefulWidget {
  const SunscreenReminderPage({Key? key}) : super(key: key);

  @override
  _SunscreenReminderPageState createState() => _SunscreenReminderPageState();
}

/// State class for Sunscreen Reminder functionality
/// Manages location data, UV index fetching, and timer calculations
class _SunscreenReminderPageState extends State<SunscreenReminderPage> {
  // Location service instance for getting user's current position
  Location location = Location();
  LocationData? _locationData;
  
  // UV index data and status message
  double? _uvIndex;
  String _reminderMessage = 'Fetching UV data...';

  // User preferences for personalized calculations
  int _selectedFitzpatrick = 1; // Fitzpatrick skin type scale (1-6)
  int _selectedSPF = 30; // Selected SPF or PA value
  bool _isSPFScale = true; // Toggle between SPF and PA scale

  @override
  void initState() {
    super.initState();
    // Initialize location services when page loads
    initLocation();
  }

  /// Initialize location services and request necessary permissions
  /// Handles location service enablement and permission requests
  Future<void> initLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    // Check if location services are enabled on the device
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        setState(() {
          _reminderMessage = 'Location services are disabled.';
        });
        return;
      }
    }

    // Check and request location permissions
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        setState(() {
          _reminderMessage = 'Location permission denied.';
        });
        return;
      }
    }

    // Get current location and fetch UV data
    _locationData = await location.getLocation();
    fetchUVIndex();
  }

  /// Fetch UV index data from OpenUV API based on current location
  /// Makes HTTP request to get real-time UV index for user's position
  Future<void> fetchUVIndex() async {
    if (_locationData == null) {
      setState(() {
        _reminderMessage = 'Unable to get location data.';
      });
      return;
    }

    final lat = _locationData!.latitude;
    final lon = _locationData!.longitude;

    // OpenUV API configuration (requires API key)
    const apiKey = 'YOUR_OPENUV_API_KEY';
    final url = Uri.parse('https://api.openuv.io/api/v1/uv?lat=\$lat&lng=\$lon');

    try {
      // Make HTTP request to fetch UV index data
      final response = await http.get(url, headers: {'x-access-token': apiKey});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _uvIndex = data['result']['uv'];
          _reminderMessage = 'Current UV Index: \${_uvIndex?.toStringAsFixed(1)}';
        });
      } else {
        setState(() {
          _reminderMessage = 'Failed to fetch UV data.';
        });
      }
    } catch (e) {
      setState(() {
        _reminderMessage = 'Error fetching UV data.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with page title
      appBar: AppBar(
        title: const Text('My Sunscreen Reminder'),
      ),
      // Main content area with UV data display and user controls
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display current UV index or status message
            Text(
              _reminderMessage,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 24),
            // Fitzpatrick skin type selection section
            const Text(
              'Select Fitzpatrick Skin Type:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            // Choice chips for Fitzpatrick scale (1-6)
            Wrap(
              spacing: 8,
              children: List<Widget>.generate(6, (int index) {
                final type = index + 1;
                return ChoiceChip(
                  label: Text(type.toString()),
                  selected: _selectedFitzpatrick == type,
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedFitzpatrick = selected ? type : _selectedFitzpatrick;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 24),
            // Sunscreen protection scale selection
            const Text(
              'Select Sunscreen Protection:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            // Toggle between SPF and PA scales
            Row(
              children: [
                ChoiceChip(
                  label: const Text('SPF'),
                  selected: _isSPFScale,
                  onSelected: (bool selected) {
                    setState(() {
                      _isSPFScale = true;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('PA'),
                  selected: !_isSPFScale,
                  onSelected: (bool selected) {
                    setState(() {
                      _isSPFScale = false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Dynamic choice chips for SPF or PA values
            Wrap(
              spacing: 8,
              children: _isSPFScale
                  // SPF scale options (5, 10, 15, ... 75)
                  ? List<Widget>.generate(15, (int index) {
                      final spf = (index + 1) * 5;
                      return ChoiceChip(
                        label: Text('SPF \$spf'),
                        selected: _selectedSPF == spf,
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedSPF = spf;
                          });
                        },
                      );
                    })
                  // PA scale options (PA+, PA++, PA+++, etc.)
                  : List<Widget>.generate(6, (int index) {
                      final pa = index + 1;
                      return ChoiceChip(
                        label: Text('PA+\${'+' * pa}'),
                        selected: _selectedSPF == pa,
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedSPF = pa;
                          });
                        },
                      );
                    }),
            ),
            const SizedBox(height: 24),
            // Calculate timer button that shows result in dialog
            ElevatedButton(
              onPressed: () {
                final timerMinutes = calculateReapplicationTimer();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reapplication Timer'),
                    content: Text('Reapply sunscreen in \$timerMinutes minutes.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Calculate Reapplication Timer'),
            ),
          ],
         ),
       ),
       // Floating action button to refresh UV index data
       floatingActionButton: FloatingActionButton(
         onPressed: fetchUVIndex,
         tooltip: 'Refresh UV Index',
         child: const Icon(Icons.refresh),
       ),
     );
   }

  /// Calculate sunscreen reapplication timer based on UV index, skin type, and SPF
  /// Implements custom algorithm with rounding rules as per app specifications
  int calculateReapplicationTimer() {
    if (_uvIndex == null) return 0;

    // Base protection time in minutes
    int baseTime = 120;

    // Adjust base time based on UV index intensity
    // Higher UV index requires more frequent reapplication
    if (_uvIndex! >= 8) {
      baseTime = 60;  // Very high UV
    } else if (_uvIndex! >= 6) {
      baseTime = 90;  // High UV
    } else if (_uvIndex! >= 3) {
      baseTime = 120; // Moderate UV
    } else {
      baseTime = 180; // Low UV
    }

    // Adjust based on Fitzpatrick skin type
    // Lighter skin types need more frequent reapplication
    switch (_selectedFitzpatrick) {
      case 1:
      case 2:
        // Very fair to fair skin - reduce protection time
        baseTime = (baseTime * 0.8).toInt();
        break;
      case 3:
      case 4:
        // Medium skin - standard protection time
        baseTime = baseTime;
        break;
      case 5:
      case 6:
        // Dark to very dark skin - extend protection time
        baseTime = (baseTime * 1.2).toInt();
        break;
      default:
        baseTime = baseTime;
    }

    // Adjust based on sunscreen protection factor
    if (_isSPFScale) {
      // SPF scale adjustment (normalized to SPF 30)
      baseTime = (baseTime * (_selectedSPF / 30)).toInt();
    } else {
      // PA scale adjustment (approximate multiplier)
      baseTime = (baseTime * (1 + _selectedSPF)).toInt();
    }

    // Apply custom rounding rules as specified
    int roundedTime = roundDownTimer(baseTime);

    return roundedTime;
  }

  /// Apply custom rounding rules for timer values
  /// Rounds down for safety unless minutes end with 8
  int roundDownTimer(int minutes) {
    int lastDigit = minutes % 10;
    // Special case: don't round down if minutes end with 8
    if ([8, 18, 28, 38, 48, 58].contains(minutes % 60)) {
      return minutes;
    }
    // Round down to nearest 10 for safety
    if (lastDigit >= 0 && lastDigit < 8) {
      return minutes - lastDigit;
    }
    return minutes;
  }
}

// Import packages for date formatting and UI components
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Skincare Cabinet page for tracking cosmetic product expiration dates
/// Manages product inventory with PAO (Period After Opening) calculations
class SkincareCabinetPage extends StatefulWidget {
  const SkincareCabinetPage({Key? key}) : super(key: key);

  @override
  _SkincareCabinetPageState createState() => _SkincareCabinetPageState();
}

/// Data model for cosmetic products with expiration tracking
/// Stores product information and calculates expiration dates based on PAO
class CosmeticProduct {
  String name;
  DateTime openDate;
  int paoDays; // Period After Opening in days

  CosmeticProduct({
    required this.name,
    required this.openDate,
    required this.paoDays,
  });

  /// Calculate expiration date by adding PAO days to open date
  DateTime get expirationDate => openDate.add(Duration(days: paoDays));

  /// Calculate remaining days until expiration
  /// Returns negative value if already expired
  int daysUntilExpiration() {
    final now = DateTime.now();
    return expirationDate.difference(now).inDays;
  }
}

/// State class for Skincare Cabinet functionality
/// Manages product list, form inputs, and expiration reminders
class _SkincareCabinetPageState extends State<SkincareCabinetPage> {
  // List to store all added cosmetic products
  final List<CosmeticProduct> _products = [];

  // Form controllers and state variables
  final _nameController = TextEditingController();
  DateTime? _selectedOpenDate;
  int? _selectedPaoDays;

  // Predefined PAO options in days (1 month to 1 year)
  final List<int> _paoOptions = [30, 60, 90, 180, 365];

  @override
  void dispose() {
    // Clean up text controller to prevent memory leaks
    _nameController.dispose();
    super.dispose();
  }

  /// Show date picker for selecting product open date
  /// Restricts selection to past dates only
  Future<void> _selectOpenDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedOpenDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // Can't select future dates
    );
    if (picked != null && picked != _selectedOpenDate) {
      setState(() {
        _selectedOpenDate = picked;
      });
    }
  }

  /// Add new product to the cabinet
  /// Validates all required fields before adding
  void _addProduct() {
    // Validate that all fields are filled
    if (_nameController.text.isEmpty || _selectedOpenDate == null || _selectedPaoDays == null) {
      return;
    }
    setState(() {
      // Create and add new product
      _products.add(CosmeticProduct(
        name: _nameController.text,
        openDate: _selectedOpenDate!,
        paoDays: _selectedPaoDays!,
      ));
      // Reset form fields after adding
      _nameController.clear();
      _selectedOpenDate = null;
      _selectedPaoDays = null;
    });
  }

  /// Format date for display in consistent format
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with page title
      appBar: AppBar(
        title: const Text('My Skincare Cabinet'),
      ),
      // Main content with product form and list
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Product name input field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // Open date selection row
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedOpenDate == null
                        ? 'Select Open Date'
                        : 'Open Date: \${_formatDate(_selectedOpenDate!)}',
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _selectOpenDate(context),
                  child: const Text('Choose Date'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // PAO (Period After Opening) dropdown selection
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Period After Opening (days)',
                border: OutlineInputBorder(),
              ),
              value: _selectedPaoDays,
              items: _paoOptions
                  .map((days) => DropdownMenuItem<int>(
                        value: days,
                        child: Text('\$days days'),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPaoDays = value;
                });
              },
            ),
            const SizedBox(height: 12),
            // Add product button
            ElevatedButton(
              onPressed: _addProduct,
              child: const Text('Add Product'),
            ),
            const SizedBox(height: 24),
            // Product list display with expiration tracking
            Expanded(
              child: _products.isEmpty
                  ? const Center(child: Text('No products added yet.'))
                  : ListView.builder(
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        final daysLeft = product.daysUntilExpiration();
                        return ListTile(
                          title: Text(product.name),
                          subtitle: Text(
                              'Expires on: \${_formatDate(product.expirationDate)} (\$daysLeft days left)'),
                          // Show reminder indicator for products expiring soon
                          // Red for 3 days or less, orange for 14 days or less
                          trailing: daysLeft <= 14
                              ? Text(
                                  'Reminder',
                                  style: TextStyle(
                                    color: daysLeft <= 3 ? Colors.red : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
