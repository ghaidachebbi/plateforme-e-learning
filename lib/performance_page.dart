import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PerformancePage extends StatelessWidget {
  const PerformancePage({super.key});

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
      appBar: AppBar(title: const Text('Suivi des performances')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📊 Progression par matière/semaine',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildProgressionSection(uid),
            const SizedBox(height: 20),
            const Text('🧠 Résultats aux quiz',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildQuizResultsSection(uid),
            const SizedBox(height: 20),
            const Text('⏱️ Engagement global',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildEngagementSection(uid),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressionSection(String uid) {
    final progressionStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('progression')
        .orderBy('semaine')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: progressionStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Erreur: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('Aucune donnée de progression disponible');
        }

        final data = snapshot.data!.docs;
        return Column(
          children: data.map((doc) {
            final matiere = doc['matiere'] ?? 'Inconnu';
            final semaine = doc['semaine'] ?? 0;
            final score = doc['score'] ?? 0;

            return ListTile(
              title: Text("$matiere - Semaine $semaine"),
              trailing: Text("$score%"),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildQuizResultsSection(String uid) {
    final quizStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('quiz_results')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: quizStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Erreur: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('Aucun résultat de quiz disponible');
        }

        final data = snapshot.data!.docs;
        return Column(
          children: data.map((doc) {
            final quiz = doc['quiz'] ?? 'Inconnu';
            final score = doc['score'] ?? 0;
            final total = doc['total'] ?? 1;

            return ListTile(
              title: Text("Quiz $quiz"),
              trailing: Text("$score / $total (${((score / total) * 100).toStringAsFixed(1)}%)"),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEngagementSection(String uid) {
    final engagementFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('engagement')
        .doc('global')
        .get();

    return FutureBuilder<DocumentSnapshot>(
      future: engagementFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Erreur: ${snapshot.error}');
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('Aucune donnée d\'engagement disponible');
        }

        final doc = snapshot.data!;
        final heuresEtude = doc['heuresEtude'] ?? 0;
        final objectifsRespectes = doc['objectifsRespectes'] ?? false;

        return Column(
          children: [
            ListTile(
              title: const Text("Heures d'étude cette semaine"),
              trailing: Text("$heuresEtude h"),
            ),
            ListTile(
              title: const Text("Objectifs respectés"),
              trailing: Icon(
                objectifsRespectes ? Icons.check_circle : Icons.cancel,
                color: objectifsRespectes ? Colors.green : Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }
}