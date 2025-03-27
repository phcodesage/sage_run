import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final _nameController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.currentUser;
    if (user != null) {
      _nameController.text = user.name;
      setState(() {});
    }
  }

  Future<void> _updateProfile() async {
    final user = await _authService.currentUser;
    if (user != null) {
      final updatedUser = AppUser(
        id: user.id,
        name: _nameController.text,
        email: user.email,
        photoUrl: user.photoUrl,
        authProvider: user.authProvider,
        createdAt: user.createdAt,
      );
      await _authService.updateUser(updatedUser);
      setState(() {
        _isEditing = false;
      });
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _updateProfile,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: FutureBuilder<AppUser?>(
        future: _authService.currentUser,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No user data available'));
          }

          final user = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 16),
                if (_isEditing)
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  )
                else
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                const SizedBox(height: 8),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Member since'),
                  subtitle: Text(
                    '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('Sign in method'),
                  subtitle: Text(
                    user.authProvider == 'google.com'
                        ? 'Google'
                        : user.authProvider == 'facebook.com'
                            ? 'Facebook'
                            : 'Email',
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _handleSignOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 