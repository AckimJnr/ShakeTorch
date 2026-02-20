import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // Function to launch URLs
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  // Function to send email
  Future<void> _sendEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'thefossildream@gmail.com', // TODO: Replace with actual email
      query: 'subject=Report Issue/Feedback',
    );
    if (!await launchUrl(emailLaunchUri)) {
      throw Exception('Could not launch email client');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
        title: const Text('About the App'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // App Icon or Logo Placeholder
              Container(
                width: 100,
                height: 100,
                child: Image.asset(
                  'assets/images/playstore.png',
                  width: 60,
                  height: 60,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ShakeTorch',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Version 1.0.0',
                style: TextStyle(fontSize: 14, color: Colors.white54),
              ),
              const SizedBox(height: 40),

              // Developer Details
              const Text(
                'Developed by',
                style: TextStyle(fontSize: 16, color: Colors.white54),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ackim Longwe Jnr',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 40),

              // Social Media Links
              const Text(
                'Follow Me',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: [
                  _SocialIcon(
                    icon: FontAwesomeIcons.tiktok,
                    onTap: () =>
                        _launchUrl('https://www.tiktok.com/@code_is_power'),
                  ),
                  _SocialIcon(
                    icon: FontAwesomeIcons.facebook,
                    onTap: () => _launchUrl(
                      'https://www.facebook.com/profile.php?id=61578292401970',
                    ),
                  ),
                  _SocialIcon(
                    icon: FontAwesomeIcons.twitter,
                    onTap: () => _launchUrl('https://x.com/@thefossildream'),
                  ),
                  _SocialIcon(
                    icon: FontAwesomeIcons.youtube,
                    onTap: () =>
                        _launchUrl('https://youtube.com/c/yourchannel'),
                  ),
                  _SocialIcon(
                    icon: FontAwesomeIcons.instagram,
                    onTap: () =>
                        _launchUrl('https://www.instagram.com/ackim_iii/'),
                  ),
                  _SocialIcon(
                    icon: FontAwesomeIcons.linkedin,
                    onTap: () => _launchUrl(
                      'https://www.linkedin.com/in/ackim-longwe-544936239/',
                    ),
                  ),
                  _SocialIcon(
                    icon: FontAwesomeIcons.github,
                    onTap: () =>
                        _launchUrl('https://github.com/AckimJnr/ShakeTorch'),
                  ),
                ],
              ),

              const SizedBox(height: 50),

              // Report Issues
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.bug_report_rounded,
                      color: Colors.white54,
                      size: 30,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Found a bug or have a suggestion?',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: _sendEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.email_outlined),
                      label: const Text('Report Issue via Email'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: FaIcon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
