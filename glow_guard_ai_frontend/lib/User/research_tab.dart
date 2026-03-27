import 'package:flutter/material.dart';
import 'research_detail_screen.dart';

// 1. Fully Updated Model including 'chatPrompts'
class ResearchTopic {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  final String header1;
  final String content1;

  final String header2;
  final String content2;

  final String listHeader;
  final List<String> listItems;

  final String chipsHeader;
  final List<String> chips;

  final String highlightHeader;
  final String highlightContent;

  // 👉 This is the variable that caused the error, now safely included!
  final List<String> chatPrompts;

  const ResearchTopic({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.header1,
    required this.content1,
    required this.header2,
    required this.content2,
    required this.listHeader,
    required this.listItems,
    required this.chipsHeader,
    required this.chips,
    required this.highlightHeader,
    required this.highlightContent,
    required this.chatPrompts, // 👉 Required here as well
  });
}

class ResearchTab extends StatelessWidget {
  const ResearchTab({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final List<ResearchTopic> topics = [
      const ResearchTopic(
        title: "Hydroquinone & Testing",
        subtitle: "Detection via Alkaline Oxidation Assay & HPLC.",
        icon: Icons.science_outlined,
        accentColor: Colors.orange,
        header1: "What it is & The Field Test",
        content1: "Hydroquinone is an aggressive tyrosinase inhibitor. The presumptive field test is the Alkaline Oxidation Assay: extract the sample with ethanol, defat it in an ice bath, and add Sodium Hydroxide (NaOH). In highly alkaline environments, hydroquinone auto-oxidizes rapidly.",
        header2: "Systemic Harm & Reactions",
        content2: "Prolonged use outside strict medical supervision causes exogenous ochronosis (permanent blue-black hyperpigmentation) and increases UV vulnerability. It also possesses suspected carcinogenic properties.",
        listHeader: "Test Endpoints & Symptoms",
        listItems: [
          "Field Test: Instant transition to a dark brown/black hue (melanin-like polymerization).",
          "Symptom: Severe redness, erythema, and contact dermatitis.",
          "Symptom: Paradoxical, permanent blue-black darkening of skin tissue."
        ],
        chipsHeader: "Chemical Identifiers",
        chips: ["Hydroquinone", "1,4-benzenediol", "Alkaline Oxidation", "p-benzoquinone"],
        highlightHeader: "Definitive Quantification",
        highlightContent: "For exact legal limits, High-Performance Liquid Chromatography (HPLC-UV) is the global gold standard (BS EN 16956), successfully detecting limits down to 0.16 μg/mL.",
        chatPrompts: [
          "Can you explain the Alkaline Oxidation Assay simply?",
          "What are the long-term dangers of Hydroquinone?",
          "How does an HPLC test work for cosmetics?"
        ],
      ),
      const ResearchTopic(
        title: "Mercury Dangers & Myths",
        subtitle: "Iodide Precipitation, CV-AAS, and the Gold Ring Fallacy.",
        icon: Icons.warning_amber_rounded,
        accentColor: Colors.redAccent,
        header1: "Iodide Halochromic Precipitation",
        content1: "Mercury salts suppress melanogenesis. Field testing requires violently digesting the cream in nitric acid to free the ions, then adding potassium iodide strictly dropwise. If mercury is present, it forms a bright precipitate.",
        header2: "The 'Gold Ring Test' Fallacy",
        content2: "Rubbing gold on cream to check for mercury is a dangerous, scientifically invalid myth. The dark streak is merely base metals in the jewelry physically scratching off against abrasive mineral sunblocks (like zinc oxide) in the cream.",
        listHeader: "Visual Endpoints & Toxicity",
        listItems: [
          "Field Test: Immediate formation of a vibrant, opaque scarlet-red solid precipitate.",
          "Symptom: Accumulates in vital organs causing profound nephrotoxicity (kidney damage).",
          "Symptom: Neurological degradation, tremors, and psychological disturbances."
        ],
        chipsHeader: "Compounds & Instruments",
        chips: ["Ammoniated Mercury", "Calomel", "HgI2", "Minamata Convention"],
        highlightHeader: "Advanced Atomic Spectrometry",
        highlightContent: "Laboratories strictly utilize Cold Vapor Atomic Absorption Spectrometry (CV-AAS) paired with high-pressure microwave acid digestion to detect volatile trace mercury down to parts-per-billion.",
        chatPrompts: [
          "Why is the gold ring test for mercury fake?",
          "What is the Minamata Convention limit for mercury?",
          "How does mercury damage the kidneys?"
        ],
      ),
      const ResearchTopic(
        title: "Hidden Steroids & TLC",
        subtitle: "Isolating potent anti-inflammatories via Chromatography.",
        icon: Icons.medical_information_outlined,
        accentColor: Colors.purple,
        header1: "Thin-Layer Chromatography (TLC)",
        content1: "Steroids lack reactive groups for simple color tests. They are aggressively extracted with methanol and separated on a silica gel plate. Intense heating with p-anisaldehyde and sulfuric acid covalently fuses to the steroids, turning them visible.",
        header2: "Severe Localized Side Effects",
        content2: "Unmonitored topical application causes severe suppression of the hypothalamic-pituitary-adrenal (HPA) axis, leading to systemic immunosuppression and massive rebound dermatitis.",
        listHeader: "Visual Stains & Symptoms",
        listItems: [
          "TLC Test: Betamethasone valerate stains dark purple/violet.",
          "TLC Test: Dexamethasone stains grey; Hydrocortisone stains dark brown.",
          "Symptom: Irreversible cutaneous atrophy (skin thinning) and striae (stretch marks).",
          "Symptom: Telangiectasia (prominent visible blood vessels)."
        ],
        chipsHeader: "Target Adulterants",
        chips: ["Clobetasol", "Betamethasone", "Dexamethasone", "TLC Silica"],
        highlightHeader: "Mass Spectrometry Interfacing",
        highlightContent: "To detect ultra-trace designer steroids, forensic labs interface liquid chromatographs with tandem mass spectrometry (LC-MS/MS), pushing detection thresholds to sub-milligram per kilogram levels.",
        chatPrompts: [
          "Why do companies hide steroids in skin creams?",
          "How does Thin-Layer Chromatography (TLC) isolate steroids?",
          "What are the symptoms of steroid rebound dermatitis?"
        ],
      ),
      const ResearchTopic(
        title: "Decoding Lab Reports (COA)",
        subtitle: "Understanding LOD, LOQ, ND, and regulatory thresholds.",
        icon: Icons.fact_check_outlined,
        accentColor: Colors.indigo,
        header1: "Core Architecture of a COA",
        content1: "A Certificate of Analysis (COA) is the foundational identity card for a product batch. The alphanumeric batch code printed on the physical cosmetic jar MUST perfectly match the lot code detailed on the COA document.",
        header2: "Specification vs. Empirical Results",
        content2: "The document compares legal Specification Limits (e.g., < 1.0 ppm for mercury) against Actual Test Results. Vague claims of being 'clinically proven' without citing highly specific ISO methodologies are massive red flags.",
        listHeader: "Navigating Analytical Thresholds",
        listItems: [
          "LOD (Limit of Detection): The absolute lowest concentration the machine can reliably distinguish from background noise.",
          "LOQ (Limit of Quantitation): The lowest concentration it can accurately and consistently measure.",
          "ND (Not Detected): The toxin sits safely below the LOD. It does not mean absolute zero, but guarantees legal safety.",
          "< LOQ: Positively identified, but too mathematically minimal to assign a definitive number."
        ],
        chipsHeader: "COA Verification Terms",
        chips: ["COA", "ISO/IEC 17025", "LOD / LOQ", "Not Detected (ND)"],
        highlightHeader: "Auditor Independence",
        highlightContent: "The most reliable, legally defensible COAs are generated by fully independent, ISO 17025 accredited third-party analytical laboratories, fully separate from the brand's manufacturing arm.",
        chatPrompts: [
          "What is the difference between LOD and LOQ on a lab report?",
          "What does 'ND' mean on a Certificate of Analysis?",
          "How can I tell if a lab report is legitimate or fake?"
        ],
      ),
      const ResearchTopic(
        title: "Spotting Fake Cosmetics",
        subtitle: "Organoleptic profiling, packaging analysis, and symbols.",
        icon: Icons.qr_code_scanner_rounded,
        accentColor: Colors.teal,
        header1: "Non-Destructive Authentication",
        content1: "Counterfeits utilize highly toxic bulking agents like raw animal feces or beryllium oxide. Identify them by blurry typography, misspelled complex INCI names, and flimsy, compressible plastic packaging.",
        header2: "Organoleptic Emulsion Stability",
        content2: "Fake creams rely on cheap petroleum and unstable emulsifiers. This causes catastrophic phase separation (where the water and heavy oil visibly split inside the jar) and leaves overtly gritty tactile sensations.",
        listHeader: "Universal Labelling Symbols",
        listItems: [
          "PAO (Open Jar): Period After Opening. E.g., '12M' means safe for 12 months after breaching the seal.",
          "BBE (Hourglass): Best Before End. A non-negotiable hard expiration date.",
          "E-Mark (Lowercase e): EU standard confirming precise filling machinery weight.",
          "Green Dot: Manufacturer paid tariff for national waste recovery (NOT a recycling capability symbol)."
        ],
        chipsHeader: "Counterfeit Red Flags",
        chips: ["Phase Separation", "Chemical Odor", "Blurry Text", "Flimsy Plastic"],
        highlightHeader: "Digital Traceability",
        highlightContent: "Verify serialized QR codes or NFC chips. Authentic products feature batch codes heavily embossed or laser-etched on both the outer carton and inner bottle. Missing codes guarantee a counterfeit.",
        chatPrompts: [
          "What does phase separation in a face cream mean?",
          "How do I read a cosmetic batch code?",
          "What does the open jar (PAO) symbol mean?"
        ],
      ),
      const ResearchTopic(
        title: "Regulatory Verification",
        subtitle: "Centralized frameworks and port-of-entry testing.",
        icon: Icons.shield_outlined,
        accentColor: Colors.blueGrey,
        header1: "State-Level Regulatory Defense",
        content1: "Robust systems require technical dossiers including CAS numbers, clinical data, and independent Heavy Metal COAs before a single commercial unit can be retailed (e.g., Sri Lanka's NMRA).",
        header2: "Combating Parallel Imports",
        content2: "Strict 'One Brand, One Distributor' policies eliminate chaotic grey-market goods. Massive commercial consignments undergo mandatory, randomized physical sampling by institutions like SLSI at shipping ports.",
        listHeader: "Active Consumer Defense",
        listItems: [
          "Check for mandatory, non-peelable security stickers (e.g., 'NMRA Approved').",
          "Actively search exact product names in centralized digital government databases (like Mediverify).",
          "Products completely lacking a digital footprint carry extremely high probabilities of heavy metal adulteration."
        ],
        chipsHeader: "Regulatory Bodies",
        chips: ["NMRA", "SLSI", "CoC", "Technical Dossier"],
        highlightHeader: "The Ultimate Bulwark",
        highlightContent: "If a highly touted skin-lightening serum cannot be located within official regulatory registries, it is irrefutable proof it bypassed safety inspections and is circulating illegally.",
        chatPrompts: [
          "Why is an NMRA approval sticker important?",
          "How do customs test imported cosmetics at ports?",
          "Why should I avoid unregistered whitening creams?"
        ],
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
              "Learn about advanced analytical methods and cosmetic authentication.",
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