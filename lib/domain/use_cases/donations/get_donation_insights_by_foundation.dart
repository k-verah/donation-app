import 'package:donation_app/domain/entities/donations/donation.dart';
import 'package:donation_app/domain/entities/foundations/foundation_point.dart';
import 'package:donation_app/domain/entities/sensors/geo_point.dart';
import 'package:donation_app/domain/repositories/donations/donations_repository.dart';
import 'package:donation_app/domain/repositories/foundations/foundation_point_repository.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' show cos, asin, sqrt;

class FoundationInsight {
  final FoundationPoint foundation;
  final int donationCount;
  final double averageDistance; 

  FoundationInsight({
    required this.foundation,
    required this.donationCount,
    required this.averageDistance,
  });
}

class GetDonationInsightsByFoundation {
  final DonationsRepository donationsRepo;
  final FoundationPointRepository foundationsRepo;

  GetDonationInsightsByFoundation({
    required this.donationsRepo,
    required this.foundationsRepo,
  });

  Future<List<FoundationInsight>> call({
    required String userId,
    required GeoPoint? userLocation,
  }) async {

    final donationsStream = donationsRepo.streamByUid(userId);
    final donations = await donationsStream.first;


    final foundations = await foundationsRepo.fetchAll();


    final insights = await compute(
      _calculateInsights,
      {
        'donations': donations,
        'foundations': foundations,
        'userLocation': userLocation,
      },
    );

    return insights;
  }


  static List<FoundationInsight> _calculateInsights(Map<String, dynamic> data) {
    final donations = data['donations'] as List<Donation>;
    final foundations = data['foundations'] as List<FoundationPoint>;
    final userLocation = data['userLocation'] as GeoPoint?;


    final foundationsMap = {
      for (final f in foundations) f.id: f,
    };


    final Map<String, List<Donation>> donationsByFoundation = {};
    
    for (final donation in donations) {
      final foundationKey = _mapDonationTypeToFoundationIdStatic(
        donation.type,
        foundations,
      );
      
      if (foundationKey != null) {
        donationsByFoundation.putIfAbsent(
          foundationKey,
          () => [],
        ).add(donation);
      }
    }


    final List<FoundationInsight> insights = [];

    for (final foundation in foundations) {

      final matchingDonations = donationsByFoundation[foundation.id] ?? [];


      double avgDistance = 0.0;
      if (userLocation != null && matchingDonations.isNotEmpty) {
        final distance = _calculateDistanceStatic(
          userLocation,
          foundation.pos,
        );
        avgDistance = distance;
      }


      if (matchingDonations.isNotEmpty) {
        insights.add(FoundationInsight(
          foundation: foundation,
          donationCount: matchingDonations.length,
          averageDistance: avgDistance,
        ));
      }
    }


    insights.sort((a, b) => b.donationCount.compareTo(a.donationCount));

    return insights;
  }


  static String? _mapDonationTypeToFoundationIdStatic(
    String donationType,
    List<FoundationPoint> foundations,
  ) {
    final type = donationType.toLowerCase().trim();
    final clothingFoundations = foundations
        .where((f) => f.cause == 'Clothing')
        .toList();
    
    if (clothingFoundations.isEmpty) return null;
    
    final typeIndex = _getTypeIndexStatic(type);
    final foundationIndex = typeIndex % clothingFoundations.length;
    return clothingFoundations[foundationIndex].id;
  }

  static int _getTypeIndexStatic(String type) {
    if (type.contains('shirt') && !type.contains('t-shirt')) {
      return 0;
    } else if (type.contains('t-shirt')) {
      return 1;
    } else if (type.contains('pants')) {
      return 2;
    } else if (type.contains('jacket')) {
      return 3;
    } else if (type.contains('dress')) {
      return 4;
    } else if (type.contains('accessory')) {
      return 5;
    }
    return type.hashCode.abs() % 6;
  }

  static double _calculateDistanceStatic(GeoPoint a, GeoPoint b) {
    const R = 6371000.0; // Radio de la Tierra en metros
    final dLat = _degStatic(b.lat - a.lat);
    final dLon = _degStatic(b.lng - a.lng);
    final la1 = _degStatic(a.lat);
    final la2 = _degStatic(b.lat);
    final h = _hStatic(dLat) + cos(la1) * cos(la2) * _hStatic(dLon);
    return 2 * R * asin(sqrt(h));
  }

  static double _degStatic(double d) => d * 3.141592653589793 / 180.0;
  static double _hStatic(double x) => (1 - cos(x)) / 2;
}

