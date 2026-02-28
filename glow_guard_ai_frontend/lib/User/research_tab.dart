import 'package:flutter/material.dart';
import 'research_detail_screen.dart';

// Data model for our research topics
class ResearchTopic {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String whatItIs;
  final String risks;
  final List<String> symptoms;
  final String safeAlternatives;
  final List<String> labelKeywords;

  const ResearchTopic({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.whatItIs,
    required this.risks,
    required this.symptoms,
    required this.safeAlternatives,
    required this.labelKeywords,
  });
}

class ResearchTab extends StatelessWidget {
  const ResearchTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Actual proper content for the research hub
    final List<ResearchTopic> topics = [
      const ResearchTopic(
        title: "Mercury in Cosmetics",
        subtitle: "Highly toxic heavy metal often hidden in lightening creams.",
        icon: Icons.warning_amber_rounded,
        accentColor: Colors.redAccent,
        whatItIs: "Mercury is a toxic heavy metal that inhibits the formation of melanin, resulting in a lighter skin tone. It is illegally added to many unregulated skin-lightening products.",
        risks: "Long-term exposure can lead to severe kidney damage, neurological issues, and permanent skin discoloration or scarring. It can also harm family members who breathe mercury vapors or share towels.",
        symptoms: [
          "Skin rashes and discoloration",
          "Numbness or tingling in extremities",
          "Tremors and memory loss",
          "Elevated protein in urine (kidney stress)"
        ],
        safeAlternatives: "Vitamin C, Niacinamide, and Licorice Root Extract.",
        labelKeywords: ["Calomel", "Mercuric", "Mercurous", "Mercurio", "Hg"],
      ),
      const ResearchTopic(
        title: "Hydroquinone Risks",
        subtitle: "A strong depigmenting agent with severe long-term risks.",
        icon: Icons.science_outlined,
        accentColor: Colors.orange,
        whatItIs: "Hydroquinone is a chemical bleaching agent used to treat hyperpigmentation. While available by prescription in some countries, it is often misused in high concentrations in over-the-counter creams.",
        risks: "Prolonged use without medical supervision can cause exogenous ochronosis—a condition where the skin turns a permanent, patchy blue-black color. It also strips the skin's top layer, increasing UV vulnerability.",
        symptoms: [
          "Severe redness and burning",
          "Blue-black darkening of the skin",
          "Extreme dryness and cracking",
          "Contact dermatitis"
        ],
        safeAlternatives: "Alpha Arbutin, Kojic Acid, and Tranexamic Acid.",
        labelKeywords: ["Hydroquinone", "1,4-benzenediol", "Quinol", "Benzene-1,4-diol"],
      ),
      const ResearchTopic(
        title: "Hidden Steroids",
        subtitle: "Potent anti-inflammatories misused for quick skin whitening.",
        icon: Icons.medical_information_outlined,
        accentColor: Colors.purple,
        whatItIs: "Topical corticosteroids are prescription medicines for inflammatory skin conditions like eczema. Unethical manufacturers illegally add them to cosmetic creams for a rapid, but temporary, 'glowing' effect.",
        risks: "Steroids suppress the skin's local immune system and inhibit collagen production. This leads to irreversible skin thinning and a massive rebound effect when the user stops applying the cream.",
        symptoms: [
          "Visible, prominent blood vessels (telangiectasia)",
          "Severe, treatment-resistant acne",
          "Stretch marks (striae)",
          "Increased facial hair growth"
        ],
        safeAlternatives: "Ceramides, Centella Asiatica (Cica), and Peptides.",
        labelKeywords: ["Clobetasol", "Betamethasone", "Hydrocortisone", "Fluocinonide"],
      ),
      const ResearchTopic(
        title: "Safe Ingredients",
        subtitle: "Dermatologist-approved ingredients for a healthy glow.",
        icon: Icons.verified_user_outlined,
        accentColor: Colors.green,
        whatItIs: "These are scientifically proven, non-toxic ingredients that promote skin health, repair the skin barrier, and gently manage uneven skin tone without causing systemic harm.",
        risks: "Generally safe for all skin types. Minimal risks involve mild, temporary irritation if allergic or if introduced in too high of a concentration (e.g., strong Vitamin C).",
        symptoms: [
          "Improved skin hydration",
          "Even, gradual brightening",
          "Stronger skin barrier"
        ],
        safeAlternatives: "Consistent use of sunscreen (SPF 30+) is the ultimate safe alternative to bleaching.",
        labelKeywords: ["Niacinamide", "Ceramides", "Glycerin", "Hyaluronic Acid"],
      ),
    ];

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text("Research & Study", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              "Learn about harmful chemicals and how to protect your skin.",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: topics.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, i) {
                final topic = topics[i];
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResearchDetailScreen(topic: topic),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: topic.accentColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(topic.icon, color: topic.accentColor, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                topic.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                topic.subtitle,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 16, color: cs.onSurfaceVariant.withOpacity(0.5)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}