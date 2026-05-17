import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import '../core/app_config.dart';
import '../widgets/theme_aware_image.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حول التطبيق'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ThemeAwareImage(
                imagePath: 'assets/images/logo.png',
                height: 150,
              ),
              const SizedBox(height: 16),
              Text(
                'تطبيق ${AppConfig.restaurantFullName}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'الإصدار 1.0.0',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 32),
              const Text(
                'تم التطوير بحب وشغف بواسطة',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Image.asset('assets/images/qatenic.png', height: 90),
              Text(
                'Qatenic',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Abdulrahman Qaten',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 12,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Remix.github_fill),
                    onPressed: () {
                      // يمكنك إضافة رابط حسابك على GitHub هنا
                    },
                  ),
                  IconButton(
                    icon: const Icon(Remix.linkedin_box_fill),
                    onPressed: () {
                      // يمكنك إضافة رابط حسابك على LinkedIn هنا
                    },
                  ),
                  IconButton(
                    icon: const Icon(Remix.mail_fill),
                    onPressed: () {
                      // يمكنك إضافة بريدك الإلكتروني هنا
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
