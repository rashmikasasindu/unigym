import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/reservation_service.dart';

class AdminScanPage extends StatefulWidget {
  const AdminScanPage({super.key});

  @override
  State<AdminScanPage> createState() => _AdminScanPageState();
}

class _AdminScanPageState extends State<AdminScanPage> {
  final ReservationService _reservationService = ReservationService();
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  bool _torchOn = false;
  bool _isFrontCamera = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return; // Prevent multiple scans at once

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        setState(() {
          _isProcessing = true;
        });

        // 1. Stop scanning immediately
        await _controller.stop();

        try {
          // 2. Fetch reservation details
          final reservationData = await _reservationService.getReservationById(code);
          
          if (!mounted) return;

          if (reservationData != null) {
            final userName = reservationData['userName'] ?? 'User';
            final alreadyAttended = reservationData['attended'] == true;

            if (alreadyAttended) {
               await _showResultDialog(
                title: "Already Checked In",
                message: "$userName has already been marked as attended.",
                isSuccess: false,
                iconData: Icons.warning_amber_rounded,
                color: Colors.orange,
              );
            } else {
              // 3. Mark as attended
              await _reservationService.markAttendance(code);
              
              if (!mounted) return;
              await _showResultDialog(
                title: "Success",
                message: "Attendance marked for $userName",
                isSuccess: true,
                iconData: Icons.check_circle_rounded,
                color: Colors.green,
              );
            }
          } else {
             await _showResultDialog(
              title: "Invalid Code",
              message: "No reservation found for this code.",
              isSuccess: false,
              iconData: Icons.error_outline_rounded,
              color: Colors.red,
            );
          }
        } catch (e) {
          if (mounted) {
             await _showResultDialog(
              title: "Error",
              message: "An error occurred: $e",
              isSuccess: false,
              iconData: Icons.error,
              color: Colors.red,
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
            // 4. Resume scanning after dialog closes
            _controller.start();
          }
        }
        break; // Process only the first valid code found in this frame
      }
    }
  }

  Future<void> _showResultDialog({
    required String title,
    required String message,
    required bool isSuccess,
    required IconData iconData,
    required Color color,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(iconData, color: color, size: 30),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: TextStyle(color: color))),
            ],
          ),
          content: Text(message, style: const TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK", style: TextStyle(fontSize: 16)),
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
        title: const Text("Scan Attendance"),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on : Icons.flash_off,
              color: _torchOn ? Colors.yellow : Colors.grey,
            ),
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
          IconButton(
            icon: Icon(
              _isFrontCamera ? Icons.camera_front : Icons.camera_rear,
            ),
            onPressed: () {
              _controller.switchCamera();
              setState(() => _isFrontCamera = !_isFrontCamera);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: _handleBarcode,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: const Text(
              "Point camera at the student's QR code to mark attendance.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
