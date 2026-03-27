import 'package:flutter/material.dart';
import 'research_tab.dart'; // Import to access ResearchTopic model
import 'chatbot_tab.dart';  // 👉 REQUIRED IMPORT FOR NAVIGATION TO CHATBOT

class ResearchDetailScreen extends StatelessWidget {
  final ResearchTopic topic;

  const ResearchDetailScreen({
    super.key,
    required this.topic,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            pinned: true,
            backgroundColor: topic.accentColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16, right: 16),
              title: Text(
                topic.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          topic.accentColor.withOpacity(0.8),
                          topic.accentColor.withOpacity(0.4),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(
                      topic.icon,
                      size: 150,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.subtitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader(context, topic.header1, Icons.info_outline, topic.accentColor),
                  _buildContentCard(context, topic.content1),
                  const SizedBox(height: 24),

                  _buildSectionHeader(context, topic.header2, Icons.warning_rounded, Colors.red),
                  _buildContentCard(context, topic.content2),
                  const SizedBox(height: 24),

                  _buildSectionHeader(context, topic.listHeader, Icons.fact_check_outlined, Colors.orange),
                  _buildListCard(context, topic.listItems),
                  const SizedBox(height: 24),

                  _buildSectionHeader(context, topic.chipsHeader, Icons.search_rounded, Colors.blue),
                  _buildChips(context, topic.chips),
                  const SizedBox(height: 24),

                  _buildSectionHeader(context, topic.highlightHeader, Icons.verified_user_rounded, Colors.green),
                  _buildContentCard(context, topic.highlightContent, isHighlighted: true),
                  const SizedBox(height: 32),

                  // Chatbot integration section
                  _buildSectionHeader(context, "Discuss with Assistant", Icons.chat_bubble_outline, Colors.deepPurpleAccent),
                  _buildChatPrompts(context, topic.chatPrompts),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(BuildContext context, String text, {bool isHighlighted = false}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted ? cs.primaryContainer.withOpacity(0.3) : cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? cs.primary.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.6,
          color: cs.onSurface,
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, List<String> items) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChips(BuildContext context, List<String> keywords) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: keywords.map((word) {
        return Chip(
          label: Text(word),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );
      }).toList(),
    );
  }

  // 👉 This method generates the buttons that navigate to the Chatbot
  Widget _buildChatPrompts(BuildContext context, List<String> prompts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: prompts.map((prompt) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.centerLeft,
              elevation: 0,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // Passes the string directly into the ChatbotTab!
                  builder: (_) => ChatbotTab(initialPrompt: prompt),
                ),
              );
            },
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: Text(
              prompt,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
            ),
          ),
        );
      }).toList(),
    );
  }
}