import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RewardSystemPage extends StatelessWidget {
  const RewardSystemPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    final String uid = user.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Système de Récompenses')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🏅 Badges obtenus',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildBadgesSection(uid),
            const SizedBox(height: 20),
            const Text('🎯 Niveau et Récompenses',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildLevelAndRewardsSection(uid),
            const SizedBox(height: 20),
            const Text('🏆 Historique des Succès',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildAchievementsSection(uid),
            const SizedBox(height: 20),
            const Text('💰 Points Disponibles',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildPointsSection(uid),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesSection(String uid) {
    final badgesStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('badges')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: badgesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Erreur: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('Aucun badge obtenu');
        }

        final badges = snapshot.data!.docs;
        return Column(
          children: badges.map((badge) {
            final badgeName = badge['name'] ?? 'Inconnu';
            final badgeDescription = badge['description'] ?? 'Pas de description';

            return ListTile(
              leading: const Icon(Icons.star, color: Colors.yellow),
              title: Text(badgeName),
              subtitle: Text(badgeDescription),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLevelAndRewardsSection(String uid) {
    final levelStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('level')
        .doc('current')
        .snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: levelStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Erreur: ${snapshot.error}');
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('Aucun niveau défini');
        }

        final levelData = snapshot.data!;
        final currentLevel = levelData['level'] ?? 0;
        final reward = levelData['reward'] ?? 'Aucune récompense';

        return Column(
          children: [
            ListTile(
              title: const Text("Niveau actuel"),
              trailing: Text('$currentLevel'),
            ),
            ListTile(
              title: const Text("Récompense obtenue"),
              trailing: Text(reward),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAchievementsSection(String uid) {
    final achievementsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('achievements')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: achievementsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Erreur: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('Aucun succès à afficher');
        }

        final achievements = snapshot.data!.docs;
        return Column(
          children: achievements.map((achievement) {
            final achievementTitle = achievement['title'] ?? 'Inconnu';
            final achievementDescription = achievement['description'] ?? 'Pas de description';

            return ListTile(
              title: Text(achievementTitle),
              subtitle: Text(achievementDescription),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPointsSection(String uid) {
    final pointsFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('points')
        .doc('current')
        .get();

    return FutureBuilder<DocumentSnapshot>(
      future: pointsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Erreur: ${snapshot.error}');
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('Aucun point disponible');
        }

        final pointsData = snapshot.data!;
        final points = pointsData['points'] ?? 0;

        return ListTile(
          title: const Text("Points disponibles"),
          trailing: Text('$points pts'),
        );
      },
    );
  }
}
