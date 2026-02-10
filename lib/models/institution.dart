import 'package:flutter/material.dart';

class Institution {
  final String id;
  final String name;
  final String urlPattern;
  final String category;
  final Color color;
  final bool isCustom;
  final DateTime? createdAt;

  const Institution({
    required this.id,
    required this.name,
    required this.urlPattern,
    required this.category,
    required this.color,
    this.isCustom = false,
    this.createdAt,
  });

  String get siteFilter => 'site:$urlPattern';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url_pattern': urlPattern,
        'category': category,
        'color_hex': '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}',
        'is_custom': isCustom,
        'created_at': createdAt?.toIso8601String(),
      };

  factory Institution.fromJson(Map<String, dynamic> json) {
    final colorHex = json['color_hex'] as String? ?? '#FF0000';
    final colorValue = int.parse(colorHex.replaceFirst('#', ''), radix: 16);
    return Institution(
      id: json['id'] as String,
      name: json['name'] as String,
      urlPattern: json['url_pattern'] as String,
      category: json['category'] as String? ?? 'Other',
      color: Color(colorValue),
      isCustom: json['is_custom'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Institution copyWith({
    String? id,
    String? name,
    String? urlPattern,
    String? category,
    Color? color,
    bool? isCustom,
    DateTime? createdAt,
  }) {
    return Institution(
      id: id ?? this.id,
      name: name ?? this.name,
      urlPattern: urlPattern ?? this.urlPattern,
      category: category ?? this.category,
      color: color ?? this.color,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Institution &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class InstitutionCategory {
  final String name;
  final Color color;
  final List<Institution> institutions;

  const InstitutionCategory({
    required this.name,
    required this.color,
    required this.institutions,
  });
}

// Pre-configured institutions
class DefaultInstitutions {
  static const Color lawEnforcementColor = Color(0xFFD32F2F);
  static const Color justiceColor = Color(0xFF8E24AA);
  static const Color intelligenceColor = Color(0xFF1565C0);
  static const Color financialColor = Color(0xFF558B2F);
  static const Color stateDiplomaticColor = Color(0xFF00897B);
  static const Color archivesColor = Color(0xFF6D4C41);
  static const Color legislativeColor = Color(0xFFE65100);
  static const Color internationalColor = Color(0xFFFF8F00);

  static List<Institution> get all => [
        // Law Enforcement
        const Institution(
          id: 'fbi',
          name: 'FBI',
          urlPattern: 'fbi.gov',
          category: 'Law Enforcement',
          color: lawEnforcementColor,
        ),
        const Institution(
          id: 'dea',
          name: 'DEA',
          urlPattern: 'dea.gov',
          category: 'Law Enforcement',
          color: lawEnforcementColor,
        ),
        const Institution(
          id: 'usmarshals',
          name: 'US Marshals',
          urlPattern: 'usmarshals.gov',
          category: 'Law Enforcement',
          color: lawEnforcementColor,
        ),
        const Institution(
          id: 'ice',
          name: 'ICE',
          urlPattern: 'ice.gov',
          category: 'Law Enforcement',
          color: lawEnforcementColor,
        ),
        const Institution(
          id: 'atf',
          name: 'ATF',
          urlPattern: 'atf.gov',
          category: 'Law Enforcement',
          color: lawEnforcementColor,
        ),

        // Justice
        const Institution(
          id: 'doj',
          name: 'Department of Justice',
          urlPattern: 'justice.gov',
          category: 'Justice',
          color: justiceColor,
        ),
        const Institution(
          id: 'pacer',
          name: 'Federal Courts (PACER)',
          urlPattern: 'uscourts.gov',
          category: 'Justice',
          color: justiceColor,
        ),
        const Institution(
          id: 'supremecourt',
          name: 'Supreme Court',
          urlPattern: 'supremecourt.gov',
          category: 'Justice',
          color: justiceColor,
        ),
        const Institution(
          id: 'courtlistener',
          name: 'CourtListener',
          urlPattern: 'courtlistener.com',
          category: 'Justice',
          color: justiceColor,
        ),

        // Intelligence
        const Institution(
          id: 'cia',
          name: 'CIA Reading Room',
          urlPattern: 'cia.gov',
          category: 'Intelligence',
          color: intelligenceColor,
        ),
        const Institution(
          id: 'dni',
          name: 'DNI',
          urlPattern: 'dni.gov',
          category: 'Intelligence',
          color: intelligenceColor,
        ),
        const Institution(
          id: 'nsa',
          name: 'NSA',
          urlPattern: 'nsa.gov',
          category: 'Intelligence',
          color: intelligenceColor,
        ),

        // Financial
        const Institution(
          id: 'sec',
          name: 'SEC',
          urlPattern: 'sec.gov',
          category: 'Financial',
          color: financialColor,
        ),
        const Institution(
          id: 'fincen',
          name: 'FinCEN',
          urlPattern: 'fincen.gov',
          category: 'Financial',
          color: financialColor,
        ),
        const Institution(
          id: 'treasury',
          name: 'Treasury',
          urlPattern: 'treasury.gov',
          category: 'Financial',
          color: financialColor,
        ),
        const Institution(
          id: 'irs',
          name: 'IRS',
          urlPattern: 'irs.gov',
          category: 'Financial',
          color: financialColor,
        ),

        // State/Diplomatic
        const Institution(
          id: 'state',
          name: 'State Department',
          urlPattern: 'state.gov',
          category: 'State/Diplomatic',
          color: stateDiplomaticColor,
        ),
        const Institution(
          id: 'foia',
          name: 'FOIA.gov',
          urlPattern: 'foia.gov',
          category: 'State/Diplomatic',
          color: stateDiplomaticColor,
        ),

        // Archives
        const Institution(
          id: 'archives',
          name: 'National Archives',
          urlPattern: 'archives.gov',
          category: 'Archives',
          color: archivesColor,
        ),
        const Institution(
          id: 'loc',
          name: 'Library of Congress',
          urlPattern: 'loc.gov',
          category: 'Archives',
          color: archivesColor,
        ),
        const Institution(
          id: 'govinfo',
          name: 'GovInfo',
          urlPattern: 'govinfo.gov',
          category: 'Archives',
          color: archivesColor,
        ),

        // Legislative
        const Institution(
          id: 'congress',
          name: 'Congress.gov',
          urlPattern: 'congress.gov',
          category: 'Legislative',
          color: legislativeColor,
        ),
        const Institution(
          id: 'senate',
          name: 'Senate',
          urlPattern: 'senate.gov',
          category: 'Legislative',
          color: legislativeColor,
        ),
        const Institution(
          id: 'house',
          name: 'House of Representatives',
          urlPattern: 'house.gov',
          category: 'Legislative',
          color: legislativeColor,
        ),

        // International
        const Institution(
          id: 'interpol',
          name: 'Interpol',
          urlPattern: 'interpol.int',
          category: 'International',
          color: internationalColor,
        ),
        const Institution(
          id: 'ukgov',
          name: 'UK Government',
          urlPattern: 'gov.uk',
          category: 'International',
          color: internationalColor,
        ),
        const Institution(
          id: 'ukjudiciary',
          name: 'UK Judiciary',
          urlPattern: 'judiciary.uk',
          category: 'International',
          color: internationalColor,
        ),
      ];

  static List<InstitutionCategory> get categories {
    final grouped = <String, List<Institution>>{};
    final categoryColors = <String, Color>{};

    for (final inst in all) {
      grouped.putIfAbsent(inst.category, () => []).add(inst);
      categoryColors[inst.category] = inst.color;
    }

    return grouped.entries
        .map((e) => InstitutionCategory(
              name: e.key,
              color: categoryColors[e.key]!,
              institutions: e.value,
            ))
        .toList();
  }
}
