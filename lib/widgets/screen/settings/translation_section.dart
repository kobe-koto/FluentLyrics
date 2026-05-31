import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../i18n/strings.g.dart';
import '../../../providers/lyrics_provider.dart';
import '../../settings_card_frame.dart';
import '../../settings_section.dart';
import '../../settings_slider_card.dart';
import '../../settings_toggle_card.dart';

class TranslationSection extends StatelessWidget {
  const TranslationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = t.settings.translation;
    return Consumer<LyricsProvider>(
      builder: (context, provider, child) {
        return SettingsSection(
          title: i18n.sectionTitle,
          description: i18n.sectionDescription,
          children: [
            // Translation Toggle
            SettingsToggleCard(
              title: i18n.enable,
              subtitle: i18n.enableSubtitle,
              value: provider.translationEnabled.current,
              onChanged: (value) => provider.setTranslationEnabled(value),
            ),
            if (provider.translationEnabled.current) ...[
              const SizedBox(height: 24),
              // Highlight Only
              SettingsToggleCard(
                title: i18n.highlightOnly,
                subtitle: i18n.highlightOnlySubtitle,
                value: provider.translationHighlightOnly.current,
                onChanged: (value) =>
                    provider.setTranslationHighlightOnly(value),
              ),
              const SizedBox(height: 24),
              // Target Language
              SettingsCardFrame(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i18n.targetLanguageTitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      i18n.targetLanguageDescription,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      i18n.targetLanguageNoteMusixmatch,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      i18n.targetLanguageNoteLlm,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      i18n.targetLanguageNoteCJK,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: provider.translationTargetLanguages.current
                          .join(', '),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: i18n.targetLanguageHint,
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: Colors.black26,
                      ),
                      onChanged: (value) {
                        provider.setTranslationTargetLanguages(
                          value.isEmpty
                              ? []
                              : value
                                    .split(',')
                                    .map((e) => e.trim())
                                    .map(
                                      (e) => e.startsWith('llm:')
                                          ? 'llm: ${e.substring(4).trim()}' // normalize input with 'llm:' prefix
                                          : e,
                                    )
                                    .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Bias
              SettingsSliderCard(
                title: i18n.bias,
                subtitle: i18n.biasSubtitle,
                value: provider.translationBias.current.toDouble(),
                min: 0,
                max: 1000,
                divisions: 20,
                label: '${provider.translationBias.current}ms',
                valueText: '${provider.translationBias.current}ms',
                onChanged: (value) =>
                    provider.setTranslationBias(value.toInt()),
                onReset: provider.translationBias.changed
                    ? () => provider.setTranslationBias(
                        provider.translationBias.defaultValue,
                      )
                    : null,
                resetTooltip: i18n.biasReset,
              ),
              const SizedBox(height: 24),
              // Alignment Threshold
              SettingsSliderCard(
                title: i18n.alignmentThreshold,
                subtitle: i18n.alignmentThresholdSubtitle,
                value: provider.translationAlignmentThreshold.current
                    .toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                label: '${provider.translationAlignmentThreshold.current}%',
                valueText: '${provider.translationAlignmentThreshold.current}%',
                onChanged: (value) =>
                    provider.setTranslationAlignmentThreshold(value.toInt()),
                onReset: provider.translationAlignmentThreshold.changed
                    ? () => provider.setTranslationAlignmentThreshold(
                        provider.translationAlignmentThreshold.defaultValue,
                      )
                    : null,
                resetTooltip: i18n.alignmentThresholdReset,
              ),
              const SizedBox(height: 24),
              // Coverage Threshold (cache validation)
              SettingsSliderCard(
                title: i18n.coverageThreshold,
                subtitle: i18n.coverageThresholdSubtitle,
                value: provider.translationCoverageThreshold.current.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                label: '${provider.translationCoverageThreshold.current}%',
                valueText: '${provider.translationCoverageThreshold.current}%',
                onChanged: (value) =>
                    provider.setTranslationCoverageThreshold(value.toInt()),
                onReset: provider.translationCoverageThreshold.changed
                    ? () => provider.setTranslationCoverageThreshold(
                        provider.translationCoverageThreshold.defaultValue,
                      )
                    : null,
                resetTooltip: i18n.coverageThresholdReset,
              ),
              const SizedBox(height: 24),
              // LLM Configuration
              LlmConfigurationCard(provider: provider),
            ],
          ],
        );
      },
    );
  }
}

class LlmConfigurationCard extends StatelessWidget {
  final LyricsProvider provider;

  const LlmConfigurationCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final i18n = t.settings.translation;
    return SettingsCardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            i18n.llmTitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Endpoint
          TextFormField(
            initialValue: provider.llmApiEndpoint.current,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: i18n.llmEndpointLabel,
              labelStyle: const TextStyle(color: Colors.white54),
              hintText: i18n.llmEndpointHint,
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.black26,
            ),
            onChanged: (value) => provider.setLlmApiEndpoint(value),
          ),
          const SizedBox(height: 12),
          // API Key
          TextFormField(
            initialValue: provider.llmApiKey.current,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: i18n.llmApiKeyLabel,
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.black26,
            ),
            obscureText: true,
            onChanged: (value) => provider.setLlmApiKey(value),
          ),
          const SizedBox(height: 12),
          // Model
          TextFormField(
            initialValue: provider.llmModel.current,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: i18n.llmModelLabel,
              labelStyle: const TextStyle(color: Colors.white54),
              hintText: i18n.llmModelHint,
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.black26,
            ),
            onChanged: (value) => provider.setLlmModel(value),
          ),
          const SizedBox(height: 16),
          // Reasoning Effort Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i18n.llmReasoningTitle,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      i18n.llmReasoningSubtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: provider.llmReasoningEffort.current,
                dropdownColor: Colors.black87,
                style: const TextStyle(color: Colors.white),
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(
                    value: 'none',
                    child: Text(i18n.llmReasoningNone),
                  ),
                  DropdownMenuItem(
                    value: 'low',
                    child: Text(i18n.llmReasoningLow),
                  ),
                  DropdownMenuItem(
                    value: 'medium',
                    child: Text(i18n.llmReasoningMedium),
                  ),
                  DropdownMenuItem(
                    value: 'high',
                    child: Text(i18n.llmReasoningHigh),
                  ),
                  DropdownMenuItem(
                    value: 'auto',
                    child: Text(i18n.llmReasoningAuto),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    provider.setLlmReasoningEffort(value);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
