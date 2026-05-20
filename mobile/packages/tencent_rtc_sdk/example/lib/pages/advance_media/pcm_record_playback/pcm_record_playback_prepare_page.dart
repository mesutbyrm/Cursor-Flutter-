import 'package:flutter/material.dart';
import 'pcm_record_playback_page.dart';

class PcmRecordPlaybackPreparePage extends StatefulWidget {
  const PcmRecordPlaybackPreparePage({Key? key}) : super(key: key);

  @override
  State<PcmRecordPlaybackPreparePage> createState() => _PcmRecordPlaybackPreparePageState();
}

class _PcmRecordPlaybackPreparePageState extends State<PcmRecordPlaybackPreparePage> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _roomIdController = TextEditingController();

  @override
  void dispose() {
    _userIdController.dispose();
    _roomIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PCM Record & Playback'),
        backgroundColor: Colors.indigo,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade50,
              Colors.indigo.shade100,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                _buildInfoCard(),
                const SizedBox(height: 24),
                _buildInputCard(),
                const SizedBox(height: 24),
                _buildEnterButton(),
                const SizedBox(height: 20),
                _buildNoteCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mic_rounded,
                size: 48,
                color: Colors.indigo.shade700,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'PCM Audio Recording & Playback',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Record audio frames from different sources and play them back using flutter_pcm_sound',
              style: TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FeatureItem(text: 'setAudioFrameCallback()'),
                  _FeatureItem(text: 'onCapturedAudioFrame'),
                  _FeatureItem(text: 'onLocalProcessedAudioFrame'),
                  _FeatureItem(text: 'onMixedPlayAudioFrame'),
                  _FeatureItem(text: 'onMixedAllAudioFrame'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextFormField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: 'User ID',
                hintText: 'Enter your user ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person, color: Colors.indigo),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter user ID';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _roomIdController,
              decoration: const InputDecoration(
                labelText: 'Room ID',
                hintText: 'Enter room ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.meeting_room, color: Colors.indigo),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter room ID';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnterButton() {
    return ElevatedButton(
      onPressed: _enterRoom,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 4,
      ),
      child: const Text(
        'Enter Room',
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildNoteCard() {
    return Card(
      elevation: 2,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text(
                  'Recording Sources:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '• Captured: Raw audio from microphone\n'
              '• Local Processed: Audio after local processing\n'
              '• Mixed Play: Remote users mixed audio\n'
              '• Mixed All: All audio sources mixed together',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _enterRoom() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PcmRecordPlaybackPage(
            userId: _userIdController.text,
            roomId: _roomIdController.text,
          ),
        ),
      );
    }
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;
  
  const _FeatureItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.indigo.shade700),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.indigo.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
