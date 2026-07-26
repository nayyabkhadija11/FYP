import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'child_details_screen.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({Key? key}) : super(key: key);

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanned = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        setState(() => _isScanned = true);

        if (!mounted) return;

        // Feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scanned Child ID: $rawValue'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 1),
          ),
        );

        // Navigate to Child Details Screen with scanned ID
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChildDetailsScreen(
              childData: {
                'id': rawValue,
                'name': 'Scanned Profile',
                'status': 'Fully Vaccinated',
              },
            ),
          ),
        );
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // LIVE CAMERA VIEW
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),

          // SEMI-TRANSPARENT OVERLAY & SCANNING FRAME
          Column(
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Align the QR code within the frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    backgroundColor: Colors.black45,
                  ),
                ),
              ),
              const Spacer(),
              
              // CUTOUT FRAME
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF10B981), width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              
              const Spacer(),

              // CONTROLS (FLASH & CAMERA SWITCH)
              Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // FLASH TOGGLE
                    IconButton(
                      icon: ValueListenableBuilder(
                        valueListenable: _scannerController,
                        builder: (context, state, child) {
                          switch (state.torchState) {
                            case TorchState.on:
                              return const Icon(Icons.flash_on, color: Colors.amber, size: 28);
                            case TorchState.off:
                            case TorchState.auto:
                            case TorchState.unavailable:
                            default:
                              return const Icon(Icons.flash_off, color: Colors.white, size: 28);
                          }
                        },
                      ),
                      onPressed: () => _scannerController.toggleTorch(),
                    ),
                    const SizedBox(width: 50),
                    
                    // CAMERA SWITCH TOGGLE
                    IconButton(
                      icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 28),
                      onPressed: () => _scannerController.switchCamera(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }
}