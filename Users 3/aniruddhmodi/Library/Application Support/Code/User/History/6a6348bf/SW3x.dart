import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkinScan AI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2),
          brightness: Brightness.light,
        ),
        fontFamily: 'Inter',
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            textStyle: TextStyle(color: Colors.white),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Inter',
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            textStyle: TextStyle(color: Colors.white),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: MainNavigationPage(),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  @override
  _MainNavigationPageState createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    ImageScannerPage(),
    HistoryPage(),
    AboutPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'About',
          ),
        ],
      ),
    );
  }
}

class ImageScannerPage extends StatefulWidget {
  @override
  _ImageScannerPageState createState() => _ImageScannerPageState();
}

class _ImageScannerPageState extends State<ImageScannerPage>
    with TickerProviderStateMixin {
  Uint8List? selectedImage;
  PredictionResult? predictionResult;
  bool isLoading = false;
  late AnimationController _animationController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.isEmpty) return;

      final fileBytes = result.files.first.bytes;
      final filePath = result.files.first.path;

      if (fileBytes != null) {
        setState(() {
          selectedImage = fileBytes;
          predictionResult = null;
        });
      } else if (filePath != null) {
        final imageBytes = await File(filePath).readAsBytes();
        setState(() {
          selectedImage = imageBytes;
          predictionResult = null;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error selecting image: $e');
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image == null) return;

      final imageBytes = await image.readAsBytes();
      setState(() {
        selectedImage = imageBytes;
        predictionResult = null;
      });
    } catch (e) {
      _showErrorSnackbar('Error taking picture: $e');
    }
  }

  Future<void> _sendImage() async {
    if (selectedImage == null) return;

    setState(() {
      isLoading = true;
      predictionResult = null;
    });

    final base64Image = base64Encode(selectedImage!);
    final url = Uri.http('192.168.1.5:8000', '/infer');

    // Debug info
    print('DEBUG: Sending request to: ' + url.toString());
    print('DEBUG: Headers: {"Content-Type": "application/json"}');
    print('DEBUG: Body: ' + jsonEncode({'image': base64Image}).substring(0, 200) + '...'); // Print only first 200 chars

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      );

      print('DEBUG: Response status: ' + response.statusCode.toString());
      print('DEBUG: Response body: ' + response.body);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final result = PredictionResult.fromJson(decoded);
        
        await _saveToHistory(result);
        
        setState(() {
          predictionResult = result;
        });
      } else {
        _showErrorSnackbar('Server Error (' + response.statusCode.toString() + ')');
      }
    } catch (e) {
      print('DEBUG: Exception occurred: ' + e.toString());
      _showErrorSnackbar('Network error occurred');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveToHistory(PredictionResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('prediction_history') ?? [];
    
    final historyEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'disease': result.disease,
      'confidence': result.confidence,
      'description': result.description,
      'severity': result.severity,
      'image': base64Encode(selectedImage!),
    };
    
    historyJson.insert(0, jsonEncode(historyEntry));
    if (historyJson.length > 50) historyJson.removeLast(); // Keep last 50
    
    await prefs.setStringList('prediction_history', historyJson);
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
    );
  }

  void _removeImage() {
    setState(() {
      selectedImage = null;
      predictionResult = null;
    });
  }

  void _navigateToDetailedDiagnosis() {
    if (predictionResult != null && selectedImage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailedDiagnosisPage(
            result: predictionResult!,
            image: selectedImage!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SkinScan AI', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageSection(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            if (isLoading) ...[
              const SizedBox(height: 32),
              _buildLoadingSection(),
            ],
            if (predictionResult != null) ...[
              const SizedBox(height: 32),
              _buildResultSection(),
            ] else if (selectedImage != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: !isLoading ? _sendImage : null,
                icon: Icon(Icons.send),
                label: Text('Analyze Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  textStyle: TextStyle(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        ),
        child: selectedImage != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      selectedImage!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: _removeImage,
                      icon: Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        shape: CircleBorder(),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No image selected',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Choose an image to analyze',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _pickImageFromGallery,
            icon: Icon(Icons.photo_library),
            label: Text('Gallery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              textStyle: TextStyle(color: Colors.white),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _takePicture,
            icon: Icon(Icons.camera_alt),
            label: Text('Camera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              textStyle: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            RotationTransition(
              turns: _animationController,
              child: Icon(
                Icons.refresh,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Analyzing your image...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              'This may take a few seconds',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    if (predictionResult == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _navigateToDetailedDiagnosis,
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _getConfidenceIcon(predictionResult!.confidence),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getConfidenceTitle(predictionResult!),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _getConfidenceColor(predictionResult!.confidence),
                              ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(predictionResult!.confidence).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getConfidenceColor(predictionResult!.confidence).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 20,
                              color: _getConfidenceColor(predictionResult!.confidence),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Confidence: ${predictionResult!.confidence.toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: _getConfidenceColor(predictionResult!.confidence),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          _getConfidenceMessage(predictionResult!),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: _getConfidenceColor(predictionResult!.confidence),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Tap for detailed information',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        Card(
          color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Theme.of(context).colorScheme.error,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '⚠️ This prediction is AI-generated and may not be accurate. Please consult a licensed medical professional before taking any action.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getConfidenceTitle(PredictionResult result) {
    if (result.confidence < 50) {
      return 'Unknown';
    } else if (result.confidence <= 70) {
      return 'Likely: ${result.disease}';
    } else {
      return 'Most Likely: ${result.disease}';
    }
  }

  String _getConfidenceMessage(PredictionResult result) {
    if (result.confidence < 50) {
      return 'The AI is unsure about this condition. Please consult a doctor for an accurate diagnosis.';
    } else if (result.confidence <= 70) {
      return 'This might be ${result.disease}, but we recommend medical consultation to confirm.';
    } else {
      return 'The model strongly suggests this is ${result.disease}. Please verify with a professional.';
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence < 50) {
      return Colors.red;
    } else if (confidence <= 70) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  Widget _getConfidenceIcon(double confidence) {
    if (confidence < 50) {
      return Icon(Icons.warning, color: Colors.red, size: 28);
    } else if (confidence <= 70) {
      return Icon(Icons.help_outline, color: Colors.orange, size: 28);
    } else {
      return Icon(Icons.check_circle, color: Colors.green, size: 28);
    }
  }
}

class DetailedDiagnosisPage extends StatelessWidget {
  final PredictionResult result;
  final Uint8List image;

  const DetailedDiagnosisPage({
    Key? key,
    required this.result,
    required this.image,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detailed Analysis'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and basic info
            Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        image,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        _getConfidenceIcon(result.confidence),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getConfidenceTitle(result),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _getConfidenceColor(result.confidence),
                                ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(result.confidence).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getConfidenceColor(result.confidence).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Confidence: ${result.confidence.toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: _getConfidenceColor(result.confidence),
                                ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _getConfidenceMessage(result),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: _getConfidenceColor(result.confidence),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),

            // Extended Description
            _buildInfoCard(
              context,
              'Description',
              _getExtendedDescription(result.disease),
              Icons.description,
            ),

            SizedBox(height: 16),

            // Symptoms
            _buildInfoCard(
              context,
              'Common Symptoms',
              _getSymptoms(result.disease),
              Icons.sick,
            ),

            SizedBox(height: 16),

            // Risk Factors
            _buildInfoCard(
              context,
              'Risk Factors',
              _getRiskFactors(result.disease),
              Icons.warning_amber,
            ),

            SizedBox(height: 16),

            // Treatments
            _buildInfoCard(
              context,
              'Common Treatments',
              _getTreatments(result.disease),
              Icons.medical_services,
            ),

            SizedBox(height: 16),

            // What to do next
            _buildInfoCard(
              context,
              'What to Do Next',
              _getNextSteps(result.disease, result.confidence),
              Icons.arrow_forward,
            ),

            SizedBox(height: 16),

            // Trusted Links
            Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.link, color: Theme.of(context).colorScheme.primary),
                        SizedBox(width: 12),
                        Text(
                          'Trusted Resources',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ..._getTrustedLinks(result.disease).map((link) => 
                      Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _launchURL(link['url']!),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.open_in_new,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    link['title']!,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).toList(),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Medical Disclaimer
            Card(
              color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.5),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.medical_services,
                          color: Theme.of(context).colorScheme.error,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Medical Disclaimer',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'This is not a medical diagnosis. The information provided is for educational purposes only and should not replace professional medical advice. Always consult with a licensed medical professional for proper diagnosis and treatment of any skin condition.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String content, IconData icon) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for confidence-based messaging
  String _getConfidenceTitle(PredictionResult result) {
    if (result.confidence < 50) {
      return 'Unknown';
    } else if (result.confidence <= 70) {
      return 'Likely: ${result.disease}';
    } else {
      return 'Most Likely: ${result.disease}';
    }
  }

  String _getConfidenceMessage(PredictionResult result) {
    if (result.confidence < 50) {
      return 'The AI is unsure about this condition. Please consult a doctor for an accurate diagnosis.';
    } else if (result.confidence <= 70) {
      return 'This might be ${result.disease}, but we recommend medical consultation to confirm.';
    } else {
      return 'The model strongly suggests this is ${result.disease}. Please verify with a professional.';
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence < 50) {
      return Colors.red;
    } else if (confidence <= 70) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  Widget _getConfidenceIcon(double confidence) {
    if (confidence < 50) {
      return Icon(Icons.warning, color: Colors.red, size: 32);
    } else if (confidence <= 70) {
      return Icon(Icons.help_outline, color: Colors.orange, size: 32);
    } else {
      return Icon(Icons.check_circle, color: Colors.green, size: 32);
    }
  }

  String _getExtendedDescription(String disease) {
    switch (disease.toLowerCase()) {
      case 'acne':
        return 'Acne is a common skin condition that occurs when hair follicles become clogged with oil and dead skin cells. It most commonly appears on the face, forehead, chest, upper back, and shoulders. Acne can range from mild blackheads and whiteheads to more severe cystic lesions. The condition is most prevalent during puberty due to hormonal changes, but it can affect people of all ages.';
      case 'eczema':
        return 'Eczema, also known as atopic dermatitis, is a chronic inflammatory skin condition characterized by red, itchy, and inflamed patches of skin. It often appears in childhood and may persist into adulthood. The condition involves a compromised skin barrier function, making the skin more susceptible to irritants and allergens. Eczema commonly affects the face, hands, elbows, and knees, and can significantly impact quality of life.';
      case 'psoriasis':
        return 'Psoriasis is an autoimmune skin disorder that causes skin cells to multiply rapidly, resulting in thick, scaly, and often silvery patches called plaques. These plaques most commonly appear on the elbows, knees, scalp, and lower back. The condition is chronic and cyclical, with periods of flare-ups and remission. Psoriasis affects about 2-3% of the global population and can also be associated with other health conditions.';
      case 'melanoma':
        return 'Melanoma is the most serious type of skin cancer, developing in melanocytes, the cells that produce melanin (skin pigment). While less common than other skin cancers, melanoma is more likely to spread to other parts of the body if not detected early. It can develop anywhere on the body, including areas not exposed to sun. Early detection and treatment are crucial for successful outcomes.';
      case 'dermatitis':
        return 'Dermatitis is a general term describing inflammation of the skin. There are several types including contact dermatitis (caused by allergens or irritants), seborrheic dermatitis (affecting oily areas), and atopic dermatitis (eczema). Symptoms typically include redness, swelling, itching, and sometimes blistering or scaling. The condition can be acute or chronic depending on the underlying cause.';
      case 'rosacea':
        return 'Rosacea is a chronic inflammatory skin condition that primarily affects the central face, causing persistent redness, visible blood vessels, and sometimes papules and pustules. It typically begins after age 30 and is more common in fair-skinned individuals. The condition can be triggered by various factors including sun exposure, stress, certain foods, and temperature extremes.';
      case 'basal cell carcinoma':
        return 'Basal cell carcinoma is the most common type of skin cancer, arising from the basal cells in the lower part of the epidermis. It typically appears as a small, shiny bump or a flat, scaly patch. While it rarely spreads to other parts of the body, it can cause significant local damage if left untreated. It most commonly occurs on sun-exposed areas of the body.';
      case 'normal':
      case 'healthy':
        return 'The analyzed skin appears healthy with no concerning features detected by the AI model. Healthy skin typically has even tone, smooth texture, and no unusual growths or discoloration. However, regular skin checks and professional evaluations are still recommended as part of routine healthcare.';
      default:
        return 'The AI has detected a potential skin condition that requires professional evaluation. Skin conditions can vary widely in their appearance, causes, and treatment requirements. A dermatologist can provide accurate diagnosis and appropriate treatment recommendations based on clinical examination.';
    }
  }

  String _getSymptoms(String disease) {
    switch (disease.toLowerCase()) {
      case 'acne':
        return '• Blackheads and whiteheads\n• Papules (small red bumps)\n• Pustules (pimples with pus)\n• Nodules (large, painful lumps)\n• Cysts (deep, pus-filled lesions)\n• Scarring in severe cases\n• Oily skin\n• Tenderness around affected areas';
      case 'eczema':
        return '• Intense itching, especially at night\n• Red, inflamed patches\n• Dry, scaly skin\n• Small, raised bumps\n• Thickened, cracked skin\n• Raw, sensitive skin from scratching\n• Weeping or crusting lesions\n• Sleep disturbances due to itching';
      case 'psoriasis':
        return '• Thick, silvery scales\n• Red patches covered with scales\n• Dry, cracked skin that may bleed\n• Itching and burning sensation\n• Thickened or ridged nails\n• Swollen and stiff joints (psoriatic arthritis)\n• Small scaling spots (common in children)';
      case 'melanoma':
        return '• Asymmetrical moles\n• Irregular or scalloped borders\n• Color variations (brown, black, red, white, blue)\n• Diameter larger than 6mm\n• Evolving size, shape, or color\n• New growths or changes in existing moles\n• Itching or tenderness\n• Bleeding or oozing';
      case 'dermatitis':
        return '• Red, inflamed skin\n• Itching or burning sensation\n• Swelling\n• Blisters or bumps\n• Dry, scaly patches\n• Skin sensitivity\n• Oozing or crusting\n• Thickened skin from scratching';
      case 'rosacea':
        return '• Persistent facial redness\n• Visible blood vessels\n• Swollen, red bumps\n• Eye irritation and dryness\n• Burning or stinging sensation\n• Thickened skin (rhinophyma)\n• Facial swelling\n• Sensitivity to skincare products';
      case 'basal cell carcinoma':
        return '• Pearly or waxy bump\n• Flat, flesh-colored or brown scar-like lesion\n• Bleeding or scabbing sore that heals and returns\n• Pink growth with raised border\n• Open sore that doesn\'t heal\n• Shiny, translucent appearance\n• Visible blood vessels in the lesion';
      case 'normal':
      case 'healthy':
        return '• Even skin tone\n• Smooth texture\n• Good elasticity\n• No unusual growths\n• No persistent redness or irritation\n• Proper moisture balance\n• No unexplained changes';
      default:
        return '• Symptoms may vary depending on the specific condition\n• Changes in skin appearance, texture, or color\n• Unusual growths or lesions\n• Persistent irritation or discomfort\n• Any concerning changes should be evaluated by a healthcare professional';
    }
  }

  String _getRiskFactors(String disease) {
    switch (disease.toLowerCase()) {
      case 'acne':
        return '• Hormonal changes (puberty, menstruation, pregnancy)\n• Family history of acne\n• Certain medications\n• High-glycemic diet\n• Stress\n• Certain cosmetics or hair products\n• Excessive scrubbing or harsh treatments\n• Environmental factors (humidity, pollution)';
      case 'eczema':
        return '• Family history of eczema, asthma, or allergies\n• Environmental allergens (dust mites, pollen, pet dander)\n• Irritants (soaps, detergents, fabrics)\n• Food allergies\n• Stress\n• Temperature and humidity changes\n• Infections\n• Early childhood exposure to allergens';
      case 'psoriasis':
        return '• Family history of psoriasis\n• Bacterial or viral infections\n• Stress\n• Skin injuries (cuts, burns, bug bites)\n• Certain medications\n• Smoking and heavy alcohol consumption\n• Obesity\n• Weather conditions (cold, dry weather)';
      case 'melanoma':
        return '• Excessive UV exposure (sun or tanning beds)\n• Fair skin, light hair, light eyes\n• History of sunburns\n• Many moles or unusual moles\n• Family history of melanoma\n• Personal history of skin cancer\n• Weakened immune system\n• Age (risk increases with age)\n• Geographic location (closer to equator)';
      case 'dermatitis':
        return '• Contact with allergens or irritants\n• Sensitive skin\n• Occupational exposure to chemicals\n• Family history of allergies\n• Age (infants and elderly more susceptible)\n• Existing skin conditions\n• Compromised skin barrier\n• Environmental factors';
      case 'rosacea':
        return '• Fair skin\n• Age 30-50\n• Female gender\n• Family history of rosacea\n• Sun exposure\n• Certain foods (spicy, hot foods)\n• Alcohol consumption\n• Stress\n• Extreme temperatures\n• Certain skincare products';
      case 'basal cell carcinoma':
        return '• Chronic sun exposure\n• Fair skin\n• Age over 40\n• Male gender\n• Family history of skin cancer\n• Previous radiation therapy\n• Exposure to arsenic\n• Weakened immune system\n• Certain genetic syndromes';
      case 'normal':
      case 'healthy':
        return '• No specific risk factors identified\n• Maintaining healthy skin through proper care\n• Regular sun protection\n• Avoiding harsh chemicals and irritants\n• Staying hydrated and eating a balanced diet';
      default:
        return '• Risk factors vary depending on the specific condition\n• Sun exposure\n• Genetic predisposition\n• Environmental factors\n• Age and gender\n• Lifestyle factors\n• Consult with a healthcare provider for specific risk assessment';
    }
  }

  String _getTreatments(String disease) {
    switch (disease.toLowerCase()) {
      case 'acne':
        return '• Topical retinoids (tretinoin, adapalene)\n• Benzoyl peroxide\n• Salicylic acid\n• Topical antibiotics (clindamycin)\n• Oral antibiotics for moderate to severe cases\n• Hormonal therapy (for women)\n• Isotretinoin for severe cases\n• Light therapy\n• Chemical peels\n• Proper skincare routine';
      case 'eczema':
        return '• Moisturizers and emollients\n• Topical corticosteroids\n• Topical calcineurin inhibitors\n• Antihistamines for itching\n• Wet wrap therapy\n• Phototherapy (UV light treatment)\n• Systemic immunosuppressants for severe cases\n• Biologic medications\n• Avoiding known triggers\n• Gentle skincare routine';
      case 'psoriasis':
        return '• Topical corticosteroids\n• Vitamin D analogues\n• Topical retinoids\n• Coal tar preparations\n• Moisturizers\n• Phototherapy (UV light)\n• Systemic medications (methotrexate, cyclosporine)\n• Biologic drugs\n• Lifestyle modifications\n• Stress management';
      case 'melanoma':
        return '• Surgical excision\n• Sentinel lymph node biopsy\n• Immunotherapy\n• Targeted therapy\n• Chemotherapy\n• Radiation therapy\n• Clinical trials\n• Regular follow-up monitoring\n• Sun protection\n• Early detection crucial for treatment success';
      case 'dermatitis':
        return '• Identifying and avoiding triggers\n• Topical corticosteroids\n• Moisturizers\n• Cool compresses\n• Antihistamines\n• Topical calcineurin inhibitors\n• Barrier repair creams\n• Gentle cleansing\n• Protective clothing\n• Stress management';
      case 'rosacea':
        return '• Topical metronidazole\n• Topical azelaic acid\n• Oral antibiotics (doxycycline, minocycline)\n• Laser therapy\n• Intense pulsed light (IPL)\n• Sun protection\n• Gentle skincare routine\n• Avoiding known triggers\n• Green-tinted primer for redness';
      case 'basal cell carcinoma':
        return '• Surgical excision\n• Mohs surgery\n• Electrodesiccation and curettage\n• Cryotherapy (freezing)\n• Topical chemotherapy (5-fluorouracil)\n• Topical immune response modifiers\n• Photodynamic therapy\n• Radiation therapy\n• Regular skin cancer screening';
      case 'normal':
      case 'healthy':
        return '• No specific treatment needed\n• Maintain good skincare routine\n• Use sunscreen daily\n• Moisturize regularly\n• Gentle cleansing\n• Stay hydrated\n• Regular skin self-examinations\n• Annual dermatological check-ups';
      default:
        return '• Treatment varies based on specific diagnosis\n• Consult with a dermatologist for proper treatment plan\n• May include topical or oral medications\n• Lifestyle modifications\n• Professional procedures\n• Regular monitoring and follow-up';
    }
  }

  String _getNextSteps(String disease, double confidence) {
    String baseSteps = '';
    String urgencyLevel = '';
    
    if (confidence < 50) {
      urgencyLevel = '• Schedule a dermatologist appointment as soon as possible for accurate diagnosis\n• Take clear photos to track any changes\n• Avoid self-treatment until professional evaluation\n';
    } else if (confidence <= 70) {
      urgencyLevel = '• Schedule a dermatologist appointment within 2-4 weeks\n• Monitor the area for any changes\n• Take photos to document current appearance\n';
    } else {
      urgencyLevel = '• Consult with a dermatologist to confirm the diagnosis\n• Discuss treatment options with a healthcare provider\n• Begin appropriate care as recommended\n';
    }

    switch (disease.toLowerCase()) {
      case 'melanoma':
      case 'basal cell carcinoma':
        baseSteps = '• URGENT: See a dermatologist immediately\n• Do not delay - early treatment is crucial\n• Avoid further sun exposure\n• Take photos to document any changes\n• Prepare list of questions for your doctor';
        break;
      case 'acne':
        baseSteps = '• Start with gentle, consistent skincare routine\n• Avoid picking or squeezing lesions\n• Consider over-the-counter treatments initially\n• Keep a diary of potential triggers\n• Be patient - treatments take 6-12 weeks to show results';
        break;
      case 'eczema':
        baseSteps = '• Identify and avoid known triggers\n• Use fragrance-free, gentle products\n• Moisturize frequently, especially after bathing\n• Keep fingernails short to prevent scratching\n• Consider allergy testing if triggers are unclear';
        break;
      case 'psoriasis':
        baseSteps = '• Avoid known triggers (stress, certain medications)\n• Maintain good skin hydration\n• Consider joining a support group\n• Keep track of flare-ups and potential causes\n• Discuss treatment goals with your doctor';
        break;
      default:
        baseSteps = '• Document any changes in the affected area\n• Avoid harsh products or treatments\n• Protect the area from further irritation\n• Keep the area clean and dry\n• Follow up if symptoms worsen';
    }

    return urgencyLevel + baseSteps + '\n\n• Always consult healthcare professionals for medical advice\n• This AI analysis is for informational purposes only';
  }

  List<Map<String, String>> _getTrustedLinks(String disease) {
    List<Map<String, String>> commonLinks = [
      {
        'title': 'American Academy of Dermatology',
        'url': 'https://www.aad.org/',
      },
      {
        'title': 'Mayo Clinic - Skin Conditions',
        'url': 'https://www.mayoclinic.org/diseases-conditions/skin-conditions/symptoms-causes/syc-20370108',
      },
    ];

    switch (disease.toLowerCase()) {
      case 'acne':
        return [
          ...commonLinks,
          {
            'title': 'Mayo Clinic - Acne',
            'url': 'https://www.mayoclinic.org/diseases-conditions/acne/symptoms-causes/syc-20368047',
          },
          {
            'title': 'WebMD - Acne Resource Center',
            'url': 'https://www.webmd.com/skin-problems-and-treatments/acne/',
          },
        ];
      case 'eczema':
        return [
          ...commonLinks,
          {
            'title': 'National Eczema Association',
            'url': 'https://nationaleczema.org/',
          },
          {
            'title': 'Mayo Clinic - Atopic Dermatitis',
            'url': 'https://www.mayoclinic.org/diseases-conditions/atopic-dermatitis-eczema/symptoms-causes/syc-20353273',
          },
        ];
      case 'psoriasis':
        return [
          ...commonLinks,
          {
            'title': 'National Psoriasis Foundation',
            'url': 'https://www.psoriasis.org/',
          },
          {
            'title': 'Mayo Clinic - Psoriasis',
            'url': 'https://www.mayoclinic.org/diseases-conditions/psoriasis/symptoms-causes/syc-20355840',
          },
        ];
      case 'melanoma':
        return [
          ...commonLinks,
          {
            'title': 'Melanoma Research Foundation',
            'url': 'https://www.melanoma.org/',
          },
          {
            'title': 'American Cancer Society - Melanoma',
            'url': 'https://www.cancer.org/cancer/melanoma-skin-cancer.html',
          },
          {
            'title': 'Mayo Clinic - Melanoma',
            'url': 'https://www.mayoclinic.org/diseases-conditions/melanoma/symptoms-causes/syc-20374884',
          },
        ];
      case 'rosacea':
        return [
          ...commonLinks,
          {
            'title': 'National Rosacea Society',
            'url': 'https://www.rosacea.org/',
          },
          {
            'title': 'Mayo Clinic - Rosacea',
            'url': 'https://www.mayoclinic.org/diseases-conditions/rosacea/symptoms-causes/syc-20353815',
          },
        ];
      case 'basal cell carcinoma':
        return [
          ...commonLinks,
          {
            'title': 'Skin Cancer Foundation - Basal Cell Carcinoma',
            'url': 'https://www.skincancer.org/skin-cancer-information/basal-cell-carcinoma/',
          },
          {
            'title': 'Mayo Clinic - Basal Cell Carcinoma',
            'url': 'https://www.mayoclinic.org/diseases-conditions/basal-cell-carcinoma/symptoms-causes/syc-20354187',
          },
        ];
      default:
        return [
          ...commonLinks,
          {
            'title': 'WebMD - Skin Problems and Treatments',
            'url': 'https://www.webmd.com/skin-problems-and-treatments/',
          },
          {
            'title': 'Healthline - Skin Conditions',
            'url': 'https://www.healthline.com/health/skin-disorders',
          },
        ];
    }
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<HistoryEntry> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('prediction_history') ?? [];
    
    setState(() {
      history = historyJson
          .map((json) => HistoryEntry.fromJson(jsonDecode(json)))
          .toList();
    });
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('prediction_history');
    setState(() {
      history.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          if (history.isNotEmpty)
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Clear History'),
                    content: Text('Are you sure you want to clear all history?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearHistory();
                        },
                        child: Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(Icons.clear_all),
            ),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No predictions yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  Text(
                    'Your scan history will appear here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        base64Decode(entry.image),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      entry.disease,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${entry.confidence.toStringAsFixed(1)}% • ${_formatDate(entry.timestamp)}',
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description:',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 8),
                            Text(entry.description),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What SkinScan AI Does',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'SkinScan AI uses machine learning to analyze skin images and provide preliminary assessments of potential skin conditions. The AI model has been trained on dermatological images to recognize various skin patterns and conditions.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber, 
                          color: Theme.of(context).colorScheme.error
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Important Limitations',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _buildLimitationItem('Accuracy depends on image quality, lighting, and angle'),
                    _buildLimitationItem('May have bias based on training dataset'),
                    _buildLimitationItem('Cannot replace professional medical diagnosis'),
                    _buildLimitationItem('Not suitable for emergency situations'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.5),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.medical_services, 
                          color: Theme.of(context).colorScheme.error
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Medical Disclaimer',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'This tool is NOT a replacement for professional dermatological consultation. Always consult with a licensed dermatologist or healthcare provider for proper diagnosis and treatment of skin conditions.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Best Practices for Use',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: 12),
                    _buildBestPracticeItem('Use in good lighting conditions'),
                    _buildBestPracticeItem('Take clear, focused images'),
                    _buildBestPracticeItem('Use as a preliminary screening tool only'),
                    _buildBestPracticeItem('Seek professional help for concerning results'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitationItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildBestPracticeItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
          SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class PredictionResult {
  final String disease;
  final double confidence;
  final String description;
  final String severity;

  PredictionResult({
    required this.disease,
    required this.confidence,
    required this.description,
    required this.severity,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      disease: json['label'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      description: _getDescriptionForDisease(json['label'] ?? 'Unknown'),
      severity: _getSeverityForDisease(json['label'] ?? 'Unknown'),
    );
  }

  static String _getExtendedDescription(String disease) {
    switch (disease.toLowerCase()) {
      case 'acne':
        return 'Acne is a common skin condition that occurs when hair follicles become clogged with oil and dead skin cells. It most commonly appears on the face, forehead, chest, upper back, and shoulders. Acne can range from mild blackheads and whiteheads to more severe cystic lesions. The condition is most prevalent during puberty due to hormonal changes, but it can affect people of all ages.';
      case 'actinic_keratosis':
      case 'actinic keratosis':
        return 'Actinic keratosis (AK) is a rough, scaly patch on the skin that develops from years of sun exposure. It\'s most commonly found on areas frequently exposed to the sun, such as the face, lips, ears, forearms, scalp, neck, or back of the hands. AKs are considered precancerous because they can develop into squamous cell carcinoma if left untreated. They appear as small, raised spots that feel rough like sandpaper.';
      case 'bullous':
        return 'Bullous disorders are a group of skin conditions characterized by fluid-filled blisters (bullae) that are larger than 5mm in diameter. These can be caused by autoimmune conditions, infections, or drug reactions. The blisters can be painful and may rupture, leading to open sores. Common types include bullous pemphigoid, pemphigus, and epidermolysis bullosa. Treatment varies depending on the underlying cause.';
      case 'candidiasis':
        return 'Candidiasis is a fungal infection caused by Candida yeast, most commonly Candida albicans. On the skin, it typically appears in warm, moist areas like skin folds, under the breasts, in the groin, or between fingers and toes. It presents as red, itchy patches often with satellite lesions around the main area. Candidiasis is more common in people with diabetes, compromised immune systems, or those taking antibiotics.';
      case 'drugeruption':
      case 'drug eruption':
        return 'Drug eruption is an adverse skin reaction to medications. These reactions can range from mild rashes to severe, life-threatening conditions. Common presentations include maculopapular rashes, urticaria (hives), or more serious reactions like Stevens-Johnson syndrome. The rash typically appears days to weeks after starting a new medication. Identifying and discontinuing the causative drug is crucial for treatment.';
      case 'eczema':
        return 'Eczema, also known as atopic dermatitis, is a chronic inflammatory skin condition characterized by red, itchy, and inflamed patches of skin. It often appears in childhood and may persist into adulthood. The condition involves a compromised skin barrier function, making the skin more susceptible to irritants and allergens. Eczema commonly affects the face, hands, elbows, and knees, and can significantly impact quality of life.';
      case 'infestations_bites':
      case 'infestations bites':
        return 'Infestations and bites refer to skin reactions caused by insects, parasites, or arthropods. Common culprits include mosquitoes, fleas, bed bugs, scabies mites, and lice. Reactions can range from small, itchy bumps to larger welts or widespread rashes. The appearance varies depending on the causative organism and individual sensitivity. Some infestations like scabies require specific treatments to eliminate the parasite.';
      case 'lichen':
        return 'Lichen planus is an inflammatory condition that can affect the skin, mucous membranes, nails, and hair. On the skin, it appears as purple, flat-topped, polygonal papules that are often very itchy. The lesions may have white lines called Wickham\'s striae. It commonly affects the wrists, ankles, and lower back. The exact cause is unknown, but it\'s thought to be an autoimmune condition.';
      case 'psoriasis':
        return 'Psoriasis is an autoimmune skin disorder that causes skin cells to multiply rapidly, resulting in thick, scaly, and often silvery patches called plaques. These plaques most commonly appear on the elbows, knees, scalp, and lower back. The condition is chronic and cyclical, with periods of flare-ups and remission. Psoriasis affects about 2-3% of the global population and can also be associated with other health conditions.';
      case 'rosacea':
        return 'Rosacea is a chronic inflammatory skin condition that primarily affects the central face, causing persistent redness, visible blood vessels, and sometimes papules and pustules. It typically begins after age 30 and is more common in fair-skinned individuals. The condition can be triggered by various factors including sun exposure, stress, certain foods, and temperature extremes.';
      case 'seborrh_keratoses':
      case 'seborrheic keratoses':
        return 'Seborrheic keratoses are common, benign (non-cancerous) skin growths that appear as brown, black, or tan patches. They have a waxy, scaly, slightly raised appearance and look like they\'re "stuck on" the skin. They\'re more common with age and are often called "barnacles of aging." While harmless, they can be cosmetically bothersome and may occasionally be confused with melanoma.';
      case 'sun_sunlight_damage':
      case 'sun damage':
      case 'sunlight damage':
        return 'Sun damage, also called photoaging or photodamage, refers to premature skin aging caused by repeated exposure to ultraviolet (UV) radiation. It manifests as wrinkles, age spots, freckles, rough texture, and loss of skin elasticity. Chronic sun exposure can also lead to precancerous lesions like actinic keratoses and increase the risk of skin cancer. Prevention through sun protection is key.';
      case 'tinea':
        return 'Tinea is a fungal infection of the skin, hair, or nails caused by dermatophyte fungi. Different types affect different body parts: tinea corporis (body), tinea pedis (athlete\'s foot), tinea cruris (jock itch), tinea capitis (scalp), and tinea unguium (nails). It typically presents as red, scaly, ring-shaped patches that may be itchy. The condition is contagious and spreads through direct contact or contaminated surfaces.';
      case 'vasculitis':
        return 'Vasculitis is inflammation of blood vessels that can affect vessels of different sizes throughout the body, including the skin. Cutaneous vasculitis presents as red or purple spots, bumps, or patches on the skin, often on the legs. It can be caused by infections, medications, autoimmune conditions, or may be idiopathic. The appearance varies depending on the size of vessels involved and severity of inflammation.';
      case 'vitiligo':
        return 'Vitiligo is an autoimmune condition that causes loss of skin pigmentation, resulting in white patches on the skin. It occurs when melanocytes (cells that produce melanin) are destroyed. The patches can appear anywhere on the body but commonly affect the face, hands, wrists, and areas around body openings. The condition is not contagious or life-threatening but can have significant psychological impact.';
      case 'warts':
        return 'Warts are small, rough growths caused by human papillomavirus (HPV) infection. They can appear anywhere on the body but are most common on hands and feet. Different types include common warts (rough, raised), plantar warts (on soles), flat warts (smooth, flat), and genital warts. Most warts are harmless and may resolve on their own, though treatment can speed up resolution.';
      case 'melanoma':
        return 'Melanoma is the most serious type of skin cancer, developing in melanocytes, the cells that produce melanin (skin pigment). While less common than other skin cancers, melanoma is more likely to spread to other parts of the body if not detected early. It can develop anywhere on the body, including areas not exposed to sun. Early detection and treatment are crucial for successful outcomes.';
      case 'dermatitis':
        return 'Dermatitis is a general term describing inflammation of the skin. There are several types including contact dermatitis (caused by allergens or irritants), seborrheic dermatitis (affecting oily areas), and atopic dermatitis (eczema). Symptoms typically include redness, swelling, itching, and sometimes blistering or scaling. The condition can be acute or chronic depending on the underlying cause.';
      case 'basal cell carcinoma':
        return 'Basal cell carcinoma is the most common type of skin cancer, arising from the basal cells in the lower part of the epidermis. It typically appears as a small, shiny bump or a flat, scaly patch. While it rarely spreads to other parts of the body, it can cause significant local damage if left untreated. It most commonly occurs on sun-exposed areas of the body.';
      case 'normal':
      case 'healthy':
        return 'The analyzed skin appears healthy with no concerning features detected by the AI model. Healthy skin typically has even tone, smooth texture, and no unusual growths or discoloration. However, regular skin checks and professional evaluations are still recommended as part of routine healthcare.';
      default:
        return 'The AI has detected a potential skin condition that requires professional evaluation. Skin conditions can vary widely in their appearance, causes, and treatment requirements. A dermatologist can provide accurate diagnosis and appropriate treatment recommendations based on clinical examination.';
    }
  }

  static String _getSeverityForDisease(String disease) {
    switch (disease.toLowerCase()) {
      case 'normal':
      case 'healthy':
        return 'Normal';
      case 'acne':
      case 'eczema':
      case 'dermatitis':
        return 'Mild';
      case 'psoriasis':
      case 'rosacea':
        return 'Moderate';
      case 'melanoma':
      case 'basal cell carcinoma':
        return 'Severe';
      default:
        return 'Unknown';
    }
  }
}

class HistoryEntry {
  final DateTime timestamp;
  final String disease;
  final double confidence;
  final String description;
  final String severity;
  final String image;

  HistoryEntry({
    required this.timestamp,
    required this.disease,
    required this.confidence,
    required this.description,
    required this.severity,
    required this.image,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      timestamp: DateTime.parse(json['timestamp']),
      disease: json['disease'],
      confidence: json['confidence'].toDouble(),
      description: json['description'],
      severity: json['severity'],
      image: json['image'],
    );
  }
    }