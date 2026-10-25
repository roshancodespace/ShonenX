import 'package:flutter/material.dart';

class AddonInfo {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final bool isInstalled;
  final bool isDownloading;
  final double downloadProgress;
  final bool hasUpdate;

  const AddonInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.isInstalled = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.hasUpdate = false,
  });

  AddonInfo copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    bool? isInstalled,
    bool? isDownloading,
    double? downloadProgress,
    bool? hasUpdate,
  }) {
    return AddonInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isInstalled: isInstalled ?? this.isInstalled,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      hasUpdate: hasUpdate ?? this.hasUpdate,
    );
  }
}
