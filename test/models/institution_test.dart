import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zephaniah/models/institution.dart';

void main() {
  group('Institution', () {
    test('creates institution with all properties', () {
      final inst = Institution(
        id: 'test_id',
        name: 'Test Institution',
        urlPattern: 'test.gov',
        category: 'Test Category',
        color: Colors.blue,
        isCustom: false,
      );

      expect(inst.id, 'test_id');
      expect(inst.name, 'Test Institution');
      expect(inst.urlPattern, 'test.gov');
      expect(inst.category, 'Test Category');
      expect(inst.color, Colors.blue);
      expect(inst.isCustom, false);
    });

    test('generates correct site filter', () {
      final inst = Institution(
        id: 'fbi',
        name: 'FBI',
        urlPattern: 'fbi.gov',
        category: 'Law Enforcement',
        color: Colors.red,
      );

      expect(inst.siteFilter, 'site:fbi.gov');
    });

    test('converts to and from JSON', () {
      final original = Institution(
        id: 'test_id',
        name: 'Test Institution',
        urlPattern: 'test.gov',
        category: 'Test Category',
        color: const Color(0xFFFF0000),
        isCustom: true,
        createdAt: DateTime(2024, 1, 1),
      );

      final json = original.toJson();
      final restored = Institution.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.urlPattern, original.urlPattern);
      expect(restored.category, original.category);
      expect(restored.isCustom, original.isCustom);
    });

    test('copyWith creates modified copy', () {
      final original = Institution(
        id: 'test_id',
        name: 'Original Name',
        urlPattern: 'test.gov',
        category: 'Category',
        color: Colors.blue,
      );

      final modified = original.copyWith(name: 'Modified Name');

      expect(modified.id, original.id);
      expect(modified.name, 'Modified Name');
      expect(modified.urlPattern, original.urlPattern);
    });

    test('equality based on id', () {
      final inst1 = Institution(
        id: 'same_id',
        name: 'Name 1',
        urlPattern: 'test1.gov',
        category: 'Category',
        color: Colors.red,
      );

      final inst2 = Institution(
        id: 'same_id',
        name: 'Different Name',
        urlPattern: 'test2.gov',
        category: 'Different Category',
        color: Colors.blue,
      );

      final inst3 = Institution(
        id: 'different_id',
        name: 'Name 1',
        urlPattern: 'test1.gov',
        category: 'Category',
        color: Colors.red,
      );

      expect(inst1, inst2);
      expect(inst1, isNot(inst3));
    });
  });

  group('DefaultInstitutions', () {
    test('contains all expected categories', () {
      final categories = DefaultInstitutions.categories;
      final categoryNames = categories.map((c) => c.name).toSet();

      expect(categoryNames, contains('Law Enforcement'));
      expect(categoryNames, contains('Justice'));
      expect(categoryNames, contains('Intelligence'));
      expect(categoryNames, contains('Financial'));
      expect(categoryNames, contains('State/Diplomatic'));
      expect(categoryNames, contains('Archives'));
      expect(categoryNames, contains('Legislative'));
      expect(categoryNames, contains('International'));
    });

    test('all institutions have required fields', () {
      for (final inst in DefaultInstitutions.all) {
        expect(inst.id, isNotEmpty);
        expect(inst.name, isNotEmpty);
        expect(inst.urlPattern, isNotEmpty);
        expect(inst.category, isNotEmpty);
      }
    });

    test('contains FBI institution', () {
      final fbi = DefaultInstitutions.all.firstWhere((i) => i.id == 'fbi');
      expect(fbi.name, 'FBI');
      expect(fbi.urlPattern, 'fbi.gov');
      expect(fbi.category, 'Law Enforcement');
    });
  });
}
