import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatefulWidget {
  const TermsAndConditionsPage({super.key});

  @override
  State<TermsAndConditionsPage> createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {
  bool _hasAgreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms and Conditions',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black54),
      ),
      body: Column(
        children: [
          // Terms content - Header text moved here
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header text content moved from the removed container
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'End-User License Agreement (EULA)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'GLAMOUR: A Makeup Shade Recommendation Application',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Based on Skin Tone and Face Shape',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Last Updated: September 10, 2025',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                  
                  const Text(
                    'This End-User License Agreement ("Agreement") is a legal contract between you ("User," "you," or "your") and the developers of GLAMOUR: A Makeup Shade Recommendation Application ("GLAMOUR," "we," "our," or "us").\n\n'
                    'By downloading, installing, or using GLAMOUR, you agree to be bound by this Agreement. If you do not agree, you must not install, access, or use the Application.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('1. License Grant'),
                  const Text(
                    'We grant you a limited, non-exclusive, non-transferable, revocable license to install and use GLAMOUR solely for personal, non-commercial purposes.',
                    style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('2. Restrictions'),
                  const Text('You agree that you will not:',
                      style: TextStyle(fontSize: 15, color: Colors.black87)),
                  _buildBulletPoint('Copy, modify, or create derivative works of GLAMOUR.'),
                  _buildBulletPoint('Sell, rent, lease, sublicense, or distribute the Application.'),
                  _buildBulletPoint('Reverse-engineer, decompile, or disassemble any part of GLAMOUR.'),
                  _buildBulletPoint('Use the Application for unlawful, abusive, or harmful purposes.'),
                  _buildBulletPoint('Circumvent or disable any security features.'),
                  const SizedBox(height: 20),
                  _buildSectionTitle('3. Ownership'),
                  const Text(
                    'GLAMOUR is licensed, not sold. All intellectual property rights, including software, content, and design, remain the exclusive property of the developers.',
                    style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('4. Age & Eligibility'),
                  _buildBulletPoint('You must be at least 16 years old to use GLAMOUR.'),
                  _buildBulletPoint('By using GLAMOUR, you represent and warrant that you meet these eligibility requirements.'),
                  const SizedBox(height: 20),
                  _buildSectionTitle('5. Data Privacy & User Data'),
                  const Text(
                    'GLAMOUR may collect and process limited user data, including but not limited to:',
                    style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                  ),
                  _buildBulletPoint('Skin tone and face shape analysis results.'),
                  _buildBulletPoint('User preferences and inputs.'),
                  _buildBulletPoint('Data will be collected, stored, and processed in compliance with the Philippine Data Privacy Act of 2012 (R.A. 10173).'),
                  _buildBulletPoint('We are committed to protecting personal information and will not sell or disclose data to unauthorized third parties.'),
                  _buildBulletPoint('Users have the right to access, correct, and request deletion of their personal data by contacting us.'),
                  const SizedBox(height: 20),
                  _buildSectionTitle('6. Updates & Modifications'),
                  _buildBulletPoint('We may release updates, bug fixes, or new features.'),
                  _buildBulletPoint('Updates may change, improve, or remove certain functions.'),
                  _buildBulletPoint('Continued use of the Application after updates constitutes acceptance of the modified version.'),
                  const SizedBox(height: 20),
                  _buildSectionTitle('7. Disclaimer of Warranties'),
                  _buildBulletPoint('GLAMOUR is provided "as is" and "as available."'),
                  _buildBulletPoint('We make no guarantees that recommendations (e.g., makeup shades) will be error-free, accurate, or suitable for all users.'),
                  _buildBulletPoint('We disclaim all warranties, express or implied, to the fullest extent permitted by law.'),
                  const SizedBox(height: 20),
                  _buildSectionTitle('8. Limitation of Liability'),
                  const Text(
                    'To the maximum extent permitted under the Civil Code of the Philippines and other applicable laws:',
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  _buildBulletPoint('We are not liable for any indirect, incidental, or consequential damages, including but not limited to, lost profits, data loss, or personal dissatisfaction with recommendations.'),
                  _buildBulletPoint('Our total liability shall not exceed the amount you paid (if any) to use the Application.'),
                  const SizedBox(height: 20),
                  _buildSectionTitle('9. Termination'),
                  _buildBulletPoint('This Agreement remains in effect until terminated.'),
                  _buildBulletPoint('We may suspend or terminate your access at any time if you violate this Agreement.'),
                  _buildBulletPoint('Upon termination, you must stop using and delete the Application.'),
                  const SizedBox(height: 20),
                  _buildSectionTitle('10. Governing Law & Dispute Resolution'),
                  _buildBulletPoint('This Agreement shall be governed by and construed in accordance with the laws of the Republic of the Philippines.'),
                  _buildBulletPoint('In case of disputes, parties shall first attempt amicable settlement.'),
                  _buildBulletPoint('If unresolved, disputes shall be submitted to the proper courts of General Santos City, Philippines, to the exclusion of other courts.'),
                  const SizedBox(height: 20),
                  _buildSectionTitle('11. Contact Information'),
                  const Text(
                    'If you have questions about this Agreement or your data rights, you may contact:',
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'glamouraika@gmail.com',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Agreement checkbox
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _hasAgreed,
                          onChanged: (value) {
                            setState(() {
                              _hasAgreed = value ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'I have read and agree to the Terms and Conditions',
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Accept button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _hasAgreed
                    ? () {
                        // Navigate to the next screen or close the dialog
                        Navigator.pop(context, true);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasAgreed ? Colors.pink : Colors.grey[300],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Accept and Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 15, color: Colors.black87)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}